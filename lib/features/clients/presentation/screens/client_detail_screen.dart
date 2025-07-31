import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/models/client_model.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../../core/providers/payment_providers.dart';
import 'add_client_screen.dart';

/// Client detail screen showing client info, projects, and payments
class ClientDetailScreen extends ConsumerWidget {
  final ClientModel client;

  const ClientDetailScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsByClientProvider(client.id));
    final paymentsAsync = ref.watch(paymentsByClientProvider(client.id));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.pencil),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddClientScreen(client: client),
                      ),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40), // Account for app bar
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          backgroundImage: client.avatarUrl != null
                              ? NetworkImage(client.avatarUrl!)
                              : null,
                          child: client.avatarUrl == null
                              ? Text(
                                  client.initials,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          client.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (client.company != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            client.company!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Contact info
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.addressBook,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contact Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildContactItem(
                          context,
                          theme,
                          PhosphorIconsRegular.envelope,
                          'Email',
                          client.email,
                          () => _launchEmail(client.email),
                        ),
                        if (client.phone != null) ...[
                          const SizedBox(height: 12),
                          _buildContactItem(
                            context,
                            theme,
                            PhosphorIconsRegular.phone,
                            'Phone',
                            client.phone!,
                            () => _launchPhone(client.phone!),
                          ),
                        ],
                        if (client.timezone != null) ...[
                          const SizedBox(height: 12),
                          _buildContactItem(
                            context,
                            theme,
                            PhosphorIconsRegular.globe,
                            'Timezone',
                            client.timezone!,
                            null,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  if (client.notes != null && client.notes!.isNotEmpty) ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.notepad,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            client.notes!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Projects
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.folder,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Projects',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            return projectsAsync.when(
                              data: (projects) {
                                if (projects.isEmpty) {
                                  return _buildEmptySection(
                                    context,
                                    theme,
                                    'No projects yet',
                                    'This client doesn\'t have any projects.',
                                  );
                                }

                                return Column(
                                  children: projects.map((project) {
                                    return _buildProjectItem(context, theme, project);
                                  }).toList(),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) => Text(
                                'Error loading projects: $error',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payments
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.creditCard,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payments',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            return paymentsAsync.when(
                              data: (payments) {
                                if (payments.isEmpty) {
                                  return _buildEmptySection(
                                    context,
                                    theme,
                                    'No payments yet',
                                    'This client doesn\'t have any payments.',
                                  );
                                }

                                return Column(
                                  children: payments.take(5).map((payment) {
                                    return _buildPaymentItem(context, theme, payment);
                                  }).toList(),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) => Text(
                                'Error loading payments: $error',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
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

  Widget _buildContactItem(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onTap != null ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                PhosphorIconsRegular.arrowSquareOut,
                size: 16,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectItem(BuildContext context, ThemeData theme, project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: _getStatusColor(theme, project.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              PhosphorIconsRegular.folder,
              size: 16,
              color: _getStatusColor(theme, project.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  project.status.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(theme, project.status),
                  ),
                ),
              ],
            ),
          ),
          if (project.progress > 0) ...[
            SizedBox(
              width: 40,
              child: Text(
                '${(project.progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, ThemeData theme, payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: _getPaymentStatusColor(theme, payment.paymentStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              payment.paymentStatus.icon,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.formattedAmount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  payment.paymentStatus.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getPaymentStatusColor(theme, payment.paymentStatus),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(payment.dueDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(
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
            PhosphorIconsRegular.fileX,
            size: 32,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall,
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

  Color _getStatusColor(ThemeData theme, status) {
    switch (status.name) {
      case 'active':
        return theme.colorScheme.primary;
      case 'completed':
        return Colors.green;
      case 'onHold':
        return Colors.orange;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  Color _getPaymentStatusColor(ThemeData theme, status) {
    switch (status.name) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'overdue':
        return theme.colorScheme.error;
      case 'cancelled':
        return theme.colorScheme.onSurface;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}