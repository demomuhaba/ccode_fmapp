import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../services/supabase_service.dart';
import '../models/user_profile_model.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final SupabaseService _supabaseService;

  UserProfileRepositoryImpl(this._supabaseService);

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _supabaseService.getUserProfile(userId);
      if (data == null) return null;
      final model = UserProfileModel.fromJson(data);
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  @override
  Future<UserProfile> createUserProfile(UserProfile userProfile) async {
    try {
      final model = UserProfileModel.fromEntity(userProfile);
      final data = await _supabaseService.createUserProfile(model.toJsonForInsert());
      final createdModel = UserProfileModel.fromJson(data);
      return createdModel.toEntity();
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    try {
      final model = UserProfileModel.fromEntity(userProfile);
      final data = await _supabaseService.updateRecord(
        table: 'user_profiles',
        id: model.id,
        data: model.toJsonForInsert(),
      );
      final updatedModel = UserProfileModel.fromJson(data);
      return updatedModel.toEntity();
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _supabaseService.deleteUserProfile(userId);
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }
}