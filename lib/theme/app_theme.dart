import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  purple, // Default purple theme (dark)
  blue, // Blue theme (dark)
  green, // Green theme (dark)
  pink, // Pink theme (dark)
  light, // Light theme
  highContrast, // High contrast for accessibility
}

class AppTheme {
  // Modern vibrant color palette
  static const Color primaryColor = Color(0xFF7C3AED); // Vibrant Purple
  static const Color primarySeed = Color(0xFF7C3AED); // Vibrant Purple (alias)
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan
  static const Color secondarySeed = Color(0xFF06B6D4); // Cyan (alias)

  static const Color backgroundColor = Color(0xFF0F172A); // Slate 900
  static const Color surfaceColor = Color(0xFF1E293B); // Slate 800
  static const Color cardColor = Color(0xFF334155); // Slate 700

  static const Color errorColor = Color(0xFFF43F5E); // Rose
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber

  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryColor = Color(0xFF000000);
  static const Color onBackgroundColor = Color(0xFFCBD5E1); // Slate 300
  static const Color onSurfaceColor = Color(0xFFE2E8F0); // Slate 200
  static const Color onCardColor = Color(0xFFF1F5F9); // Slate 100

  // Modern Google Font - Poppins
  static const String _fontFamily = 'Poppins';

  // Theme colors for each mode
  static const Map<AppThemeMode, ThemeColors> _themeColors = {
    AppThemeMode.purple: ThemeColors(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF06B6D4),
      background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
      card: Color(0xFF334155),
      onBackground: Color(0xFFCBD5E1),
      onSurface: Color(0xFFE2E8F0),
      brightness: Brightness.dark,
    ),
    AppThemeMode.blue: ThemeColors(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF0EA5E9),
      background: Color(0xFF0C1929),
      surface: Color(0xFF1A2942),
      card: Color(0xFF273549),
      onBackground: Color(0xFFCBD5E1),
      onSurface: Color(0xFFE2E8F0),
      brightness: Brightness.dark,
    ),
    AppThemeMode.green: ThemeColors(
      primary: Color(0xFF10B981),
      secondary: Color(0xFF06B6D4),
      background: Color(0xFF0C1A16),
      surface: Color(0xFF1A2F29),
      card: Color(0xFF274239),
      onBackground: Color(0xFFCBD5E1),
      onSurface: Color(0xFFE2E8F0),
      brightness: Brightness.dark,
    ),
    AppThemeMode.pink: ThemeColors(
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFF472B6),
      background: Color(0xFF1A0C1A),
      surface: Color(0xFF2D1A2D),
      card: Color(0xFF402940),
      onBackground: Color(0xFFCBD5E1),
      onSurface: Color(0xFFE2E8F0),
      brightness: Brightness.dark,
    ),
    AppThemeMode.light: ThemeColors(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF06B6D4),
      background: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      card: Color(0xFFF1F5F9),
      onBackground: Color(0xFF334155),
      onSurface: Color(0xFF1E293B),
      brightness: Brightness.light,
    ),
    AppThemeMode.highContrast: ThemeColors(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF00FFFF),
      background: Color(0xFF000000),
      surface: Color(0xFF1A1A1A),
      card: Color(0xFF2A2A2A),
      onBackground: Color(0xFFFFFFFF),
      onSurface: Color(0xFFFFFFFF),
      brightness: Brightness.dark,
    ),
  };

  static ThemeData getTheme(AppThemeMode mode) {
    final colors = _themeColors[mode]!;
    return _buildTheme(
      primary: colors.primary,
      secondary: colors.secondary,
      background: colors.background,
      surface: colors.surface,
      card: colors.card,
      onBackground: colors.onBackground,
      onSurface: colors.onSurface,
      brightness: colors.brightness,
    );
  }

  static ThemeData get darkTheme => getTheme(AppThemeMode.purple);
  static ThemeData get highContrastTheme => getTheme(AppThemeMode.highContrast);

  static ThemeData _buildTheme({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color card,
    required Color onBackground,
    required Color onSurface,
    required Brightness brightness,
  }) {
    // Create color scheme from seed for Material 3
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
    ).copyWith(
      // Override with custom colors for more vibrant look
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: card,
      surfaceContainerHighest: brightness == Brightness.dark
          ? const Color(0xFF475569)
          : const Color(0xFFE2E8F0),
      // Make surface tint transparent for better control
      surfaceTint: Colors.transparent,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: card,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: onSurface,
          size: 24,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor:
              brightness == Brightness.dark ? Colors.white : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: colorScheme.shadow,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Filled Button Theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor:
              brightness == Brightness.dark ? Colors.white : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: colorScheme.shadow,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.antiAlias,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: card, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: GoogleFonts.poppins(
          color: onBackground.withValues(alpha: 0.5),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.poppins(
          color: colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button Theme - Convex style
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor:
            brightness == Brightness.dark ? Colors.white : Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        extendedTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: onBackground.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: card,
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: onBackground,
          height: 1.5,
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return brightness == Brightness.dark
              ? const Color(0xFF64748B)
              : const Color(0xFFCBD5E1);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return card;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return card;
        }),
        checkColor: WidgetStateProperty.all(
            brightness == Brightness.dark ? Colors.white : Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: onSurface,
        size: 24,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: colorScheme.primary,
        textColor: onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
        style: ListTileStyle.list,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.2),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.2),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.2),
      ),
    );

    // Apply Google Fonts - Plus Jakarta Sans
    final googleFontsTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.getTextTheme(_fontFamily, baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.getTextTheme(_fontFamily, baseTheme.primaryTextTheme),
    );

    // Apply modern text styles
    return googleFontsTheme.copyWith(
      textTheme: _modernTextTheme(
          googleFontsTheme.textTheme, colorScheme, onSurface, onBackground),
      primaryTextTheme: _modernTextTheme(googleFontsTheme.primaryTextTheme,
          colorScheme, onSurface, onBackground),
    );
  }

  static TextTheme _modernTextTheme(TextTheme base, ColorScheme colorScheme,
      Color onSurface, Color onBackground) {
    return base.copyWith(
      // Display - Hero text
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.1,
        color: onSurface,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
        color: onSurface,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: onSurface,
      ),

      // Headline - Section headers
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
        color: onSurface,
      ),

      // Title - Card titles, section titles
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
        color: onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface,
      ),

      // Body - Paragraphs
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.6,
        color: onBackground,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onBackground,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onBackground,
      ),

      // Label - Buttons, tabs
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.3,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }

  // Helper for gradient decoration
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // Helper for glassmorphism effect
  static BoxDecoration glassmorphismDecoration({
    double borderRadius = 20,
    required Color surfaceColor,
    required Color onSurfaceColor,
  }) {
    return BoxDecoration(
      color: surfaceColor.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: onSurfaceColor.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Helper for modern card shadow
  static List<BoxShadow> modernCardShadow({required Color primaryColor}) {
    return [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

// Helper class for theme colors
class ThemeColors {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color onBackground;
  final Color onSurface;
  final Brightness brightness;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.onBackground,
    required this.onSurface,
    required this.brightness,
  });
}

// Extension on ThemeData to provide easy access to custom theme colors
extension AppThemeData on ThemeData {
  Color get appBackground => scaffoldBackgroundColor;
  Color get appSurface => colorScheme.surface;
  Color get appCard => cardColor;
  Color get appOnBackground => colorScheme.onSurface.withValues(alpha: 0.8);
  Color get appOnSurface => colorScheme.onSurface;
  Color get appPrimary => colorScheme.primary;
  Color get appSecondary => colorScheme.secondary;
  Color get appError => const Color(0xFFF43F5E);
  Color get appSuccess => const Color(0xFF10B981);
  Color get appWarning => const Color(0xFFF59E0B);
}

// Extension on BuildContext for easier access to theme colors
extension AppThemeContext on BuildContext {
  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get appSurface => Theme.of(this).colorScheme.surface;
  Color get appCard => Theme.of(this).cardColor;
  Color get appOnBackground =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.8);
  Color get appOnSurface => Theme.of(this).colorScheme.onSurface;
  Color get appPrimary => Theme.of(this).colorScheme.primary;
  Color get appSecondary => Theme.of(this).colorScheme.secondary;
  Color get appError => const Color(0xFFF43F5E);
  Color get appSuccess => const Color(0xFF10B981);
  Color get appWarning => const Color(0xFFF59E0B);
}
