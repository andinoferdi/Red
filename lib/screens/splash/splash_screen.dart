import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../routes/app_router.dart';
import '../../controllers/auth_controller.dart';
import '../../states/auth_state.dart';
import '../../utils/app_colors.dart';

@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _minDisplayTimer;
  Timer? _maxWaitTimer;
  bool _minTimeElapsed = false;
  bool _hasNavigated = false;
  
  @override
  void initState() {
    super.initState();
    
    // Quick check if user is already authenticated (from previous session)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authControllerProvider);
      
      // If user is clearly authenticated and not loading, skip splash
      if (authState.isAuthenticated && !authState.isLoading) {
        _navigateToHome();
        return;
      }
    });
    
    // Minimum display time (1 second for better UX)
    _minDisplayTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkAndNavigate();
      }
    });
    
    // Maximum wait time (5 seconds - force navigation if taking too long)
    _maxWaitTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) {
        final authState = ref.read(authControllerProvider);
        if (authState.isAuthenticated) {
          _navigateToHome();
        } else {
          _navigateToOnboarding();
        }
      }
    });
  }
  
  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    context.router.replace(const HomeRoute());
  }
  
  void _navigateToOnboarding() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    context.router.replace(const OnboardingRoute());
  }
  
  void _checkAndNavigate() {
    if (_hasNavigated || !_minTimeElapsed) {
      return;
    }
    
    final authState = ref.read(authControllerProvider);
    
    // Don't navigate while loading
    if (authState.isLoading) {
      return;
    }
    
    // Navigate based on auth state
    if (authState.isAuthenticated) {
      _navigateToHome();
    } else {
      _navigateToOnboarding();
    }
  }
  
  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    _maxWaitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    // Listen for auth state changes
    ref.listen<AuthState>(authControllerProvider, (previous, state) {
      _checkAndNavigate();
    });
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/wave_icon.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 30),
            Image.asset(
              'assets/images/red_rhythm_text.png',
              width: 240,
            ),
            const SizedBox(height: 40),
            // Show loading indicator when appropriate
            if (authState.isLoading || !_minTimeElapsed)
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            if (authState.error != null && !authState.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Initializing...',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
