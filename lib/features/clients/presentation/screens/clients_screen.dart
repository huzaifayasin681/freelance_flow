import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/client_providers.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/models/client_model.dart';
import 'add_client_screen.dart';
import 'client_detail_screen.dart';

/// Clients management screen with CRUD operations
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(filteredClientsProvider);
    final searchQuery = ref.watch(clientSearchProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clients',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manage your client relationships',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            PhosphorIconsRegular.plus,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddClientScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SearchTextField(
                    hint: 'Search clients by name, email, or company...',
                    onChanged: (value) {
                      ref.read(clientSearchProvider.notifier).state = value;
                    },
                    onClear: () {
                      ref.read(clientSearchProvider.notifier).state = '';
                    },
                  ),
                ],
              ),
            ),

            // Clients list
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final clientsAsync = ref.watch(clientsProvider);
                  
                  return clientsAsync.when(
                    data: (clients) {
                      final filteredClients = ref.watch(filteredClientsProvider);
                      
                      if (filteredClients.isEmpty && searchQuery.isEmpty) {
                        return _buildEmptyState(context, theme);
                      }
                      
                      if (filteredClients.isEmpty && searchQuery.isNotEmpty) {
                        return _buildNoResultsState(context, theme, searchQuery);
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.refresh(clientsProvider);
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: filteredClients.length,
                          itemBuilder: (context, index) {
                            return _buildClientCard(
                              context,
                              theme,
                              filteredClients[index],
                              ref,
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIconsRegular.warning,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading clients',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.refresh(clientsProvider);
                            },
                            icon: const Icon(PhosphorIconsRegular.arrowClockwise),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    ThemeData theme,
    ClientModel client,
    WidgetRef ref,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClientDetailScreen(client: client),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and menu
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage: client.avatarUrl != null
                      ? NetworkImage(client.avatarUrl!)
                      : null,
                  child: client.avatarUrl == null
                      ? Text(
                          client.initials,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Icon(
                    PhosphorIconsRegular.dotsThreeVertical,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 20,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddClientScreen(client: client),
                          ),
                        );
                        break;
                      case 'delete':
                        _showDeleteDialog(context, theme, client, ref);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.pencil, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.trash, size: 16),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Client name
            Text(
              client.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Company or email
            Text(
              client.company ?? client.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Contact info
            Row(
              children: [
                if (client.phone != null) ...[
                  Icon(
                    PhosphorIconsRegular.phone,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(
                  PhosphorIconsRegular.envelope,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                if (client.timezone != null) ...[
                  Icon(
                    PhosphorIconsRegular.globe,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              PhosphorIconsRegular.users,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No clients yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first client to start managing\nyour freelance relationships',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddClientScreen(),
                ),
              );
            },
            icon: const Icon(PhosphorIconsRegular.plus),
            label: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, ThemeData theme, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 48,
            color: theme.colorScheme.onBackground.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No clients match "$query"',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ThemeData theme,
    ClientModel client,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${client.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await ref.read(deleteClientProvider(client.id).future);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${client.name} deleted successfully'),
                      backgroundColor: theme.colorScheme.secondary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete client: $e'),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}