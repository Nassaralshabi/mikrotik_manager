import 'dart:async';
import 'package:flutter/material.dart';

class PerformanceUtils {
  static const int defaultCacheExtent = 500;
  static const int lowEndCacheExtent = 250;

  static int getCacheExtent({bool isLowEnd = false}) {
    return isLowEnd ? lowEndCacheExtent : defaultCacheExtent;
  }
}

class OptimizedListView extends StatelessWidget {
  final int? itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool addRepaintBoundaries;
  final bool addAutomaticKeepAlives;
  final double? itemExtent;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.addRepaintBoundaries = true,
    this.addAutomaticKeepAlives = true,
    this.itemExtent,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      itemCount: itemCount,
      itemExtent: itemExtent,
      addRepaintBoundaries: addRepaintBoundaries,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      cacheExtent: PerformanceUtils.defaultCacheExtent.toDouble(),
      itemBuilder: itemBuilder,
    );
  }
}

class OptimizedGridView extends StatelessWidget {
  final int? itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const OptimizedGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: itemCount,
      cacheExtent: PerformanceUtils.defaultCacheExtent.toDouble(),
      itemBuilder: itemBuilder,
    );
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Throttler {
  final Duration delay;
  DateTime? _lastRun;

  Throttler({this.delay = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) > delay) {
      _lastRun = now;
      action();
    }
  }
}
