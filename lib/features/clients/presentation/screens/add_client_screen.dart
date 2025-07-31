import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/client_providers.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/models/client_model.dart';

/// Screen for adding or editing a client
class AddClientScreen extends ConsumerWidget {
  final ClientModel? client;

  const AddClientScreen({super.key, this.client});

  bool get isEditing => client != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formNotifier = ref.watch(clientFormProvider(client).notifier);
    final formState = ref.watch(clientFormProvider(client));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'Add Client'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              GlassCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        PhosphorIconsRegular.userPlus,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Update Client Information' : 'Add New Client',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEditing 
                          ? 'Update the client details below'
                          : 'Fill in the client details to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name field
                    CustomTextField(
                      label: 'Full Name *',
                      hint: 'Enter client\'s full name',
                      initialValue: formState.name,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: PhosphorIconsRegular.user,
                      onChanged: formNotifier.updateName,
                    ),

                    const SizedBox(height: 16),

                    // Email field
                    CustomTextField(
                      label: 'Email Address *',
                      hint: 'Enter client\'s email',
                      initialValue: formState.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: PhosphorIconsRegular.envelope,
                      onChanged: formNotifier.updateEmail,
                    ),

                    const SizedBox(height: 16),

                    // Company field
                    CustomTextField(
                      label: 'Company',
                      hint: 'Enter company name (optional)',
                      initialValue: formState.company,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: PhosphorIconsRegular.buildings,
                      onChanged: formNotifier.updateCompany,
                    ),

                    const SizedBox(height: 16),

                    // Phone field
                    CustomTextField(
                      label: 'Phone Number',
                      hint: 'Enter phone number (optional)',
                      initialValue: formState.phone,
                      keyboardType: TextInputType.phone,
                      prefixIcon: PhosphorIconsRegular.phone,
                      onChanged: formNotifier.updatePhone,
                    ),

                    const SizedBox(height: 16),

                    // Timezone field
                    CustomTextField(
                      label: 'Timezone',
                      hint: 'e.g., UTC-5, EST, PST (optional)',
                      initialValue: formState.timezone,
                      prefixIcon: PhosphorIconsRegular.globe,
                      onChanged: formNotifier.updateTimezone,
                    ),

                    const SizedBox(height: 16),

                    // Notes field
                    CustomTextField(
                      label: 'Notes',
                      hint: 'Any additional notes about the client',
                      initialValue: formState.notes,
                      maxLines: 3,
                      prefixIcon: PhosphorIconsRegular.notepad,
                      onChanged: formNotifier.updateNotes,
                    ),

                    const SizedBox(height: 24),

                    // Error message
                    if (formState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsRegular.warning,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formState.errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Save button
                    CustomButton(
                      text: isEditing ? 'Update Client' : 'Add Client',
                      isLoading: formState.isLoading,
                      onPressed: formState.isLoading 
                          ? null 
                          : () => _saveClient(context, ref, formNotifier),
                      icon: Icon(
                        isEditing 
                            ? PhosphorIconsRegular.check 
                            : PhosphorIconsRegular.plus,
                      ),
                    ),

                    if (isEditing) ...[
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Cancel',
                        isOutlined: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIconsRegular.lightbulb,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Name and email are required fields\n'
                      '• Company helps organize clients by business\n'
                      '• Timezone is useful for scheduling meetings\n'
                      '• Use notes for important client preferences',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveClient(
    BuildContext context,
    WidgetRef ref,
    ClientFormNotifier formNotifier,
  ) async {
    final success = await formNotifier.saveClient();
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing 
                ? 'Client updated successfully!' 
                : 'Client added successfully!',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      Navigator.of(context).pop();
    }
  }
}