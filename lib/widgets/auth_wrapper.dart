import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../controllers/auth_controller.dart';

/// Widget that manages redirection based on auth state
@RoutePage(name: 'AuthWrapperRoute')
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Show loading indicator when checking auth status
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user is authenticated, navigate to home screen
    if (authState.isAuthenticated) {
      return const AutoRouter();
    }

    // If user is not authenticated, navigate to auth options screen
    return AutoRouter();
  }
}
