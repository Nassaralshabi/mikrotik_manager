import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class SyncStatusIndicator extends ConsumerStatefulWidget {
  final String label;
  final VoidCallback? onRefresh;

  const SyncStatusIndicator({
    super.key,
    this.label = 'Last synced',
    this.onRefresh,
  });

  @override
  ConsumerState<SyncStatusIndicator> createState() =>
      _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends ConsumerState<SyncStatusIndicator> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      widget.onRefresh?.call();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _formatTime(DateTime? lastSync) {
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(cacheServiceProvider);
    final lastSync = cache.getLastUpdate();

    return InkWell(
      onTap: _isRefreshing ? null : _handleRefresh,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRefreshing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.sync,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(width: 4),
            Text(
              '${widget.label}: ${_formatTime(lastSync)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManualRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const ManualRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  State<ManualRefreshIndicator> createState() => _ManualRefreshIndicatorState();
}

class _ManualRefreshIndicatorState extends State<ManualRefreshIndicator> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_isRefreshing)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Refreshing...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
