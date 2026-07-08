import 'package:flutter/services.dart';

enum HapticType {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  error,
}

class HapticUtils {
  static void trigger(HapticType type) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.success:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.warning:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  static void light() => trigger(HapticType.light);
  static void medium() => trigger(HapticType.medium);
  static void heavy() => trigger(HapticType.heavy);
  static void selection() => trigger(HapticType.selection);
  static void success() => trigger(HapticType.success);
  static void warning() => trigger(HapticType.warning);
  static void error() => trigger(HapticType.error);
}
