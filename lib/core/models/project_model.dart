class ProjectFile {
  final String id;
  final String filename;
  final String mimeType;
  final String content;
  final DateTime createdAt;

  ProjectFile({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? 'file.txt',
      mimeType: json['mimeType'] as String? ?? 'text/plain',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class ProjectModel {
  final String id;
  String name;
  String? description;
  String? customInstructions;
  int fileCount;
  int chatCount;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ProjectFile> files;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.customInstructions,
    this.fileCount = 0,
    this.chatCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProjectFile>? files,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        files = files ?? [];

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    List<ProjectFile> parsedFiles = [];
    if (json['files'] != null && json['files'] is List) {
      parsedFiles = (json['files'] as List)
          .map((f) => ProjectFile.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    return ProjectModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Project',
      description: json['description'] as String?,
      customInstructions: json['customInstructions'] as String?,
      fileCount: (json['fileCount'] as num?)?.toInt() ?? parsedFiles.length,
      chatCount: (json['chatCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      files: parsedFiles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'customInstructions': customInstructions,
    };
  }
}
