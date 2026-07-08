import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../services/log_service.dart';
import '../../utils/performance_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/back_to_top_fab.dart';
import 'hotspot_user_details_screen.dart';
import 'add_hotspot_user_screen.dart';
import 'edit_hotspot_user_screen.dart';
import 'voucher_generation_screen.dart';
import 'widgets/enhanced_user_card.dart';
import 'widgets/bulk_mode_indicator.dart';
import '../../utils/show_feedback.dart';
import '../../l10n/translations.dart';

class HotspotUsersScreen extends ConsumerStatefulWidget {
  const HotspotUsersScreen({super.key});

  @override
  ConsumerState<HotspotUsersScreen> createState() => _HotspotUsersScreenState();
}

class _HotspotUsersScreenState extends ConsumerState<HotspotUsersScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  UserStatusFilter _statusFilter = UserStatusFilter.all;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isSelectionActive = false;
  final Set<String> _selectedUserIds = {};
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 300));

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if this is the first time - rely on auto-refresh after
    // No manual refresh needed - data will come from cache or auto-refresh
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore) return;

    final paginatedUsers = ref.read(hotspotUsersProvider).value;
    if (paginatedUsers == null || !paginatedUsers.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(hotspotUsersProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final usersAsync = ref.watch(hotspotUsersProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _SearchAndFilterBar(
              searchQuery: _searchQuery,
              statusFilter: _statusFilter,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _searchDebouncer.run(() {});
              },
              onClearSearch: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              onFilterChanged: (filter) {
                setState(() {
                  _statusFilter = filter;
                });
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(hotspotUsersProvider.notifier).refresh();
                  // Wait for refresh to complete before returning
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                color: context.appPrimary,
                child: usersAsync.when(
                  data: (paginatedUsers) {
                    // Convert Map data to HotspotUser objects
                    final users = paginatedUsers.users
                        .map((data) => HotspotUser.fromJson(data,
                            activeUsernames: paginatedUsers.activeUsernames))
                        .toList();
                    final filteredUsers = _filterUsers(users);

                    if (filteredUsers.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length +
                          (paginatedUsers.hasMore ? 1 : 0),
                      // Remove fixed itemExtent for expandable cards
                      addRepaintBoundaries: true,
                      cacheExtent: 500,
                      itemBuilder: (context, index) {
                        if (index == filteredUsers.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final user = filteredUsers[index];
                        return RepaintBoundary(
                          key: ValueKey(user.id),
                          child: EnhancedUserCard(
                            user: user,
                            onTap: () => _navigateToUserDetails(user),
                            onLongPress: () =>
                                _toggleSelectionModeAndSelect(user.id),
                            isSelectionMode: _isSelectionActive,
                            isSelected: _selectedUserIds.contains(user.id),
                            onToggleSelection: () =>
                                _toggleUserSelection(user.id),
                            onSwipeLeft: _handleSwipeLeft,
                            onSwipeRight: _handleSwipeRight,
                            onQuickAction: _handleQuickAction,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => SizedBox(
                    height: 400,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) =>
                          SkeletonLoaders.userListItem(),
                    ),
                  ),
                  error: (error, stack) => _buildErrorState(error.toString()),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _isSelectionActive
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BackToTopFAB(scrollController: _scrollController),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'generate_vouchers',
                    onPressed: () => _navigateToGenerateVouchers(),
                    backgroundColor: context.appSecondary,
                    foregroundColor: context.appOnBackground,
                    child: const Icon(Icons.confirmation_number_rounded),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'add_user',
                    onPressed: () => _navigateToAddUser(),
                    backgroundColor: context.appPrimary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.person_add_rounded),
                  ),
                ],
              ),
        bottomNavigationBar: _isSelectionActive
            ? BulkModeIndicator(
                selectedCount: _selectedUserIds.length,
                onExit: _exitSelectionMode,
                onSelectAll: _selectAllVisible,
                onDelete: () => _confirmBulkDelete(context),
                onDisable: _bulkDisableUsers,
                onEnable: _bulkEnableUsers,
                onMoveProfile: () => _showMoveProfileDialog(context),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.appSurface,
      foregroundColor: context.appOnSurface,
      elevation: 0,
      leading: _isSelectionActive
          ? IconButton(
              icon: Icon(Icons.close_rounded),
              onPressed: _exitSelectionMode,
              tooltip: 'Exit selection',
            )
          : IconButton(
              icon: Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/main'),
              tooltip: 'Back',
            ),
      title: _isSelectionActive
          ? Text(AppStrings.of(context)
              .selectedCount
              .replaceAll('%d', '${_selectedUserIds.length}'))
          : Text(
              AppStrings.of(context).hotspotUsers,
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
      actions: [
        if (!_isSelectionActive) ...[
          IconButton(
            icon: Icon(Icons.checklist_rounded),
            onPressed: _toggleSelectionMode,
            tooltip: 'Select multiple',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(hotspotUsersProvider.notifier).refresh();
            },
          ),
        ] else ...[
          IconButton(
            icon: Icon(Icons.select_all_rounded),
            onPressed: _selectAllVisible,
            tooltip: 'Select all',
          ),
        ],
      ],
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionActive = true;
      _selectedUserIds.clear();
    });
  }

  void _toggleSelectionModeAndSelect(String userId) {
    setState(() {
      if (!_isSelectionActive) {
        _isSelectionActive = true;
        _selectedUserIds.clear();
      }
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        if (_selectedUserIds.isEmpty) {
          _isSelectionActive = false;
        }
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionActive = false;
      _selectedUserIds.clear();
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        if (_selectedUserIds.isEmpty) {
          _isSelectionActive = false;
        }
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _selectAllVisible() {
    final usersAsync = ref.read(hotspotUsersProvider).value;
    if (usersAsync == null) return;

    final users = usersAsync.users
        .map((data) => HotspotUser.fromJson(data,
            activeUsernames: usersAsync.activeUsernames))
        .toList();
    final filteredUsers = _filterUsers(users);

    setState(() {
      _selectedUserIds.clear();
      _selectedUserIds.addAll(filteredUsers.map((u) => u.id));
    });
  }

  // Swipe action handlers
  Future<void> _handleSwipeLeft(HotspotUser user) async {
    // Swipe left to disable
    if (!user.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context)
              .alreadyDisabled
              .replaceAll('%s', user.name)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          AppStrings.of(context).disable,
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          '${AppStrings.of(context).disable} user "${user.name}"?',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(AppStrings.of(context).disable),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(hotspotUsersProvider.notifier).toggleUserStatus(user.id);
      await LogService.logUserDisabled(user.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppStrings.of(context).disabled.replaceAll('%s', user.name)),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSwipeRight(HotspotUser user) async {
    // Swipe right to enable if disabled, or show info if already enabled
    if (!user.disabled) {
      FeedbackUtils.showInfo(context, 'User "${user.name}" is already enabled');
      return;
    }
    await ref.read(hotspotUsersProvider.notifier).toggleUserStatus(user.id);
    await LogService.logUserEnabled(user.name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppStrings.of(context).enabled.replaceAll('%s', user.name)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleQuickAction(HotspotUser user, String action) {
    switch (action) {
      case 'details':
        _navigateToUserDetails(user);
        break;
      case 'edit':
        _navigateToEditUser(user);
        break;
      case 'toggle':
        _toggleUserStatus(user);
        break;
      case 'extend':
        _handleSwipeRight(user);
        break;
      case 'delete':
        _confirmDeleteSingleUser(user);
        break;
      default:
        break;
    }
  }

  Future<void> _confirmDeleteSingleUser(HotspotUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Delete User?',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'Delete user "${user.name}"? This action cannot be undone.',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(hotspotUsersProvider.notifier).deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User "${user.name}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToEditUser(HotspotUser user) async {
    final userData = {
      '.id': user.id,
      'name': user.name,
      'profile': user.profile,
      'active': user.active.toString(),
      'uptime': user.uptime ?? '0',
      'bytes-in': (user.bytesIn ?? 0).toString(),
      'bytes-out': (user.bytesOut ?? 0).toString(),
      'limit-uptime': '0',
      'disabled': user.disabled.toString(),
      'comment': user.comment ?? '',
    };
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHotspotUserScreen(user: userData),
      ),
    );
  }

  Future<void> _toggleUserStatus(HotspotUser user) async {
    await ref.read(hotspotUsersProvider.notifier).toggleUserStatus(user.id);
    if (mounted) {
      FeedbackUtils.showSuccess(context,
          'User "${user.name}" ${user.disabled ? 'disabled' : 'enabled'}');
    }
  }

  Future<void> _confirmBulkDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Delete ${_selectedUserIds.length} users?',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bulkDeleteUsers();
    }
  }

  Future<void> _bulkDeleteUsers() async {
    int successCount = 0;
    int failCount = 0;
    final totalUsers = _selectedUserIds.length;

    // Show progress dialog and store the dialog context for closing
    if (!mounted) return;

    late BuildContext dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          backgroundColor: context.appSurface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Deleting $totalUsers users...',
                style: TextStyle(color: context.appOnSurface),
              ),
            ],
          ),
        );
      },
    );

    for (final userId in _selectedUserIds) {
      try {
        await ref.read(hotspotUsersProvider.notifier).deleteUser(userId);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    // Exit selection mode first
    _exitSelectionMode();

    // Close progress dialog using the dialog context
    if (mounted) {
      Navigator.of(dialogContext).pop();
    }

    // Show snackbar after dialog is closed
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Deleted $successCount users${failCount > 0 ? ' ($failCount failed)' : ''}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: failCount > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  Future<void> _bulkDisableUsers() async {
    final usersAsync = ref.read(hotspotUsersProvider).value;
    if (usersAsync == null) return;

    final allUsers = usersAsync.users
        .map((data) => HotspotUser.fromJson(data,
            activeUsernames: usersAsync.activeUsernames))
        .toList();
    int successCount = 0;
    int failCount = 0;
    final totalUsers = _selectedUserIds.length;

    if (!mounted) return;

    late BuildContext dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          backgroundColor: context.appSurface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Disabling $totalUsers users...',
                style: TextStyle(color: context.appOnSurface),
              ),
            ],
          ),
        );
      },
    );

    for (final userId in _selectedUserIds) {
      try {
        final user = allUsers.firstWhere((u) => u.id == userId);
        // Only disable if currently enabled
        if (!user.disabled) {
          await ref
              .read(hotspotUsersProvider.notifier)
              .toggleUserStatus(userId);
          successCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    // Exit selection mode first
    _exitSelectionMode();

    // Close progress dialog
    if (mounted) {
      Navigator.of(dialogContext).pop();
    }

    // Show snackbar after dialog is closed
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Disabled $successCount users${failCount > 0 ? ' ($failCount failed)' : ''}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: failCount > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  Future<void> _bulkEnableUsers() async {
    final usersAsync = ref.read(hotspotUsersProvider).value;
    if (usersAsync == null) return;

    final allUsers = usersAsync.users
        .map((data) => HotspotUser.fromJson(data,
            activeUsernames: usersAsync.activeUsernames))
        .toList();
    int successCount = 0;
    int failCount = 0;
    final totalUsers = _selectedUserIds.length;

    if (!mounted) return;

    late BuildContext dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          backgroundColor: context.appSurface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Enabling $totalUsers users...',
                style: TextStyle(color: context.appOnSurface),
              ),
            ],
          ),
        );
      },
    );

    for (final userId in _selectedUserIds) {
      try {
        final user = allUsers.firstWhere((u) => u.id == userId);
        // Only enable if currently disabled
        if (user.disabled) {
          await ref
              .read(hotspotUsersProvider.notifier)
              .toggleUserStatus(userId);
          successCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    // Exit selection mode first
    _exitSelectionMode();

    // Close progress dialog
    if (mounted) {
      Navigator.of(dialogContext).pop();
    }

    // Show snackbar after dialog is closed
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Enabled $successCount users${failCount > 0 ? ' ($failCount failed)' : ''}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: failCount > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  Future<void> _showMoveProfileDialog(BuildContext context) async {
    final profilesAsync = ref.read(userProfileProvider);

    profilesAsync.when(
      data: (profiles) {
        final profileNames = profiles.map((p) => p.name).toList();

        if (profileNames.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).noProfilesAvailable),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        String? selectedProfile;

        showDialog(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              backgroundColor: context.appSurface,
              title: Text(
                'Move ${_selectedUserIds.length} users to profile',
                style: TextStyle(color: context.appOnSurface),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a profile:',
                    style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selectedProfile,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedProfile = value;
                      });
                    },
                    child: Column(
                      children: profileNames
                          .map((profile) => RadioListTile<String>(
                                title: Text(
                                  profile.toUpperCase(),
                                  style: TextStyle(color: context.appOnSurface),
                                ),
                                value: profile,
                                activeColor: context.appPrimary,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                  ),
                ),
                TextButton(
                  onPressed: selectedProfile == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          _bulkMoveToProfile(selectedProfile!);
                        },
                  child: Text(
                    'Move',
                    style: TextStyle(color: context.appPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).loadingProfiles),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      error: (_, __) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).failedToLoadProfiles),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }

  Future<void> _bulkMoveToProfile(String targetProfile) async {
    final usersAsync = ref.read(hotspotUsersProvider).value;
    if (usersAsync == null) return;

    final allUsers = usersAsync.users
        .map((data) => HotspotUser.fromJson(data,
            activeUsernames: usersAsync.activeUsernames))
        .toList();
    int successCount = 0;
    int failCount = 0;

    if (!mounted) return;

    late BuildContext dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          backgroundColor: context.appSurface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Moving users...',
                style: TextStyle(color: context.appOnSurface),
              ),
            ],
          ),
        );
      },
    );

    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      if (mounted) {
        Navigator.of(dialogContext).pop();
      }
      return;
    }

    for (final userId in _selectedUserIds) {
      try {
        final user = allUsers.firstWhere((u) => u.id == userId);
        if (user.profile != targetProfile) {
          await client.setHotspotUserProfile(userId, targetProfile);
          successCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    // Exit selection mode first
    _exitSelectionMode();

    // Refresh the user list
    await ref.read(hotspotUsersProvider.notifier).refresh();

    // Close progress dialog
    if (mounted) {
      Navigator.of(dialogContext).pop();
    }

    // Show snackbar after dialog is closed
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Moved $successCount users${failCount > 0 ? ' ($failCount failed)' : ''}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: failCount > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  List<HotspotUser> _filterUsers(List<HotspotUser> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.profile.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    switch (_statusFilter) {
      case UserStatusFilter.online:
        filtered = filtered.where((user) => user.active).toList();
        break;
      case UserStatusFilter.disabled:
        filtered = filtered.where((user) => user.isDisabledOnly).toList();
        break;
      case UserStatusFilter.expired:
        filtered = filtered.where((user) => user.isExpired).toList();
        break;
      case UserStatusFilter.all:
        break;
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchQuery.isNotEmpty || _statusFilter != UserStatusFilter.all;

    if (hasFilters) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No users found',
        description:
            'No hotspot users match your current filters. Try adjusting your search or filter criteria.',
        iconColor: Colors.orange,
      );
    }

    return EmptyStates.noUsers(() {
      context.push('/main/users/add');
    });
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: context.appError,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading users',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHotspotUserScreen(),
      ),
    );
  }

  Future<void> _navigateToGenerateVouchers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoucherGenerationScreen(),
      ),
    );
  }

  void _navigateToUserDetails(HotspotUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotspotUserDetailsScreen(user: user),
      ),
    );
  }
}

// Extracted search and filter bar widget for better performance
class _SearchAndFilterBar extends StatelessWidget {
  final String searchQuery;
  final UserStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<UserStatusFilter> onFilterChanged;

  const _SearchAndFilterBar({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by username or profile...',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: context.appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          SizedBox(height: 12),
          SegmentedButton<UserStatusFilter>(
            segments: [
              ButtonSegment(
                value: UserStatusFilter.all,
                label: Text(AppStrings.of(context).filterAll),
                icon: Icon(Icons.people_rounded, size: 18),
              ),
              ButtonSegment(
                value: UserStatusFilter.online,
                label: Text('Online'),
                icon: Icon(Icons.wifi_rounded, size: 18),
              ),
              ButtonSegment(
                value: UserStatusFilter.disabled,
                label: Text('Disabled'),
                icon: Icon(Icons.wifi_off_rounded, size: 18),
              ),
              ButtonSegment(
                value: UserStatusFilter.expired,
                label: Text('Expired'),
                icon: Icon(Icons.timer_off_rounded, size: 18),
              ),
            ],
            selected: {statusFilter},
            onSelectionChanged: (newSelection) =>
                onFilterChanged(newSelection.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return context.appPrimary;
                }
                return context.appBackground;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return context.appOnSurface;
              }),
            ),
          ),
        ],
      ),
    );
  }
}

enum UserStatusFilter { all, online, disabled, expired }
