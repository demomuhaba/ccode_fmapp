import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'pin_entry_widget.dart';

/// Screen for authenticating users with PIN or biometric
class AuthenticationScreen extends ConsumerStatefulWidget {
  final String? message;

  const AuthenticationScreen({
    super.key,
    this.message,
  });

  @override
  ConsumerState<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends ConsumerState<AuthenticationScreen>
    with WidgetsBindingObserver {
  String _enteredPin = '';
  bool _obscurePin = true;
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Try biometric authentication first if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuthentication();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background, reset auth session
      ref.read(providers.securityNotifierProvider.notifier).resetAuthSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final securityState = ref.watch(providers.securityNotifierProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildAuthenticationContent(securityState),
                  const SizedBox(height: 24),
                  if (securityState.error != null) ...[
                    _buildErrorMessage(securityState.error!),
                    const SizedBox(height: 16),
                  ],
                  _buildActionButtons(securityState),
                  const SizedBox(height: 24),
                  _buildFailedAttemptsWarning(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock,
            size: 40,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'fmapp',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.message ?? 'Enter your PIN to access your financial data',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthenticationContent(dynamic securityState) {
    return Column(
      children: [
        Text(
          'Enter PIN',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        PinEntryWidget(
          onPinChanged: (pin) {
            _enteredPin = pin;
            if (pin.length == 4) {
              _authenticateWithPin();
            }
          },
          obscurePin: _obscurePin,
          autoFocus: false,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() => _obscurePin = !_obscurePin),
              icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
            ),
            Text(
              _obscurePin ? 'Show PIN' : 'Hide PIN',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic securityState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (securityState.biometricEnabled &&
            securityState.biometricAvailable) ...[
          ElevatedButton.icon(
            onPressed: securityState.isLoading
                ? null
                : () => _authenticateWithBiometric(),
            icon: Icon(_getBiometricIcon(securityState.availableBiometrics)),
            label: Text(
              'Use ${_getBiometricLabel(securityState.availableBiometrics)}',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: securityState.isLoading || _enteredPin.length != 4
              ? null
              : () => _authenticateWithPin(),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: securityState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Authenticate'),
        ),
      ],
    );
  }

  Widget _buildFailedAttemptsWarning() {
    if (_failedAttempts == 0) return const SizedBox.shrink();

    final remainingAttempts = _maxFailedAttempts - _failedAttempts;
    final isLastAttempt = remainingAttempts == 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLastAttempt
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isLastAttempt ? Icons.warning : Icons.info_outline,
            color: isLastAttempt
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onSecondaryContainer,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLastAttempt
                  ? 'Last attempt remaining. The app will be locked after this.'
                  : 'Incorrect PIN. $remainingAttempts attempts remaining.',
              style: TextStyle(
                color: isLastAttempt
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBiometricIcon(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return Icons.face;
    } else if (types.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else {
      return Icons.security;
    }
  }

  String _getBiometricLabel(List<BiometricType> types) {
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else {
      return 'Biometric';
    }
  }

  Future<void> _tryBiometricAuthentication() async {
    final securityState = ref.read(providers.securityNotifierProvider);
    
    if (securityState.biometricEnabled &&
        securityState.biometricAvailable) {
      await _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await ref.read(providers.securityNotifierProvider.notifier).authenticateWithBiometric();
    if (success) {
      _onAuthenticationSuccess();
    }
  }

  Future<void> _authenticateWithPin() async {
    final success = await ref.read(providers.securityNotifierProvider.notifier).verifyPin(_enteredPin);
    if (success) {
      _onAuthenticationSuccess();
    } else {
      _onAuthenticationFailed();
    }
  }

  void _onAuthenticationSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _onAuthenticationFailed() {
    setState(() {
      _failedAttempts++;
      _enteredPin = '';
    });

    if (_failedAttempts >= _maxFailedAttempts) {
      _showMaxAttemptsDialog();
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Too Many Failed Attempts'),
        content: const Text(
          'You have exceeded the maximum number of authentication attempts. '
          'Please restart the app and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}