import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: context.appError,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> showDelete({
    required BuildContext context,
    required String itemName,
    String itemType = 'item',
  }) async {
    return show(
      context: context,
      title: 'Delete $itemType',
      message:
          'Are you sure you want to delete "$itemName"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
  }

  static Future<bool> showArchive({
    required BuildContext context,
    required String itemName,
    String itemType = 'item',
  }) async {
    return show(
      context: context,
      title: 'Archive $itemType',
      message: 'Are you sure you want to archive "$itemName"?',
      confirmText: 'Archive',
      cancelText: 'Cancel',
      isDestructive: true,
    );
  }

  static Future<bool> showBulkDelete({
    required BuildContext context,
    required int itemCount,
    String itemType = 'items',
  }) async {
    return show(
      context: context,
      title: 'Delete Multiple $itemType',
      message:
          'Are you sure you want to delete $itemCount $itemType? This action cannot be undone.',
      confirmText: 'Delete All',
      cancelText: 'Cancel',
      isDestructive: true,
    );
  }

  static Future<bool> showDiscardChanges({
    required BuildContext context,
  }) async {
    return show(
      context: context,
      title: 'Discard Changes',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      isDestructive: true,
    );
  }
}
