import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../../shared/models/client_model.dart';

/// Provider for clients stream
final clientsProvider = StreamProvider<List<ClientModel>>((ref) {
  return FirestoreService.getClients();
});

/// Provider for client search query
final clientSearchProvider = StateProvider<String>((ref) => '');

/// Provider for filtered clients based on search
final filteredClientsProvider = Provider<List<ClientModel>>((ref) {
  final clients = ref.watch(clientsProvider).value ?? [];
  final searchQuery = ref.watch(clientSearchProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return clients;
  }

  return clients.where((client) {
    return client.name.toLowerCase().contains(searchQuery) ||
           client.email.toLowerCase().contains(searchQuery) ||
           (client.company?.toLowerCase().contains(searchQuery) ?? false);
  }).toList();
});

/// Provider for client form state
final clientFormProvider = StateNotifierProvider.family<ClientFormNotifier, ClientFormState, ClientModel?>((ref, client) {
  return ClientFormNotifier(client);
});

/// Client form state
class ClientFormState {
  final String name;
  final String email;
  final String company;
  final String phone;
  final String timezone;
  final String notes;
  final bool isLoading;
  final String? errorMessage;

  const ClientFormState({
    this.name = '',
    this.email = '',
    this.company = '',
    this.phone = '',
    this.timezone = '',
    this.notes = '',
    this.isLoading = false,
    this.errorMessage,
  });

  ClientFormState copyWith({
    String? name,
    String? email,
    String? company,
    String? phone,
    String? timezone,
    String? notes,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClientFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Client form state notifier
class ClientFormNotifier extends StateNotifier<ClientFormState> {
  final ClientModel? initialClient;

  ClientFormNotifier(this.initialClient) : super(
    ClientFormState(
      name: initialClient?.name ?? '',
      email: initialClient?.email ?? '',
      company: initialClient?.company ?? '',
      phone: initialClient?.phone ?? '',
      timezone: initialClient?.timezone ?? '',
      notes: initialClient?.notes ?? '',
    ),
  );

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void updateCompany(String company) {
    state = state.copyWith(company: company, errorMessage: null);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone, errorMessage: null);
  }

  void updateTimezone(String timezone) {
    state = state.copyWith(timezone: timezone, errorMessage: null);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes, errorMessage: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  Future<bool> saveClient() async {
    if (state.name.isEmpty || state.email.isEmpty) {
      setError('Name and email are required');
      return false;
    }

    setLoading(true);

    try {
      final now = DateTime.now();
      
      if (initialClient != null) {
        // Update existing client
        final updatedClient = initialClient!.copyWith(
          name: state.name,
          email: state.email,
          company: state.company.isEmpty ? null : state.company,
          phone: state.phone.isEmpty ? null : state.phone,
          timezone: state.timezone.isEmpty ? null : state.timezone,
          notes: state.notes.isEmpty ? null : state.notes,
          updatedAt: now,
        );
        
        await FirestoreService.updateClient(updatedClient);
      } else {
        // Create new client
        final newClient = ClientModel(
          id: '', // Will be set by Firestore
          userId: '', // Will be set by FirestoreService
          name: state.name,
          email: state.email,
          company: state.company.isEmpty ? null : state.company,
          phone: state.phone.isEmpty ? null : state.phone,
          timezone: state.timezone.isEmpty ? null : state.timezone,
          notes: state.notes.isEmpty ? null : state.notes,
          createdAt: now,
          updatedAt: now,
        );
        
        await FirestoreService.createClient(newClient);
      }

      return true;
    } catch (e) {
      setError('Failed to save client: $e');
      return false;
    }
  }
}

/// Provider for deleting a client
final deleteClientProvider = FutureProvider.family<void, String>((ref, clientId) async {
  await FirestoreService.deleteClient(clientId);
});

/// Provider for getting a single client
final clientProvider = FutureProvider.family<ClientModel?, String>((ref, clientId) async {
  return await FirestoreService.getClient(clientId);
});