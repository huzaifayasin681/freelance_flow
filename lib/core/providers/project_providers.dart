import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../../shared/models/project_model.dart';
import '../../shared/models/client_model.dart';

/// Provider for projects stream
final projectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  return FirestoreService.getProjects();
});

/// Provider for active projects stream
final activeProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  return FirestoreService.getActiveProjects();
});

/// Provider for projects by client
final projectsByClientProvider = StreamProvider.family<List<ProjectModel>, String>((ref, clientId) {
  return FirestoreService.getProjectsByClient(clientId);
});

/// Provider for project search query
final projectSearchProvider = StateProvider<String>((ref) => '');

/// Provider for filtered projects based on search
final filteredProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectsProvider).value ?? [];
  final searchQuery = ref.watch(projectSearchProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return projects;
  }

  return projects.where((project) {
    return project.projectName.toLowerCase().contains(searchQuery) ||
           (project.description?.toLowerCase().contains(searchQuery) ?? false);
  }).toList();
});

/// Provider for project form state
final projectFormProvider = StateNotifierProvider.family<ProjectFormNotifier, ProjectFormState, ProjectModel?>((ref, project) {
  return ProjectFormNotifier(project);
});

/// Project form state
class ProjectFormState {
  final String projectName;
  final String description;
  final String clientId;
  final DateTime startDate;
  final DateTime? deadline;
  final ProjectStatus status;
  final double? budget;
  final String currency;
  final bool isLoading;
  final String? errorMessage;

  const ProjectFormState({
    this.projectName = '',
    this.description = '',
    this.clientId = '',
    DateTime? startDate,
    this.deadline,
    this.status = ProjectStatus.active,
    this.budget,
    this.currency = 'USD',
    this.isLoading = false,
    this.errorMessage,
  }) : startDate = startDate ?? const ProjectFormState._defaultDate();

  const ProjectFormState._defaultDate() : startDate = null;

  ProjectFormState copyWith({
    String? projectName,
    String? description,
    String? clientId,
    DateTime? startDate,
    DateTime? deadline,
    ProjectStatus? status,
    double? budget,
    String? currency,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProjectFormState(
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Project form state notifier
class ProjectFormNotifier extends StateNotifier<ProjectFormState> {
  final ProjectModel? initialProject;

  ProjectFormNotifier(this.initialProject) : super(
    ProjectFormState(
      projectName: initialProject?.projectName ?? '',
      description: initialProject?.description ?? '',
      clientId: initialProject?.clientId ?? '',
      startDate: initialProject?.startDate ?? DateTime.now(),
      deadline: initialProject?.deadline,
      status: initialProject?.status ?? ProjectStatus.active,
      budget: initialProject?.budget,
      currency: initialProject?.currency ?? 'USD',
    ),
  );

  void updateProjectName(String name) {
    state = state.copyWith(projectName: name, errorMessage: null);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description, errorMessage: null);
  }

  void updateClientId(String clientId) {
    state = state.copyWith(clientId: clientId, errorMessage: null);
  }

  void updateStartDate(DateTime date) {
    state = state.copyWith(startDate: date, errorMessage: null);
  }

  void updateDeadline(DateTime? deadline) {
    state = state.copyWith(deadline: deadline, errorMessage: null);
  }

  void updateStatus(ProjectStatus status) {
    state = state.copyWith(status: status, errorMessage: null);
  }

  void updateBudget(double? budget) {
    state = state.copyWith(budget: budget, errorMessage: null);
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency, errorMessage: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  Future<bool> saveProject() async {
    if (state.projectName.isEmpty || state.clientId.isEmpty) {
      setError('Project name and client are required');
      return false;
    }

    setLoading(true);

    try {
      final now = DateTime.now();
      
      if (initialProject != null) {
        // Update existing project
        final updatedProject = initialProject!.copyWith(
          projectName: state.projectName,
          description: state.description.isEmpty ? null : state.description,
          clientId: state.clientId,
          startDate: state.startDate,
          deadline: state.deadline,
          status: state.status,
          budget: state.budget,
          currency: state.currency,
          updatedAt: now,
        );
        
        await FirestoreService.updateProject(updatedProject);
      } else {
        // Create new project
        final newProject = ProjectModel(
          id: '', // Will be set by Firestore
          userId: '', // Will be set by FirestoreService
          clientId: state.clientId,
          projectName: state.projectName,
          description: state.description.isEmpty ? null : state.description,
          startDate: state.startDate,
          deadline: state.deadline,
          status: state.status,
          budget: state.budget,
          currency: state.currency,
          createdAt: now,
          updatedAt: now,
        );
        
        await FirestoreService.createProject(newProject);
      }

      return true;
    } catch (e) {
      setError('Failed to save project: $e');
      return false;
    }
  }
}

/// Provider for deleting a project
final deleteProjectProvider = FutureProvider.family<void, String>((ref, projectId) async {
  await FirestoreService.deleteProject(projectId);
});

/// Provider for getting a single project
final projectProvider = FutureProvider.family<ProjectModel?, String>((ref, projectId) async {
  return await FirestoreService.getProject(projectId);
});

/// Provider for updating task status in a project
final updateTaskStatusProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final projectId = params['projectId'] as String;
  final taskId = params['taskId'] as String;
  final newStatus = params['status'] as TaskStatus;

  final project = await FirestoreService.getProject(projectId);
  if (project != null) {
    final updatedTasks = project.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(status: newStatus);
      }
      return task;
    }).toList();

    final updatedProject = project.copyWith(tasks: updatedTasks);
    await FirestoreService.updateProject(updatedProject);
  }
});

/// Provider for adding a new task to a project
final addProjectTaskProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final projectId = params['projectId'] as String;
  final taskTitle = params['title'] as String;
  final taskDescription = params['description'] as String?;

  final project = await FirestoreService.getProject(projectId);
  if (project != null) {
    final newTask = ProjectTaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: taskTitle,
      description: taskDescription,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final updatedTasks = [...project.tasks, newTask];
    final updatedProject = project.copyWith(tasks: updatedTasks);
    await FirestoreService.updateProject(updatedProject);
  }
});