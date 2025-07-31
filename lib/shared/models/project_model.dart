import 'package:cloud_firestore/cloud_firestore.dart';

/// Project status enumeration
enum ProjectStatus {
  active,
  completed,
  onHold,
  cancelled;

  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Task status enumeration for Kanban board
enum TaskStatus {
  todo,
  inProgress,
  done;

  String get displayName {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

/// Project milestone model
class MilestoneModel {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final DateTime createdAt;

  const MilestoneModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory MilestoneModel.fromMap(Map<String, dynamic> map) {
    return MilestoneModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Project task model
class ProjectTaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final int priority; // 1-5 (5 being highest)
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectTaskModel({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = 3,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectTaskModel.fromMap(Map<String, dynamic> map) {
    return ProjectTaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: map['priority'] ?? 3,
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProjectTaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    int? priority,
    DateTime? dueDate,
    DateTime? updatedAt,
  }) {
    return ProjectTaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Project model for managing freelance projects
class ProjectModel {
  final String id;
  final String userId;
  final String clientId;
  final String projectName;
  final String? description;
  final DateTime startDate;
  final DateTime? deadline;
  final ProjectStatus status;
  final List<MilestoneModel> milestones;
  final List<ProjectTaskModel> tasks;
  final double? budget;
  final String? currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.projectName,
    this.description,
    required this.startDate,
    this.deadline,
    this.status = ProjectStatus.active,
    this.milestones = const [],
    this.tasks = const [],
    this.budget,
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ProjectModel from Firestore document
  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      userId: map['userId'] ?? '',
      clientId: map['clientId'] ?? '',
      projectName: map['projectName'] ?? '',
      description: map['description'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      deadline: map['deadline'] != null ? (map['deadline'] as Timestamp).toDate() : null,
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProjectStatus.active,
      ),
      milestones: (map['milestones'] as List<dynamic>?)
          ?.map((milestone) => MilestoneModel.fromMap(milestone as Map<String, dynamic>))
          .toList() ?? [],
      tasks: (map['tasks'] as List<dynamic>?)
          ?.map((task) => ProjectTaskModel.fromMap(task as Map<String, dynamic>))
          .toList() ?? [],
      budget: map['budget']?.toDouble(),
      currency: map['currency'] ?? 'USD',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert ProjectModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientId': clientId,
      'projectName': projectName,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'status': status.name,
      'milestones': milestones.map((milestone) => milestone.toMap()).toList(),
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'budget': budget,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Calculate project progress based on completed tasks
  double get progress {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((task) => task.status == TaskStatus.done).length;
    return completedTasks / tasks.length;
  }

  /// Get tasks by status for Kanban board
  List<ProjectTaskModel> getTasksByStatus(TaskStatus status) {
    return tasks.where((task) => task.status == status).toList();
  }

  /// Check if project is overdue
  bool get isOverdue {
    if (deadline == null || status == ProjectStatus.completed) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// Create a copy with updated fields
  ProjectModel copyWith({
    String? clientId,
    String? projectName,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    ProjectStatus? status,
    List<MilestoneModel>? milestones,
    List<ProjectTaskModel>? tasks,
    double? budget,
    String? currency,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id,
      userId: userId,
      clientId: clientId ?? this.clientId,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      milestones: milestones ?? this.milestones,
      tasks: tasks ?? this.tasks,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, projectName: $projectName, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}