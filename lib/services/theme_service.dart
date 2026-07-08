import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

/// Service for managing app theme persistence and switching
class ThemeService {
  static const String _storageKey = 'app_theme_mode';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Load the saved theme mode from storage
  static Future<AppThemeMode> loadThemeMode() async {
    try {
      final savedMode = await _storage.read(key: _storageKey);
      if (savedMode != null) {
        return AppThemeMode.values.firstWhere(
          (e) => e.toString() == savedMode,
          orElse: () => AppThemeMode.light,
        );
      }
    } catch (e) {
      // Error loading theme, use default
    }
    return AppThemeMode.light;
  }

  /// Save theme mode to storage
  static Future<void> saveThemeMode(AppThemeMode mode) async {
    try {
      await _storage.write(key: _storageKey, value: mode.toString());
    } catch (e) {
      // Error saving theme
    }
  }

  /// Clear saved theme mode (reset to default)
  static Future<void> clearThemeMode() async {
    try {
      await _storage.delete(key: _storageKey);
    } catch (e) {
      // Error clearing theme
    }
  }

  /// Get ThemeData for the given theme mode
  static ThemeData getThemeData(AppThemeMode mode) {
    return AppTheme.getTheme(mode);
  }

  /// Get all available theme modes
  static List<AppThemeMode> get availableThemes => AppThemeMode.values;

  /// Get theme display name
  static String getThemeDisplayName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.purple:
        return 'Purple Theme';
      case AppThemeMode.light:
        return 'Light Theme';
      case AppThemeMode.blue:
        return 'Blue Theme';
      case AppThemeMode.green:
        return 'Green Theme';
      case AppThemeMode.pink:
        return 'Pink Theme';
      case AppThemeMode.highContrast:
        return 'High Contrast';
    }
  }

  /// Get theme icon
  static IconData getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.purple:
        return Icons.auto_awesome_rounded;
      case AppThemeMode.light:
        return Icons.wb_sunny_rounded;
      case AppThemeMode.blue:
        return Icons.waves_rounded;
      case AppThemeMode.green:
        return Icons.eco_rounded;
      case AppThemeMode.pink:
        return Icons.favorite_rounded;
      case AppThemeMode.highContrast:
        return Icons.contrast_rounded;
    }
  }

  /// Get theme primary color
  static Color getThemeColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.purple:
        return const Color(0xFF7C3AED);
      case AppThemeMode.light:
        return const Color(0xFF7C3AED);
      case AppThemeMode.blue:
        return const Color(0xFF2563EB);
      case AppThemeMode.green:
        return const Color(0xFF10B981);
      case AppThemeMode.pink:
        return const Color(0xFFEC4899);
      case AppThemeMode.highContrast:
        return const Color(0xFFFFFFFF);
    }
  }

  /// Get theme description
  static String getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.purple:
        return 'Default vibrant purple';
      case AppThemeMode.light:
        return 'Clean and modern look';
      case AppThemeMode.blue:
        return 'Ocean blue vibes';
      case AppThemeMode.green:
        return 'Nature inspired green';
      case AppThemeMode.pink:
        return 'Romantic pink vibes';
      case AppThemeMode.highContrast:
        return 'Maximum contrast for accessibility';
    }
  }
}
