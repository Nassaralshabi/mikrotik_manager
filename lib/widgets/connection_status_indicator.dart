import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class ConnectionStatusIndicator extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectionStatusIndicator({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState
    extends ConsumerState<ConnectionStatusIndicator> {
  bool _wasConnected = true;

  @override
  Widget build(BuildContext context) {
    final routerService = ref.watch(routerOSServiceProvider);
    final isConnected = routerService.isConnected;

    // Show snackbar on connection state change
    if (_wasConnected != isConnected) {
      _wasConnected = isConnected;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConnectionSnackbar(context, isConnected);
      });
    }

    return Stack(
      children: [
        widget.child,
        // Status indicator in corner
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 8,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withValues(alpha: 0.9)
                  : Colors.red.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showConnectionSnackbar(BuildContext context, bool isConnected) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Connected to router' : 'Lost connection to router',
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isConnected ? 2 : 4),
        action: isConnected
            ? null
            : SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  ref.read(routerOSServiceProvider).reconnect();
                },
              ),
      ),
    );
  }
}

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerService = ref.watch(routerOSServiceProvider);
    final isConnected = routerService.isConnected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isConnected ? 0 : 28,
      color: Colors.red,
      child: isConnected
          ? const SizedBox.shrink()
          : InkWell(
              onTap: () {
                ref.read(routerOSServiceProvider).reconnect();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Disconnected - Tap to retry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
