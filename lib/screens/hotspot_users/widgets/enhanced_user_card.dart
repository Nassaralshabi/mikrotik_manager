import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models.dart';
import '../../../providers/app_providers.dart';

/// User status types with color coding
enum UserStatusType {
  connected, // Green - currently online
  active, // Light green - enabled and not expired
  expired, // Red - voucher expired
  idle, // Amber - enabled but no recent activity
  disabled; // Gray - disabled user
}

/// Enhanced user card with swipe gestures, inline expand, and quick actions
class EnhancedUserCard extends ConsumerStatefulWidget {
  final HotspotUser user;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onToggleSelection;
  final Function(HotspotUser)? onSwipeLeft; // Disable
  final Function(HotspotUser)? onSwipeRight; // Extend time
  final Function(HotspotUser, String)? onQuickAction;

  const EnhancedUserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onQuickAction,
  });

  @override
  ConsumerState<EnhancedUserCard> createState() => _EnhancedUserCardState();
}

class _EnhancedUserCardState extends ConsumerState<EnhancedUserCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  UserStatusType _getUserStatusType(bool isConnected) {
    if (isConnected) return UserStatusType.connected;
    if (widget.user.isExpired) return UserStatusType.expired;
    if (widget.user.disabled) return UserStatusType.disabled;
    return UserStatusType.active;
  }

  Color _getStatusColor(UserStatusType status) {
    return switch (status) {
      UserStatusType.connected => const Color(0xFF10B981), // Green
      UserStatusType.active => const Color(0xFF22C55E), // Light green
      UserStatusType.expired => const Color(0xFFEF4444), // Red
      UserStatusType.idle => const Color(0xFFF59E0B), // Amber
      UserStatusType.disabled => const Color(0xFF64748B), // Slate gray
    };
  }

  String _getStatusText(UserStatusType status) {
    return switch (status) {
      UserStatusType.connected => 'Connected',
      UserStatusType.active => 'Active',
      UserStatusType.expired => 'Expired',
      UserStatusType.idle => 'Idle',
      UserStatusType.disabled => 'Disabled',
    };
  }

  bool _isUserConnected() {
    try {
      final activeUsersAsync = ref.read(hotspotActiveUsersProvider);
      if (activeUsersAsync.hasError) return false;
      final activeUsersValue = activeUsersAsync.value;
      if (activeUsersValue == null) return false;
      return activeUsersValue.users
          .any((activeUser) => activeUser['user'] == widget.user.name);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _isUserConnected();
    final statusType = _getUserStatusType(isConnected);
    final statusColor = _getStatusColor(statusType);

    return Dismissible(
      key: ValueKey('user_${widget.user.id}'),
      confirmDismiss: (direction) async {
        if (widget.isSelectionMode) return false;
        if (direction == DismissDirection.endToStart) {
          // Swipe right to left - Disable
          widget.onSwipeLeft?.call(widget.user);
          return false; // Don't actually dismiss
        } else if (direction == DismissDirection.startToEnd) {
          // Swipe left to right - Extend time
          widget.onSwipeRight?.call(widget.user);
          return false;
        }
        return false;
      },
      background: _buildSwipeBackground(direction: true),
      secondaryBackground: _buildSwipeBackground(direction: false),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: widget.isSelected
            ? context.appPrimary.withValues(alpha: 0.15)
            : context.appSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.isSelectionMode && widget.onToggleSelection != null
                  ? widget.onToggleSelection
                  : _toggleExpanded,
              onLongPress: widget.isSelectionMode ? null : widget.onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (widget.isSelectionMode) ...[
                      Checkbox(
                        value: widget.isSelected,
                        onChanged: (_) => widget.onToggleSelection?.call(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: context.appPrimary),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      _buildUserAvatar(statusColor, isConnected),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child:
                          _buildUserInfo(statusType, statusColor, isConnected),
                    ),
                    if (!widget.isSelectionMode) ...[
                      _buildExpandIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _buildExpandedContent(isConnected, statusType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({required bool direction}) {
    // direction=true means startToEnd (right swipe), direction=false means endToStart (left swipe)
    final isRightSwipe = direction;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRightSwipe
            ? const Color(0xFF10B981).withValues(alpha: 0.9) // Green for extend
            : const Color(0xFFF43F5E).withValues(alpha: 0.9), // Red for disable
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isRightSwipe ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(
        left: isRightSwipe ? 24 : 0,
        right: isRightSwipe ? 0 : 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isRightSwipe ? Icons.access_time_rounded : Icons.block_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            isRightSwipe ? 'Extend' : 'Disable',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(Color statusColor, bool isConnected) {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: !widget.user.disabled
                  ? [statusColor, statusColor.withValues(alpha: 0.7)]
                  : [
                      const Color(0xFF475569),
                      const Color(0xFF334155),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: isConnected
                ? Border.all(color: const Color(0xFF10B981), width: 2)
                : null,
          ),
          child: Icon(
            Icons.person_rounded,
            color: !widget.user.disabled ? Colors.white : Colors.white54,
          ),
        ),
        if (isConnected)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: context.appSurface, width: 2),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(
      UserStatusType statusType, Color statusColor, bool isConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.user.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(statusType, statusColor),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.card_membership_rounded,
              size: 14,
              color: context.appOnSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              widget.user.profile.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 12),
            Icon(
              widget.user.isVoucher
                  ? Icons.confirmation_number_rounded
                  : Icons.person_rounded,
              size: 14,
              color: context.appOnSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              widget.user.isVoucher ? 'Voucher' : 'Manual',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(UserStatusType statusType, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
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
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(statusType),
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandIndicator() {
    return AnimatedRotation(
      turns: _isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: Icon(
        Icons.expand_more_rounded,
        color: context.appOnSurface.withValues(alpha: 0.4),
        size: 24,
      ),
    );
  }

  Widget _buildExpandedContent(bool isConnected, UserStatusType statusType) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Divider(
            color: context.appOnSurface.withValues(alpha: 0.1),
            height: 1,
          ),
          const SizedBox(height: 12),
          // Usage info row
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.data_usage_rounded,
                label: 'Data',
                value: widget.user.dataUsed,
              ),
              const SizedBox(width: 8),
              if (widget.user.uptime != null && widget.user.uptime != '0s')
                _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  label: 'Up',
                  value: widget.user.simpleUptime,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(
                icon: Icons.visibility_rounded,
                label: 'Details',
                color: context.appPrimary,
                onTap: () => widget.onQuickAction?.call(widget.user, 'details'),
              ),
              _buildQuickAction(
                icon: Icons.edit_rounded,
                label: 'Edit',
                color: const Color(0xFF6366F1),
                onTap: () => widget.onQuickAction?.call(widget.user, 'edit'),
              ),
              if (!widget.user.isExpired) ...[
                _buildQuickAction(
                  icon: !widget.user.disabled
                      ? Icons.wifi_off_rounded
                      : Icons.wifi_rounded,
                  label: !widget.user.disabled ? 'Disable' : 'Enable',
                  color: !widget.user.disabled
                      ? const Color(0xFFF43F5E)
                      : const Color(0xFF10B981),
                  onTap: () => widget.onQuickAction?.call(widget.user, 'toggle'),
                ),
                _buildQuickAction(
                  icon: Icons.access_time_rounded,
                  label: 'Extend',
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onQuickAction?.call(widget.user, 'extend'),
                ),
              ],
              if (widget.user.isExpired)
                _buildQuickAction(
                  icon: Icons.delete_forever_rounded,
                  label: 'Delete',
                  color: const Color(0xFFF43F5E),
                  onTap: () => widget.onQuickAction?.call(widget.user, 'delete'),
                ),
              _buildQuickAction(
                icon: Icons.key_rounded,
                label: 'Reset PWD',
                color: const Color(0xFF06B6D4),
                onTap: () =>
                    widget.onQuickAction?.call(widget.user, 'reset_password'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.appBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 12,
              color: context.appOnSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label: ',
                style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: context.appOnSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action result for handling user actions
enum QuickActionType {
  details,
  edit,
  toggle,
  extend,
  resetPassword,
  delete,
}
