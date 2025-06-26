import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/riverpod_providers.dart' as providers;
import 'pin_setup_screen.dart';

/// Screen for managing security settings
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize security provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(providers.securityNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final securityState = ref.watch(providers.securityNotifierProvider);
          
          if (securityState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(providers.securityNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSecurityOverview(securityState),
                const SizedBox(height: 24),
                _buildPinSection(securityState),
                const SizedBox(height: 24),
                _buildBiometricSection(securityState),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
                const SizedBox(height: 24),
                _buildDangerZone(securityState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityOverview(dynamic securityState) {
    final pinEnabled = securityState.pinEnabled;
    final biometricEnabled = securityState.biometricEnabled;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (pinEnabled && biometricEnabled) {
      statusColor = Colors.green;
      statusIcon = Icons.security;
      statusText = 'Excellent Security';
    } else if (pinEnabled) {
      statusColor = Colors.orange;
      statusIcon = Icons.lock;
      statusText = 'Good Security';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.lock_open;
      statusText = 'No Security';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 48,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getSecurityDescription(pinEnabled, biometricEnabled),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection(dynamic securityState) {
    final pinEnabled = securityState.pinEnabled;
    
    return _buildSettingsSection(
      title: 'PIN Security',
      icon: Icons.pin,
      children: [
        ListTile(
          leading: Icon(
            pinEnabled ? Icons.check_circle : Icons.radio_button_unchecked,
            color: pinEnabled ? Colors.green : null,
          ),
          title: const Text('PIN Protection'),
          subtitle: Text(
            pinEnabled
                ? 'Your app is protected with a 4-digit PIN'
                : 'Set up a PIN to secure your financial data',
          ),
          trailing: pinEnabled
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToPinSetup(isChanging: true),
                )
              : ElevatedButton(
                  onPressed: () => _navigateToPinSetup(isChanging: false),
                  child: const Text('Set Up'),
                ),
        ),
        if (pinEnabled) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your current PIN'),
            onTap: () => _navigateToPinSetup(isChanging: true),
          ),
        ],
      ],
    );
  }

  Widget _buildBiometricSection(dynamic securityState) {
    final biometricAvailable = securityState.biometricAvailable;
    final biometricEnabled = securityState.biometricEnabled;
    final pinEnabled = securityState.pinEnabled;
    final availableBiometrics = securityState.availableBiometricNames;

    return _buildSettingsSection(
      title: 'Biometric Authentication',
      icon: Icons.fingerprint,
      children: [
        if (!biometricAvailable) ...[
          ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.grey),
            title: const Text('Biometric Not Available'),
            subtitle: const Text('This device does not support biometric authentication'),
          ),
        ] else if (!pinEnabled) ...[
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: const Text('PIN Required'),
            subtitle: const Text('Set up a PIN first before enabling biometric authentication'),
          ),
        ] else ...[
          SwitchListTile(
            secondary: Icon(
              _getBiometricIcon(securityState.availableBiometrics),
              color: biometricEnabled ? Colors.green : null,
            ),
            title: Text('${_getBiometricLabel(securityState.availableBiometrics)} Authentication'),
            subtitle: Text(
              biometricEnabled
                  ? 'Use ${_getBiometricLabel(securityState.availableBiometrics).toLowerCase()} to unlock the app'
                  : 'Enable ${_getBiometricLabel(securityState.availableBiometrics).toLowerCase()} authentication for quick access',
            ),
            value: biometricEnabled,
            onChanged: securityState.isLoading
                ? null
                : (value) => _toggleBiometric(value),
          ),
          if (availableBiometrics.isNotEmpty) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Available Methods'),
              subtitle: Text(availableBiometrics.join(', ')),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
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
              ),
              const SizedBox(width: 12),
              Text(
                'Security Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Authentication expires after 5 minutes of inactivity\n'
            '• Your PIN is securely encrypted and stored locally\n'
            '• Biometric data never leaves your device\n'
            '• Security settings protect all your financial data\n'
            '• You can disable security anytime from settings',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(dynamic securityState) {
    if (!securityState.pinEnabled) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Disabling security will remove all protection from your financial data.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: securityState.isLoading
                  ? null
                  : () => _showDisableSecurityDialog(),
              icon: const Icon(Icons.security_update_warning),
              label: const Text('Disable Security'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSecurityDescription(bool pinEnabled, bool biometricEnabled) {
    if (pinEnabled && biometricEnabled) {
      return 'Your financial data is protected with both PIN and biometric authentication.';
    } else if (pinEnabled) {
      return 'Your financial data is protected with PIN authentication. Consider enabling biometric authentication for convenience.';
    } else {
      return 'Your financial data is not protected. Set up security to keep your information safe.';
    }
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

  void _navigateToPinSetup({required bool isChanging}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(
          isChanging: isChanging,
          title: isChanging ? 'Change PIN' : 'Set Up PIN',
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh security status
      ref.read(providers.securityNotifierProvider.notifier).refresh();
    }
  }

  void _toggleBiometric(bool enabled) async {
    final success = await ref.read(providers.securityNotifierProvider.notifier).toggleBiometric(enabled);
    if (!success && mounted) {
      final securityState = ref.read(providers.securityNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(securityState.error ?? 'Failed to update biometric settings'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showDisableSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Security?'),
        content: const Text(
          'This will remove your PIN and disable biometric authentication. '
          'Your financial data will no longer be protected.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _disableSecurity(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Disable Security'),
          ),
        ],
      ),
    );
  }

  void _disableSecurity() async {
    Navigator.of(context).pop(); // Close dialog
    
    final success = await ref.read(providers.securityNotifierProvider.notifier).removePin();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security has been disabled'),
        ),
      );
    } else if (mounted) {
      final securityState = ref.read(providers.securityNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(securityState.error ?? 'Failed to disable security'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}