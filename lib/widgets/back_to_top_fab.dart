import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A floating action button that appears when scrolling down and scrolls back to top
class BackToTopFAB extends StatefulWidget {
  final ScrollController scrollController;
  final double showThreshold;
  final Duration animationDuration;

  const BackToTopFAB({
    super.key,
    required this.scrollController,
    this.showThreshold = 200,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<BackToTopFAB> createState() => _BackToTopFABState();
}

class _BackToTopFABState extends State<BackToTopFAB>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    widget.scrollController.addListener(_onScroll);
    _checkVisibility();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkVisibility();
  }

  void _checkVisibility() {
    if (!widget.scrollController.hasClients) return;
    final shouldShow = widget.scrollController.offset > widget.showThreshold;
    if (shouldShow != _isVisible) {
      setState(() {
        _isVisible = shouldShow;
      });
      if (_isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _fadeAnimation,
        child: FloatingActionButton.small(
          onPressed: _scrollToTop,
          backgroundColor: context.appSurface,
          foregroundColor: context.appPrimary,
          elevation: 4,
          heroTag: 'back_to_top',
          child: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
      ),
    );
  }
}

/// A widget that wraps a scrollable and shows a back-to-top FAB
class ScrollableWithBackToTop extends StatelessWidget {
  final ScrollController? controller;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Axis scrollDirection;
  final bool showFAB;

  const ScrollableWithBackToTop({
    super.key,
    this.controller,
    required this.child,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.showFAB = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showFAB && controller != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: BackToTopFAB(scrollController: controller!),
          ),
      ],
    );
  }
}
