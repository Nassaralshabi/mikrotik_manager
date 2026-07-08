import 'package:flutter/material.dart';

class FeedbackUtils {
  /// Shows a temporary success message (Toast-like behavior) on the screen.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return; // Safety check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${message}'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a temporary error message (Toast-like behavior) on the screen.
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return; // Safety check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a general warning/info message.
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return; // Safety check
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ℹ️ $message'),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
