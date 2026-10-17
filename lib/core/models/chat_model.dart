import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String generateId() => _uuid.v4();

class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  String content;
  final String? model;
  String? audioUrl;
  final List<String> imageUrls;
  final List<String> fileNames;
  final DateTime timestamp;
  bool isStreaming;
  bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.model,
    DateTime? timestamp,
    this.imageUrls = const [],
    this.fileNames = const [],
    this.audioUrl,
    this.isStreaming = false,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? generateId(),
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      model: json['model'] as String?,
      audioUrl: json['audioUrl'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fileNames: (json['fileNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'model': model,
      'audioUrl': audioUrl,
      'imageUrls': imageUrls,
      'fileNames': fileNames,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // AI Stream API request format
  Map<String, dynamic> toApiMessage() {
    return {
      'role': role,
      'content': content,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
    };
  }
}

class ChatSession {
  final String id;
  String title;
  String model;
  bool pinned;
  final bool isBranch;
  final String? projectId;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ChatMessage> messages;
  bool isPersisted;

  ChatSession({
    required this.id,
    required this.title,
    required this.model,
    this.pinned = false,
    this.isBranch = false,
    this.projectId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    this.isPersisted = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messages = messages ?? [];

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    List<ChatMessage> parsedMessages = [];
    if (json['messages'] != null && json['messages'] is List) {
      parsedMessages = (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return ChatSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'New Chat',
      model: json['model'] as String? ?? 'google/gemini-2.0-flash-exp:free',
      pinned: json['pinned'] as bool? ?? false,
      isBranch: json['isBranch'] as bool? ?? false,
      projectId: json['projectId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      messages: parsedMessages,
      isPersisted: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'model': model,
      'pinned': pinned,
      'isBranch': isBranch,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}
