import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/sse_stream_reader.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/models/model_info.dart';
import '../../auth/controllers/auth_controller.dart';

const _uuid = Uuid();
String _generateId() => _uuid.v4();

class ChatState {
  final List<ModelInfo> models;
  final ModelInfo selectedModel;
  final ChatSession? currentChat;
  final List<ChatSession> chatList;
  final bool isStreaming;
  final bool isWebSearch;
  final bool isLoadingHistory;
  final List<String> pendingImages; // Local file paths / base64
  final List<String> pendingFileNames;
  final String? activeAudioUrl;
  final String? activeProjectId;

  const ChatState({
    this.models = const [],
    required this.selectedModel,
    this.currentChat,
    this.chatList = const [],
    this.isStreaming = false,
    this.isWebSearch = false,
    this.isLoadingHistory = false,
    this.pendingImages = const [],
    this.pendingFileNames = const [],
    this.activeAudioUrl,
    this.activeProjectId,
  });

  ChatState copyWith({
    List<ModelInfo>? models,
    ModelInfo? selectedModel,
    ChatSession? currentChat,
    List<ChatSession>? chatList,
    bool? isStreaming,
    bool? isWebSearch,
    bool? isLoadingHistory,
    List<String>? pendingImages,
    List<String>? pendingFileNames,
    String? activeAudioUrl,
    String? activeProjectId,
    bool clearActiveAudio = false,
    bool clearChat = false,
    bool clearProject = false,
  }) {
    return ChatState(
      models: models ?? this.models,
      selectedModel: selectedModel ?? this.selectedModel,
      currentChat: clearChat ? null : (currentChat ?? this.currentChat),
      chatList: chatList ?? this.chatList,
      isStreaming: isStreaming ?? this.isStreaming,
      isWebSearch: isWebSearch ?? this.isWebSearch,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      pendingImages: pendingImages ?? this.pendingImages,
      pendingFileNames: pendingFileNames ?? this.pendingFileNames,
      activeAudioUrl: clearActiveAudio ? null : (activeAudioUrl ?? this.activeAudioUrl),
      activeProjectId: clearProject ? null : (activeProjectId ?? this.activeProjectId),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiClient _api = ApiClient();
  final SSEStreamReader _streamReader = SSEStreamReader();
  final Ref _ref;

  ChatNotifier(this._ref)
      : super(
          ChatState(
            models: ModelInfo.defaultChatModels,
            selectedModel: ModelInfo.defaultChatModels.first,
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    final savedModelName = await SecureStorageService.getSelectedModel();
    final isWebSearch = await SecureStorageService.getWebSearch();

    state = state.copyWith(isWebSearch: isWebSearch);
    await loadModels(savedModelName);
    await loadChats();
  }

  Future<void> loadModels([String? preferModel]) async {
    try {
      final response = await _api.get(ApiEndpoints.models);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data is List
            ? response.data
            : (response.data['models'] as List<dynamic>? ?? []);

        if (list.isNotEmpty) {
          final fetchedModels = list.map((m) => ModelInfo.fromJson(m)).toList();
          ModelInfo selected = fetchedModels.first;

          if (preferModel != null) {
            final match = fetchedModels.firstWhere(
              (m) => m.name == preferModel,
              orElse: () => fetchedModels.first,
            );
            selected = match;
          }

          state = state.copyWith(models: fetchedModels, selectedModel: selected);
          return;
        }
      }
    } catch (_) {}

    // Fallback to defaults
    state = state.copyWith(models: ModelInfo.defaultChatModels);
  }

  void selectModel(ModelInfo model) {
    state = state.copyWith(selectedModel: model);
    SecureStorageService.saveSelectedModel(model.name);
  }

  void toggleWebSearch() {
    final updated = !state.isWebSearch;
    state = state.copyWith(isWebSearch: updated);
    SecureStorageService.saveWebSearch(updated);
  }

  void addPendingImage(String pathOrBase64) {
    state = state.copyWith(pendingImages: [...state.pendingImages, pathOrBase64]);
  }

  void removePendingImage(int index) {
    final list = List<String>.from(state.pendingImages)..removeAt(index);
    state = state.copyWith(pendingImages: list);
  }

  void addPendingFile(String name) {
    state = state.copyWith(pendingFileNames: [...state.pendingFileNames, name]);
  }

  void removePendingFile(int index) {
    final list = List<String>.from(state.pendingFileNames)..removeAt(index);
    state = state.copyWith(pendingFileNames: list);
  }

  void startNewChat({String? projectId}) {
    state = state.copyWith(
      clearChat: true,
      pendingImages: [],
      pendingFileNames: [],
      activeProjectId: projectId,
    );
  }

  Future<void> loadChats() async {
    state = state.copyWith(isLoadingHistory: true);
    try {
      final response = await _api.get(ApiEndpoints.chats);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> raw = response.data['chats'] ?? [];
        final parsed = raw.map((c) => ChatSession.fromJson(c)).toList();
        state = state.copyWith(chatList: parsed, isLoadingHistory: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  Future<void> selectChat(String chatId) async {
    try {
      final response = await _api.get('${ApiEndpoints.chats}/$chatId');
      if (response.statusCode == 200 && response.data != null) {
        final session = ChatSession.fromJson(response.data['chat']);
        state = state.copyWith(
          currentChat: session,
          activeProjectId: session.projectId,
        );
      }
    } catch (_) {}
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && state.pendingImages.isEmpty) return;

    // Build user message
    final userMsg = ChatMessage(
      id: _generateId(),
      role: 'user',
      content: trimmed,
      imageUrls: List.from(state.pendingImages),
      fileNames: List.from(state.pendingFileNames),
    );

    // Build placeholder assistant message
    final assistantMsg = ChatMessage(
      id: _generateId(),
      role: 'assistant',
      content: '',
      model: state.selectedModel.displayName,
      isStreaming: true,
    );

    ChatSession session;
    if (state.currentChat == null) {
      session = ChatSession(
        id: _generateId(),
        title: trimmed.isNotEmpty
            ? (trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed)
            : 'Image Query',
        model: state.selectedModel.name,
        projectId: state.activeProjectId,
        messages: [userMsg, assistantMsg],
        isPersisted: false,
      );
    } else {
      session = state.currentChat!;
      session.messages.add(userMsg);
      session.messages.add(assistantMsg);
    }

    state = state.copyWith(
      currentChat: session,
      isStreaming: true,
      pendingImages: [],
      pendingFileNames: [],
    );

    // Effective model name with web search suffix
    String effectiveModel = state.selectedModel.name;
    if (state.isWebSearch && !effectiveModel.endsWith(':online')) {
      effectiveModel = '$effectiveModel:online';
    }

    final apiMessages = session.messages
        .where((m) => !m.isStreaming || m.content.isNotEmpty)
        .map((m) => m.toApiMessage())
        .toList();

    // In case assistantMsg was filtered out because it's empty, userMsg is the last
    if (apiMessages.isEmpty || apiMessages.last['role'] != 'user') {
      apiMessages.add(userMsg.toApiMessage());
    }

    final body = {
      'model': effectiveModel,
      'messages': apiMessages,
      'temperature': 0.7,
      'maxTokens': 4096,
      if (session.projectId != null || state.activeProjectId != null)
        'projectId': session.projectId ?? state.activeProjectId,
    };

    await _streamReader.streamChat(
      body: body,
      onChunk: (chunk) {
        assistantMsg.content += chunk;
        state = state.copyWith(currentChat: session);
      },
      onDone: () {
        assistantMsg.isStreaming = false;
        state = state.copyWith(isStreaming: false, currentChat: session);
        _saveChatToServer(session);
        _ref.read(authProvider.notifier).refreshProfile();
      },
      onError: (err) {
        assistantMsg.isStreaming = false;
        assistantMsg.isError = true;
        assistantMsg.content = 'Error: $err';
        state = state.copyWith(isStreaming: false, currentChat: session);
      },
    );
  }

  Future<void> _saveChatToServer(ChatSession session) async {
    try {
      final payload = {
        'title': session.title,
        'model': session.model,
        'messages': session.messages.map((m) => m.toJson()).toList(),
        if (session.projectId != null) 'projectId': session.projectId,
      };

      if (session.isPersisted) {
        await _api.put('${ApiEndpoints.chats}/${session.id}', data: payload);
      } else {
        final res = await _api.post(ApiEndpoints.chats, data: payload);
        if (res.statusCode == 200 && res.data['chat'] != null) {
          session = ChatSession.fromJson(res.data['chat']);
          state = state.copyWith(currentChat: session);
        }
      }
      loadChats();
    } catch (_) {}
  }

  void cancelStreaming() {
    _streamReader.cancel();
    if (state.currentChat != null && state.currentChat!.messages.isNotEmpty) {
      final last = state.currentChat!.messages.last;
      if (last.isStreaming) {
        last.isStreaming = false;
      }
    }
    state = state.copyWith(isStreaming: false);
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _api.delete('${ApiEndpoints.chats}/$chatId');
      if (state.currentChat?.id == chatId) {
        startNewChat();
      }
      loadChats();
    } catch (_) {}
  }

  Future<void> pinChat(String chatId, bool pinned) async {
    try {
      await _api.put('${ApiEndpoints.chats}/$chatId', data: {'pinned': pinned});
      loadChats();
    } catch (_) {}
  }

  // Rename Chat
  Future<bool> renameChat(String chatId, String newTitle) async {
    try {
      final res = await _api.put(
        '${ApiEndpoints.chats}/$chatId',
        data: {'title': newTitle.trim()},
      );
      if (res.statusCode == 200) {
        if (state.currentChat?.id == chatId) {
          state.currentChat!.title = newTitle.trim();
          state = state.copyWith(currentChat: state.currentChat);
        }
        await loadChats();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Branch Chat
  Future<bool> branchChat(String sourceChatId, int branchAtIndex) async {
    try {
      final res = await _api.post(
        ApiEndpoints.branchChat,
        data: {
          'sourceChatId': sourceChatId,
          'branchAtIndex': branchAtIndex,
        },
      );
      if (res.statusCode == 200 && res.data['chat'] != null) {
        final branched = ChatSession.fromJson(res.data['chat']);
        state = state.copyWith(currentChat: branched);
        await loadChats();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // TTS Read Aloud for assistant message
  Future<String?> readAloud(ChatMessage msg, int index) async {
    if (state.currentChat == null) return null;
    try {
      final res = await _api.post(
        ApiEndpoints.readAloud,
        data: {
          'chatId': state.currentChat!.id,
          'messageIndex': index,
          'text': msg.content,
        },
      );
      if (res.statusCode == 200 && res.data['audioUrl'] != null) {
        final url = res.data['audioUrl'] as String;
        msg.audioUrl = url;
        state = state.copyWith(activeAudioUrl: url);
        return url;
      }
    } catch (_) {}
    return null;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
