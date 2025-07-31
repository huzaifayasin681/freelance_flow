import 'package:cloud_firestore/cloud_firestore.dart';

/// Repeat frequency for daily routine tasks
enum RepeatFrequency {
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RepeatFrequency.daily:
        return 'Daily';
      case RepeatFrequency.weekly:
        return 'Weekly';
      case RepeatFrequency.monthly:
        return 'Monthly';
    }
  }
}

/// Task category for organization
enum TaskCategory {
  linkedin,
  upwork,
  client,
  development,
  marketing,
  administrative,
  personal;

  String get displayName {
    switch (this) {
      case TaskCategory.linkedin:
        return 'LinkedIn';
      case TaskCategory.upwork:
        return 'Upwork';
      case TaskCategory.client:
        return 'Client';
      case TaskCategory.development:
        return 'Development';
      case TaskCategory.marketing:
        return 'Marketing';
      case TaskCategory.administrative:
        return 'Administrative';
      case TaskCategory.personal:
        return 'Personal';
    }
  }

  String get icon {
    switch (this) {
      case TaskCategory.linkedin:
        return '💼';
      case TaskCategory.upwork:
        return '💰';
      case TaskCategory.client:
        return '👥';
      case TaskCategory.development:
        return '💻';
      case TaskCategory.marketing:
        return '📢';
      case TaskCategory.administrative:
        return '📋';
      case TaskCategory.personal:
        return '🏠';
    }
  }
}

/// Task status for completion tracking
enum TaskCompletionStatus {
  pending,
  completed,
  skipped;

  String get displayName {
    switch (this) {
      case TaskCompletionStatus.pending:
        return 'Pending';
      case TaskCompletionStatus.completed:
        return 'Completed';
      case TaskCompletionStatus.skipped:
        return 'Skipped';
    }
  }
}

/// Daily routine task model
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final RepeatFrequency repeatFrequency;
  final int hour; // 0-23
  final int minute; // 0-59
  final TaskCategory category;
  final TaskCompletionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isActive;
  final bool notificationsEnabled;
  final int? notificationId; // For local notifications

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.repeatFrequency = RepeatFrequency.daily,
    required this.hour,
    required this.minute,
    this.category = TaskCategory.personal,
    this.status = TaskCompletionStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.isActive = true,
    this.notificationsEnabled = true,
    this.notificationId,
  });

  /// Create TaskModel from Firestore document
  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      repeatFrequency: RepeatFrequency.values.firstWhere(
        (e) => e.name == map['repeatFrequency'],
        orElse: () => RepeatFrequency.daily,
      ),
      hour: map['hour'] ?? 9,
      minute: map['minute'] ?? 0,
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.personal,
      ),
      status: TaskCompletionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskCompletionStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      isActive: map['isActive'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      notificationId: map['notificationId'],
    );
  }

  /// Convert TaskModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'repeatFrequency': repeatFrequency.name,
      'hour': hour,
      'minute': minute,
      'category': category.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null 
          ? Timestamp.fromDate(completedAt!) 
          : null,
      'isActive': isActive,
      'notificationsEnabled': notificationsEnabled,
      'notificationId': notificationId,
    };
  }

  /// Get formatted time string
  String get timeString {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  /// Check if task is due today
  bool get isDueToday {
    final now = DateTime.now();
    switch (repeatFrequency) {
      case RepeatFrequency.daily:
        return true;
      case RepeatFrequency.weekly:
        return now.weekday == createdAt.weekday;
      case RepeatFrequency.monthly:
        return now.day == createdAt.day;
    }
  }

  /// Check if task is completed today
  bool get isCompletedToday {
    if (status != TaskCompletionStatus.completed || completedAt == null) {
      return false;
    }
    final now = DateTime.now();
    final completed = completedAt!;
    return completed.year == now.year &&
           completed.month == now.month &&
           completed.day == now.day;
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (status == TaskCompletionStatus.completed || !isActive) return false;
    
    final now = DateTime.now();
    final taskTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    return now.isAfter(taskTime);
  }

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? title,
    String? description,
    RepeatFrequency? repeatFrequency,
    int? hour,
    int? minute,
    TaskCategory? category,
    TaskCompletionStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? isActive,
    bool? notificationsEnabled,
    int? notificationId,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  /// Mark task as completed
  TaskModel markCompleted() {
    return copyWith(
      status: TaskCompletionStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Mark task as skipped
  TaskModel markSkipped() {
    return copyWith(
      status: TaskCompletionStatus.skipped,
      updatedAt: DateTime.now(),
    );
  }

  /// Reset task status to pending
  TaskModel resetStatus() {
    return copyWith(
      status: TaskCompletionStatus.pending,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, time: $timeString, category: ${category.displayName}, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}