import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment status enumeration
enum PaymentStatus {
  paid,
  unpaid,
  overdue,
  cancelled;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case PaymentStatus.paid:
        return '✅';
      case PaymentStatus.unpaid:
        return '⏳';
      case PaymentStatus.overdue:
        return '❌';
      case PaymentStatus.cancelled:
        return '🚫';
    }
  }
}

/// Payment method enumeration
enum PaymentMethod {
  bankTransfer,
  paypal,
  stripe,
  upwork,
  freelancer,
  cash,
  check,
  other;

  String get displayName {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.upwork:
        return 'Upwork';
      case PaymentMethod.freelancer:
        return 'Freelancer.com';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.paypal:
        return '💳';
      case PaymentMethod.stripe:
        return '💳';
      case PaymentMethod.upwork:
        return '💼';
      case PaymentMethod.freelancer:
        return '💼';
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.check:
        return '📋';
      case PaymentMethod.other:
        return '💰';
    }
  }
}

/// Payment model for tracking freelance payments
class PaymentModel {
  final String id;
  final String userId;
  final String? clientId;
  final String? projectId;
  final double amount;
  final String currency;
  final String? description;
  final DateTime dueDate;
  final DateTime? paidDate;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? invoiceUrl;
  final String? invoiceNumber;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? reminderDays; // Days before due date to send reminder
  final DateTime? lastReminderSent;

  const PaymentModel({
    required this.id,
    required this.userId,
    this.clientId,
    this.projectId,
    required this.amount,
    this.currency = 'USD',
    this.description,
    required this.dueDate,
    this.paidDate,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod = PaymentMethod.bankTransfer,
    this.invoiceUrl,
    this.invoiceNumber,
    this.transactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.reminderDays = 3,
    this.lastReminderSent,
  });

  /// Create PaymentModel from Firestore document
  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      userId: map['userId'] ?? '',
      clientId: map['clientId'],
      projectId: map['projectId'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      description: map['description'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      paidDate: map['paidDate'] != null 
          ? (map['paidDate'] as Timestamp).toDate() 
          : null,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.bankTransfer,
      ),
      invoiceUrl: map['invoiceUrl'],
      invoiceNumber: map['invoiceNumber'],
      transactionId: map['transactionId'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      reminderDays: map['reminderDays'] ?? 3,
      lastReminderSent: map['lastReminderSent'] != null
          ? (map['lastReminderSent'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert PaymentModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'clientId': clientId,
      'projectId': projectId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paymentStatus': paymentStatus.name,
      'paymentMethod': paymentMethod.name,
      'invoiceUrl': invoiceUrl,
      'invoiceNumber': invoiceNumber,
      'transactionId': transactionId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reminderDays': reminderDays,
      'lastReminderSent': lastReminderSent != null 
          ? Timestamp.fromDate(lastReminderSent!) 
          : null,
    };
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    switch (currency) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      case 'JPY':
        return '¥${amount.toStringAsFixed(0)}';
      default:
        return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  /// Check if payment is overdue
  bool get isOverdue {
    if (paymentStatus == PaymentStatus.paid || paymentStatus == PaymentStatus.cancelled) {
      return false;
    }
    return DateTime.now().isAfter(dueDate);
  }

  /// Get days until due date (negative if overdue)
  int get daysUntilDue {
    final now = DateTime.now();
    final difference = dueDate.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// Check if reminder should be sent
  bool get shouldSendReminder {
    if (paymentStatus == PaymentStatus.paid || 
        paymentStatus == PaymentStatus.cancelled ||
        reminderDays == null) {
      return false;
    }

    final reminderDate = dueDate.subtract(Duration(days: reminderDays!));
    final now = DateTime.now();

    // Should send if we're past the reminder date and haven't sent one today
    if (now.isAfter(reminderDate)) {
      if (lastReminderSent == null) return true;
      
      final lastSent = lastReminderSent!;
      return !(lastSent.year == now.year && 
               lastSent.month == now.month && 
               lastSent.day == now.day);
    }

    return false;
  }

  /// Create a copy with updated fields
  PaymentModel copyWith({
    String? clientId,
    String? projectId,
    double? amount,
    String? currency,
    String? description,
    DateTime? dueDate,
    DateTime? paidDate,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? invoiceUrl,
    String? invoiceNumber,
    String? transactionId,
    String? notes,
    DateTime? updatedAt,
    int? reminderDays,
    DateTime? lastReminderSent,
  }) {
    return PaymentModel(
      id: id,
      userId: userId,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      reminderDays: reminderDays ?? this.reminderDays,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
    );
  }

  /// Mark payment as paid
  PaymentModel markAsPaid({
    DateTime? paidDate,
    String? transactionId,
  }) {
    return copyWith(
      paymentStatus: PaymentStatus.paid,
      paidDate: paidDate ?? DateTime.now(),
      transactionId: transactionId ?? this.transactionId,
      updatedAt: DateTime.now(),
    );
  }

  /// Mark payment as overdue
  PaymentModel markAsOverdue() {
    return copyWith(
      paymentStatus: PaymentStatus.overdue,
      updatedAt: DateTime.now(),
    );
  }

  /// Update reminder sent timestamp
  PaymentModel updateReminderSent() {
    return copyWith(
      lastReminderSent: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'PaymentModel(id: $id, amount: $formattedAmount, dueDate: $dueDate, status: ${paymentStatus.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}