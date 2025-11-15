import 'package:flutter/material.dart';

/// Material Kit Flutter color palette
/// Based on: https://github.com/creativetimofficial/material-kit-flutter
abstract class AppPalette {
  // Primary Colors
  static const primary = Color(0xFF9C26B0); // Purple
  static const primaryLight = Color(0xFFBB86FC);
  static const primaryDark = Color(0xFF6B3FA0);
  
  // Secondary Colors
  static const secondary = Color(0xFF00BCD4); // Info
  static const secondaryLight = Color(0xFF03DAC6);
  static const secondaryDark = Color(0xFF018786);
  
  // Accent Colors
  static const accent = Color(0xFFFE2472); // Label/Pink
  
  // Status Colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF00BCD4);
  
  // Neutral Colors
  static const defaultColor = Color(0xFFDCDCDC);
  static const muted = Color(0xFF9CA3AF);
  static const input = Color(0xFFE8ECF7);
  static const active = Color(0xFF9C26B0);
  static const placeholder = Color(0xFF9FA5AA);
  static const switchOff = Color(0xFFD4D9DD);
  static const border = Color(0xFFD5DBF0);
  static const caption = Color(0xFF4A4A4A);
  
  // Background Colors
  static const bgColorScreen = Color(0xFFF4F6FB);
  static const cardSurface = Color(0xFFFAFBFF);
  static const priceColor = Color(0xFFEAD5FB);
  
  // Gradient Colors
  static const gradientStart = Color(0xFF6B24AA);
  static const gradientEnd = Color(0xFFAC2688);

  static const gradientSoftStart = Color(0xFFEAF2FF);
  static const gradientSoftMiddle = Color(0xFFEFF7FF);
  static const gradientSoftEnd = Color(0xFFFBF6FF);
  
  // Sign/Auth Gradient
  static const signStartGradient = Color(0xFF6C24AA);
  static const signEndGradient = Color(0xFF15002B);
  
  // Drawer
  static const drawerHeader = Color(0xFF4B1958);
  
  // Social Colors
  static const socialFacebook = Color(0xFF3B5998);
  static const socialTwitter = Color(0xFF5BC0DE);
  static const socialDribbble = Color(0xFFEA4C89);
  
  // Dark Theme Colors
  static const darkBackground = Color(0xFF1A1329);
  static const darkSurface = Color(0xFF2D213F);
  static const darkCard = Color(0xFF2D213F);
  
  // Text Colors
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF4B5563);
  static const textWhite = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFBDBDBD);
}
