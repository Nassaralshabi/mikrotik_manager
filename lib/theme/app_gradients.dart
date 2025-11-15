import 'package:flutter/material.dart';
import 'app_palette.dart';

abstract class AppGradients {
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
}
