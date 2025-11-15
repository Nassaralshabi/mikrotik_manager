import 'package:flutter/material.dart';
import 'app_palette.dart';

abstract class AppGradients {
  // Light Theme Gradients
  static const LinearGradient softBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppPalette.gradientSoftStart,
      AppPalette.gradientSoftMiddle,
      AppPalette.gradientSoftEnd,
    ],
  );

  static final LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white.withOpacity(0.45),
      Colors.white.withOpacity(0.2),
    ],
  );

  // Dark Theme Gradients - خلفيات متدرجة للثيم الغامق
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0514),  // بنفسجي داكن جداً
      Color(0xFF1A1329),  // بنفسجي داكن
      Color(0xFF2D213F),  // بنفسجي أفتح قليلاً
    ],
  );

  static final LinearGradient lightCardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white.withOpacity(0.95),  // شبه شفاف عالي
      Colors.white.withOpacity(0.85),  // شبه شفاف متوسط
    ],
  );

  // Additional Dark Theme Gradients
  static final LinearGradient darkCardElevation = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.98),
      Colors.white.withOpacity(0.92),
      Colors.white.withOpacity(0.88),
    ],
  );

  // Soft Dark Gradient for Overlays
  static final LinearGradient softDarkOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppPalette.darkBackground.withOpacity(0.8),
      AppPalette.darkSurface.withOpacity(0.9),
    ],
  );
}
