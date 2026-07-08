import 'package:flutter/material.dart';

class AccessibilityUtils {
  static double get minTouchTarget => 48.0;

  static bool isReduceMotionEnabled(BuildContext context) {
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.iOS:
        return MediaQuery.of(context).accessibleNavigation;
      case TargetPlatform.android:
        return MediaQuery.of(context).disableAnimations;
      default:
        return false;
    }
  }

  static double get textScaleFactor =>
      WidgetsBinding.instance.platformDispatcher.textScaleFactor;

  static bool shouldReduceMotion(BuildContext context) {
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.iOS:
        return MediaQuery.of(context).accessibleNavigation;
      case TargetPlatform.android:
        return MediaQuery.of(context).disableAnimations;
      default:
        return false;
    }
  }

  static String? getSemanticLabel(String? label) => label;

  static Widget withSemantic(
    BuildContext context, {
    required Widget child,
    String? label,
    String? hint,
    bool? checked,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      checked: checked,
      button: true,
      child: child,
    );
  }
}

class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? color;
  final double size;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox(
        width: AccessibilityUtils.minTouchTarget,
        height: AccessibilityUtils.minTouchTarget,
        child: IconButton(
          icon: Icon(icon, size: size),
          onPressed: onPressed,
          color: color,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }
}

class AccessibleListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AccessibleListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints:
              BoxConstraints(minHeight: AccessibilityUtils.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(child: leading),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
