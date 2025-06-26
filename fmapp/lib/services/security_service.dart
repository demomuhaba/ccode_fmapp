import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for handling app-level security including PIN and biometric authentication
class SecurityService {
  static const String _pinKey = 'app_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _authRequiredKey = 'auth_required';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const int _authTimeoutMinutes = 5;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Set up PIN for the application
  Future<bool> setPin(String pin) async {
    try {
      if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
        throw Exception('PIN must be exactly 4 digits');
      }

      final String hashedPin = _hashPin(pin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      await _setAuthRequired(true);
      
      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    }
  }

  /// Verify PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final String? storedHashedPin = await _secureStorage.read(key: _pinKey);
      if (storedHashedPin == null) return false;

      final String hashedPin = _hashPin(pin);
      final bool isValid = storedHashedPin == hashedPin;
      
      if (isValid) {
        await _updateLastAuthTime();
      }
      
      return isValid;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Enable/disable biometric authentication
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
      return true;
    } catch (e) {
      debugPrint('Error setting biometric preference: $e');
      return false;
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking biometric preference: $e');
      return false;
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your financial data',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (isAuthenticated) {
        await _updateLastAuthTime();
      }
      
      return isAuthenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Check if authentication is required
  Future<bool> isAuthRequired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool authRequired = prefs.getBool(_authRequiredKey) ?? false;
      
      if (!authRequired) return false;

      // Check if we're within the timeout period
      final int? lastAuthTime = prefs.getInt(_lastAuthTimeKey);
      if (lastAuthTime != null) {
        final DateTime lastAuth = DateTime.fromMillisecondsSinceEpoch(lastAuthTime);
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(lastAuth);
        
        // If within timeout period, no auth required
        if (difference.inMinutes < _authTimeoutMinutes) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking auth requirement: $e');
      return false;
    }
  }

  /// Check if PIN is set up
  Future<bool> isPinSetup() async {
    try {
      final String? pin = await _secureStorage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking PIN setup: $e');
      return false;
    }
  }

  /// Remove PIN and disable security
  Future<bool> removePin() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _setAuthRequired(false);
      await setBiometricEnabled(false);
      return true;
    } catch (e) {
      debugPrint('Error removing PIN: $e');
      return false;
    }
  }

  /// Change existing PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final bool isOldPinValid = await verifyPin(oldPin);
      if (!isOldPinValid) {
        throw Exception('Current PIN is incorrect');
      }
      
      return await setPin(newPin);
    } catch (e) {
      debugPrint('Error changing PIN: $e');
      return false;
    }
  }

  /// Get security status summary
  Future<Map<String, dynamic>> getSecurityStatus() async {
    return {
      'pinEnabled': await isPinSetup(),
      'biometricAvailable': await isBiometricAvailable(),
      'biometricEnabled': await isBiometricEnabled(),
      'authRequired': await isAuthRequired(),
      'availableBiometrics': await getAvailableBiometrics(),
    };
  }

  // Private helper methods

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'fmapp_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _setAuthRequired(bool required) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authRequiredKey, required);
  }

  Future<void> _updateLastAuthTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAuthTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Reset authentication session (call when app goes to background)
  Future<void> resetAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAuthTimeKey);
  }

  /// Authenticate user with available methods
  Future<bool> authenticate() async {
    try {
      final bool isPinSet = await isPinSetup();
      if (!isPinSet) return true; // No security set up

      final bool biometricEnabled = await isBiometricEnabled();
      final bool biometricAvailable = await isBiometricAvailable();
      
      // Try biometric first if enabled and available
      if (biometricEnabled && biometricAvailable) {
        return await authenticateWithBiometric();
      }
      
      // Otherwise, PIN authentication will be handled by UI
      return false;
    } catch (e) {
      debugPrint('Error during authentication: $e');
      return false;
    }
  }
}