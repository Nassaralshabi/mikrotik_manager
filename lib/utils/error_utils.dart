import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ErrorUtils {
  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection reset')) {
      return "Can't reach router. Check your network connection.";
    }

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. The router might be busy.';
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('authentication')) {
      return 'Login failed. Check your username and password.';
    }

    if (errorString.contains('permission denied') ||
        errorString.contains('access denied') ||
        errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return "Permission denied. Your account doesn't have access to this.";
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Resource not found. It may have been deleted.';
    }

    if (errorString.contains('no route to host')) {
      return "Can't find router. Check the IP address.";
    }

    if (errorString.contains('no internet') ||
        errorString.contains('internet')) {
      return 'No internet connection. Check your network.';
    }

    if (errorString.contains('ssl') || errorString.contains('certificate')) {
      return 'Security error. Check router SSL settings.';
    }

    if (errorString.contains('parse') || errorString.contains('format')) {
      return 'Data error. The router response was invalid.';
    }

    if (errorString.contains('not connected to routeros')) {
      return 'Not connected. Please login first.';
    }

    // Default to generic message but include original for debugging
    return 'Something went wrong. Pull down to retry.';
  }

  static IconData getErrorIcon(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('timeout') ||
        errorString.contains('no route')) {
      return Icons.wifi_off_rounded;
    }

    if (errorString.contains('unauthorized') ||
        errorString.contains('authentication') ||
        errorString.contains('permission')) {
      return Icons.lock_outline_rounded;
    }

    if (errorString.contains('not found')) {
      return Icons.search_off_rounded;
    }

    return Icons.error_outline_rounded;
  }

  static Color getErrorColor(BuildContext context, dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return Colors.orange;
    }

    return context.appError;
  }
}

class ErrorStateWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? ErrorUtils.getFriendlyMessage(error);
    final icon = ErrorUtils.getErrorIcon(error);
    final color = ErrorUtils.getErrorColor(context, error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.appOnBackground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appOnBackground.withValues(alpha: 0.7),
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
