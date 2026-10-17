import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/projects_controller.dart';
import '../../chat/controllers/chat_controller.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isLoading = true;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final proj = await ref.read(projectsProvider.notifier).getProjectDetail(widget.projectId);
    if (mounted && proj != null) {
      _nameController.text = proj.name;
      _descController.text = proj.description ?? '';
      _instructionsController.text = proj.customInstructions ?? '';
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await ref.read(projectsProvider.notifier).updateProject(
          widget.projectId,
          name: _nameController.text,
          description: _descController.text,
          customInstructions: _instructionsController.text,
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project saved successfully'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'csv', 'json', 'html', 'js', 'css'],
      );

      if (res != null && res.files.single.path != null) {
        final file = File(res.files.single.path!);
        final content = await file.readAsString();
        final filename = res.files.single.name;

        String mimeType = 'text/plain';
        if (filename.endsWith('.md')) mimeType = 'text/markdown';
        if (filename.endsWith('.csv')) mimeType = 'text/csv';
        if (filename.endsWith('.json')) mimeType = 'application/json';
        if (filename.endsWith('.html')) mimeType = 'text/html';

        setState(() => _isUploadingFile = true);

        final success = await ref.read(projectsProvider.notifier).uploadProjectFile(
              widget.projectId,
              filename: filename,
              content: content,
              mimeType: mimeType,
            );

        if (mounted) {
          setState(() => _isUploadingFile = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Document uploaded to project context!'), backgroundColor: AppColors.success),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload document'), backgroundColor: AppColors.error),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmDeleteFile(String fileId, String filename) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Document?'),
        content: Text('Are you sure you want to remove "$filename" from project context?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(projectsProvider.notifier).deleteProjectFile(widget.projectId, fileId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(projectsProvider).currentProject;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(project?.name ?? 'Project Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () {
              ref.read(projectsProvider.notifier).deleteProject(widget.projectId);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Project Name',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descController,
                    labelText: 'Description',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _instructionsController,
                    labelText: 'Project Custom Instructions',
                    hintText: 'Define specialized guidelines, persona, or rules the AI should follow in this project...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Context Documents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Context Documents',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      TextButton.icon(
                        icon: _isUploadingFile
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                              )
                            : const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('Add Document', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        onPressed: _isUploadingFile ? null : _pickAndUploadDocument,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (project?.files.isEmpty ?? true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No documents uploaded yet. Upload .txt, .md, .csv, or .json files to provide context to the AI.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ...project!.files.map((file) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_rounded, size: 20, color: AppColors.primaryLight),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                file.filename,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              onPressed: () => _confirmDeleteFile(file.id, file.filename),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Save Project Details',
                    onPressed: _handleSave,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Start Scoped Project Chat',
                    isOutlined: true,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    onPressed: () {
                      ref.read(chatProvider.notifier).startNewChat(projectId: widget.projectId);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
