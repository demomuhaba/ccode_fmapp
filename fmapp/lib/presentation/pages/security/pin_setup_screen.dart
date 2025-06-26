import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'pin_entry_widget.dart';

/// Screen for setting up or changing PIN
class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isChanging;
  final String title;

  const PinSetupScreen({
    super.key,
    this.isChanging = false,
    this.title = 'Set Up PIN',
  });

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  int _step = 1; // 1: current pin (if changing), 2: new pin, 3: confirm pin
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    // If not changing PIN, skip to step 2
    if (!widget.isChanging) {
      _step = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final securityState = ref.watch(providers.securityNotifierProvider);
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildStepIndicator(),
                const SizedBox(height: 32),
                _buildStepContent(),
                const SizedBox(height: 24),
                if (securityState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      securityState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildActionButtons(securityState),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    final totalSteps = widget.isChanging ? 3 : 2;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == _step;
        final isCompleted = stepNumber < _step;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : isCompleted
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                    : Theme.of(context).colorScheme.outline,
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildCurrentPinStep();
      case 2:
        return _buildNewPinStep();
      case 3:
        return _buildConfirmPinStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCurrentPinStep() {
    return Column(
      children: [
        Icon(
          Icons.lock_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Enter Current PIN',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please enter your current PIN to continue',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PinEntryWidget(
          onPinChanged: (pin) => _currentPin = pin,
          obscurePin: _obscurePin,
        ),
      ],
    );
  }

  Widget _buildNewPinStep() {
    return Column(
      children: [
        Icon(
          Icons.lock_open,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          widget.isChanging ? 'Enter New PIN' : 'Create Your PIN',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter a 4-digit PIN to secure your financial data',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PinEntryWidget(
          onPinChanged: (pin) => _newPin = pin,
          obscurePin: _obscurePin,
        ),
      ],
    );
  }

  Widget _buildConfirmPinStep() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Confirm Your PIN',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please re-enter your PIN to confirm',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        PinEntryWidget(
          onPinChanged: (pin) => _confirmPin = pin,
          obscurePin: _obscurePin,
        ),
      ],
    );
  }

  Widget _buildActionButtons(dynamic securityState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: securityState.isLoading ? null : _handleNextPressed,
          child: securityState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_getButtonText()),
        ),
        if (_step > 1 || widget.isChanging) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: securityState.isLoading ? null : _handleBackPressed,
            child: const Text('Back'),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Security Information',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Your PIN secures access to all financial data\n'
            '• Use a PIN that\'s easy for you to remember but hard for others to guess\n'
            '• You can enable biometric authentication after setting up your PIN\n'
            '• Authentication expires after 5 minutes of inactivity',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_step) {
      case 1:
        return 'Verify Current PIN';
      case 2:
        return 'Continue';
      case 3:
        return widget.isChanging ? 'Change PIN' : 'Set Up PIN';
      default:
        return 'Continue';
    }
  }

  void _handleNextPressed() async {
    final securityNotifier = ref.read(providers.securityNotifierProvider.notifier);

    switch (_step) {
      case 1:
        // Verify current PIN
        final isValid = await securityNotifier.verifyPin(_currentPin);
        if (isValid) {
          setState(() => _step = 2);
        }
        break;

      case 2:
        // Validate new PIN
        if (_newPin.length != 4) {
          _showError('PIN must be exactly 4 digits');
          return;
        }
        if (!RegExp(r'^\d{4}$').hasMatch(_newPin)) {
          _showError('PIN must contain only numbers');
          return;
        }
        setState(() => _step = 3);
        break;

      case 3:
        // Confirm PIN and set up
        if (_newPin != _confirmPin) {
          _showError('PINs do not match. Please try again.');
          return;
        }

        final success = widget.isChanging
            ? await securityNotifier.changePin(_currentPin, _newPin)
            : await securityNotifier.setupPin(_newPin);

        if (success) {
          if (!mounted) return;
          
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(
                widget.isChanging
                    ? 'Your PIN has been changed successfully.'
                    : 'Your PIN has been set up successfully. Your financial data is now secure.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(true); // Close screen with success
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        break;
    }
  }

  void _handleBackPressed() {
    if (_step > 1) {
      setState(() => _step--);
    } else if (widget.isChanging) {
      setState(() => _step = 1);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}