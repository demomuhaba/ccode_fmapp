import '../../services/supabase_service.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class AuthUseCases {
  final SupabaseService _supabaseService;
  final UserProfileRepository _userProfileRepository;

  AuthUseCases(this._supabaseService, this._userProfileRepository);

  Future<Map<String, dynamic>> signUp(String email, String password, String fullName) async {
    try {
      final authResponse = await _supabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      // Convert AuthResponse to Map for compatibility
      final result = {
        'user': authResponse.user?.toJson(),
        'session': authResponse.session?.toJson(),
      };
      
      return result;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final authResponse = await _supabaseService.signIn(
        email: email,
        password: password,
      );
      
      // Convert AuthResponse to Map for compatibility
      final result = {
        'user': authResponse.user?.toJson(),
        'session': authResponse.session?.toJson(),
      };
      
      return result;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabaseService.resetPassword(email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<String?> getCurrentUserId() async {
    try {
      return _supabaseService.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUserSignedIn() async {
    try {
      final userId = await getCurrentUserId();
      return userId != null;
    } catch (e) {
      return false;
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return null;
      
      return await _userProfileRepository.getUserProfile(userId);
    } catch (e) {
      return null;
    }
  }

  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    try {
      return await _userProfileRepository.updateUserProfile(userProfile);
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }
}