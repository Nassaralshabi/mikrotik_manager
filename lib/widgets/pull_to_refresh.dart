import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PullToRefreshWrapper extends ConsumerWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool enabled;

  const PullToRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

class PullToRefreshScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final Future<void> Function() onRefresh;
  final bool enablePullToRefresh;

  const PullToRefreshScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    required this.onRefresh,
    this.enablePullToRefresh = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: enablePullToRefresh
          ? RefreshIndicator(
              onRefresh: onRefresh,
              child: body,
            )
          : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );

    return content;
  }
}
