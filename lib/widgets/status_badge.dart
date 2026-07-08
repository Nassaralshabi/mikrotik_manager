import 'package:flutter/material.dart';

/// Voucher status types
enum VoucherStatus {
  active, // Voucher is valid and not expired
  expired, // Voucher has passed its expiration date
  used, // Voucher has been used (for future use)
  disabled, // Voucher is disabled
}

/// A reusable status badge widget with color-coded indicators
class StatusBadge extends StatelessWidget {
  final VoucherStatus status;
  final bool showLabel;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(context);

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              config.label,
              style: TextStyle(
                color: config.textColor,
                fontSize: fontSize ?? 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(BuildContext context) {
    switch (status) {
      case VoucherStatus.active:
        return _StatusConfig(
          label: 'Active',
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.3),
          textColor: const Color(0xFF10B981),
          dotColor: const Color(0xFF10B981),
        );
      case VoucherStatus.expired:
        return _StatusConfig(
          label: 'Expired',
          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
          textColor: const Color(0xFFEF4444),
          dotColor: const Color(0xFFEF4444),
        );
      case VoucherStatus.used:
        return _StatusConfig(
          label: 'Used',
          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
          borderColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
          textColor: const Color(0xFF6366F1),
          dotColor: const Color(0xFF6366F1),
        );
      case VoucherStatus.disabled:
        return _StatusConfig(
          label: 'Disabled',
          backgroundColor: const Color(0xFF6B7280).withValues(alpha: 0.15),
          borderColor: const Color(0xFF6B7280).withValues(alpha: 0.3),
          textColor: const Color(0xFF6B7280),
          dotColor: const Color(0xFF6B7280),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
  });
}

/// Compact status indicator (dot only)
class StatusDot extends StatelessWidget {
  final VoucherStatus status;
  final double size;

  const StatusDot({
    super.key,
    required this.status,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case VoucherStatus.active:
        return const Color(0xFF10B981);
      case VoucherStatus.expired:
        return const Color(0xFFEF4444);
      case VoucherStatus.used:
        return const Color(0xFF6366F1);
      case VoucherStatus.disabled:
        return const Color(0xFF6B7280);
    }
  }
}

/// Helper to get VoucherStatus from Voucher model
extension VoucherStatusHelper on VoucherStatus {
  static VoucherStatus fromVoucher({
    required bool isExpired,
    bool isUsed = false,
    bool isDisabled = false,
  }) {
    if (isDisabled) return VoucherStatus.disabled;
    if (isExpired) return VoucherStatus.expired;
    if (isUsed) return VoucherStatus.used;
    return VoucherStatus.active;
  }
}
