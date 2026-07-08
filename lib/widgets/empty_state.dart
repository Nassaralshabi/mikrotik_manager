import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A reusable empty state widget with icon, title, description, and optional action button
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double? iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? context.appPrimary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize ?? 40,
                  color:
                      (iconColor ?? context.appPrimary).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(_getActionIcon()),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon() {
    // Return appropriate icon based on common actions
    if (actionLabel?.toLowerCase().contains('create') == true) {
      return Icons.add_rounded;
    } else if (actionLabel?.toLowerCase().contains('connect') == true) {
      return Icons.link_rounded;
    } else if (actionLabel?.toLowerCase().contains('refresh') == true) {
      return Icons.refresh_rounded;
    } else if (actionLabel?.toLowerCase().contains('generate') == true) {
      return Icons.add_card_rounded;
    } else if (actionLabel?.toLowerCase().contains('sell') == true) {
      return Icons.payments_rounded;
    }
    return Icons.arrow_forward_rounded;
  }
}

/// Pre-configured empty states for common scenarios
class EmptyStates {
  // Vouchers
  static Widget noVouchers(VoidCallback onCreate) {
    return EmptyState(
      icon: Icons.confirmation_number_outlined,
      title: 'No vouchers yet',
      description:
          'Create WiFi vouchers for your customers. You can generate single or bulk vouchers with QR codes.',
      actionLabel: 'Generate Vouchers',
      onAction: onCreate,
    );
  }

  static Widget noSearchResults(String query) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results found',
      description: 'No vouchers match "$query". Try a different search term.',
      iconColor: Colors.orange,
    );
  }

  // Hotspot Users
  static Widget noUsers(VoidCallback onAdd) {
    return EmptyState(
      icon: Icons.people_outline_rounded,
      title: 'No hotspot users',
      description:
          'Add users to your hotspot or generate vouchers. Users will appear here once they connect.',
      actionLabel: 'Add User',
      onAction: onAdd,
    );
  }

  static Widget noActiveUsers() {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: 'No active users',
      description:
          'There are no users currently connected to the hotspot. Active users will appear here in real-time.',
    );
  }

  // Revenue/Transactions
  static Widget noTransactions() {
    return EmptyState(
      icon: Icons.receipt_long_rounded,
      title: 'No transactions yet',
      description:
          'Transaction history will appear here when you sell vouchers. Start by generating and selling vouchers.',
    );
  }

  static Widget noRevenueData() {
    return EmptyState(
      icon: Icons.attach_money_rounded,
      title: 'No revenue data',
      description:
          'Revenue data will appear here once you start selling vouchers. Charts and summaries will be generated automatically.',
    );
  }

  // Activity Logs
  static Widget noLogs() {
    return EmptyState(
      icon: Icons.history_rounded,
      title: 'No activity logs',
      description:
          'Activity logs will appear here as you use the app. Track logins, voucher creation, and other events.',
      iconColor: const Color(0xFF6366F1),
    );
  }

  // Settings
  static Widget noSavedRouters(VoidCallback onAdd) {
    return EmptyState(
      icon: Icons.router_rounded,
      title: 'No saved routers',
      description:
          'Save your router connections for quick access. Your connections will be stored securely.',
      actionLabel: 'Add Router',
      onAction: onAdd,
    );
  }

  // Generic states
  static Widget connectionError(VoidCallback onRetry) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Connection failed',
      description:
          'Unable to connect to RouterOS. Please check your network connection and router settings.',
      actionLabel: 'Retry',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }

  static Widget error(String message, VoidCallback onRetry) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      description: message,
      actionLabel: 'Try Again',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }

  static Widget loading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
