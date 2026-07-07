// ============================================================
//  AppTheme — تعريف الثيم الداكن للتطبيق
//  استُخرج من main.dart لتقليل حجمه وتنظيمه
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryPurple = Color(0xFF6b3fa0);
  static const Color darkBg = Color(0xFF1a1329);
  static const Color cardBg = Color(0xFF2d213f);
  static const Color lightPurple = Color(0xFFB39DDB);
  static const Color mutedText = Color(0xFFB0A8C1);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryPurple,
        scaffoldBackgroundColor: darkBg,
        fontFamily: 'Tajawal',
        cardColor: cardBg,
        colorScheme: const ColorScheme.dark(
          primary: primaryPurple,
          secondary: lightPurple,
          surface: cardBg,
          error: Colors.redAccent,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onError: Colors.white,
        ),
        textTheme: _textTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        appBarTheme: _appBarTheme,
        iconTheme: _iconTheme,
        dividerTheme: _dividerTheme,
        snackBarTheme: _snackBarTheme,
        dialogTheme: _dialogTheme,
      );

  static const TextTheme _textTheme = TextTheme(
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
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryPurple,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
      elevation: 2,
      shadowColor: const Color(0x4D000000),
    ),
  );

  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: lightPurple,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    labelStyle: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
    hintStyle: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.5),
    iconColor: Colors.white,
    prefixIconColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  static final CardThemeData _cardTheme = CardThemeData(
    color: cardBg,
    elevation: 2,
    shadowColor: const Color(0x33000000),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.all(8),
  );

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: cardBg,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', height: 1.5),
    iconTheme: IconThemeData(color: Colors.white),
  );

  static const IconThemeData _iconTheme = IconThemeData(color: mutedText, size: 24);

  static const DividerThemeData _dividerTheme = DividerThemeData(color: Color(0x1AFFFFFF), thickness: 1, space: 16);

  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: cardBg,
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Tajawal', height: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
    elevation: 4,
  );

  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: cardBg,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 8,
    titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', height: 1.5),
    contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Tajawal', height: 1.6),
  );
}
