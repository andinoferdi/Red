import 'package:flutter/material.dart';

/// A custom page transition that uses a smooth fade effect for transitions
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Customize the animation curve for a smoother feel
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    
    // Use FadeTransition for clean, app-like transitions
    return FadeTransition(
      opacity: fadeAnimation,
      child: child,
    );
  }
}

/// A custom page transition that combines fade with a slight scale effect
/// This creates a very premium-feeling transition
class FadeScalePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeScalePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use easeOut for entry and easeIn for exit animations
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    // Combine fade with a subtle scale effect
    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
