import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/credit_badge.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../studio/controllers/studio_controller.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import 'model_selector_sheet.dart';
import 'chat_drawer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    final chatNotifier = ref.read(chatProvider.notifier);
    if (ref.read(chatProvider).isStreaming) {
      chatNotifier.cancelStreaming();
      return;
    }

    if (text.trim().isEmpty && ref.read(chatProvider).pendingImages.isEmpty) return;

    _textController.clear();
    await chatNotifier.sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        ref.read(chatProvider.notifier).addPendingImage(picked.path);
      }
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'json', 'md'],
      );
      if (res != null && res.files.single.path != null) {
        final path = res.files.single.path!;
        final name = res.files.single.name;
        ref.read(chatProvider.notifier).addPendingFile(name);

        try {
          final file = File(path);
          final text = await file.readAsString();
          if (text.isNotEmpty) {
            final truncated = text.length > 4000 ? '${text.substring(0, 4000)}\n...[truncated]' : text;
            setState(() {
              _textController.text = _textController.text.isEmpty
                  ? '[Context Document: $name]\n$truncated\n\n'
                  : '${_textController.text}\n\n[Context Document: $name]\n$truncated\n\n';
            });
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          final transcribed = await ref.read(studioProvider.notifier).transcribeAudio(path);
          if (transcribed != null && transcribed.trim().isNotEmpty) {
            setState(() {
              _textController.text = _textController.text.isEmpty
                  ? transcribed.trim()
                  : '${_textController.text.trim()} ${transcribed.trim()}';
            });
          }
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/mic_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: filePath);
          setState(() => _isRecording = true);
        }
      }
    } catch (_) {
      setState(() => _isRecording = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.secondaryLight),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_rounded, color: AppColors.warning),
                title: const Text('Upload Document (PDF, TXT, CSV)'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(authProvider).user;
    final messages = chatState.currentChat?.messages ?? [];

    if (chatState.isStreaming) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const ChatDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ModelSelectorSheet(
                models: chatState.models,
                selectedModel: chatState.selectedModel,
                onSelect: (m) => ref.read(chatProvider.notifier).selectModel(m),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chatState.selectedModel.displayName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        actions: [
          // Web Search Toggle
          IconButton(
            icon: Icon(
              Icons.travel_explore_rounded,
              color: chatState.isWebSearch ? AppColors.success : AppColors.textMuted,
            ),
            tooltip: 'Web Search (:online)',
            onPressed: () => ref.read(chatProvider.notifier).toggleWebSearch(),
          ),
          // Credit Badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CreditBadge(
              count: user?.credits.text ?? 50,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message List or Empty Suggestions
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        message: msg,
                        index: index,
                        onReadAloud: msg.isAssistant
                            ? () => ref.read(chatProvider.notifier).readAloud(msg, index)
                            : null,
                      );
                    },
                  ),
          ),

          // Pending attachments strip
          if (chatState.pendingImages.isNotEmpty || chatState.pendingFileNames.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.card,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...chatState.pendingImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(entry.value)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 10,
                            child: GestureDetector(
                              onTap: () => ref.read(chatProvider.notifier).removePendingImage(entry.key),
                              child: const CircleAvatar(
                                radius: 9,
                                backgroundColor: Colors.black87,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    ...chatState.pendingFileNames.asMap().entries.map((entry) {
                      return Chip(
                        label: Text(entry.value, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.surfaceElevated,
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => ref.read(chatProvider.notifier).removePendingFile(entry.key),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.textSecondary,
                    onPressed: _showAttachmentOptions,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: chatState.isWebSearch
                              ? 'Search the web & ask anything...'
                              : 'Ask EzboAI anything...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.mic_off_rounded : Icons.mic_rounded,
                      color: _isRecording ? AppColors.error : AppColors.textSecondary,
                    ),
                    tooltip: _isRecording ? 'Stop Recording' : 'Voice Dictation',
                    onPressed: _toggleRecording,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: chatState.isStreaming ? null : AppColors.primaryGradient,
                      color: chatState.isStreaming ? AppColors.error : null,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        chatState.isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      {'title': 'Write Code', 'prompt': 'Write a Python FastAPI service with JWT authentication'},
      {'title': 'Summarize & Analyze', 'prompt': 'Explain quantum computing in simple terms with metaphors'},
      {'title': 'Creative Writing', 'prompt': 'Write an engaging script for a sci-fi mystery teaser trailer'},
      {'title': 'Business Plan', 'prompt': 'Create a step-by-step launch strategy for a SaaS startup'},
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.auto_awesome, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'How can EzboAI help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a prompt below or start typing to begin',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ...suggestions.map((s) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  dense: true,
                  title: Text(s['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text(s['prompt']!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryLight),
                  onTap: () {
                    _textController.text = s['prompt']!;
                    _handleSend();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
