import 'package:flutter/material.dart';

abstract class AppGradients {
  static LinearGradient softBackground(ColorScheme scheme) {
    if (scheme.brightness == Brightness.dark) {
      return darkBackground(scheme);
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primaryContainer.withOpacity(0.9),
        scheme.surface,
        scheme.secondaryContainer.withOpacity(0.8),
      ],
    );
  }

  static LinearGradient darkBackground(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.surface.withOpacity(0.95),
        scheme.surfaceVariant.withOpacity(0.88),
        scheme.primary.withOpacity(0.45),
      ],
    );
  }

  static LinearGradient cardOverlay(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.surface.withOpacity(0.6),
        scheme.surface.withOpacity(0.2),
      ],
    );
  }

  static LinearGradient lightCardOverlay(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.surface.withOpacity(0.96),
        scheme.surface.withOpacity(0.86),
      ],
    );
  }

  static LinearGradient darkCardElevation(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.surface.withOpacity(0.94),
        scheme.surfaceVariant.withOpacity(0.9),
        scheme.surface.withOpacity(0.84),
      ],
    );
  }

  static LinearGradient softDarkOverlay(ColorScheme scheme) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.primary.withOpacity(0.22),
        scheme.surface.withOpacity(0.78),
      ],
    );
  }
}
