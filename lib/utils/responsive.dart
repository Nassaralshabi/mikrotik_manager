import 'package:flutter/material.dart';

class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static int gridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint) return 4;
    if (width >= tabletBreakpoint) return 3;
    if (width >= mobileBreakpoint) return 2;
    return 1;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(24),
    );
  }

  static double cardRadius(BuildContext context) {
    return value(context, mobile: 12, tablet: 16, desktop: 16);
  }

  static double iconSize(BuildContext context) {
    return value(context, mobile: 20, tablet: 24, desktop: 28);
  }

  static double titleFontSize(BuildContext context) {
    return value(context, mobile: 18, tablet: 22, desktop: 26);
  }

  static double bodyFontSize(BuildContext context) {
    return value(context, mobile: 14, tablet: 15, desktop: 16);
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
          BuildContext context, bool isMobile, bool isTablet, bool isDesktop)
      builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final isTablet = Responsive.isTablet(context);
        final isDesktop = Responsive.isDesktop(context);
        return builder(context, isMobile, isTablet, isDesktop);
      },
    );
  }
}

class SliverResponsivePadding extends StatelessWidget {
  final Widget child;

  const SliverResponsivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: Responsive.screenPadding(context),
      sliver: child,
    );
  }
}
