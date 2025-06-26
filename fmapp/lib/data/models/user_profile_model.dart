// Data model for User Profile
// Maps between domain entity and Supabase data structure

import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.fullName,
    required super.createdAt,
    required super.updatedAt,
    super.preferences,
  });

  /// Create UserProfileModel from JSON (Supabase response)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }

  /// Convert UserProfileModel to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences': preferences ?? <String, dynamic>{},
    };
  }

  /// Create UserProfileModel from domain entity
  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      preferences: entity.preferences,
    );
  }

  /// Convert to domain entity
  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      preferences: preferences,
    );
  }

  /// Convert UserProfileModel to JSON for insert operations (without ID for auto-generation)
  Map<String, dynamic> toJsonForInsert() {
    return {
      'id': id, // Include id for user profiles since they use auth user id
      'email': email,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences': preferences ?? <String, dynamic>{},
    };
  }

  /// Create UserProfileModel for new user insert (generates timestamps)
  factory UserProfileModel.forInsert({
    required String id,
    required String email,
    String? fullName,
    Map<String, dynamic>? preferences,
  }) {
    final now = DateTime.now();
    return UserProfileModel(
      id: id,
      email: email,
      fullName: fullName,
      createdAt: now,
      updatedAt: now,
      preferences: preferences,
    );
  }

  /// Create UserProfileModel for update (preserves createdAt, updates updatedAt)
  UserProfileModel copyWithUpdate({
    String? email,
    String? fullName,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfileModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt, // Preserve original created date
      updatedAt: DateTime.now(), // Update timestamp
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(id: $id, email: $email, fullName: $fullName)';
  }
}