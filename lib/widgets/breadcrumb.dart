import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// A single breadcrumb item
class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

/// A breadcrumb navigation widget for detail screens
class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final bool showHome;
  final TextStyle? textStyle;

  const Breadcrumb({
    super.key,
    required this.items,
    this.showHome = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = <BreadcrumbItem>[
      if (showHome)
        const BreadcrumbItem(
          label: 'Dashboard',
          route: '/main/dashboard',
          icon: Icons.dashboard_rounded,
        ),
      ...items,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < allItems.length; i++) ...[
            _BreadcrumbChip(
              item: allItems[i],
              isLast: i == allItems.length - 1,
              onTap: allItems[i].route != null && i < allItems.length - 1
                  ? () => context.go(allItems[i].route!)
                  : null,
              textStyle: textStyle,
            ),
            if (i < allItems.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: context.appOnBackground.withValues(alpha: 0.4),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  final BreadcrumbItem item;
  final bool isLast;
  final VoidCallback? onTap;
  final TextStyle? textStyle;

  const _BreadcrumbChip({
    required this.item,
    required this.isLast,
    this.onTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final canNavigate = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLast
                ? context.appPrimary.withValues(alpha: 0.15)
                : canNavigate
                    ? context.appSurface.withValues(alpha: 0.5)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 14,
                  color: isLast
                      ? context.appPrimary
                      : context.appOnBackground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                item.label,
                style: textStyle ??
                    Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLast
                              ? context.appPrimary
                              : canNavigate
                                  ? context.appOnBackground
                                  : context.appOnBackground
                                      .withValues(alpha: 0.6),
                          fontWeight:
                              isLast ? FontWeight.w600 : FontWeight.w400,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sliver version of the breadcrumb for use in CustomScrollView
class SliverBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final bool showHome;

  const SliverBreadcrumb({
    super.key,
    required this.items,
    this.showHome = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Breadcrumb(
        items: items,
        showHome: showHome,
      ),
    );
  }
}
