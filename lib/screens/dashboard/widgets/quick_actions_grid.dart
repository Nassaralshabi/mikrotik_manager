import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../navigation/app_router.dart';

/// A quick action item
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// A horizontal scrolling grid of quick action buttons
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = _getActions(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildActionButton(context, actions[index]);
            },
          ),
        ),
      ],
    );
  }

  List<QuickActionItem> _getActions(BuildContext context) {
    return [
      QuickActionItem(
        icon: Icons.add_card_rounded,
        label: 'Create Vouchers',
        color: const Color(0xFF8B5CF6), // Purple
        onTap: () => context.push('/main/vouchers/generate'),
      ),
      QuickActionItem(
        icon: Icons.person_add_rounded,
        label: 'Add User',
        color: const Color(0xFF6366F1), // Indigo
        onTap: () => context.push('/main/users/add'),
      ),
      QuickActionItem(
        icon: Icons.confirmation_number_rounded,
        label: 'Vouchers',
        color: const Color(0xFF8B5CF6), // Purple
        onTap: () => context.push('/main/vouchers'),
      ),
      QuickActionItem(
        icon: Icons.people_rounded,
        label: 'Users',
        color: const Color(0xFF06B6D4), // Cyan
        onTap: () => context.go('/main/users'),
      ),
      QuickActionItem(
        icon: Icons.card_membership_rounded,
        label: 'Profiles',
        color: const Color(0xFF10B981), // Emerald
        onTap: () => context.go('/main/profiles'),
      ),
      QuickActionItem(
        icon: Icons.lan_rounded,
        label: 'Hosts',
        color: const Color(0xFFF59E0B), // Amber
        onTap: () => context.go('/main/hosts'),
      ),
      QuickActionItem(
        icon: Icons.devices_rounded,
        label: 'DHCP',
        color: const Color(0xFFEF4444), // Red
        onTap: () => context.go('/main/dhcp-leases'),
      ),
      QuickActionItem(
        icon: Icons.payments_rounded,
        label: 'Revenue',
        color: const Color(0xFFEC4899), // Pink
        onTap: () => context.push('/main/revenue'),
      ),
      QuickActionItem(
        icon: Icons.history_rounded,
        label: 'Logs',
        color: const Color(0xFFF59E0B), // Amber
        onTap: () => context.push('/main/logs'),
      ),
      QuickActionItem(
        icon: Icons.folder_rounded,
        label: 'Files',
        color: const Color(0xFF3B82F6), // Blue
        onTap: () => context.go('/main/files'),
      ),
      QuickActionItem(
        icon: Icons.description_outlined,
        label: 'PDF Templates',
        color: const Color(0xFF8B5CF6), // Violet
        onTap: () => context.push(AppRouter.pdfTemplatesEditorRoute),
      ),
      QuickActionItem(
        icon: Icons.document_scanner_outlined,
        label: 'OCR',
        color: const Color(0xFF10B981), // Emerald
        onTap: () => context.push(AppRouter.processImageRoute),
      ),
      QuickActionItem(
        icon: Icons.backup_outlined,
        label: 'Backup',
        color: const Color(0xFF06B6D4), // Cyan
        onTap: () => context.push(AppRouter.backupSystemRoute),
      ),
    ];
  }

  Widget _buildActionButton(BuildContext context, QuickActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
