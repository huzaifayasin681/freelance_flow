import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_service.dart';
import '../../shared/models/payment_model.dart';

/// Provider for payments stream
final paymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  return FirestoreService.getPayments();
});

/// Provider for unpaid payments stream
final unpaidPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  return FirestoreService.getUnpaidPayments();
});

/// Provider for overdue payments stream
final overduePaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  return FirestoreService.getOverduePayments();
});

/// Provider for payments by client
final paymentsByClientProvider = StreamProvider.family<List<PaymentModel>, String>((ref, clientId) {
  return FirestoreService.getPaymentsByClient(clientId);
});

/// Provider for payments by project
final paymentsByProjectProvider = StreamProvider.family<List<PaymentModel>, String>((ref, projectId) {
  return FirestoreService.getPaymentsByProject(projectId);
});

/// Provider for payment search query
final paymentSearchProvider = StateProvider<String>((ref) => '');

/// Provider for filtered payments based on search
final filteredPaymentsProvider = Provider<List<PaymentModel>>((ref) {
  final payments = ref.watch(paymentsProvider).value ?? [];
  final searchQuery = ref.watch(paymentSearchProvider).toLowerCase();

  if (searchQuery.isEmpty) {
    return payments;
  }

  return payments.where((payment) {
    return (payment.description?.toLowerCase().contains(searchQuery) ?? false) ||
           payment.formattedAmount.toLowerCase().contains(searchQuery) ||
           payment.invoiceNumber?.toLowerCase().contains(searchQuery) ?? false;
  }).toList();
});

/// Provider for payment form state
final paymentFormProvider = StateNotifierProvider.family<PaymentFormNotifier, PaymentFormState, PaymentModel?>((ref, payment) {
  return PaymentFormNotifier(payment);
});

/// Payment form state
class PaymentFormState {
  final String clientId;
  final String projectId;
  final double amount;
  final String currency;
  final String description;
  final DateTime dueDate;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String invoiceUrl;
  final String invoiceNumber;
  final String notes;
  final int reminderDays;
  final bool isLoading;
  final String? errorMessage;

  const PaymentFormState({
    this.clientId = '',
    this.projectId = '',
    this.amount = 0.0,
    this.currency = 'USD',
    this.description = '',
    DateTime? dueDate,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.bankTransfer,
    this.invoiceUrl = '',
    this.invoiceNumber = '',
    this.notes = '',
    this.reminderDays = 3,
    this.isLoading = false,
    this.errorMessage,
  }) : dueDate = dueDate ?? DateTime.now().add(const Duration(days: 30));

  PaymentFormState copyWith({
    String? clientId,
    String? projectId,
    double? amount,
    String? currency,
    String? description,
    DateTime? dueDate,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? invoiceUrl,
    String? invoiceNumber,
    String? notes,
    int? reminderDays,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PaymentFormState(
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      reminderDays: reminderDays ?? this.reminderDays,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Payment form state notifier
class PaymentFormNotifier extends StateNotifier<PaymentFormState> {
  final PaymentModel? initialPayment;

  PaymentFormNotifier(this.initialPayment) : super(
    PaymentFormState(
      clientId: initialPayment?.clientId ?? '',
      projectId: initialPayment?.projectId ?? '',
      amount: initialPayment?.amount ?? 0.0,
      currency: initialPayment?.currency ?? 'USD',
      description: initialPayment?.description ?? '',
      dueDate: initialPayment?.dueDate ?? DateTime.now().add(const Duration(days: 30)),
      paymentStatus: initialPayment?.paymentStatus ?? PaymentStatus.unpaid,
      paymentMethod: initialPayment?.paymentMethod ?? PaymentMethod.bankTransfer,
      invoiceUrl: initialPayment?.invoiceUrl ?? '',
      invoiceNumber: initialPayment?.invoiceNumber ?? '',
      notes: initialPayment?.notes ?? '',
      reminderDays: initialPayment?.reminderDays ?? 3,
    ),
  );

  void updateClientId(String clientId) {
    state = state.copyWith(clientId: clientId, errorMessage: null);
  }

  void updateProjectId(String projectId) {
    state = state.copyWith(projectId: projectId, errorMessage: null);
  }

  void updateAmount(double amount) {
    state = state.copyWith(amount: amount, errorMessage: null);
  }

  void updateCurrency(String currency) {
    state = state.copyWith(currency: currency, errorMessage: null);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description, errorMessage: null);
  }

  void updateDueDate(DateTime dueDate) {
    state = state.copyWith(dueDate: dueDate, errorMessage: null);
  }

  void updatePaymentStatus(PaymentStatus status) {
    state = state.copyWith(paymentStatus: status, errorMessage: null);
  }

  void updatePaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method, errorMessage: null);
  }

  void updateInvoiceUrl(String url) {
    state = state.copyWith(invoiceUrl: url, errorMessage: null);
  }

  void updateInvoiceNumber(String number) {
    state = state.copyWith(invoiceNumber: number, errorMessage: null);
  }

  void updateNotes(String notes) {
    state = state.copyWith(notes: notes, errorMessage: null);
  }

  void updateReminderDays(int days) {
    state = state.copyWith(reminderDays: days, errorMessage: null);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error, isLoading: false);
  }

  Future<bool> savePayment() async {
    if (state.amount <= 0) {
      setError('Amount must be greater than 0');
      return false;
    }

    setLoading(true);

    try {
      final now = DateTime.now();
      
      if (initialPayment != null) {
        // Update existing payment
        final updatedPayment = initialPayment!.copyWith(
          clientId: state.clientId.isEmpty ? null : state.clientId,
          projectId: state.projectId.isEmpty ? null : state.projectId,
          amount: state.amount,
          currency: state.currency,
          description: state.description.isEmpty ? null : state.description,
          dueDate: state.dueDate,
          paymentStatus: state.paymentStatus,
          paymentMethod: state.paymentMethod,
          invoiceUrl: state.invoiceUrl.isEmpty ? null : state.invoiceUrl,
          invoiceNumber: state.invoiceNumber.isEmpty ? null : state.invoiceNumber,
          notes: state.notes.isEmpty ? null : state.notes,
          reminderDays: state.reminderDays,
          updatedAt: now,
        );
        
        await FirestoreService.updatePayment(updatedPayment);
      } else {
        // Create new payment
        final newPayment = PaymentModel(
          id: '', // Will be set by Firestore
          userId: '', // Will be set by FirestoreService
          clientId: state.clientId.isEmpty ? null : state.clientId,
          projectId: state.projectId.isEmpty ? null : state.projectId,
          amount: state.amount,
          currency: state.currency,
          description: state.description.isEmpty ? null : state.description,
          dueDate: state.dueDate,
          paymentStatus: state.paymentStatus,
          paymentMethod: state.paymentMethod,
          invoiceUrl: state.invoiceUrl.isEmpty ? null : state.invoiceUrl,
          invoiceNumber: state.invoiceNumber.isEmpty ? null : state.invoiceNumber,
          notes: state.notes.isEmpty ? null : state.notes,
          reminderDays: state.reminderDays,
          createdAt: now,
          updatedAt: now,
        );
        
        await FirestoreService.createPayment(newPayment);
      }

      return true;
    } catch (e) {
      setError('Failed to save payment: $e');
      return false;
    }
  }
}

/// Provider for deleting a payment
final deletePaymentProvider = FutureProvider.family<void, String>((ref, paymentId) async {
  await FirestoreService.deletePayment(paymentId);
});

/// Provider for getting a single payment
final paymentProvider = FutureProvider.family<PaymentModel?, String>((ref, paymentId) async {
  return await FirestoreService.getPayment(paymentId);
});

/// Provider for marking payment as paid
final markPaymentPaidProvider = FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final paymentId = params['paymentId'] as String;
  final transactionId = params['transactionId'] as String?;

  final payment = await FirestoreService.getPayment(paymentId);
  if (payment != null) {
    final paidPayment = payment.markAsPaid(transactionId: transactionId);
    await FirestoreService.updatePayment(paidPayment);
  }
});

/// Provider for payment analytics
final paymentAnalyticsProvider = FutureProvider<PaymentAnalytics>((ref) async {
  final payments = ref.watch(paymentsProvider).value ?? [];
  
  // Calculate totals
  double totalEarnings = 0;
  double pendingAmount = 0;
  double overdueAmount = 0;
  int totalPayments = payments.length;
  int paidCount = 0;
  int overdueCount = 0;

  // Monthly earnings (last 12 months)
  final now = DateTime.now();
  final monthlyEarnings = <String, double>{};
  final currencyBreakdown = <String, double>{};

  for (final payment in payments) {
    // Currency breakdown
    currencyBreakdown[payment.currency] = 
        (currencyBreakdown[payment.currency] ?? 0) + payment.amount;

    if (payment.paymentStatus == PaymentStatus.paid) {
      totalEarnings += payment.amount;
      paidCount++;

      // Monthly earnings
      if (payment.paidDate != null && 
          payment.paidDate!.isAfter(now.subtract(const Duration(days: 365)))) {
        final monthKey = '${payment.paidDate!.year}-${payment.paidDate!.month.toString().padLeft(2, '0')}';
        monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + payment.amount;
      }
    } else if (payment.paymentStatus == PaymentStatus.unpaid) {
      pendingAmount += payment.amount;
    } else if (payment.paymentStatus == PaymentStatus.overdue) {
      overdueAmount += payment.amount;
      overdueCount++;
    }
  }

  return PaymentAnalytics(
    totalEarnings: totalEarnings,
    pendingAmount: pendingAmount,
    overdueAmount: overdueAmount,
    totalPayments: totalPayments,
    paidPayments: paidCount,
    overduePayments: overdueCount,
    paymentRate: totalPayments > 0 ? paidCount / totalPayments : 0.0,
    monthlyEarnings: monthlyEarnings,
    currencyBreakdown: currencyBreakdown,
    averagePaymentAmount: totalPayments > 0 ? totalEarnings / paidCount : 0.0,
  );
});

/// Payment analytics model
class PaymentAnalytics {
  final double totalEarnings;
  final double pendingAmount;
  final double overdueAmount;
  final int totalPayments;
  final int paidPayments;
  final int overduePayments;
  final double paymentRate;
  final Map<String, double> monthlyEarnings;
  final Map<String, double> currencyBreakdown;
  final double averagePaymentAmount;

  const PaymentAnalytics({
    required this.totalEarnings,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.totalPayments,
    required this.paidPayments,
    required this.overduePayments,
    required this.paymentRate,
    required this.monthlyEarnings,
    required this.currencyBreakdown,
    required this.averagePaymentAmount,
  });
}