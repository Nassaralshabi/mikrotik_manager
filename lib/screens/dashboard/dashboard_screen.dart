import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/expandable_chart.dart';
import 'widgets/traffic_monitor_widgets.dart';
import 'widgets/at_a_glance_card.dart';
import 'widgets/system_alerts_card.dart';
import 'widgets/quick_actions_grid.dart';
import '../../widgets/native_ad_widget.dart';
import '../../l10n/translations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _errorMessage;
  SystemResources? _resources;
  Timer? _refreshTimer;
  bool _isFetching = false;

  bool _highPriorityLoaded = false;
  bool _mediumPriorityLoaded = false;
  bool _lowPriorityLoaded = false;

  @override
  void initState() {
    super.initState();
    // Use schedulerBinding to defer initialization
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _checkConnectionAndLoad();
    });
  }

  void _checkConnectionAndLoad() {
    final service = ref.read(routerOSServiceProvider);
    if (!service.isConnected) {
      // Not connected - redirect to home
      if (mounted) {
        context.go('/');
      }
      return;
    }
    _loadInitialData();
  }

  void _loadInitialData() {
    if (!mounted) return;

    // Mark all priorities as loaded immediately to show cached data
    setState(() {
      _highPriorityLoaded = true;
      _mediumPriorityLoaded = true;
      _lowPriorityLoaded = true;
    });

    final cache = ref.read(cacheServiceProvider);
    final hasCachedData = cache.getSystemResources() != null ||
        ref.read(authStateProvider).value?.systemResources != null;

    // Load system resources in background (if no cache)
    if (!hasCachedData) {
      _loadDashboardData(showLoading: false);
    }

    // Start periodic refresh for system resources
    _startPeriodicRefresh();

    // Don't manually refresh hotspot users - data comes from cache via provider
    // Auto-refresh in provider handles background updates
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Delay periodic refresh to not block initial render
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _fetchAndCacheResources();
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (mounted) {
            _fetchAndCacheResources();
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  void _updateResourceHistory() {
    if (_resources != null) {
      ref.read(resourceHistoryProvider).addFromResources(_resources!);
    }
  }

  Future<void> _loadDashboardData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);

      // Check if we have pre-fetched data from login (fastest path)
      final authState = ref.read(authStateProvider);
      if (authState.value?.systemResources != null) {
        if (mounted) {
          setState(() {
            _resources =
                SystemResources.fromJson(authState.value!.systemResources!);
            _isLoading = false;
            _isInitialLoad = false;
          });
          _updateResourceHistory();
        }
        // Clear the pre-fetched data so future refreshes fetch new data
        // Delay to avoid modifying provider during widget lifecycle
        Future.microtask(() =>
            ref.read(authStateProvider.notifier).clearPrefetchedResources());
        // Background refresh to get latest data
        _fetchAndCacheResources();
        return;
      }

      // Check cache for instant data display (second fastest path)
      final cachedResources = cache.getSystemResources();
      if (cachedResources != null) {
        if (mounted) {
          setState(() {
            _resources = SystemResources.fromJson(cachedResources);
            _isLoading = false;
            _isInitialLoad = false;
          });
          _updateResourceHistory();
        }
        // Don't fetch fresh data on navigation - use cached data instantly
        // The periodic timer will keep data updated
        return;
      }

      // Fetch new data if we're connected (slowest path - first time ever)
      if (service.isConnected) {
        await _fetchAndCacheResources();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = AppStrings.of(context).notConnectedLoginFirst;
          });
        }
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fetch resources from RouterOS and cache them
  /// Guarded against concurrent fetches with _isFetching flag
  Future<void> _fetchAndCacheResources() async {
    // Prevent concurrent fetches
    if (_isFetching) {
      return;
    }

    _isFetching = true;

    try {
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);

      if (!service.isConnected) {
        return;
      }

      final client = service.client;
      if (client == null) {
        return;
      }

      final resourcesData = await client.getSystemResources();

      // Validate that we got meaningful data before saving
      // Check if we have at least some expected fields
      if (resourcesData.isEmpty ||
          (!resourcesData.containsKey('platform') &&
              !resourcesData.containsKey('cpu-load') &&
              !resourcesData.containsKey('free-memory'))) {
        return;
      }

      // Save to cache
      await cache.saveSystemResources(resourcesData);

      // Update UI if mounted
      if (mounted) {
        final newResources = SystemResources.fromJson(resourcesData);
        setState(() {
          _resources = newResources;
          _errorMessage = null;
          _isInitialLoad = false; // First successful data load
        });
        _updateResourceHistory();
      }
    } catch (e) {
      // Don't show error on background refresh failures
      // Only show error if there's no cached data
      if (_resources == null && mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.of(context).dashboard,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.appSuccess.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_rounded, size: 14, color: context.appSuccess),
                  const SizedBox(width: 4),
                  Text(AppStrings.of(context).live,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: AppStrings.of(context).searchUsers,
            onPressed: () => _openUserSearch(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/main/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed:
                _isLoading ? null : () => _loadDashboardData(showLoading: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // At a glance skeleton
          SkeletonLoaders.card(height: 100),
          const SizedBox(height: 16),
          // System info skeleton
          SkeletonLoaders.card(height: 180),
          const SizedBox(height: 16),
          // Resource chart skeleton
          SkeletonLoaders.chart(height: 250),
          const SizedBox(height: 16),
          // Traffic monitor skeleton
          SkeletonLoaders.card(height: 150),
          const SizedBox(height: 16),
          // Quick actions skeleton
          SkeletonLoaders.card(height: 200),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Show full skeleton on initial load when no cached data
    final cache = ref.read(cacheServiceProvider);
    final hasCachedData = cache.getSystemResources() != null ||
        ref.read(authStateProvider).value?.systemResources != null;

    if (_isInitialLoad && _isLoading && !hasCachedData) {
      return _buildDashboardSkeleton();
    }

    if (_errorMessage != null && _resources == null) {
      return SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: context.appError,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.of(context).connectionError,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: context.appOnBackground,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                context.appOnBackground.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDashboardData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppStrings.of(context).retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(showLoading: false),
      color: context.appPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 400;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // System info card (Low priority) - FIRST
                if (_lowPriorityLoaded && _resources != null) ...[
                  _buildSystemInfoCard(),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ] else
                  SkeletonLoaders.card(height: 180),
                // Expandable resource chart (Low priority) - SECOND
                if (_lowPriorityLoaded && _resources != null) ...[
                  _buildResourceChart(),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ] else
                  SkeletonLoaders.chart(height: 250),
                // At a Glance summary (High priority) - THIRD
                if (_highPriorityLoaded) ...[
                  const AtAGlanceCard(),
                  const NativeAdWidget(),
                ] else
                  SkeletonLoaders.card(height: 100),
                SizedBox(height: isSmallScreen ? 12 : 16),
                // System alerts (High priority)
                if (_highPriorityLoaded)
                  _buildAlertsSection()
                else
                  SkeletonLoaders.card(height: 80),
                SizedBox(height: isSmallScreen ? 12 : 16),
                // Traffic monitor (Medium priority)
                if (_mediumPriorityLoaded) ...[
                  const TrafficMonitorCard(),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ] else
                  SkeletonLoaders.card(height: 150),
                // Quick actions grid (Medium priority)
                if (_mediumPriorityLoaded)
                  const QuickActionsGrid()
                else
                  SkeletonLoaders.card(height: 200),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    color: context.appPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resources!.boardName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: context.appOnSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RouterOS ${_resources!.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.memory_rounded,
              AppStrings.of(context).platform,
              _resources!.platform,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.speed_rounded,
              AppStrings.of(context).cpu,
              '${_resources!.cpuFrequency} MHz',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_rounded,
              AppStrings.of(context).uptime,
              _formatUptime(_resources!.uptimeSeconds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceChart() {
    return ListenableBuilder(
      listenable: ref.read(resourceHistoryProvider),
      builder: (context, child) {
        return ExpandableResourceChart(
          resourceHistory: ref.read(resourceHistoryProvider),
        );
      },
    );
  }

  Widget _buildAlertsSection() {
    return ListenableBuilder(
      listenable: ref.read(resourceHistoryProvider),
      builder: (context, child) {
        return SystemAlertsCard(
          resourceHistory: ref.read(resourceHistoryProvider),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: context.appPrimary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface.withValues(alpha: 0.7),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _openUserSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _UserSearchDelegate(ref),
    );
  }
}

class _UserSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  _UserSearchDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.of(context).searchUsersPlaceholder,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      );
    }

    final usersAsync = ref.read(hotspotUsersProvider);
    return usersAsync.when(
      data: (paginatedUsers) {
        final users = paginatedUsers.users
            .map((data) => HotspotUser.fromJson(data,
                activeUsernames: paginatedUsers.activeUsernames))
            .where((user) =>
                user.name.toLowerCase().contains(query.toLowerCase()) ||
                user.id.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.of(context).noUsersFoundForQuery.replaceAll('%s', query),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              title: Text(user.name),
              subtitle: Text(user.id),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
              onTap: () {
                close(context, '');
                context.push('/main/users/${user.id}');
              },
            );
          },
        );
      },
      loading: () => SizedBox(
                height: 400,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (context, index) =>
                      SkeletonLoaders.summaryCard(),
                ),
              ),
      error: (error, _) => Center(
        child: Text(AppStrings.of(context)
            .errorPrefix
            .replaceAll('%s', error.toString())),
      ),
    );
  }
}
