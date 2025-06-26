import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'services/isar_service.dart';
import 'services/recurring_transaction_scheduler.dart';
import 'presentation/providers/riverpod_providers.dart' as providers;
import 'presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.currentUrl,
    anonKey: SupabaseConfig.currentAnonKey,
  );

  // Initialize Isar database
  await IsarService.instance.database;
  
  // Start background sync
  await IsarService.instance.startBackgroundSync();
  
  // Initialize recurring transaction scheduler
  try {
    await RecurringTransactionScheduler.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize recurring transaction scheduler: $e');
  }

  runApp(const ProviderScope(child: FMApp()));
}

class FMApp extends ConsumerWidget {
  const FMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(providers.themeNotifierProvider);
    
    return MaterialApp(
      title: 'FM Finance Manager',
      theme: _getLightTheme(),
      darkTheme: _getDarkTheme(),
      themeMode: _getThemeMode(themeState.themeMode),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData _getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }

  ThemeMode _getThemeMode(providers.ThemeMode mode) {
    switch (mode) {
      case providers.ThemeMode.light:
        return ThemeMode.light;
      case providers.ThemeMode.dark:
        return ThemeMode.dark;
      case providers.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}