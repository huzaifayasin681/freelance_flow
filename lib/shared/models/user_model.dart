import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for FreelanceFlow application
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String? timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });

  /// Create UserModel from Firebase User and additional data
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      timezone: map['timezone'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      preferences: map['preferences'] as Map<String, dynamic>?,
    );
  }

  /// Convert UserModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'timezone': timezone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferences': preferences,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? timezone,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}