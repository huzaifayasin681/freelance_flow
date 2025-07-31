import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../../shared/models/task_model.dart';

/// Provider for tasks stream
final tasksProvider = StreamProvider<List<TaskModel>>((ref) {
  return FirestoreService.getTasks();
});

/// Provider for today's tasks stream
final todaysTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  return FirestoreService.getTodaysTasks();
});

/// Provider for tasks by category
final tasksByCategoryProvider = StreamProvider.family<List<TaskModel>, TaskCategory>((ref, category) {
  return FirestoreService.getTasksByCategory(category);
});

/// Provider for task search query
final taskSearchProvider = StateProvider<String>((ref) => '');

/// Provider for filtered tasks based on search
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  final searchQuery = ref.watch(taskSearchProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return tasks;
  }

  return tasks.where((task) {
    return task.title.toLowerCase().contains(searchQuery) ||
           (task.description?.toLowerCase().contains(searchQuery) ?? false);
  }).toList();
});

/// Provider for task form state
final taskFormProvider = StateNotifierProvider.family<TaskFormNotifier, TaskFormState, TaskModel?>((ref, task) {
  return TaskFormNotifier(task);
});

/// Task form state
class TaskFormState {
  final String title;
  final String description;
  final RepeatFrequency repeatFrequency;
  final int hour;
  final int minute;
  final TaskCategory category;
  final bool notificationsEnabled;
  final bool isLoading;
  final String? errorMessage;

  const TaskFormState({
    this.title = '',
    this.description = '',
    this.repeatFrequency = RepeatFrequency.daily,
    this.hour = 9,
    this.minute = 0,
    this.category = TaskCategory.personal,
    this.notificationsEnabled = true,
    this.isLoading = false,
    this.errorMessage,
  });

  TaskFormState copyWith({
    String? title,
    String? description,
    RepeatFrequency? repeatFrequency,
    int? hour,
    int? minute,
    TaskCategory? category,
    bool? notificationsEnabled,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      category: category ?? this.category,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Task form state notifier
class TaskFormNotifier extends StateNotifier<TaskFormState> {
  final TaskModel? initialTask;

  TaskFormNotifier(this.initialTask) : super(
    TaskFormState(
      title: initialTask?.title ?? '',
      description: initialTask?.description ?? '',
      repeatFrequency: initialTask?.repeatFrequency ?? RepeatFrequency.daily,
      hour: initialTask?.hour ?? 9,
      minute: initialTask?.minute ?? 0,
      category: initialTask?.category ?? TaskCategory.personal,
      notificationsEnabled: initialTask?.notificationsEnabled ?? true,
    ),
  );

  void updateTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description, errorMessage: null);
  }

  void updateRepeatFrequency(RepeatFrequency frequency) {
    state = state.copyWith(repeatFrequency: frequency, errorMessage: null);
  }

  void updateTime(int hour, int minute) {
    state = state.copyWith(hour: hour, minute: minute, errorMessage: null);
  }

  void updateCategory(TaskCategory category) {
    state = state.copyWith(category: category, errorMessage: null);
  }

  void updateNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled, errorMessage: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  Future<bool> saveTask() async {
    if (state.title.isEmpty) {
      setError('Task title is required');
      return false;
    }

    setLoading(true);

    try {
      final now = DateTime.now();
      final notificationId = state.notificationsEnabled 
          ? DateTime.now().millisecondsSinceEpoch 
          : null;
      
      if (initialTask != null) {
        // Update existing task
        final updatedTask = initialTask!.copyWith(
          title: state.title,
          description: state.description.isEmpty ? null : state.description,
          repeatFrequency: state.repeatFrequency,
          hour: state.hour,
          minute: state.minute,
          category: state.category,
          notificationsEnabled: state.notificationsEnabled,
          notificationId: notificationId,
          updatedAt: now,
        );
        
        await FirestoreService.updateTask(updatedTask);
        
        // Update notification
        if (initialTask!.notificationId != null) {
          await NotificationService.cancelNotification(initialTask!.notificationId!);
        }
        
        if (state.notificationsEnabled && notificationId != null) {
          await NotificationService.scheduleDailyTaskReminder(
            id: notificationId,
            title: 'Task Reminder',
            body: state.title,
            hour: state.hour,
            minute: state.minute,
          );
        }
      } else {
        // Create new task
        final newTask = TaskModel(
          id: '', // Will be set by Firestore
          userId: '', // Will be set by FirestoreService
          title: state.title,
          description: state.description.isEmpty ? null : state.description,
          repeatFrequency: state.repeatFrequency,
          hour: state.hour,
          minute: state.minute,
          category: state.category,
          notificationsEnabled: state.notificationsEnabled,
          notificationId: notificationId,
          createdAt: now,
          updatedAt: now,
        );
        
        final taskId = await FirestoreService.createTask(newTask);
        
        // Schedule notification
        if (state.notificationsEnabled && notificationId != null) {
          await NotificationService.scheduleDailyTaskReminder(
            id: notificationId,
            title: 'Task Reminder',
            body: state.title,
            hour: state.hour,
            minute: state.minute,
          );
        }
      }

      return true;
    } catch (e) {
      setError('Failed to save task: $e');
      return false;
    }
  }
}

/// Provider for deleting a task
final deleteTaskProvider = FutureProvider.family<void, String>((ref, taskId) async {
  // Get task first to cancel notification
  final task = await FirestoreService.getTask(taskId);
  if (task?.notificationId != null) {
    await NotificationService.cancelNotification(task!.notificationId!);
  }
  
  await FirestoreService.deleteTask(taskId);
});

/// Provider for getting a single task
final taskProvider = FutureProvider.family<TaskModel?, String>((ref, taskId) async {
  return await FirestoreService.getTask(taskId);
});

/// Provider for completing a task
final completeTaskProvider = FutureProvider.family<void, String>((ref, taskId) async {
  final task = await FirestoreService.getTask(taskId);
  if (task != null) {
    final completedTask = task.markCompleted();
    await FirestoreService.updateTask(completedTask);
  }
});

/// Provider for skipping a task
final skipTaskProvider = FutureProvider.family<void, String>((ref, taskId) async {
  final task = await FirestoreService.getTask(taskId);
  if (task != null) {
    final skippedTask = task.markSkipped();
    await FirestoreService.updateTask(skippedTask);
  }
});

/// Provider for resetting task status
final resetTaskStatusProvider = FutureProvider.family<void, String>((ref, taskId) async {
  final task = await FirestoreService.getTask(taskId);
  if (task != null) {
    final resetTask = task.resetStatus();
    await FirestoreService.updateTask(resetTask);
  }
});

/// Provider for task completion statistics
final taskStatsProvider = FutureProvider<TaskStats>((ref) async {
  final tasks = ref.watch(tasksProvider).value ?? [];
  final todaysTasks = tasks.where((task) => task.isDueToday).toList();
  
  final completedToday = todaysTasks.where((task) => task.isCompletedToday).length;
  final totalToday = todaysTasks.length;
  final overdue = todaysTasks.where((task) => task.isOverdue).length;
  
  return TaskStats(
    totalTasks: tasks.length,
    todaysTasks: totalToday,
    completedToday: completedToday,
    overdueTasks: overdue,
    completionRate: totalToday > 0 ? completedToday / totalToday : 0.0,
  );
});

/// Task statistics model
class TaskStats {
  final int totalTasks;
  final int todaysTasks;
  final int completedToday;
  final int overdueTasks;
  final double completionRate;

  const TaskStats({
    required this.totalTasks,
    required this.todaysTasks,
    required this.completedToday,
    required this.overdueTasks,
    required this.completionRate,
  });
}