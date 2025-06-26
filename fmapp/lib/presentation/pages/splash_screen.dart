import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod_providers.dart' as providers;
import 'auth/login_screen.dart';
import 'main_navigation.dart';
import 'security/authentication_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Check auth status
    await ref.read(providers.authNotifierProvider.notifier).checkAuthStatus();
    
    if (mounted) {
      final authState = ref.read(providers.authNotifierProvider);
      final securityState = ref.read(providers.securityNotifierProvider);
      
      if (authState.isSignedIn) {
        // User is signed in, check if app-level authentication is required
        final securityService = ref.read(providers.securityServiceProvider);
        final authRequired = await securityService.isAuthRequired();
        
        if (authRequired) {
          // Show authentication screen
          _navigateToAuthentication();
        } else {
          // Go directly to dashboard
          _navigateToDashboard();
        }
      } else {
        // User not signed in, go to login
        _navigateToLogin();
      }
    }
  }

  void _navigateToAuthentication() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AuthenticationScreen(),
      ),
    ).then((authenticated) {
      if (authenticated == true) {
        _navigateToDashboard();
      } else {
        _navigateToLogin();
      }
    });
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigation(),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'FM Finance Manager',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Personal Multi-SIM Finance & Loan Manager',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}