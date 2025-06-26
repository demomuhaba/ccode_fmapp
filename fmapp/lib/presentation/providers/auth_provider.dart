import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/auth_usecases.dart';

class AuthProvider extends ChangeNotifier {
  final AuthUseCases _authUseCases;

  AuthProvider(this._authUseCases);

  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isSignedIn = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _isSignedIn;

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      _isSignedIn = await _authUseCases.isUserSignedIn();
      if (_isSignedIn) {
        _userProfile = await _authUseCases.getCurrentUserProfile();
      }
      _clearError();
    } catch (e) {
      _setError('Failed to check auth status: $e');
      _isSignedIn = false;
      _userProfile = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    _setLoading(true);
    try {
      final result = await _authUseCases.signUp(email, password, fullName);
      
      if (result['user'] != null) {
        _isSignedIn = true;
        _userProfile = await _authUseCases.getCurrentUserProfile();
        _clearError();
        return true;
      } else {
        _setError('Sign up failed');
        return false;
      }
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authUseCases.signIn(email, password);
      
      if (result['user'] != null) {
        _isSignedIn = true;
        _userProfile = await _authUseCases.getCurrentUserProfile();
        _clearError();
        return true;
      } else {
        _setError('Sign in failed');
        return false;
      }
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authUseCases.signOut();
      _isSignedIn = false;
      _userProfile = null;
      _clearError();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authUseCases.resetPassword(email);
      _clearError();
      return true;
    } catch (e) {
      _setError('Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(UserProfile userProfile) async {
    _setLoading(true);
    try {
      _userProfile = await _authUseCases.updateUserProfile(userProfile);
      _clearError();
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}