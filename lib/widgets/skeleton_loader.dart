import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A shimmer animation widget for skeleton loading
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? context.appCard,
                widget.highlightColor ?? context.appCard.withValues(alpha: 0.5),
                widget.baseColor ?? context.appCard,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Reusable skeleton base widget
class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? context.appCard,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Pre-configured skeleton widgets for common UI patterns
class SkeletonLoaders {
  static Widget card({double height = 100}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Skeleton(
        height: height,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static Widget voucherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Skeleton(
              width: 150,
              height: 150,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Skeleton(width: 100, height: 16),
          const SizedBox(height: 8),
          Skeleton(width: 60, height: 12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton(width: 80, height: 12),
              Skeleton(width: 50, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  static Widget userListItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Skeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 120, height: 16),
                const SizedBox(height: 6),
                Skeleton(width: 80, height: 12),
              ],
            ),
          ),
          Skeleton(
              width: 50, height: 24, borderRadius: BorderRadius.circular(12)),
        ],
      ),
    );
  }

  static Widget summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(
              width: 24, height: 24, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 12),
          Skeleton(width: 60, height: 12),
          const SizedBox(height: 6),
          Skeleton(width: 100, height: 20),
        ],
      ),
    );
  }

  static Widget chart({double height = 200}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 120, height: 16),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 6 ? 8 : 0),
                      child: Skeleton(
                        width: 30,
                        height: 40 + (i % 3) * 30.0,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget transactionItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Skeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 100, height: 14),
                const SizedBox(height: 6),
                Skeleton(width: 60, height: 12),
              ],
            ),
          ),
          Skeleton(width: 80, height: 16),
        ],
      ),
    );
  }

  static Widget list({
    int itemCount = 5,
    Widget Function()? itemBuilder,
  }) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return itemBuilder?.call() ?? card();
      },
    );
  }

  static Widget grid({
    int crossAxisCount = 2,
    int itemCount = 4,
    double spacing = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => voucherCard(),
      ),
    );
  }

  static Widget text({
    int lines = 3,
    double spacing = 8,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        final isLast = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : spacing),
          child: Skeleton(
            width: isLast ? 150 : double.infinity,
            height: 14,
          ),
        );
      }),
    );
  }

  static Widget profile() {
    return Row(
      children: [
        Skeleton(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(30),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton(width: 120, height: 18),
            const SizedBox(height: 8),
            Skeleton(width: 80, height: 14),
          ],
        ),
      ],
    );
  }

  static Widget tableRow({bool showHeader = false}) {
    return Row(
      children: [
        Expanded(flex: 3, child: Skeleton(height: showHeader ? 14 : 16)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Skeleton(height: showHeader ? 14 : 16)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Skeleton(height: showHeader ? 14 : 16)),
      ],
    );
  }

  static Widget fileItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Skeleton(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 14),
                const SizedBox(height: 6),
                Skeleton(width: 80, height: 12),
              ],
            ),
          ),
          Skeleton(width: 24, height: 24, borderRadius: BorderRadius.circular(6)),
        ],
      ),
    );
  }
}