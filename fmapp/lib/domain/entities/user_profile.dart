// Domain entity for User Profile
// Represents the authenticated user in the application

import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        createdAt,
        updatedAt,
        preferences,
      ];

  String get userId => id;

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName)';
  }
}