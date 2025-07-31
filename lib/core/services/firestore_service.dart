import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../shared/models/client_model.dart';
import '../../shared/models/project_model.dart';
import '../../shared/models/task_model.dart';
import '../../shared/models/payment_model.dart';
import 'auth_service.dart';

/// Firestore database service for all CRUD operations
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user ID
  static String? get _currentUserId => AuthService.currentUserId;

  // ============ CLIENT OPERATIONS ============

  /// Create a new client
  static Future<String> createClient(ClientModel client) async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('clients').add(
        client.copyWith(userId: _currentUserId!).toMap(),
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Create client error: $e');
      rethrow;
    }
  }

  /// Get all clients for current user
  static Stream<List<ClientModel>> getClients() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('clients')
        .where('userId', isEqualTo: _currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get single client by ID
  static Future<ClientModel?> getClient(String clientId) async {
    try {
      final doc = await _firestore.collection('clients').doc(clientId).get();
      
      if (doc.exists && doc.data() != null) {
        return ClientModel.fromMap(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      debugPrint('Get client error: $e');
      return null;
    }
  }

  /// Update client
  static Future<void> updateClient(ClientModel client) async {
    try {
      await _firestore
          .collection('clients')
          .doc(client.id)
          .update(client.toMap());
    } catch (e) {
      debugPrint('Update client error: $e');
      rethrow;
    }
  }

  /// Delete client (soft delete)
  static Future<void> deleteClient(String clientId) async {
    try {
      await _firestore.collection('clients').doc(clientId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Delete client error: $e');
      rethrow;
    }
  }

  // ============ PROJECT OPERATIONS ============

  /// Create a new project
  static Future<String> createProject(ProjectModel project) async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('projects').add(
        project.copyWith(userId: _currentUserId!).toMap(),
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Create project error: $e');
      rethrow;
    }
  }

  /// Get all projects for current user
  static Stream<List<ProjectModel>> getProjects() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('projects')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get projects by client
  static Stream<List<ProjectModel>> getProjectsByClient(String clientId) {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('projects')
        .where('userId', isEqualTo: _currentUserId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get active projects
  static Stream<List<ProjectModel>> getActiveProjects() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('projects')
        .where('userId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: ProjectStatus.active.name)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get single project by ID
  static Future<ProjectModel?> getProject(String projectId) async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      
      if (doc.exists && doc.data() != null) {
        return ProjectModel.fromMap(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      debugPrint('Get project error: $e');
      return null;
    }
  }

  /// Update project
  static Future<void> updateProject(ProjectModel project) async {
    try {
      await _firestore
          .collection('projects')
          .doc(project.id)
          .update(project.toMap());
    } catch (e) {
      debugPrint('Update project error: $e');
      rethrow;
    }
  }

  /// Delete project
  static Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      debugPrint('Delete project error: $e');
      rethrow;
    }
  }

  // ============ TASK OPERATIONS ============

  /// Create a new daily task
  static Future<String> createTask(TaskModel task) async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('tasks').add(
        task.copyWith(userId: _currentUserId!).toMap(),
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Create task error: $e');
      rethrow;
    }
  }

  /// Get all tasks for current user
  static Stream<List<TaskModel>> getTasks() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('hour')
        .orderBy('minute')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get today's tasks
  static Stream<List<TaskModel>> getTodaysTasks() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('hour')
        .orderBy('minute')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .where((task) => task.isDueToday)
            .toList());
  }

  /// Get tasks by category
  static Stream<List<TaskModel>> getTasksByCategory(TaskCategory category) {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _currentUserId)
        .where('category', isEqualTo: category.name)
        .where('isActive', isEqualTo: true)
        .orderBy('hour')
        .orderBy('minute')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get single task by ID
  static Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection('tasks').doc(taskId).get();
      
      if (doc.exists && doc.data() != null) {
        return TaskModel.fromMap(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      debugPrint('Get task error: $e');
      return null;
    }
  }

  /// Update task
  static Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      debugPrint('Update task error: $e');
      rethrow;
    }
  }

  /// Delete task (soft delete)
  static Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Delete task error: $e');
      rethrow;
    }
  }

  // ============ PAYMENT OPERATIONS ============

  /// Create a new payment
  static Future<String> createPayment(PaymentModel payment) async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _firestore.collection('payments').add(
        payment.copyWith(userId: _currentUserId!).toMap(),
      );

      return docRef.id;
    } catch (e) {
      debugPrint('Create payment error: $e');
      rethrow;
    }
  }

  /// Get all payments for current user
  static Stream<List<PaymentModel>> getPayments() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get payments by client
  static Stream<List<PaymentModel>> getPaymentsByClient(String clientId) {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: _currentUserId)
        .where('clientId', isEqualTo: clientId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get payments by project
  static Stream<List<PaymentModel>> getPaymentsByProject(String projectId) {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: _currentUserId)
        .where('projectId', isEqualTo: projectId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get unpaid payments
  static Stream<List<PaymentModel>> getUnpaidPayments() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: _currentUserId)
        .where('paymentStatus', whereIn: [PaymentStatus.unpaid.name, PaymentStatus.overdue.name])
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get overdue payments
  static Stream<List<PaymentModel>> getOverduePayments() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: _currentUserId)
        .where('paymentStatus', isEqualTo: PaymentStatus.overdue.name)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get single payment by ID
  static Future<PaymentModel?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      
      if (doc.exists && doc.data() != null) {
        return PaymentModel.fromMap(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      debugPrint('Get payment error: $e');
      return null;
    }
  }

  /// Update payment
  static Future<void> updatePayment(PaymentModel payment) async {
    try {
      await _firestore
          .collection('payments')
          .doc(payment.id)
          .update(payment.toMap());
    } catch (e) {
      debugPrint('Update payment error: $e');
      rethrow;
    }
  }

  /// Delete payment
  static Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
    } catch (e) {
      debugPrint('Delete payment error: $e');
      rethrow;
    }
  }

  // ============ ANALYTICS & DASHBOARD DATA ============

  /// Get total earnings
  static Future<double> getTotalEarnings({String? currency}) async {
    try {
      if (_currentUserId == null) return 0.0;

      Query query = _firestore
          .collection('payments')
          .where('userId', isEqualTo: _currentUserId)
          .where('paymentStatus', isEqualTo: PaymentStatus.paid.name);

      if (currency != null) {
        query = query.where('currency', isEqualTo: currency);
      }

      final snapshot = await query.get();
      
      double total = 0.0;
      for (final doc in snapshot.docs) {
        final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        total += payment.amount;
      }

      return total;
    } catch (e) {
      debugPrint('Get total earnings error: $e');
      return 0.0;
    }
  }

  /// Get pending payments amount
  static Future<double> getPendingPaymentsAmount({String? currency}) async {
    try {
      if (_currentUserId == null) return 0.0;

      Query query = _firestore
          .collection('payments')
          .where('userId', isEqualTo: _currentUserId)
          .where('paymentStatus', whereIn: [PaymentStatus.unpaid.name, PaymentStatus.overdue.name]);

      if (currency != null) {
        query = query.where('currency', isEqualTo: currency);
      }

      final snapshot = await query.get();
      
      double total = 0.0;
      for (final doc in snapshot.docs) {
        final payment = PaymentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        total += payment.amount;
      }

      return total;
    } catch (e) {
      debugPrint('Get pending payments amount error: $e');
      return 0.0;
    }
  }

  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      if (_currentUserId == null) {
        return {
          'totalClients': 0,
          'activeProjects': 0,
          'completedTasksToday': 0,
          'totalEarnings': 0.0,
          'pendingPayments': 0.0,
          'overduePayments': 0,
        };
      }

      final futures = await Future.wait([
        _firestore
            .collection('clients')
            .where('userId', isEqualTo: _currentUserId)
            .where('isActive', isEqualTo: true)
            .count()
            .get(),
        _firestore
            .collection('projects')
            .where('userId', isEqualTo: _currentUserId)
            .where('status', isEqualTo: ProjectStatus.active.name)
            .count()
            .get(),
        getTotalEarnings(),
        getPendingPaymentsAmount(),
      ]);

      final overdueSnapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: _currentUserId)
          .where('paymentStatus', isEqualTo: PaymentStatus.overdue.name)
          .count()
          .get();

      return {
        'totalClients': futures[0].count,
        'activeProjects': futures[1].count,
        'totalEarnings': futures[2] as double,
        'pendingPayments': futures[3] as double,
        'overduePayments': overdueSnapshot.count,
      };
    } catch (e) {
      debugPrint('Get dashboard stats error: $e');
      return {
        'totalClients': 0,
        'activeProjects': 0,
        'totalEarnings': 0.0,
        'pendingPayments': 0.0,
        'overduePayments': 0,
      };
    }
  }

  // ============ BATCH OPERATIONS ============

  /// Update payment statuses to overdue for payments past due date
  static Future<void> updateOverduePayments() async {
    try {
      if (_currentUserId == null) return;

      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: _currentUserId)
          .where('paymentStatus', isEqualTo: PaymentStatus.unpaid.name)
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'paymentStatus': PaymentStatus.overdue.name,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Update overdue payments error: $e');
    }
  }
}