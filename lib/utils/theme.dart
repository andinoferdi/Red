import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';
import 'custom_page_transitions.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Main app theme
  static ThemeData get theme => ThemeData(
        // Base colors
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,

        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surfaceContainer: AppColors.background,
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurfaceVariant: Colors.white,
          onSurface: Colors.white,
        ),

        // Typography - menggunakan font DM Sans
        fontFamily: 'DM Sans',
        textTheme: _textTheme,

        // Component themes
        appBarTheme: _appBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        iconTheme: _iconTheme,
        bottomNavigationBarTheme: _bottomNavBarTheme,

        // Material 3
        useMaterial3: true,

        // Transitions - Use consistent fade+scale transition across all platforms
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.iOS: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.windows: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.macOS: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.linux: const FadeScalePageTransitionsBuilder(),
          },
        ),
      );

  // Text theme - Semua menggunakan font Gotham
  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodySmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelSmall: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );

  // AppBar theme
  static AppBarTheme get _appBarTheme => const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );

  // Elevated button theme
  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: AppConstants.largeFontSize,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      );

  // Text button theme
  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: AppConstants.mediumFontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  // Input decoration theme
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textField,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'DM Sans',
          color: AppColors.textDisabled,
        ),
        prefixIconColor: AppColors.textDisabled,
        suffixIconColor: AppColors.textDisabled,
      );

  // Card theme
  static CardTheme get _cardTheme => CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        margin: const EdgeInsets.all(0),
      );

  // Icon theme
  static IconThemeData get _iconTheme => const IconThemeData(
        color: Colors.white,
        size: AppConstants.mediumIconSize,
      );

  // Bottom navigation bar theme - dengan font Poppins
  static BottomNavigationBarThemeData get _bottomNavBarTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected, 
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      );

  // Custom button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: AppConstants.largeFontSize,
          fontWeight: FontWeight.w500,
        ),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: AppConstants.largeFontSize,
          fontWeight: FontWeight.w500,
        ),
      );

  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.white, width: 1),
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: AppConstants.largeFontSize,
          fontWeight: FontWeight.w500,
        ),
      );

  // Custom text styles
  static TextStyle get headingStyle => const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: AppConstants.titleFontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get subheadingStyle => const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: AppConstants.extraLargeFontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: AppConstants.mediumFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: AppConstants.smallFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get linkStyle => const TextStyle(
        fontFamily: 'DM Sans',
        fontSize: AppConstants.mediumFontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );
}


