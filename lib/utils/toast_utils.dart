import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class ToastUtils {
  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool dismissible = true,
    VoidCallback? onDismiss,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    final color = switch (type) {
      ToastType.success => Colors.green,
      ToastType.error => context.appError,
      ToastType.warning => Colors.orange,
      ToastType.info => context.appPrimary,
    };

    final icon = switch (type) {
      ToastType.success => Icons.check_circle_rounded,
      ToastType.error => Icons.error_rounded,
      ToastType.warning => Icons.warning_rounded,
      ToastType.info => Icons.info_rounded,
    };

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (dismissible)
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onDismiss?.call();
                },
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  static void success(BuildContext context, String message,
      {bool dismissible = true}) {
    show(
        context: context,
        message: message,
        type: ToastType.success,
        dismissible: dismissible);
  }

  static void error(BuildContext context, String message,
      {bool dismissible = true}) {
    show(
        context: context,
        message: message,
        type: ToastType.error,
        dismissible: dismissible);
  }

  static void warning(BuildContext context, String message,
      {bool dismissible = true}) {
    show(
        context: context,
        message: message,
        type: ToastType.warning,
        dismissible: dismissible);
  }

  static void info(BuildContext context, String message,
      {bool dismissible = true}) {
    show(
        context: context,
        message: message,
        type: ToastType.info,
        dismissible: dismissible);
  }
}
