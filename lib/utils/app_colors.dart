import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFFE71E27);
  static const Color secondary = Color(0xFF424242);

  // Background colors
  static const Color background = Colors.black;
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFF2A0D0E);

  // Text colors
  static const Color text = Colors.white;
  static const Color textSecondary = Color.fromRGBO(255, 255, 255, 0.7);
  static const Color textDisabled = Color.fromRGBO(255, 255, 255, 0.6);
  static const Color textOnPrimary = Colors.white;

  // UI element colors
  static const Color textField = Color(0xFF1E1E1E);
  static const Color border = Color(0xFF424242);
  static const Color divider = Colors.black26;

  // Interactive colors
  static const Color success = Color(0xFF8BC34A);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Colors.red;
  static const Color info = Color(0xFF039BE5);

  // Navigation colors
  static const Color navBackground = Colors.black;
  static const Color navSelected = primary;
  static const Color navUnselected = Colors.white;
  static const Color navIndicator = Color(0xFF1E1E1E);

  // Genre/Category colors
  static const Color genreKpop = Color(0xFF8BC34A);
  static const Color genreIndie = Color(0xFFE91E63);
  static const Color genreRnB = Color(0xFF5C6BC0);
  static const Color genrePop = Color(0xFFE67E22);
  static const Color genreBollywood = Color(0xFFFF9800);
  static const Color genrePopFusion = Color(0xFF009688);
  static const Color genreCharts = Color(0xFF3F51B5);
  static const Color genrePodcasts = Color(0xFFD32F2F);
  static const Color genreReleased = Color(0xFF9C27B0);

  // Additional utility colors
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color greyLight = Color(0xFF757575);
  static const Color greyDark = Color(0xFF424242);

  // Gradient colors
  static const List<Color> homeGradient = [
    Color(0xFF1E1E1E),
    Color(0xFF0D0D0D),
  ];

  // Progress/Loading colors
  static const Color progressActive = Colors.white;
  static const Color progressInactive = Color(0xFF424242);
}


