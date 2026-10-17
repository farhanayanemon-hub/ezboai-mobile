import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/project_model.dart';

class ProjectsState {
  final List<ProjectModel> projects;
  final ProjectModel? currentProject;
  final bool isLoading;
  final String? error;

  const ProjectsState({
    this.projects = const [],
    this.currentProject,
    this.isLoading = false,
    this.error,
  });

  ProjectsState copyWith({
    List<ProjectModel>? projects,
    ProjectModel? currentProject,
    bool? isLoading,
    String? error,
    bool clearCurrent = false,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      currentProject: clearCurrent ? null : (currentProject ?? this.currentProject),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ApiClient _api = ApiClient();

  ProjectsNotifier() : super(const ProjectsState()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiEndpoints.projects);
      if (res.statusCode == 200 && res.data != null) {
        final List<dynamic> list = res.data['projects'] ?? [];
        final parsed = list.map((p) => ProjectModel.fromJson(p)).toList();
        state = state.copyWith(projects: parsed, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<ProjectModel?> getProjectDetail(String projectId) async {
    try {
      final res = await _api.get('${ApiEndpoints.projects}/$projectId');
      if (res.statusCode == 200 && res.data != null) {
        final proj = ProjectModel.fromJson(res.data['project']);
        state = state.copyWith(currentProject: proj);
        return proj;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> createProject({required String name, String? description}) async {
    try {
      final res = await _api.post(
        ApiEndpoints.projects,
        data: {'name': name.trim(), 'description': description?.trim()},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        loadProjects();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> updateProject(String projectId, {String? name, String? description, String? customInstructions}) async {
    try {
      final res = await _api.put(
        '${ApiEndpoints.projects}/$projectId',
        data: {
          if (name != null) 'name': name.trim(),
          if (description != null) 'description': description.trim(),
          if (customInstructions != null) 'customInstructions': customInstructions.trim(),
        },
      );
      if (res.statusCode == 200) {
        loadProjects();
        getProjectDetail(projectId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      final res = await _api.delete('${ApiEndpoints.projects}/$projectId');
      if (res.statusCode == 200) {
        loadProjects();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Upload context document to project
  Future<bool> uploadProjectFile(
    String projectId, {
    required String filename,
    required String content,
    String mimeType = 'text/plain',
  }) async {
    try {
      final res = await _api.post(
        '${ApiEndpoints.projects}/$projectId/files',
        data: {
          'filename': filename,
          'content': content,
          'mimeType': mimeType,
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await getProjectDetail(projectId);
        await loadProjects();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Delete context document from project
  Future<bool> deleteProjectFile(String projectId, String fileId) async {
    try {
      final res = await _api.delete('${ApiEndpoints.projects}/$projectId/files/$fileId');
      if (res.statusCode == 200) {
        await getProjectDetail(projectId);
        await loadProjects();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier();
});
