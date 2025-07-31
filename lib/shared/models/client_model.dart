import 'package:cloud_firestore/cloud_firestore.dart';

/// Client model for managing freelance clients
class ClientModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? company;
  final String? phone;
  final String? timezone;
  final String? notes;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const ClientModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.company,
    this.phone,
    this.timezone,
    this.notes,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Create ClientModel from Firestore document
  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      company: map['company'],
      phone: map['phone'],
      timezone: map['timezone'],
      notes: map['notes'],
      avatarUrl: map['avatarUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  /// Convert ClientModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'company': company,
      'phone': phone,
      'timezone': timezone,
      'notes': notes,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  ClientModel copyWith({
    String? name,
    String? email,
    String? company,
    String? phone,
    String? timezone,
    String? notes,
    String? avatarUrl,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ClientModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get client initials for avatar
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, name: $name, email: $email, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}