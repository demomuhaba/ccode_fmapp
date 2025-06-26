import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/security_service.dart';

/// Provider for managing app security state
class SecurityProvider with ChangeNotifier {
  final SecurityService _securityService;

  SecurityProvider(this._securityService);

  bool _isLoading = false;
  String? _error;
  bool _pinEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  bool _authRequired = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get pinEnabled => _pinEnabled;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnabled => _biometricEnabled;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  bool get authRequired => _authRequired;

  /// Initialize security status
  Future<void> initialize() async {
    await _loadSecurityStatus();
  }

  /// Load current security status
  Future<void> _loadSecurityStatus() async {
    try {
      _setLoading(true);
      _clearError();

      final status = await _securityService.getSecurityStatus();
      
      _pinEnabled = status['pinEnabled'] ?? false;
      _biometricAvailable = status['biometricAvailable'] ?? false;
      _biometricEnabled = status['biometricEnabled'] ?? false;
      _authRequired = status['authRequired'] ?? false;
      _availableBiometrics = status['availableBiometrics'] ?? [];
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load security status: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set up PIN
  Future<bool> setupPin(String pin) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _securityService.setPin(pin);
      if (success) {
        _pinEnabled = true;
        _authRequired = true;
        notifyListeners();
      } else {
        _setError('Failed to set up PIN');
      }
      
      return success;
    } catch (e) {
      _setError('Error setting up PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _securityService.verifyPin(pin);
      if (!success) {
        _setError('Incorrect PIN');
      }
      
      return success;
    } catch (e) {
      _setError('Error verifying PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _securityService.changePin(oldPin, newPin);
      if (!success) {
        _setError('Failed to change PIN. Please check your current PIN.');
      }
      
      return success;
    } catch (e) {
      _setError('Error changing PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Remove PIN and disable security
  Future<bool> removePin() async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _securityService.removePin();
      if (success) {
        _pinEnabled = false;
        _biometricEnabled = false;
        _authRequired = false;
        notifyListeners();
      } else {
        _setError('Failed to remove PIN');
      }
      
      return success;
    } catch (e) {
      _setError('Error removing PIN: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle biometric authentication
  Future<bool> toggleBiometric(bool enabled) async {
    try {
      _setLoading(true);
      _clearError();

      if (enabled && !_biometricAvailable) {
        _setError('Biometric authentication is not available on this device');
        return false;
      }

      if (enabled && !_pinEnabled) {
        _setError('Please set up a PIN first before enabling biometric authentication');
        return false;
      }

      final success = await _securityService.setBiometricEnabled(enabled);
      if (success) {
        _biometricEnabled = enabled;
        notifyListeners();
      } else {
        _setError('Failed to update biometric settings');
      }
      
      return success;
    } catch (e) {
      _setError('Error updating biometric settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _securityService.authenticateWithBiometric();
      if (!success) {
        _setError('Biometric authentication failed');
      }
      
      return success;
    } catch (e) {
      _setError('Error during biometric authentication: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if authentication is required
  Future<bool> checkAuthRequired() async {
    try {
      _authRequired = await _securityService.isAuthRequired();
      notifyListeners();
      return _authRequired;
    } catch (e) {
      _setError('Error checking authentication requirement: $e');
      return false;
    }
  }

  /// Authenticate user (try biometric first, then PIN)
  Future<bool> authenticate() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if authentication is even required
      final isRequired = await _securityService.isAuthRequired();
      if (!isRequired) return true;

      // Try biometric authentication if enabled
      if (_biometricEnabled && _biometricAvailable) {
        final biometricSuccess = await _securityService.authenticateWithBiometric();
        if (biometricSuccess) return true;
      }

      // If biometric fails or not available, PIN authentication will be handled by UI
      return false;
    } catch (e) {
      _setError('Error during authentication: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset authentication session
  Future<void> resetAuthSession() async {
    await _securityService.resetAuthSession();
    _authRequired = true;
    notifyListeners();
  }

  /// Get biometric type display name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Recognition';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Biometric Authentication';
    }
  }

  /// Get available biometric types as display strings
  List<String> get availableBiometricNames {
    return _availableBiometrics
        .map((type) => getBiometricTypeName(type))
        .toList();
  }

  // Private helper methods
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

  /// Refresh security status
  Future<void> refresh() async {
    await _loadSecurityStatus();
  }
}