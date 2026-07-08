import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// An improved bulk selection mode indicator with clear exit button
class BulkModeIndicator extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onExit;
  final VoidCallback onSelectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onDisable;
  final VoidCallback? onEnable;
  final VoidCallback? onMoveProfile;

  const BulkModeIndicator({
    super.key,
    required this.selectedCount,
    required this.onExit,
    required this.onSelectAll,
    this.onDelete,
    this.onDisable,
    this.onEnable,
    this.onMoveProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with count and exit button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: context.appPrimary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Selection count with icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.appPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$selectedCount user${selectedCount > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Select All button
                  TextButton.icon(
                    onPressed: onSelectAll,
                    icon: Icon(
                      Icons.select_all_rounded,
                      size: 18,
                      color: context.appPrimary,
                    ),
                    label: Text(
                      'All',
                      style: TextStyle(color: context.appPrimary),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  // Clear/Deselect All button
                  if (selectedCount > 0)
                    TextButton.icon(
                      onPressed: onExit,
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: context.appError,
                      ),
                      label: Text(
                        'Clear',
                        style: TextStyle(color: context.appError),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onDelete != null)
                    _buildActionButton(
                      context,
                      icon: Icons.delete_rounded,
                      label: 'Delete',
                      color: const Color(0xFFF43F5E),
                      onTap: onDelete!,
                    ),
                  if (onDisable != null)
                    _buildActionButton(
                      context,
                      icon: Icons.block_rounded,
                      label: 'Disable',
                      color: const Color(0xFFF59E0B),
                      onTap: onDisable!,
                    ),
                  if (onEnable != null)
                    _buildActionButton(
                      context,
                      icon: Icons.check_circle_rounded,
                      label: 'Enable',
                      color: const Color(0xFF10B981),
                      onTap: onEnable!,
                    ),
                  if (onMoveProfile != null)
                    _buildActionButton(
                      context,
                      icon: Icons.swap_horiz_rounded,
                      label: 'Profile',
                      color: context.appPrimary,
                      onTap: onMoveProfile!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A floating selection counter that shows when scrolling in bulk mode
class FloatingSelectionCounter extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onTap;

  const FloatingSelectionCounter({
    super.key,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.appPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.appPrimary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$selectedCount selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
