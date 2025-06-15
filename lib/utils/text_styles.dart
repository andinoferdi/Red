import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';

class AppTextStyles {
  // Prevent instantiation
  AppTextStyles._();

  // Font family constant
  static const String _fontFamily = 'Poppins';

  // Display styles - for large headings
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.titleFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.extraLargeFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  // Headline styles - for section headings
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.largeFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  // Title styles - for card titles and important text
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.largeFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  // Body styles - for main content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.smallFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Label styles - for buttons and labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.smallFontSize,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Special purpose styles
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.largeFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.smallFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  static const TextStyle error = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
  );

  static const TextStyle success = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
  );

  // Navigation styles
  static const TextStyle navLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.navUnselected,
  );

  static const TextStyle navLabelSelected = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.navSelected,
  );

  // App bar styles
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  // Input field styles
  static const TextStyle inputText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.normal,
    color: AppColors.textDisabled,
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
}
