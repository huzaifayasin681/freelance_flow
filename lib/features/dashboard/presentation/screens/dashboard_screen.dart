import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/dashboard_providers.dart';
import '../../../../core/providers/task_providers.dart';
import '../../../../core/providers/payment_providers.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/analytics_charts.dart';
import '../../../tasks/presentation/screens/tasks_screen.dart';
import '../../../projects/presentation/screens/projects_screen.dart';
import '../../../payments/presentation/screens/payments_screen.dart';

/// Dashboard screen showing overview, analytics, and quick actions
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    final taskStatsAsync = ref.watch(taskStatsProvider);
    final paymentAnalyticsAsync = ref.watch(paymentAnalyticsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome back to FreelanceFlow',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.bell),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick stats overview
                  Consumer(
                    builder: (context, ref, child) {
                      return dashboardStatsAsync.when(
                        data: (stats) => _buildQuickStats(context, theme, stats),
                        loading: () => _buildQuickStatsLoading(context, theme),
                        error: (error, stack) => _buildErrorCard(context, theme, 'Failed to load dashboard stats'),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Today's task completion
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          theme,
                          'Today\'s Progress',
                          PhosphorIconsRegular.checkCircle,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TasksScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            return taskStatsAsync.when(
                              data: (taskStats) => Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TaskCompletionChart(
                                      completedTasks: taskStats.completedToday,
                                      totalTasks: taskStats.todaysTasks,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildStatRow(
                                          context,
                                          theme,
                                          'Completed',
                                          '${taskStats.completedToday}',
                                          Colors.green,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildStatRow(
                                          context,
                                          theme,
                                          'Remaining',
                                          '${taskStats.todaysTasks - taskStats.completedToday}',
                                          Colors.orange,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildStatRow(
                                          context,
                                          theme,
                                          'Overdue',
                                          '${taskStats.overdueTasks}',
                                          theme.colorScheme.error,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stack) => Text('Error: $error'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Earnings chart
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          theme,
                          'Earnings Overview',
                          PhosphorIconsRegular.trendUp,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            return paymentAnalyticsAsync.when(
                              data: (analytics) => Column(
                                children: [
                                  EarningsChart(
                                    monthlyEarnings: analytics.monthlyEarnings,
                                    currency: 'USD',
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildEarningsMetric(
                                          context,
                                          theme,
                                          'Total Earned',
                                          '\$${analytics.totalEarnings.toStringAsFixed(0)}',
                                          Colors.green,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildEarningsMetric(
                                          context,
                                          theme,
                                          'Pending',
                                          '\$${analytics.pendingAmount.toStringAsFixed(0)}',
                                          Colors.orange,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildEarningsMetric(
                                          context,
                                          theme,
                                          'Overdue',
                                          '\$${analytics.overdueAmount.toStringAsFixed(0)}',
                                          theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stack) => Text('Error: $error'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment status breakdown
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          theme,
                          'Payment Status',
                          PhosphorIconsRegular.creditCard,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentsScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            return paymentAnalyticsAsync.when(
                              data: (analytics) => Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: PaymentStatusChart(
                                      paidPayments: analytics.paidPayments,
                                      unpaidPayments: analytics.totalPayments - analytics.paidPayments - analytics.overduePayments,
                                      overduePayments: analytics.overduePayments,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: ChartLegend(
                                      items: [
                                        const LegendItem(label: 'Paid', color: Colors.green),
                                        const LegendItem(label: 'Unpaid', color: Colors.orange),
                                        LegendItem(label: 'Overdue', color: theme.colorScheme.error),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stack) => Text('Error: $error'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Active projects progress
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          theme,
                          'Active Projects',
                          PhosphorIconsRegular.folder,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final activeProjectsAsync = ref.watch(activeProjectsProvider);
                            
                            return activeProjectsAsync.when(
                              data: (projects) {
                                final projectData = projects.take(5).map((project) {
                                  return ProjectData(
                                    name: project.projectName,
                                    progress: project.progress,
                                  );
                                }).toList();

                                return ProjectProgressChart(projects: projectData);
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stack) => Text('Error: $error'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recent activity
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          theme,
                          'Recent Activity',
                          PhosphorIconsRegular.clockCounterClockwise,
                          null,
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final recentActivityAsync = ref.watch(recentActivityProvider);
                            
                            return recentActivityAsync.when(
                              data: (activities) {
                                if (activities.isEmpty) {
                                  return _buildEmptyState(
                                    context,
                                    theme,
                                    'No recent activity',
                                    'Start by adding clients, projects, or completing tasks',
                                  );
                                }

                                return Column(
                                  children: activities.take(5).map((activity) {
                                    return _buildActivityItem(context, theme, activity);
                                  }).toList(),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (error, stack) => Text('Error: $error'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Extra space for bottom nav
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ThemeData theme, DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            theme,
            'Active Projects',
            '${stats.activeProjects}',
            PhosphorIconsRegular.folder,
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            theme,
            'Tasks Today',
            '${stats.completedTasksToday}/${stats.totalTasks}',
            PhosphorIconsRegular.checkCircle,
            theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsLoading(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCardLoading(context, theme),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCardLoading(context, theme),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardLoading(BuildContext context, ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  PhosphorIconsRegular.arrowRight,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsMetric(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, ThemeData theme, activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  activity.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(activity.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            PhosphorIconsRegular.clockCounterClockwise,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ThemeData theme, String message) {
    return GlassCard(
      child: Column(
        children: [
          Icon(
            PhosphorIconsRegular.warning,
            size: 32,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! 👋';
    if (hour < 17) return 'Good Afternoon! 👋';
    return 'Good Evening! 👋';
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.client:
        return PhosphorIconsRegular.user;
      case ActivityType.project:
        return PhosphorIconsRegular.folder;
      case ActivityType.task:
        return PhosphorIconsRegular.checkCircle;
      case ActivityType.payment:
        return PhosphorIconsRegular.creditCard;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}