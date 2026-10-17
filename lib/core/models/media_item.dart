class MediaItem {
  final String id;
  final String type; // 'image', 'video', 'music', 'audio', 'sound_effect', 'transcription', 'voice_change'
  final String url;
  final String? prompt;
  final String? model;
  final String? aspectRatio;
  final String? mimeType;
  final int? fileSize;
  final int? durationMs;
  final String? text; // for audio/transcription
  final String? chatTitle;
  final DateTime createdAt;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.prompt,
    this.model,
    this.aspectRatio,
    this.mimeType,
    this.fileSize,
    this.durationMs,
    this.text,
    this.chatTitle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'image',
      url: json['url'] as String? ?? '',
      prompt: json['prompt'] as String? ?? json['text'] as String?,
      model: json['model'] as String?,
      aspectRatio: json['aspectRatio'] as String?,
      mimeType: json['mimeType'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? (json['duration'] as num?)?.toInt(),
      text: json['text'] as String?,
      chatTitle: json['chatTitle'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'prompt': prompt,
      'model': model,
      'aspectRatio': aspectRatio,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'durationMs': durationMs,
      'text': text,
      'chatTitle': chatTitle,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
