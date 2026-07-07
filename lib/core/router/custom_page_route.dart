// ============================================================
//  CustomPageRoute — صفحة انتقال مخصصة مع animation
//  محسّنة للأجهزة الضعيفة (DeviceCapability)
// ============================================================

import 'package:flutter/material.dart';
import '../../perf/device_capability.dart';

class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration {
    return DeviceCapability.instance.animationDuration;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (DeviceCapability.instance.isLowEnd) {
      return FadeTransition(opacity: animation, child: child);
    }
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}
