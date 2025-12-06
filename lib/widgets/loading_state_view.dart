import 'package:flutter/material.dart';

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message = 'جاري التحميل...', this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          if (icon != null) ...[
            const SizedBox(height: 8),
            Icon(icon, color: Theme.of(context).colorScheme.primary),
          ],
        ],
      ),
    );
  }
}
