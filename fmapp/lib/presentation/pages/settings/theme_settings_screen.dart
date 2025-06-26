import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riverpod_providers.dart' as providers;

/// Screen for managing theme settings
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(providers.themeNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCurrentThemeInfo(context, themeState),
          const SizedBox(height: 24),
          _buildThemeSelector(context, ref, themeState),
          const SizedBox(height: 24),
          _buildThemePreview(context),
          const SizedBox(height: 24),
          _buildThemeInfo(context),
        ],
      ),
    );
  }

  Widget _buildCurrentThemeInfo(BuildContext context, dynamic themeState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getThemeModeIcon(themeState.themeMode),
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Theme',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                    Text(
                      _getThemeModeString(themeState.themeMode),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getThemeDescription(themeState.themeMode),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, dynamic themeState) {
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
            child: Text(
              'Choose Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ..._getAvailableThemes().map((themeOption) {
            final providers.ThemeMode mode = themeOption['mode'];
            final bool isSelected = themeState.themeMode == mode;
            
            return ListTile(
              leading: Icon(
                themeOption['icon'],
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(themeOption['name']),
              subtitle: Text(themeOption['description']),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => ref.read(providers.themeNotifierProvider.notifier).setThemeMode(mode),
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context) {
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
            child: Text(
              'Theme Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sample card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sample Account',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Bank Account • ETB 1,250.00',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Transaction'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text('View Details'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sample list items
                ...List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: index % 2 == 0 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        child: Icon(
                          index % 2 == 0 ? Icons.arrow_downward : Icons.arrow_upward,
                          color: index % 2 == 0 ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        index % 2 == 0 ? 'Income Transaction' : 'Expense Transaction',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        'Yesterday • Sample Description',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Text(
                        index % 2 == 0 ? '+ETB 500.00' : '-ETB 125.50',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: index % 2 == 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeInfo(BuildContext context) {
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
                'About Themes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• System: Automatically switches between light and dark based on your device settings\n'
            '• Light: Always uses the light theme with bright colors\n'
            '• Dark: Always uses the dark theme with muted colors, better for low-light environments\n'
            '• Your theme preference is saved and will be restored when you restart the app',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getThemeDescription(providers.ThemeMode mode) {
    switch (mode) {
      case providers.ThemeMode.system:
        return 'Automatically adapts to your device\'s system settings';
      case providers.ThemeMode.light:
        return 'Bright theme optimized for daytime use';
      case providers.ThemeMode.dark:
        return 'Dark theme optimized for low-light environments';
    }
  }

  String _getThemeModeString(providers.ThemeMode mode) {
    switch (mode) {
      case providers.ThemeMode.light:
        return 'Light';
      case providers.ThemeMode.dark:
        return 'Dark';
      case providers.ThemeMode.system:
        return 'System';
    }
  }

  IconData _getThemeModeIcon(providers.ThemeMode mode) {
    switch (mode) {
      case providers.ThemeMode.light:
        return Icons.light_mode;
      case providers.ThemeMode.dark:
        return Icons.dark_mode;
      case providers.ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  List<Map<String, dynamic>> _getAvailableThemes() {
    return [
      {
        'mode': providers.ThemeMode.system,
        'name': 'System',
        'icon': Icons.brightness_auto,
        'description': 'Follow system setting',
      },
      {
        'mode': providers.ThemeMode.light,
        'name': 'Light',
        'icon': Icons.light_mode,
        'description': 'Light theme',
      },
      {
        'mode': providers.ThemeMode.dark,
        'name': 'Dark',
        'icon': Icons.dark_mode,
        'description': 'Dark theme',
      },
    ];
  }
}