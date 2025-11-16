import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors_extension.dart';
import 'app_text_theme_extension.dart';
import 'app_typography.dart';

/// Custom app theme with Material Kit Flutter colors and ThemeExtension support.
/// Provides both light and dark theme configurations with smooth transitions.
/// Manages theme switching and saves user preference.
///
/// Usage in MaterialApp:
/// ```dart
/// ChangeNotifierProvider(
///   create: (context) => AppTheme(),
///   child: Consumer<AppTheme>(
///     builder: (context, themeProvider, child) => MaterialApp(
///       theme: AppTheme.light,
///       darkTheme: AppTheme.dark,
///       themeMode: themeProvider.themeMode,
///     ),
///   ),
/// )
/// ```
class AppTheme with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  static final _ThemeBundle _lightBundle = _buildThemeBundle(Brightness.light);
  static final _ThemeBundle _darkBundle = _buildThemeBundle(Brightness.dark);

  static final ThemeData light = _lightBundle.theme;
  static final ThemeData dark = _darkBundle.theme;

  static AppColorsExtension get _lightAppColors => _lightBundle.colors;
  static AppColorsExtension get _darkAppColors => _darkBundle.colors;
  static AppTextThemeExtension get _lightTextTheme => _lightBundle.texts;
  static AppTextThemeExtension get _darkTextTheme => _darkBundle.texts;

  ThemeMode get themeMode => _themeMode;

  /// Initialize theme from saved preference
  Future<void> initialize() async {
    await _loadThemeFromPrefs();
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Set specific theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    await _saveThemeToPrefs();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeModeKey);
      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, keep default theme
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Check if current theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if current theme is light
  bool get isLightMode => _themeMode == ThemeMode.light;

  static _ThemeBundle _buildThemeBundle(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    );

    final textTheme = _buildTypography(scheme);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Cairo',
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final theme = base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor:
            brightness == Brightness.dark ? scheme.surfaceVariant : scheme.primary,
        foregroundColor:
            brightness == Brightness.dark ? scheme.onSurface : scheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: brightness == Brightness.dark ? scheme.onSurface : scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(
          color: brightness == Brightness.dark ? scheme.onSurface : scheme.onPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: scheme.surfaceVariant,
        elevation: 2,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 1.5,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          hoverColor: scheme.primary.withOpacity(0.1),
          highlightColor: scheme.primary.withOpacity(0.1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceVariant,
        labelStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant.withOpacity(0.65)),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionHandleColor: scheme.primary,
        selectionColor: scheme.primary.withOpacity(0.35),
      ),
    );

    final colorsExtension = _buildColorsExtension(scheme);
    final textExtension = _buildTextThemeExtension(scheme);

    return _ThemeBundle(
      theme.copyWith(
        extensions: <ThemeExtension<dynamic>>[
          colorsExtension,
          textExtension,
        ],
      ),
      colorsExtension,
      textExtension,
    );
  }

  static TextTheme _buildTypography(ColorScheme scheme) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: scheme.onBackground),
      displayMedium: AppTypography.displayMedium.copyWith(color: scheme.onBackground),
      displaySmall: AppTypography.displaySmall.copyWith(color: scheme.onBackground),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: scheme.onBackground),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: scheme.onBackground),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: scheme.onBackground),
      titleLarge: AppTypography.titleLarge.copyWith(color: scheme.onSurface),
      titleMedium: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
      titleSmall: AppTypography.titleSmall.copyWith(color: scheme.onSurfaceVariant),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
      bodySmall: AppTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
      labelMedium: AppTypography.labelMedium.copyWith(color: scheme.onSurface),
      labelSmall: AppTypography.labelSmall.copyWith(color: scheme.onSurfaceVariant),
    );
  }

  static AppColorsExtension _buildColorsExtension(ColorScheme scheme) {
    return AppColorsExtension(
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      secondary: scheme.secondary,
      onSecondary: scheme.onSecondary,
      error: scheme.error,
      onError: scheme.onError,
      success: scheme.tertiary,
      onSuccess: scheme.onTertiary,
      warning: scheme.secondaryContainer,
      onWarning: scheme.onSecondaryContainer,
      info: scheme.primaryContainer,
      onInfo: scheme.onPrimaryContainer,
      background: scheme.background,
      onBackground: scheme.onBackground,
      surface: scheme.surface,
      onSurface: scheme.onSurface,
      card: scheme.surfaceVariant,
      onCard: scheme.onSurfaceVariant,
      accent: scheme.secondary,
      muted: scheme.onSurfaceVariant,
      border: scheme.outlineVariant,
      inputBackground: scheme.surfaceVariant,
    );
  }

  static AppTextThemeExtension _buildTextThemeExtension(ColorScheme scheme) {
    return AppTextThemeExtension(
      displayLarge: AppTypography.displayLarge.copyWith(color: scheme.onBackground),
      displayMedium: AppTypography.displayMedium.copyWith(color: scheme.onBackground),
      displaySmall: AppTypography.displaySmall.copyWith(color: scheme.onBackground),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: scheme.onBackground),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: scheme.onBackground),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: scheme.onBackground),
      titleLarge: AppTypography.titleLarge.copyWith(color: scheme.onSurface),
      titleMedium: AppTypography.titleMedium.copyWith(color: scheme.onSurface),
      titleSmall: AppTypography.titleSmall.copyWith(color: scheme.onSurfaceVariant),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
      bodySmall: AppTypography.bodySmall.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: AppTypography.labelLarge.copyWith(color: scheme.onSurface),
      labelMedium: AppTypography.labelMedium.copyWith(color: scheme.onSurface),
      labelSmall: AppTypography.labelSmall.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _ThemeBundle {
  const _ThemeBundle(this.theme, this.colors, this.texts);

  final ThemeData theme;
  final AppColorsExtension colors;
  final AppTextThemeExtension texts;
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
