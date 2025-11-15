import 'package:flutter/material.dart';
import 'app_colors_extension.dart';
import 'app_text_theme_extension.dart';
import 'app_typography.dart';
import 'app_palette.dart';

/// Custom app theme with Material Kit Flutter colors and ThemeExtension support.
/// Provides both light and dark theme configurations with smooth transitions.
///
/// Usage in MaterialApp:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system, // or ThemeMode.light / ThemeMode.dark
/// )
/// ```
class AppTheme with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  set themeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  //
  // Light theme (Material Kit Flutter style)
  //

  static final light = () {
    final defaultTheme = ThemeData.light();

    return defaultTheme.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.bgColorScreen,
      colorScheme: ColorScheme.light(
        primary: AppPalette.primary,
        secondary: AppPalette.secondary,
        error: AppPalette.error,
        background: AppPalette.bgColorScreen,
        surface: AppPalette.cardSurface,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppPalette.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppPalette.textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppPalette.textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppPalette.textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppPalette.textPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppPalette.textPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppPalette.textPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppPalette.textPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppPalette.textSecondary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppPalette.textPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppPalette.textPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppPalette.textSecondary),
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppPalette.cardSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
      ),
      extensions: [
        _lightAppColors,
        _lightTextTheme,
      ],
    );
  }();

  static final _lightAppColors = AppColorsExtension(
    primary: AppPalette.primary,
    onPrimary: Colors.white,
    secondary: AppPalette.secondary,
    onSecondary: Colors.black,
    error: AppPalette.error,
    onError: Colors.white,
    success: AppPalette.success,
    onSuccess: Colors.white,
    warning: AppPalette.warning,
    onWarning: Colors.white,
    info: AppPalette.info,
    onInfo: Colors.white,
    background: AppPalette.bgColorScreen,
    onBackground: AppPalette.textPrimary,
    surface: AppPalette.cardSurface,
    onSurface: AppPalette.textPrimary,
    card: AppPalette.cardSurface,
    onCard: AppPalette.textPrimary,
    accent: AppPalette.accent,
    muted: AppPalette.muted,
    border: AppPalette.border,
    inputBackground: AppPalette.input,
  );

  static final _lightTextTheme = AppTextThemeExtension(
    displayLarge: AppTypography.displayLarge.copyWith(color: _lightAppColors.onBackground),
    displayMedium: AppTypography.displayMedium.copyWith(color: _lightAppColors.onBackground),
    displaySmall: AppTypography.displaySmall.copyWith(color: _lightAppColors.onBackground),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: _lightAppColors.onBackground),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: _lightAppColors.onBackground),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: _lightAppColors.onBackground),
    titleLarge: AppTypography.titleLarge.copyWith(color: _lightAppColors.onBackground),
    titleMedium: AppTypography.titleMedium.copyWith(color: _lightAppColors.onBackground),
    titleSmall: AppTypography.titleSmall.copyWith(color: _lightAppColors.onSurface),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: _lightAppColors.onBackground),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: _lightAppColors.onBackground),
    bodySmall: AppTypography.bodySmall.copyWith(color: _lightAppColors.muted),
    labelLarge: AppTypography.labelLarge,
    labelMedium: AppTypography.labelMedium,
    labelSmall: AppTypography.labelSmall,
  );

  //
  // Dark theme (Material Kit Flutter dark mode)
  //

  static final dark = () {
    final defaultTheme = ThemeData.dark();

    return defaultTheme.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppPalette.primaryLight,
        secondary: AppPalette.secondaryLight,
        error: AppPalette.error,
        background: AppPalette.darkBackground,
        surface: AppPalette.darkSurface,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: Colors.white),
        displayMedium: AppTypography.displayMedium.copyWith(color: Colors.white),
        displaySmall: AppTypography.displaySmall.copyWith(color: Colors.white),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: Colors.white),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: Colors.white),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: Colors.white),
        titleLarge: AppTypography.titleLarge.copyWith(color: Colors.white),
        titleMedium: AppTypography.titleMedium.copyWith(color: Colors.white),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppPalette.textMuted),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: Colors.white),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: Colors.white),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppPalette.textMuted),
        labelLarge: AppTypography.labelLarge.copyWith(color: Colors.white),
        labelMedium: AppTypography.labelMedium.copyWith(color: Colors.white),
        labelSmall: AppTypography.labelSmall.copyWith(color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppPalette.darkCard,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primaryLight,
          foregroundColor: Colors.black,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.muted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.muted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppPalette.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primaryLight,
        foregroundColor: Colors.black,
      ),
      extensions: [
        _darkAppColors,
        _darkTextTheme,
      ],
    );
  }();

  static final _darkAppColors = AppColorsExtension(
    primary: AppPalette.primaryLight,
    onPrimary: Colors.black,
    secondary: AppPalette.secondaryLight,
    onSecondary: Colors.black,
    error: AppPalette.error,
    onError: Colors.white,
    success: AppPalette.success,
    onSuccess: Colors.white,
    warning: AppPalette.warning,
    onWarning: Colors.black,
    info: AppPalette.info,
    onInfo: Colors.black,
    background: AppPalette.darkBackground,
    onBackground: Colors.white,
    surface: AppPalette.darkSurface,
    onSurface: Colors.white,
    card: AppPalette.darkCard,
    onCard: Colors.white,
    accent: AppPalette.accent,
    muted: AppPalette.textMuted,
    border: AppPalette.muted,
    inputBackground: AppPalette.darkSurface,
  );

  static final _darkTextTheme = AppTextThemeExtension(
    displayLarge: AppTypography.displayLarge.copyWith(color: _darkAppColors.onBackground),
    displayMedium: AppTypography.displayMedium.copyWith(color: _darkAppColors.onBackground),
    displaySmall: AppTypography.displaySmall.copyWith(color: _darkAppColors.onBackground),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: _darkAppColors.onBackground),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: _darkAppColors.onBackground),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: _darkAppColors.onBackground),
    titleLarge: AppTypography.titleLarge.copyWith(color: _darkAppColors.onBackground),
    titleMedium: AppTypography.titleMedium.copyWith(color: _darkAppColors.onBackground),
    titleSmall: AppTypography.titleSmall.copyWith(color: _darkAppColors.onSurface),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: _darkAppColors.onBackground),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: _darkAppColors.onBackground),
    bodySmall: AppTypography.bodySmall.copyWith(color: _darkAppColors.muted),
    labelLarge: AppTypography.labelLarge.copyWith(color: Colors.white),
    labelMedium: AppTypography.labelMedium.copyWith(color: Colors.white),
    labelSmall: AppTypography.labelSmall.copyWith(color: Colors.white),
  );
}

/// Extension to safely access AppColorsExtension from ThemeData.
///
/// Usage: `Theme.of(context).appColors.primary`
extension AppThemeExtension on ThemeData {
  AppColorsExtension get appColors =>
      extension<AppColorsExtension>() ?? AppTheme._lightAppColors;

  AppTextThemeExtension get appTextTheme =>
      extension<AppTextThemeExtension>() ?? AppTheme._lightTextTheme;
}

/// Convenient way to get ThemeData from BuildContext.
///
/// Usage: `context.theme.appColors.primary`
extension ThemeGetter on BuildContext {
  ThemeData get theme => Theme.of(this);
}
