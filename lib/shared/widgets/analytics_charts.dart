import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Earnings chart showing monthly earnings over time
class EarningsChart extends StatelessWidget {
  final Map<String, double> monthlyEarnings;
  final String currency;

  const EarningsChart({
    super.key,
    required this.monthlyEarnings,
    this.currency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (monthlyEarnings.isEmpty) {
      return _buildEmptyChart(context, theme, 'No earnings data available');
    }

    // Sort months and get last 6 months
    final sortedEntries = monthlyEarnings.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final lastSixMonths = sortedEntries.length > 6 
        ? sortedEntries.sublist(sortedEntries.length - 6)
        : sortedEntries;

    final spots = lastSixMonths.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(lastSixMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b)),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outline.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= lastSixMonths.length) return const Text('');
                  
                  final monthKey = lastSixMonths[value.toInt()].key;
                  final month = monthKey.split('-')[1];
                  final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      monthNames[int.parse(month)],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateInterval(lastSixMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b)),
                reservedSize: 50,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    _formatCurrency(value, currency),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (lastSixMonths.length - 1).toDouble(),
          minY: 0,
          maxY: lastSixMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, ThemeData theme, String message) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 100) return 25;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 250;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2500;
    return 5000;
  }

  String _formatCurrency(double amount, String currency) {
    if (amount >= 1000) {
      return '${currency == 'USD' ? '\$' : currency}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '${currency == 'USD' ? '\$' : currency}${amount.toStringAsFixed(0)}';
  }
}

/// Payment status pie chart
class PaymentStatusChart extends StatelessWidget {
  final int paidPayments;
  final int unpaidPayments;
  final int overduePayments;

  const PaymentStatusChart({
    super.key,
    required this.paidPayments,
    required this.unpaidPayments,
    required this.overduePayments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = paidPayments + unpaidPayments + overduePayments;
    
    if (total == 0) {
      return _buildEmptyChart(context, theme, 'No payment data');
    }

    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            if (paidPayments > 0)
              PieChartSectionData(
                color: Colors.green,
                value: paidPayments.toDouble(),
                title: '${((paidPayments / total) * 100).toInt()}%',
                radius: 50,
                titleStyle: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (unpaidPayments > 0)
              PieChartSectionData(
                color: Colors.orange,
                value: unpaidPayments.toDouble(),
                title: '${((unpaidPayments / total) * 100).toInt()}%',
                radius: 50,
                titleStyle: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (overduePayments > 0)
              PieChartSectionData(
                color: theme.colorScheme.error,
                value: overduePayments.toDouble(),
                title: '${((overduePayments / total) * 100).toInt()}%',
                radius: 50,
                titleStyle: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, ThemeData theme, String message) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Project progress bar chart
class ProjectProgressChart extends StatelessWidget {
  final List<ProjectData> projects;

  const ProjectProgressChart({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (projects.isEmpty) {
      return _buildEmptyChart(context, theme, 'No projects to display');
    }

    return Column(
      children: projects.map((project) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(project.progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: project.progress,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(theme, project.progress),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyChart(BuildContext context, ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(ThemeData theme, double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return theme.colorScheme.primary;
    if (progress >= 0.3) return Colors.orange;
    return theme.colorScheme.error;
  }
}

/// Task completion donut chart
class TaskCompletionChart extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;

  const TaskCompletionChart({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (totalTasks == 0) {
      return _buildEmptyChart(context, theme, 'No tasks today');
    }

    final completionRate = completedTasks / totalTasks;
    final remaining = totalTasks - completedTasks;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                PieChartSectionData(
                  color: theme.colorScheme.primary,
                  value: completedTasks.toDouble(),
                  title: '',
                  radius: 25,
                ),
                PieChartSectionData(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  value: remaining.toDouble(),
                  title: '',
                  radius: 25,
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(completionRate * 100).toInt()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '$completedTasks/$totalTasks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context, ThemeData theme, String message) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for project information
class ProjectData {
  final String name;
  final double progress;

  const ProjectData({
    required this.name,
    required this.progress,
  });
}

/// Chart legend widget
class ChartLegend extends StatelessWidget {
  final List<LegendItem> items;

  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Legend item data class
class LegendItem {
  final String label;
  final Color color;

  const LegendItem({
    required this.label,
    required this.color,
  });
}