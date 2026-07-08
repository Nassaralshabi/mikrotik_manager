import 'package:flutter/material.dart';

/// إعدادات الثيم الموحدة للتطبيق
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF6b3fa0);
  static const Color secondaryColor = Color(0xFFB39DDB);
  static const Color scaffoldBg = Color(0xFF1a1329);
  static const Color cardBg = Color(0xFF2d213f);
  static const Color subtitleGrey = Color(0xFF5A5278);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBg,
    fontFamily: 'Tajawal',
    cardColor: cardBg,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardBg,
      background: scaffoldBg,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.4),
      displayMedium: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
      displaySmall: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
      headlineLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
      headlineMedium: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
      headlineSmall: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
      titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.5),
      titleMedium: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
      titleSmall: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
      bodySmall: TextStyle(color: Colors.white, fontSize: 12, height: 1.6),
      labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: secondaryColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
      iconColor: Colors.white,
      prefixIconColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      color: cardBg,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cardBg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', height: 1.5,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Color(0xFFB0A8C1), size: 24),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.1), thickness: 1, space: 16),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardBg,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Tajawal', height: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', height: 1.5),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Tajawal', height: 1.6),
    ),
  );
}
