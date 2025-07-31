import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freelance_flow/shared/models/payment_model.dart';

import '../services/firestore_service.dart';
import 'client_providers.dart';
import 'project_providers.dart';
import 'task_providers.dart';
import 'payment_providers.dart';

/// Provider for dashboard statistics
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final firebaseStats = await FirestoreService.getDashboardStats();
  
  // Get additional computed stats
  final taskStatsAsync = ref.watch(taskStatsProvider);
  final paymentAnalyticsAsync = ref.watch(paymentAnalyticsProvider);
  
  final taskStats = taskStatsAsync.value;
  final paymentAnalytics = paymentAnalyticsAsync.value;
  
  return DashboardStats(
    totalClients: firebaseStats['totalClients'] ?? 0,
    activeProjects: firebaseStats['activeProjects'] ?? 0,
    totalTasks: taskStats?.totalTasks ?? 0,
    completedTasksToday: taskStats?.completedToday ?? 0,
    totalEarnings: paymentAnalytics?.totalEarnings ?? 0.0,
    pendingPayments: paymentAnalytics?.pendingAmount ?? 0.0,
    overduePayments: firebaseStats['overduePayments'] ?? 0,
    taskCompletionRate: taskStats?.completionRate ?? 0.0,
    paymentSuccessRate: paymentAnalytics?.paymentRate ?? 0.0,
  );
});

/// Provider for recent activity
final recentActivityProvider = FutureProvider<List<ActivityItem>>((ref) async {
  final activities = <ActivityItem>[];
  
  // Get recent clients, projects, tasks, and payments
  final clients = ref.watch(clientsProvider).value ?? [];
  final projects = ref.watch(projectsProvider).value ?? [];
  final tasks = ref.watch(tasksProvider).value ?? [];
  final payments = ref.watch(paymentsProvider).value ?? [];
  
  // Add recent clients
  for (final client in clients.take(5)) {
    activities.add(ActivityItem(
      id: client.id,
      type: ActivityType.client,
      title: 'New client: ${client.name}',
      subtitle: client.company ?? client.email,
      timestamp: client.createdAt,
      icon: 'user-plus',
    ));
  }
  
  // Add recent projects
  for (final project in projects.take(5)) {
    activities.add(ActivityItem(
      id: project.id,
      type: ActivityType.project,
      title: 'Project: ${project.projectName}',
      subtitle: 'Status: ${project.status.displayName}',
      timestamp: project.updatedAt,
      icon: 'folder',
    ));
  }
  
  // Add completed tasks from today
  final todayCompletedTasks = tasks
      .where((task) => task.isCompletedToday)
      .take(5);
  
  for (final task in todayCompletedTasks) {
    activities.add(ActivityItem(
      id: task.id,
      type: ActivityType.task,
      title: 'Completed: ${task.title}',
      subtitle: task.category.displayName,
      timestamp: task.completedAt ?? task.updatedAt,
      icon: 'check-circle',
    ));
  }
  
  // Add recent paid payments
  final recentPaidPayments = payments
      .where((payment) => payment.paymentStatus == PaymentStatus.paid)
      .take(5);
  
  for (final payment in recentPaidPayments) {
    activities.add(ActivityItem(
      id: payment.id,
      type: ActivityType.payment,
      title: 'Payment received: ${payment.formattedAmount}',
      subtitle: payment.description ?? 'Payment',
      timestamp: payment.paidDate ?? payment.updatedAt,
      icon: 'dollar-sign',
    ));
  }
  
  // Sort by timestamp (most recent first)
  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  
  return activities.take(20).toList();
});

/// Provider for upcoming deadlines
final upcomingDeadlinesProvider = FutureProvider<List<DeadlineItem>>((ref) async {
  final deadlines = <DeadlineItem>[];
  final now = DateTime.now();
  final nextWeek = now.add(const Duration(days: 7));
  
  // Get projects with upcoming deadlines
  final projects = ref.watch(activeProjectsProvider).value ?? [];
  for (final project in projects) {
    if (project.deadline != null && 
        project.deadline!.isAfter(now) && 
        project.deadline!.isBefore(nextWeek)) {
      deadlines.add(DeadlineItem(
        id: project.id,
        type: DeadlineType.project,
        title: project.projectName,
        subtitle: 'Project deadline',
        deadline: project.deadline!,
        isOverdue: false,
      ));
    }
  }
  
  // Get payments with upcoming due dates
  final payments = ref.watch(unpaidPaymentsProvider).value ?? [];
  for (final payment in payments) {
    if (payment.dueDate.isAfter(now) && payment.dueDate.isBefore(nextWeek)) {
      deadlines.add(DeadlineItem(
        id: payment.id,
        type: DeadlineType.payment,
        title: payment.formattedAmount,
        subtitle: payment.description ?? 'Payment due',
        deadline: payment.dueDate,
        isOverdue: false,
      ));
    }
  }
  
  // Get overdue items
  for (final project in projects) {
    if (project.deadline != null && project.deadline!.isBefore(now)) {
      deadlines.add(DeadlineItem(
        id: project.id,
        type: DeadlineType.project,
        title: project.projectName,
        subtitle: 'Project overdue',
        deadline: project.deadline!,
        isOverdue: true,
      ));
    }
  }
  
  final overduePayments = ref.watch(overduePaymentsProvider).value ?? [];
  for (final payment in overduePayments) {
    deadlines.add(DeadlineItem(
      id: payment.id,
      type: DeadlineType.payment,
      title: payment.formattedAmount,
      subtitle: payment.description ?? 'Payment overdue',
      deadline: payment.dueDate,
      isOverdue: true,
    ));
  }
  
  // Sort by deadline (soonest first)
  deadlines.sort((a, b) => a.deadline.compareTo(b.deadline));
  
  return deadlines.take(10).toList();
});

/// Dashboard statistics model
class DashboardStats {
  final int totalClients;
  final int activeProjects;
  final int totalTasks;
  final int completedTasksToday;
  final double totalEarnings;
  final double pendingPayments;
  final int overduePayments;
  final double taskCompletionRate;
  final double paymentSuccessRate;

  const DashboardStats({
    required this.totalClients,
    required this.activeProjects,
    required this.totalTasks,
    required this.completedTasksToday,
    required this.totalEarnings,
    required this.pendingPayments,
    required this.overduePayments,
    required this.taskCompletionRate,
    required this.paymentSuccessRate,
  });
}

/// Activity item model
class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String icon;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
  });
}

/// Activity type enum
enum ActivityType {
  client,
  project,
  task,
  payment;

  String get displayName {
    switch (this) {
      case ActivityType.client:
        return 'Client';
      case ActivityType.project:
        return 'Project';
      case ActivityType.task:
        return 'Task';
      case ActivityType.payment:
        return 'Payment';
    }
  }
}

/// Deadline item model
class DeadlineItem {
  final String id;
  final DeadlineType type;
  final String title;
  final String subtitle;
  final DateTime deadline;
  final bool isOverdue;

  const DeadlineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.deadline,
    required this.isOverdue,
  });

  int get daysUntilDeadline {
    final now = DateTime.now();
    final difference = deadline.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }
}

/// Deadline type enum
enum DeadlineType {
  project,
  payment;

  String get displayName {
    switch (this) {
      case DeadlineType.project:
        return 'Project';
      case DeadlineType.payment:
        return 'Payment';
    }
  }
}