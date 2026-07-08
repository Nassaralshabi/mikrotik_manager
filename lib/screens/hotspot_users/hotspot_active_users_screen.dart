import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../utils/performance_utils.dart';
import '../../widgets/skeleton_loader.dart';
import '../../l10n/translations.dart';

class HotspotActiveUsersScreen extends ConsumerStatefulWidget {
  const HotspotActiveUsersScreen({super.key});

  @override
  ConsumerState<HotspotActiveUsersScreen> createState() =>
      _HotspotActiveUsersScreenState();
}

class _HotspotActiveUsersScreenState
    extends ConsumerState<HotspotActiveUsersScreen> {
  String _searchQuery = '';
  String _selectedServer = 'All';
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _refreshTimer;
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startAutoRefresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No manual refresh needed - rely on auto-refresh from provider
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
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

    final paginatedUsers = ref.read(hotspotActiveUsersProvider).value;
    if (paginatedUsers == null || !paginatedUsers.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(hotspotActiveUsersProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds to get actual data from router
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        ref.read(hotspotActiveUsersProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeUsersAsync = ref.watch(hotspotActiveUsersProvider);

    return PopScope(
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/main/users'),
          ),
          title: Text(
            'Active Users',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.read(hotspotActiveUsersProvider.notifier).refresh();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(hotspotActiveUsersProvider.notifier).refresh();
                },
                color: context.appPrimary,
                child: activeUsersAsync.when(
                  data: (paginatedUsers) {
                    final users = paginatedUsers.users
                        .map((data) => HotspotActiveUser.fromJson(data))
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
                      itemBuilder: (context, index) {
                        if (index == filteredUsers.length) {
                          return _buildLoadingIndicator();
                        }
                        final user = filteredUsers[index];
                        // Use the new widget card that handles its own dynamic updates
                        return RepaintBoundary(
                          key: ValueKey(user.id),
                          child: _UserCardWidget(
                            user: user,
                            onTap: () => _showUserDetails(user),
                            onDetails: () => _showUserDetails(user),
                            onLogout: () => _confirmLogout(user),
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
                  error: (error, stack) => Center(
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
                          'Error loading active users',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: context.appOnSurface,
                                  ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color:
                                    context.appOnSurface.withValues(alpha: 0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
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
              hintText: 'Search by username or IP...',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _searchDebouncer.run(() {});
            },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: context.appOnSurface.withValues(alpha: 0.6),
              ),
              SizedBox(width: 8),
              Text(
                'Filter by server:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'all',
                      label: Text(AppStrings.of(context).filterAll),
                    ),
                    ButtonSegment(
                      value: 'HS1',
                      label: Text('HS1'),
                    ),
                  ],
                  selected: {_selectedServer},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedServer = newSelection.first;
                    });
                  },
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<HotspotActiveUser> _filterUsers(List<HotspotActiveUser> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.username
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            user.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply server filter
    if (_selectedServer != 'All') {
      filtered =
          filtered.where((user) => user.server == _selectedServer).toList();
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No active users',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                ),
          ),
          SizedBox(height: 8),
          Text(
            'Currently no users are logged into the hotspot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.appOnSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
        ),
      ),
    );
  }

  void _showUserDetails(HotspotActiveUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.appOnSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.appPrimary,
                          context.appPrimary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: context.appOnSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Connected',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                controller: scrollController,
                children: [
                  _buildDetailTile(
                      Icons.badge_rounded, 'Username', user.username),
                  _buildDetailTile(
                      Icons.computer_rounded, 'IP Address', user.address),
                  _buildDetailTile(
                      Icons.router_rounded, 'MAC Address', user.macAddress),
                  _buildDetailTile(Icons.access_time_rounded, 'Login Time',
                      _formatLoginTime(user.loginTime)),
                  _buildDetailTile(Icons.timer_rounded, 'Uptime', user.uptime),
                  _buildDetailTile(
                      Icons.swap_vert_rounded, 'Data Used', user.dataUsed),
                  _buildDetailTile(
                      Icons.cloud_rounded, 'Server', user.server ?? 'N/A'),
                  _buildDetailTile(
                      Icons.card_membership_rounded, 'Profile', user.profile),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmLogout(user);
                    },
                    icon: Icon(Icons.logout_rounded),
                    label: Text(AppStrings.of(context).logoutUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appError,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: context.appPrimary,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatLoginTime(String timestamp) {
    try {
      final seconds = int.parse(timestamp);
      final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  void _confirmLogout(HotspotActiveUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).logoutUser),
        content: Text(
            'Are you sure you want to logout "${user.username}" from ${user.address}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(hotspotActiveUsersProvider.notifier)
                    .logoutUser(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'User "${user.username}" logged out successfully'),
                      backgroundColor: context.appPrimary,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppStrings.of(context)
                          .failedToLogoutUser
                          .replaceAll('%s', e.toString())),
                      backgroundColor: context.appError,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: context.appError,
            ),
            child: Text(AppStrings.of(context).logout),
          ),
        ],
      ),
    );
  }
}

/// Individual user card widget that handles its own dynamic updates
/// Only the dynamic values (uptime, data used) update, not the entire card
class _UserCardWidget extends StatefulWidget {
  final HotspotActiveUser user;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onLogout;

  const _UserCardWidget({
    required this.user,
    required this.onTap,
    required this.onDetails,
    required this.onLogout,
  });

  @override
  State<_UserCardWidget> createState() => _UserCardWidgetState();
}

class _UserCardWidgetState extends State<_UserCardWidget> {
  late String _displayUptime;
  late String _displayDataUsed;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _displayUptime = widget.user.uptime;
    _displayDataUsed = widget.user.dataUsed;

    // Start local timer for dynamic updates (every 1 second)
    _startDynamicUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startDynamicUpdates() {
    // Update dynamic values every second independently
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Use actual values from user object
          // (these update when provider refreshes)
          _displayUptime = widget.user.uptime;
          _displayDataUsed = widget.user.dataUsed;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          context.appPrimary,
                          context.appPrimary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.username,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: context.appOnSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.computer_rounded,
                              size: 14,
                              color:
                                  context.appOnSurface.withValues(alpha: 0.6),
                            ),
                            SizedBox(width: 4),
                            Text(
                              widget.user.address,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.appOnSurface
                                        .withValues(alpha: 0.7),
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Online',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.access_time_rounded,
                      'Uptime',
                      _displayUptime,
                      context.appPrimary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.appOnSurface.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.download_rounded,
                      'Download',
                      _displayDataUsed,
                      Colors.blue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.appOnSurface.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.router_rounded,
                      'Server',
                      widget.user.server ?? 'N/A',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onDetails,
                    icon: Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(AppStrings.of(context).details),
                    style: TextButton.styleFrom(
                      foregroundColor: context.appPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onLogout,
                    icon: Icon(Icons.logout_rounded, size: 18),
                    label: Text(AppStrings.of(context).logout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appError.withValues(alpha: 0.1),
                      foregroundColor: context.appError,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appOnSurface.withValues(alpha: 0.6),
              ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
