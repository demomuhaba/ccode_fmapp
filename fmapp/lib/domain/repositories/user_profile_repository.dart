import '../entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> getUserProfile(String userId);
  Future<UserProfile> createUserProfile(UserProfile userProfile);
  Future<UserProfile> updateUserProfile(UserProfile userProfile);
  Future<void> deleteUserProfile(String userId);
}