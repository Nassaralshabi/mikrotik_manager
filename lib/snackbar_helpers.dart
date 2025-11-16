import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  final theme = context.theme;
  final appColors = theme.appColors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: appColors.onError, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: appColors.onError,
                    height: 1.5,
                    fontSize: 14,
                  ) ??
                  TextStyle(
                    color: appColors.onError,
                    height: 1.5,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
      backgroundColor: appColors.error,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'إغلاق',
        textColor: appColors.onError,
        onPressed: () {},
      ),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  final theme = context.theme;
  final appColors = theme.appColors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle_outline, color: appColors.onSuccess, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: appColors.onSuccess,
                    height: 1.5,
                    fontSize: 14,
                  ) ??
                  TextStyle(
                    color: appColors.onSuccess,
                    height: 1.5,
                    fontSize: 14,
                  ),
            ),
          ),
        ],
      ),
      backgroundColor: appColors.success,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}
