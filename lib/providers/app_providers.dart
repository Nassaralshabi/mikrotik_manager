import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/routeros_service.dart';
import '../services/models.dart';
import '../services/models/voucher.dart';
import '../services/cache_service.dart';
import '../services/traffic_rate_service.dart';
import '../services/resource_history.dart';
import '../services/theme_service.dart';
import '../services/template_service.dart';
import '../services/log_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/command_center_minimal.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/setup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../utils/on_login_script_generator.dart';
import '../utils/async_lock.dart';
import '../utils/currency_formatter.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/hotspot_users/hotspot_users_screen.dart';
import '../screens/hotspot_users/hotspot_active_users_screen.dart';
import '../screens/hotspot_users/hotspot_hosts_screen.dart';
import '../screens/hotspot_users/hotspot_host_details_screen.dart';
import '../screens/hotspot_users/dhcp_leases_screen.dart';
import '../screens/hotspot_users/add_hotspot_user_screen.dart';
import '../screens/hotspot_users/hotspot_user_details_screen.dart';
import '../screens/hotspot_users/user_profiles_screen.dart';
import '../screens/hotspot_users/voucher_generation_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/voucher_template_editor_screen.dart';
import '../screens/revenue/revenue_screen.dart';
import '../screens/vouchers/vouchers_list_screen.dart';
import '../screens/activity_logs/activity_logs_screen.dart';
import '../screens/feedback/feedback_screen.dart';
import '../screens/main/main_shell_screen.dart';
import '../screens/files/files_screen.dart';

// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
});

// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// Theme Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light) {
    _loadThemeMode();
  }

  ThemeModeNotifier.preloaded(super.mode);

  Future<void> _loadThemeMode() async {
    final mode = await ThemeService.loadThemeMode();
    state = mode;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await ThemeService.saveThemeMode(mode);
  }

  /// Clear saved theme (reset to default)
  Future<void> clearTheme() async {
    await ThemeService.clearThemeMode();
    state = AppThemeMode.light;
  }

  /// Get theme data for current mode
  ThemeData getThemeData() {
    return ThemeService.getThemeData(state);
  }
}

// Currency Provider
final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyInfo>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<CurrencyInfo> {
  CurrencyNotifier() : super(CurrencyData.currencies['USD']!) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final cache = CacheService();
    final settings = cache.getAppSettings();
    final savedCurrency = settings?['currency'] as String?;

    if (savedCurrency != null &&
        CurrencyData.currencies.containsKey(savedCurrency)) {
      state = CurrencyData.currencies[savedCurrency]!;
    } else {
      // Default to device locale currency
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      state = CurrencyData.getCurrencyForLocale(deviceLocale.languageCode);
    }
  }

  Future<void> setCurrency(String code) async {
    if (CurrencyData.currencies.containsKey(code)) {
      state = CurrencyData.currencies[code]!;

      // Save to settings
      final cache = CacheService();
      final settings = cache.getAppSettings() ?? {};
      settings['currency'] = code;
      await cache.saveAppSettings(
        country: settings['country'] ?? '',
        currency: code,
        companyName: settings['companyName'] ?? '',
      );
    }
  }
}

// Voucher Template Provider
final voucherTemplateProvider =
    StateNotifierProvider<TemplateNotifier, VoucherTemplate>((ref) {
  return TemplateNotifier();
});

class TemplateNotifier extends StateNotifier<VoucherTemplate> {
  TemplateNotifier() : super(VoucherTemplate.full) {
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final template = await TemplateService.loadTemplate();
    state = template;
  }

  Future<void> setTemplate(VoucherTemplate template) async {
    state = template;
    await TemplateService.saveTemplate(template);
  }
}

// RouterOS Service Provider
final routerOSServiceProvider = Provider<RouterOSService>((ref) {
  return RouterOSService();
});

// Authentication State Provider
final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final Map<String, dynamic>? systemResources;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    this.systemResources,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    Map<String, dynamic>? systemResources,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      systemResources: systemResources ?? this.systemResources,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return const AuthState(isAuthenticated: false);
  }

  Future<void> login({
    required String host,
    required String port,
    required String username,
    required String password,
    required bool rememberMe,
    bool useRest = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);
      
      // Clear cache before connecting to a new host to prevent data leaks
      await cache.clearCache();

      // Connect to RouterOS
      final client = await service.connectWithCredentials(
        host: host,
        port: port,
        username: username,
        password: password,
        useRest: useRest,
      );

      // Pre-fetch system resources during login
      final resources = await client.getSystemResources();

      await cache.saveSystemResources(resources);

      // Pre-fetch hotspot users and profiles in background for faster screen loads
      _prefetchHotspotData(client, cache);

      // Log successful login
      await LogService.logLogin(username, '$host:$port');

      // Store credentials if remember me is checked
      if (rememberMe) {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'router_ip', value: host);
        await storage.write(key: 'port', value: port);
        await storage.write(key: 'username', value: username);
        await storage.write(key: 'password', value: password);
      }

      return AuthState(
        isAuthenticated: true,
        systemResources: resources,
      );
    });
  }

  Future<void> _prefetchHotspotData(client, CacheService cache) async {
    try {
      // Pre-fetch user profiles
      final profiles = await client.getHotspotProfiles();
      await cache.saveUserProfiles(profiles);
    } catch (_) {}

    try {
      // Pre-fetch hotspot users
      final users = await client.getHotspotUsers();
      await cache.saveHotspotUsers(users);
    } catch (_) {}
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(routerOSServiceProvider);
      await service.disconnect();

      // Clear credentials
      await service.clearCredentials();

      // Clear cache on logout
      final cache = ref.read(cacheServiceProvider);
      await cache.clearCache();

      // Log logout
      await LogService.logLogout('User');

      return const AuthState(isAuthenticated: false);
    });
  }

  // Clear pre-fetched resources after dashboard has consumed them
  void clearPrefetchedResources() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(systemResources: null));
    }
  }
}

// Navigation state provider for bottom navigation
final currentTabProvider = StateProvider<int>((ref) => 0);

// GoRouter Provider with refresh support
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
        redirect: (context, state) async {
          final completed = await OnboardingService.isCompleted();
          if (!completed) return '/onboarding';
          return null;
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        redirect: (context, state) async {
          final container = ProviderScope.containerOf(context);
          final service = container.read(routerOSServiceProvider);
          if (!service.isConnected) {
            return '/';
          }
          return null;
        },
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/main',
            name: 'main',
            redirect: (context, state) => '/main/dashboard',
          ),
          GoRoute(
            path: '/main/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/main/command-center',
            name: 'command_center',
            builder: (context, state) => const CommandCenterMinimalScreen(),
          ),
          GoRoute(
            path: '/main/users',
            name: 'users',
            builder: (context, state) => const HotspotUsersScreen(),
            routes: [
              GoRoute(
                path: 'active',
                name: 'active_users',
                builder: (context, state) => const HotspotActiveUsersScreen(),
              ),
              GoRoute(
                path: 'add',
                name: 'add_user',
                builder: (context, state) => const AddHotspotUserScreen(),
              ),
              GoRoute(
                path: 'generate',
                name: 'generate_user_vouchers',
                builder: (context, state) => const VoucherGenerationScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'user_details',
                pageBuilder: (context, state) {
                  final user = state.extra as HotspotUser?;
                  if (user == null) {
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: const Scaffold(
                        body: Center(child: Text('User not found')),
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    );
                  }
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: HotspotUserDetailsScreen(user: user),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 250),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/main/profiles',
            name: 'profiles',
            builder: (context, state) => const UserProfilesScreen(),
          ),
          GoRoute(
            path: '/main/hosts',
            name: 'hosts',
            builder: (context, state) => const HotspotHostsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'host_details',
                pageBuilder: (context, state) {
                  final host = state.extra as HotspotHost?;
                  if (host == null) {
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: const Scaffold(
                        body: Center(child: Text('Host not found')),
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    );
                  }
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: HotspotHostDetailsScreen(host: host),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      );
                    },
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/main/dhcp-leases',
            name: 'dhcp_leases',
            builder: (context, state) => const DhcpLeasesScreen(),
          ),
          GoRoute(
            path: '/main/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'voucher-template',
                name: 'voucher_template_editor',
                builder: (context, state) => const VoucherTemplateEditorScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/main/revenue',
            name: 'revenue',
            builder: (context, state) => const RevenueScreen(),
          ),
          GoRoute(
            path: '/main/vouchers',
            name: 'vouchers',
            builder: (context, state) => const VouchersListScreen(),
            routes: [
              GoRoute(
                path: 'generate',
                name: 'generate_vouchers',
                builder: (context, state) => const VoucherGenerationScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/main/logs',
            name: 'activity_logs',
            builder: (context, state) => const ActivityLogsScreen(),
          ),
          GoRoute(
            path: '/main/files',
            name: 'files',
            builder: (context, state) => const FilesScreen(),
          ),
          GoRoute(
            path: '/main/feedback',
            name: 'feedback',
            builder: (context, state) => const FeedbackScreen(),
          ),
        ],
      ),
    ],
  );
});

// Custom ChangeNotifier for router refresh
class _RouterRefreshNotifier extends ChangeNotifier {
  final Ref ref;

  _RouterRefreshNotifier(this.ref) {
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

// Hotspot Users Provider
final hotspotUsersProvider =
    AsyncNotifierProvider<HotspotUsersNotifier, PaginatedUsers>(() {
  return HotspotUsersNotifier();
});

// Pagination state class
class PaginatedUsers {
  final List<Map<String, dynamic>> users;
  final bool hasMore;
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final Set<String> activeUsernames;

  PaginatedUsers({
    required this.users,
    required this.hasMore,
    required this.currentPage,
    required this.pageSize,
    this.totalCount = 0,
    this.activeUsernames = const {},
  });

  PaginatedUsers copyWith({
    List<Map<String, dynamic>>? users,
    bool? hasMore,
    int? currentPage,
    Set<String>? activeUsernames,
  }) {
    return PaginatedUsers(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize,
      totalCount: totalCount,
      activeUsernames: activeUsernames ?? this.activeUsernames,
    );
  }
}

class HotspotUsersNotifier extends AsyncNotifier<PaginatedUsers> {
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _timerStarted = false;
  Timer? _refreshTimer;
  final Set<String> _recordedConnections = {};
  bool _isRefreshing = false;

  @override
  Future<PaginatedUsers> build() async {
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _timerStarted = false;
    });
    _currentPage = 1;

    // Record previously seen connections for revenue tracking
    if (_recordedConnections.isEmpty) {
      final cache = ref.read(cacheServiceProvider);
      _recordedConnections.addAll(cache.getRecordedConnections());
    }

    // Try to load from cache first for instant display
    final cache = ref.read(cacheServiceProvider);
    final cachedUsers = cache.getHotspotUsers();

    // If we have cached data, show it immediately and refresh in background
    if (cachedUsers != null && cachedUsers.isNotEmpty) {
      final cachedData = _paginateUsers(cachedUsers, page: 1);

      _startAutoRefresh();
      Future.microtask(() => silentRefresh());

      return cachedData;
    }

    // No cache - fetch from API with timeout
    final data = await _loadUsers(page: 1).timeout(
      const Duration(seconds: 15),
      onTimeout: () => _emptyPaginatedUsers(),
    );
    _startAutoRefresh();
    return data;
  }

  bool _isUserData(Map<String, dynamic> data) {
    // Users should have a name
    final name = data['name'] as String? ?? '';
    if (name.isEmpty) return false;
    // Users typically don't have profile-specific fields only
    // But they DO have password field
    return data.containsKey('password');
  }

  PaginatedUsers _paginateUsers(List<Map<String, dynamic>> allUsers,
      {required int page, Set<String> activeUsernames = const {}}) {
    // Filter out system/default users like "trial", "admin", "default" and non-user data
    final systemUserNames = {'trial', 'admin', 'default'};
    final filteredUsers = allUsers.where((user) {
      final userName = user['name'] as String? ?? '';
      if (systemUserNames.contains(userName.toLowerCase())) {
        return false;
      }
      // Only include actual users (must have password field)
      if (!_isUserData(user)) {
        return false;
      }
      return true;
    }).toList();

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final hasMore = endIndex < filteredUsers.length;
    final users = filteredUsers.skip(startIndex).take(_pageSize).toList();

    return PaginatedUsers(
      users: users,
      hasMore: hasMore,
      currentPage: page,
      pageSize: _pageSize,
      totalCount: filteredUsers.length,
      activeUsernames: activeUsernames,
    );
  }

  PaginatedUsers _emptyPaginatedUsers() {
    return PaginatedUsers(
      users: [],
      hasMore: false,
      currentPage: 1,
      pageSize: _pageSize,
      totalCount: 0,
    );
  }

  void _startAutoRefresh() {
    if (_timerStarted) return;
    _timerStarted = true;
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isRefreshing) {
        Future.microtask(() => silentRefresh());
      }
    });
  }

  Future<PaginatedUsers> _loadUsers({required int page}) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;

    // Return cached data if not connected
    if (client == null) {
      final cache = ref.read(cacheServiceProvider);
      final cachedUsers = cache.getHotspotUsers();
      if (cachedUsers != null) {
        return _paginateUsers(cachedUsers, page: 1);
      }
      return _emptyPaginatedUsers();
    }

    // Fetch hotspot users first (critical data) with timeout
    final allUsers = await client.getHotspotUsers().timeout(
      const Duration(seconds: 15),
      onTimeout: () => [],
    );
    if (allUsers.isEmpty) return _emptyPaginatedUsers();

    // Fetch active users separately (non-critical - don't fail the whole load)
    List<Map<String, dynamic>> activeUsers = [];
    try {
      activeUsers = await client.getHotspotActiveUsers().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      // Active users fetch failed - continue without active status
    }

    // Extract active usernames
    final activeUsernames = activeUsers
        .map((u) => u['user'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    // Auto-record revenue for new connections
    if (activeUsers.isNotEmpty) {
      await _autoRecordRevenue(activeUsers, allUsers);
    }

    // Track session time for vouchers
    await _trackSessionTime(activeUsers, allUsers);

    // Cache the users
    final cache = ref.read(cacheServiceProvider);
    await cache.saveHotspotUsers(allUsers);

    return _paginateUsers(allUsers,
        page: page, activeUsernames: activeUsernames);
  }

  /// Auto-record revenue when a voucher connects to the hotspot.
  Future<void> _autoRecordRevenue(
      List<Map<String, dynamic>> activeUsers,
      List<Map<String, dynamic>> allUsers) async {
    if (activeUsers.isEmpty || _recordedConnections.length > 500) return;
    try {
      final userComments = <String, String>{};
      for (final u in allUsers) {
        final name = u['name'] as String? ?? '';
        final comment = u['comment'] as String? ?? '';
        if (name.isNotEmpty) {
          userComments[name] = comment;
        }
      }

      // Use cached profiles instead of triggering provider fetch
      final cache = ref.read(cacheServiceProvider);
      final cachedProfiles = cache.getUserProfiles();
      final profilePrices = <String, double>{};
      if (cachedProfiles != null) {
        for (final data in cachedProfiles) {
          final name = data['name'] as String? ?? '';
          final localPrices = cache.getProfilePrices();
          double? price;
          final priceStr = data['price'] as String?;
          if (priceStr != null) price = double.tryParse(priceStr);
          if ((price == null || price == 0) && localPrices.containsKey(name)) {
            price = localPrices[name];
          }
          if (price != null && price > 0) {
            profilePrices[name.toLowerCase()] = price;
          }
        }
      }
      if (profilePrices.isEmpty) return;

      for (final activeUser in activeUsers) {
        final username = activeUser['user'] as String? ?? '';
        final profileName = activeUser['profile'] as String? ?? '';
        if (username.isEmpty || _recordedConnections.contains(username)) continue;

        final commentLower = (userComments[username] ?? '').toLowerCase();
        if (!commentLower.contains('mode:vc') &&
            !commentLower.contains('mode:up') &&
            !commentLower.startsWith('vc-') &&
            !commentLower.startsWith('up-')) continue;

        final price = profilePrices[profileName.toLowerCase()];
        if (price == null || price <= 0) continue;

        _recordedConnections.add(username);
        await cache.saveRecordedConnections(_recordedConnections);

        ref.read(incomeProvider.notifier).recordSale(
              username: username,
              profile: profileName,
              price: price,
              comment: 'Auto: voucher activated',
            );
      }
    } catch (_) {}
  }

  /// Track session time for active voucher users.
  /// Validity countdown starts on FIRST USE and runs continuously (wall-clock based).
  /// Even if disconnected, time continues counting down.
  Future<void> _trackSessionTime(List<Map<String, dynamic>> activeUsers,
      List<Map<String, dynamic>> allUsers) async {
    try {
      final cache = ref.read(cacheServiceProvider);
      final vouchersData = cache.getVouchers();
      if (vouchersData == null || vouchersData.isEmpty) return;

      final now = DateTime.now();
      final activeUsernames =
          activeUsers.map((u) => u['user'] as String? ?? '').toSet();

      for (final vData in vouchersData) {
        final voucher = Voucher.fromJson(vData);
        final username = voucher.username;
        final totalSecs = voucher.totalSeconds;

        if (totalSecs == null || totalSecs <= 0) continue;

        final isFirstUse = voucher.isFirstUse;
        final isActive = activeUsernames.contains(username);

        if (isFirstUse) {
          // FIRST USE - mark the start time, countdown begins
          if (isActive) {
            await cache.updateVoucher(username, {
              'firstUsedAt': now.toIso8601String(),
              'sessionStartedAt': now.toIso8601String(),
            });
          }
          continue;
        }

        // Calculate remaining based on wall-clock time since first use
        final elapsed = now.difference(voucher.firstUsedAt!).inSeconds;
        final newRemaining = (totalSecs - elapsed).clamp(0, totalSecs);

        if (newRemaining <= 0) {
          // Time is up - disable on router
          await _disableVoucherOnRouter(username);
          await cache.updateVoucher(username, {
            'remainingSeconds': 0,
            'sessionStartedAt': null,
          });
          continue;
        }

        // Update remaining time and session status
        await cache.updateVoucher(username, {
          'remainingSeconds': newRemaining,
          'sessionStartedAt': isActive ? now.toIso8601String() : null,
        });
      }

      ref.invalidate(vouchersProvider);
    } catch (_) {}
  }

  /// Disable a voucher (hotspot user) on the router when time expires
  Future<void> _disableVoucherOnRouter(String username) async {
    try {
      final service = ref.read(routerOSServiceProvider);
      final client = service.client;
      if (client == null) return;

      // Find the user on the router by name
      final users = await client.getHotspotUsers();
      final user = users.firstWhere(
        (u) => u['name'] == username,
        orElse: () => {},
      );
      if (user.isEmpty) return;

      final userId = user['.id'] as String? ?? '';
      if (userId.isEmpty) return;

      // Disable the user on the router
      await client.setHotspotUserStatus(userId, true);

      // Also log them out if still active
      try {
        await client.logoutHotspotUser(userId);
      } catch (_) {
        // User might not be active, that's OK
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    _currentPage++;
    final nextPageData = await _loadUsers(page: _currentPage);

    state = AsyncValue.data(PaginatedUsers(
      users: [...currentState.users, ...nextPageData.users],
      hasMore: nextPageData.hasMore,
      currentPage: nextPageData.currentPage,
      pageSize: _pageSize,
      activeUsernames: nextPageData.activeUsernames.isNotEmpty
          ? nextPageData.activeUsernames
          : currentState.activeUsernames,
    ));
  }

  Future<void> refresh() async {
    return refreshLock.synchronizedRefresh('hotspotUsers', () async {
      _currentPage = 1;
      state = const AsyncValue.loading();
      try {
        state = AsyncValue.data(await _loadUsers(page: 1));
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    });
  }

  Future<void> addUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
    String? sessionTimeout,
  }) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.addUser({
      'name': username,
      'password': password,
      'profile': profile,
      if (comment != null) 'comment': comment,
      if (sessionTimeout != null) 'session-timeout': sessionTimeout,
    });

    ref.invalidate(hotspotUsersProvider);
  }

  Future<void> deleteUser(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Get username before deleting
    final currentState = state.value;
    String? usernameToDelete;
    if (currentState != null) {
      final userToDelete = currentState.users.firstWhere(
        (user) => user['.id'] == id,
        orElse: () => <String, dynamic>{},
      );
      usernameToDelete = userToDelete['name'] as String?;
    }

    await client.deleteUser(id);

    // Delete associated voucher if exists
    if (usernameToDelete != null) {
      try {
        await ref
            .read(vouchersProvider.notifier)
            .expireVoucher(usernameToDelete);
      } catch (_) {
        // Ignore if voucher deletion fails
      }
    }

    // Immediately remove user from current state for instant UI update
    if (currentState != null) {
      final updatedUsers =
          currentState.users.where((user) => user['.id'] != id).toList();
      state = AsyncValue.data(PaginatedUsers(
        users: updatedUsers,
        hasMore: currentState.hasMore,
        currentPage: currentState.currentPage,
        pageSize: currentState.pageSize,
        activeUsernames: currentState.activeUsernames,
      ));
    }

    // Wait a moment for router to process deletion, then refresh
    await Future.delayed(const Duration(milliseconds: 500));
    await silentRefresh();
  }

  Future<void> silentRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final newData = await _loadUsers(page: 1).timeout(
        const Duration(seconds: 20),
        onTimeout: () => _emptyPaginatedUsers(),
      );
      if (newData.users.isNotEmpty) {
        state = AsyncValue.data(newData);
      }
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> updateUser({
    required String id,
    required String username,
    required String profile,
    String? comment,
  }) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Get current user data to preserve disabled status and password
    final allUsers = await client.getHotspotUsers();
    final currentUser =
        allUsers.firstWhere((u) => u['.id'] == id, orElse: () => {});

    // Update user using remove and re-add approach
    await client.updateUser(id, {
      'name': username,
      'password': currentUser['password'] ?? username,
      'profile': profile,
      'disabled': currentUser['disabled'] == 'true' ? 'yes' : 'no',
      if (comment != null) 'comment': comment,
    });

    // Refresh the list
    ref.invalidate(hotspotUsersProvider);
  }

  Future<void> toggleUserStatus(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Get current user status from current state
    final currentState = state.value;
    if (currentState != null) {
      final currentUser = currentState.users
          .firstWhere((u) => u['.id'] == id, orElse: () => {});
      final isCurrentlyDisabled =
          currentUser['disabled'] == 'true' || currentUser['disabled'] == 'yes';

      // Immediately update UI by toggling the disabled status in current state
      final updatedUsers = currentState.users.map((user) {
        if (user['.id'] == id) {
          final updatedUser = Map<String, dynamic>.from(user);
          updatedUser['disabled'] = isCurrentlyDisabled ? 'false' : 'true';
          updatedUser['active'] = isCurrentlyDisabled ? 'true' : 'false';
          return updatedUser;
        }
        return user;
      }).toList();

      state = AsyncValue.data(PaginatedUsers(
        users: updatedUsers,
        hasMore: currentState.hasMore,
        currentPage: currentState.currentPage,
        pageSize: currentState.pageSize,
      ));

      // Toggle the status on RouterOS
      try {
        await client.toggleUserStatus(
          id,
          !isCurrentlyDisabled,
        );

        // Auto-kick: If we are disabling the user, remove their active session
        if (!isCurrentlyDisabled && currentUser['name'] != null) {
          try {
            await client.logoutUserByName(currentUser['name'].toString());
          } catch (e) {
            debugPrint('Failed to auto-kick user ${currentUser['name']}: $e');
          }
        }
      } catch (e) {
        // Revert UI change on error
        state = AsyncValue.data(currentState);
        rethrow;
      }

      // Refresh in background to ensure data is accurate
      silentRefresh();
    } else {
      // Fallback if no current state
      final allUsers = await client.getHotspotUsers();
      final currentUser =
          allUsers.firstWhere((u) => u['.id'] == id, orElse: () => {});
      final isCurrentlyDisabled =
          currentUser['disabled'] == 'true' || currentUser['disabled'] == 'yes';

      await client.toggleUserStatus(
        id,
        !isCurrentlyDisabled,
      );

      ref.invalidate(hotspotUsersProvider);
    }

    ref.invalidate(hotspotActiveUsersProvider);
  }
}

// System Resources Provider
final systemResourcesProvider =
    AsyncNotifierProvider<SystemResourcesNotifier, Map<String, dynamic>>(() {
  return SystemResourcesNotifier();
});

class SystemResourcesNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    ref.keepAlive();

    final service = ref.read(routerOSServiceProvider);
    final cache = ref.read(cacheServiceProvider);

    // Try cache first
    final cachedResources = cache.getSystemResources();
    if (cachedResources != null) {
      return cachedResources;
    }

    // No cache, fetch from API
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    final resources = await client.getSystemResources();
    await cache.saveSystemResources(resources);
    return resources;
  }

  Future<void> refresh() async {
    final cache = ref.read(cacheServiceProvider);
    await cache.clearEntry('system_resources');
    ref.invalidate(systemResourcesProvider);
  }
}

// Resource History Provider - persists across navigation for seamless charts
final resourceHistoryProvider =
    ChangeNotifierProvider<ResourceHistoryNotifier>((ref) {
  return ResourceHistoryNotifier();
});

// Hotspot Active Users Provider
final hotspotActiveUsersProvider =
    AsyncNotifierProvider<HotspotActiveUsersNotifier, PaginatedUsers>(() {
  return HotspotActiveUsersNotifier();
});

class HotspotActiveUsersNotifier extends AsyncNotifier<PaginatedUsers> {
  int _currentPage = 1;
  final int _pageSize = 15;

  @override
  Future<PaginatedUsers> build() async {
    _currentPage = 1;

    // Try to load from cache first for instant display
    final cache = ref.read(cacheServiceProvider);
    final cachedUsers = cache.getHotspotUsers();

    // If we have cached data, return it immediately and refresh in background
    if (cachedUsers != null && cachedUsers.isNotEmpty) {
      // Filter only active users from cache (users with 'active' in their data)
      final activeUsers = cachedUsers
          .where((u) => u['disabled'] != 'true' || !u.containsKey('disabled'))
          .toList();

      final cachedData = _paginateActiveUsers(activeUsers, page: 1);

      // Refresh in background
      Future.microtask(() => refresh());

      return cachedData;
    }

    // No cache - fetch from API
    return await _loadActiveUsers(page: 1);
  }

  PaginatedUsers _paginateActiveUsers(List<Map<String, dynamic>> allUsers,
      {required int page}) {
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final hasMore = endIndex < allUsers.length;
    final users = allUsers.skip(startIndex).take(_pageSize).toList();

    return PaginatedUsers(
      users: users,
      hasMore: hasMore,
      currentPage: page,
      pageSize: _pageSize,
    );
  }

  Future<PaginatedUsers> _loadActiveUsers({required int page}) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    final allActiveUsers = await client.getHotspotActiveUsers();
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final hasMore = endIndex < allActiveUsers.length;
    final users = allActiveUsers.skip(startIndex).take(_pageSize).toList();

    return PaginatedUsers(
      users: users,
      hasMore: hasMore,
      currentPage: page,
      pageSize: _pageSize,
    );
  }

  Future<void> refresh() async {
    return refreshLock.synchronizedRefresh('hotspotActiveUsers', () async {
      _currentPage = 1;
      state = const AsyncValue.loading();
      state = AsyncValue.data(await _loadActiveUsers(page: 1));
    });
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    _currentPage++;
    final nextPageData = await _loadActiveUsers(page: _currentPage);

    state = AsyncValue.data(PaginatedUsers(
      users: [...currentState.users, ...nextPageData.users],
      hasMore: nextPageData.hasMore,
      currentPage: nextPageData.currentPage,
      pageSize: _pageSize,
    ));
  }

  Future<void> logoutUser(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.logoutUser(id);
    ref.invalidate(hotspotActiveUsersProvider);
  }
}

// User Profiles Provider
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, List<UserProfile>>(() {
  return UserProfileNotifier();
});

// Interface Traffic Provider
final interfaceTrafficProvider =
    AsyncNotifierProvider<InterfaceTrafficNotifier, List<InterfaceTraffic>>(() {
  return InterfaceTrafficNotifier();
});

class UserProfileNotifier extends AsyncNotifier<List<UserProfile>> {
  // System profiles to filter out (only trial, keep default visible per user request)
  static const Set<String> _systemProfileNames = {'trial'};

  bool _isProfileData(Map<String, dynamic> data) {
    // User profiles from /ip/hotspot/user/profile/print
    // Profiles typically have profile-specific fields like shared-users, rate-limit, session-timeout
    // Users from /ip/hotspot/user/print have password field
    final hasPassword = data.containsKey('password');
    final hasSharedUsers = data.containsKey('shared-users');
    final hasRateLimit = data.containsKey('rate-limit');
    final hasSessionTimeout = data.containsKey('session-timeout');

    // If it has password, it's definitely a user
    if (hasPassword) return false;

    // If it has any profile-specific field, it's a profile
    if (hasSharedUsers || hasRateLimit || hasSessionTimeout) return true;

    // If no clear indicators, check the name pattern
    final name = data['name']?.toString().toLowerCase() ?? '';
    // System profiles like trial, default should be filtered out elsewhere
    return name.isNotEmpty;
  }

  @override
  Future<List<UserProfile>> build() async {
    // Try to load from cache first for instant display
    final cache = ref.read(cacheServiceProvider);
    final cachedProfiles = cache.getUserProfiles();

    // If we have cached data, show it immediately and refresh in background
    if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
      final filteredProfiles = cachedProfiles
          .where((p) => !_systemProfileNames
              .contains(p['name']?.toString().toLowerCase()))
          .where((p) => _isProfileData(p))
          .map((data) => UserProfile.fromJson(data))
          .toList();

      // Refresh in background
      refresh();

      return filteredProfiles;
    }

    // No cache - fetch from API
    final profiles = await _fetchProfilesAndCache();
    return profiles;
  }

  Future<List<UserProfile>> _fetchProfilesAndCache() async {
    final service = ref.read(routerOSServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    final client = service.client;
    if (client == null) {
      return [];
    }

    try {
      var profilesData = await client.getHotspotProfiles().timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );

      // Filter out system profiles AND any user data that leaked in
      profilesData = profilesData
          .where((p) => !_systemProfileNames
              .contains(p['name']?.toString().toLowerCase()))
          .where((p) => _isProfileData(p))
          .toList();

      final localPrices = cache.getProfilePrices();
      final List<UserProfile> profiles = [];
      
      for (var data in profilesData) {
        var profile = UserProfile.fromJson(data);
        
        // If price is missing from MikroTik, check local persistent map
        if ((profile.price == null || profile.price == 0) && 
            localPrices.containsKey(profile.name)) {
          profile = profile.copyWith(price: localPrices[profile.name]);
        }
        
        profiles.add(profile);
      }

      // Cache the profiles
      await cache.saveUserProfiles(profilesData);

      return profiles;
    } catch (e) {
      return [];
    }
  }

  Future<void> refresh() async {
    await silentRefresh();
  }

  Future<void> silentRefresh() async {
    try {
      // Clear cache to force re-parsing with updated logic
      final cache = ref.read(cacheServiceProvider);
      await cache.clearEntry('user_profiles');
      
      final newData = await _fetchProfilesAndCache();
      if (newData.isNotEmpty) {
        state = AsyncValue.data(newData);
      }
    } catch (_) {}
  }

  Future<void> addProfile(UserProfile profile) async {
    final service = ref.read(routerOSServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Build rate-limit string from upload/download
    final rateLimit = (profile.rateLimitUpload == null ||
                profile.rateLimitUpload == 'unlimited') &&
            (profile.rateLimitDownload == null ||
                profile.rateLimitDownload == 'unlimited')
        ? null
        : '${profile.rateLimitUpload ?? 'unlimited'}/${profile.rateLimitDownload ?? 'unlimited'}';

    String? onLoginScript;
    try {
      if (profile.validity != null &&
          profile.validity!.toLowerCase() != 'unlimited' &&
          profile.validity!.isNotEmpty) {
          onLoginScript = OnLoginScriptGenerator.generate(
            profile.validity!,
            price: profile.price,
          );
        }
    } catch (e) {
      // Skip on-login script if generation fails
    }

    // Format comment with price for Mikhmon compatibility
    final comment = profile.price != null 
        ? '${profile.validity ?? "unlimited"}/${profile.price!.toInt()}'
        : null;

    final profileData = {
      'name': profile.name,
      if (rateLimit != null) 'rate-limit': rateLimit,
      if (onLoginScript != null) 'on-login': onLoginScript,
      if (comment != null) 'comment': comment,
      if (profile.sharedUsers != null) 'shared-users': profile.sharedUsers,
    };

    debugPrint('addProfile sending: $profileData');

    try {
      // Save price to local persistent cache first
      if (profile.price != null && profile.price! > 0) {
        await cache.saveProfilePrice(profile.name, profile.price!);
      }
      
      await client.addProfile(profileData);
      debugPrint('addProfile success');
    } catch (e) {
      debugPrint('addProfile error: $e');
      rethrow;
    }

    silentRefresh();
  }

  Future<void> updateProfile(UserProfile oldProfile, UserProfile updatedProfile) async {
    final service = ref.read(routerOSServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Save price to local persistent cache first
    if (updatedProfile.price != null && updatedProfile.price! > 0) {
      await cache.saveProfilePrice(updatedProfile.name, updatedProfile.price!);
    }

    // Build rate-limit string from upload/download
    final rateLimit = (updatedProfile.rateLimitUpload == null ||
                updatedProfile.rateLimitUpload == 'unlimited') &&
            (updatedProfile.rateLimitDownload == null ||
                updatedProfile.rateLimitDownload == 'unlimited')
        ? null
        : '${updatedProfile.rateLimitUpload ?? 'unlimited'}/${updatedProfile.rateLimitDownload ?? 'unlimited'}';

    String? onLoginScript;
    try {
      if (updatedProfile.validity != null &&
          updatedProfile.validity!.toLowerCase() != 'unlimited' &&
          updatedProfile.validity!.isNotEmpty) {
          onLoginScript = OnLoginScriptGenerator.generate(
            updatedProfile.validity!,
            price: updatedProfile.price,
          );
        }
    } catch (e) {}

    // Format comment with price for Mikhmon compatibility
    final comment = updatedProfile.price != null 
        ? '${updatedProfile.validity ?? "unlimited"}/${updatedProfile.price!.toInt()}'
        : null;

    await client.updateProfile(updatedProfile.id, {
      'name': updatedProfile.name,
      if (rateLimit != null) 'rate-limit': rateLimit,
      if (onLoginScript != null) 'on-login': onLoginScript,
      if (comment != null) 'comment': comment,
      if (updatedProfile.sharedUsers != null) 'shared-users': updatedProfile.sharedUsers,
    });

    await silentRefresh();
  }

  Future<void> deleteProfile(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.deleteProfile(id);

    await silentRefresh();
  }
}

// Provider for getting disabled hotspot usernames from MikroTik
final disabledHotspotUsersProvider = FutureProvider<Set<String>>((ref) async {
  try {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) return {};
    final users = await client.getHotspotUsers();
    return users
        .where((u) => u['disabled'] == 'true')
        .map((u) => u['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();
  } catch (e) {
    return {};
  }
});

// Vouchers Provider
final vouchersProvider =
    AsyncNotifierProvider<VouchersNotifier, List<Voucher>>(() {
  return VouchersNotifier();
});

class VouchersNotifier extends AsyncNotifier<List<Voucher>> {
  Timer? _refreshTimer;

  @override
  Future<List<Voucher>> build() async {
    ref.onDispose(() => _refreshTimer?.cancel());

    // Start auto-refresh for expired status
    _startAutoRefresh();
    
    final cache = ref.read(cacheServiceProvider);

    // Try to get cached vouchers first
    final cachedVouchers = cache.getVouchers();
    if (cachedVouchers != null && cachedVouchers.isNotEmpty) {
      // Get disabled users from MikroTik
      final disabledUsers = await ref.read(disabledHotspotUsersProvider.future);
      
      // Convert to Voucher with disabled status
      return cachedVouchers.map((data) {
        final username = data['username'] as String? ?? '';
        final v = Voucher.fromJson(data);
        // Return voucher with disabled status from MikroTik
        return Voucher(
          username: v.username,
          password: v.password,
          profile: v.profile,
          validity: v.validity,
          dataLimit: v.dataLimit,
          comment: v.comment,
          createdAt: v.createdAt,
          firstUsedAt: v.firstUsedAt,
          remainingSeconds: v.remainingSeconds,
          sessionStartedAt: v.sessionStartedAt,
          price: v.price,
          disabled: disabledUsers.contains(username),
        );
      }).toList();
    }

    // No cache, return empty list
    return [];
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (ref.read(routerOSServiceProvider).isConnected) {
        refresh();
      }
    });
  }

  /// Add new vouchers to cache and update state
  Future<void> addVouchers(List<Voucher> newVouchers) async {
    final cache = ref.read(cacheServiceProvider);
    final vouchersJson = newVouchers.map((v) => v.toJson()).toList();
    await cache.addVouchers(vouchersJson);

    // Refresh state from cache
    await refresh();
  }

  /// Delete a voucher by username
  Future<void> deleteVoucher(String username) async {
    final cache = ref.read(cacheServiceProvider);
    await cache.deleteVoucher(username);

    // Also delete from MikroTik router
    try {
      final service = ref.read(routerOSServiceProvider);
      if (service.isConnected && service.client != null) {
        await service.client!.deleteUserByName(username);
        // We should also remove their active session if they are logged in
        await service.client!.logoutUserByName(username);
      }
    } catch (e) {
      debugPrint('Failed to delete user $username from router: $e');
    }

    // Refresh state from cache
    await refresh();
  }

  /// Delete multiple vouchers by usernames (for bulk delete)
  Future<void> deleteVouchers(List<String> usernames) async {
    final cache = ref.read(cacheServiceProvider);
    final service = ref.read(routerOSServiceProvider);
    final bool connected = service.isConnected && service.client != null;

    for (final username in usernames) {
      await cache.deleteVoucher(username);
      
      if (connected) {
        try {
          await service.client!.deleteUserByName(username);
          await service.client!.logoutUserByName(username);
        } catch (e) {
          debugPrint('Failed to delete user $username from router: $e');
        }
      }
    }

    // Refresh state from cache
    await refresh();
  }

  /// Expire vouchers when hotspot user is deleted
  Future<void> expireVoucher(String username) async {
    // Delete the voucher when the user is deleted
    await deleteVoucher(username);
  }

  /// Expire multiple vouchers when hotspot users are deleted
  Future<void> expireVouchers(List<String> usernames) async {
    await deleteVouchers(usernames);
  }

  /// Clear all vouchers
  Future<void> clearVouchers() async {
    final cache = ref.read(cacheServiceProvider);
    await cache.clearVouchers();

    // Update state to empty list
    state = const AsyncValue.data([]);
  }

  /// Refresh vouchers from cache
  Future<void> refresh() async {
    return refreshLock.synchronizedRefresh('vouchers', () async {
      try {
        final cache = ref.read(cacheServiceProvider);
        final cachedVouchers = cache.getVouchers();

        if (cachedVouchers != null) {
          state = AsyncValue.data(
              cachedVouchers.map((data) => Voucher.fromJson(data)).toList());
        } else {
          state = const AsyncValue.data([]);
        }
      } catch (e) {
        // Refresh failed silently
      }
    });
  }

  /// Sort vouchers by specified criteria
  void sortVouchers(VoucherSort sort) {
    final currentVouchers = state.valueOrNull ?? [];
    if (currentVouchers.isEmpty) return;

    List<Voucher> sorted = List.from(currentVouchers);

    switch (sort) {
      case VoucherSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case VoucherSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case VoucherSort.az:
        sorted.sort((a, b) =>
            a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        break;
    }

    state = AsyncValue.data(sorted);
  }
}

// Income/Transactions Provider
final incomeProvider = AsyncNotifierProvider<IncomeNotifier, IncomeState>(() {
  return IncomeNotifier();
});

class IncomeState {
  final List<SalesTransaction> transactions;
  final IncomeSummary summary;
  final List<SalesChartPoint> chartPoints;
  final String filter; // '7days', '30days', 'all'

  const IncomeState({
    this.transactions = const [],
    required this.summary,
    this.chartPoints = const [],
    this.filter = '30days',
  });

  IncomeState copyWith({
    List<SalesTransaction>? transactions,
    IncomeSummary? summary,
    List<SalesChartPoint>? chartPoints,
    String? filter,
  }) {
    return IncomeState(
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      chartPoints: chartPoints ?? this.chartPoints,
      filter: filter ?? this.filter,
    );
  }
}

class SalesChartPoint {
  final DateTime date;
  final double amount;

  SalesChartPoint({required this.date, required this.amount});
}

class IncomeNotifier extends AsyncNotifier<IncomeState> {
  @override
  Future<IncomeState> build() async {
    final cache = ref.read(cacheServiceProvider);
    
    // Load all historical transactions from cache
    final cachedData = cache.getSalesTransactions() ?? [];
    final transactions = cachedData
        .map((t) => SalesTransaction.fromJson(t))
        .toList();
    
    // Sort transactions by timestamp (newest first)
    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Try to sync with router in background to capture new activations
    _syncWithRouter(transactions);

    return _calculateState(transactions, '30days');
  }

  Future<void> _syncWithRouter(List<SalesTransaction> existingTransactions) async {
    try {
      // Force a fresh refresh of hotspot users to see the latest comments
      ref.invalidate(hotspotUsersProvider);
      final usersAsync = await ref.read(hotspotUsersProvider.future);
      
      final cache = ref.read(cacheServiceProvider);
      bool updated = false;

      for (final user in usersAsync.users) {
        final comment = user['comment'] as String? ?? '';
        
        // Look for our specific activation tag: aktif-PRICE-DATE
        if (comment.startsWith('aktif-')) {
          final parts = comment.split('-');
          if (parts.length >= 3) {
            final price = double.tryParse(parts[1]) ?? 0.0;
            final username = user['name'] as String? ?? '';
            
            // Check if we already recorded this specific activation
            // Using username + exact comment as a unique key
            final alreadyRecorded = existingTransactions.any((t) => 
              t.username == username && t.comment == comment);
              
            if (!alreadyRecorded && price > 0) {
              final transaction = SalesTransaction(
                id: 'sync_${username}_${DateTime.now().millisecondsSinceEpoch}',
                username: username,
                profile: user['profile'] as String? ?? 'default',
                price: price,
                timestamp: DateTime.now(),
                comment: comment,
              );
              
              await cache.saveSalesTransaction(transaction.toJson());
              updated = true;
            }
          }
        }
      }

      if (updated) {
        // Refresh local state if new transactions were added
        ref.invalidateSelf();
      }
    } catch (e) {
      debugPrint('Revenue sync failed: $e');
    }
  }

  Future<void> setFilter(String filter) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    
    state = AsyncValue.data(_calculateState(currentState.transactions, filter));
  }

  IncomeState _calculateState(List<SalesTransaction> transactions, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfMonth = DateTime(now.year, now.month, 1);

    // Filter for summary calculations (always show today/this month in summary)
    final todayTransactions = transactions.where((t) => 
      t.timestamp.isAfter(today) || t.timestamp.isAtSameMomentAs(today)).toList();
    
    final monthTransactions = transactions.where((t) => 
      t.timestamp.isAfter(firstOfMonth) || t.timestamp.isAtSameMomentAs(firstOfMonth)).toList();

    final todayIncome = todayTransactions.fold(0.0, (sum, t) => sum + t.price);
    final monthIncome = monthTransactions.fold(0.0, (sum, t) => sum + t.price);

    final summary = IncomeSummary(
      todayIncome: todayIncome,
      thisMonthIncome: monthIncome,
      transactionsToday: todayTransactions.length,
      transactionsThisMonth: monthTransactions.length,
    );

    // Calculate chart points (daily income for the last N days)
    final int daysToCalculate = filter == '7days' ? 7 : 30;
    final List<SalesChartPoint> points = [];
    
    for (int i = daysToCalculate - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));
      
      final dailyTotal = transactions
          .where((t) => t.timestamp.isAfter(date.subtract(const Duration(milliseconds: 1))) && t.timestamp.isBefore(nextDate))
          .fold(0.0, (sum, t) => sum + t.price);
          
      points.add(SalesChartPoint(date: date, amount: dailyTotal));
    }

    return IncomeState(
      transactions: transactions,
      summary: summary,
      chartPoints: points,
      filter: filter,
    );
  }

  Future<void> recordSale({
    required String username,
    required String profile,
    required double price,
    String? comment,
  }) async {
    final cache = ref.read(cacheServiceProvider);

    final transaction = SalesTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      profile: profile,
      price: price,
      timestamp: DateTime.now(),
      comment: comment,
    );

    // Save to cache
    await cache.saveSalesTransaction(transaction.toJson());

    // Refresh state
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// Interface Traffic Provider
final savedConnectionsProvider =
    AsyncNotifierProvider<SavedConnectionsNotifier, List<RouterConnection>>(() {
  return SavedConnectionsNotifier();
});

class SavedConnectionsNotifier extends AsyncNotifier<List<RouterConnection>> {
  @override
  Future<List<RouterConnection>> build() async {
    final cache = ref.read(cacheServiceProvider);
    final cachedConnections = cache.getSavedConnections();

    if (cachedConnections != null) {
      return cachedConnections
          .map((c) => RouterConnection.fromJson(c))
          .toList();
    }

    return [];
  }

  Future<void> addConnection({
    required String name,
    required String host,
    required String port,
    required String username,
  }) async {
    final cache = ref.read(cacheServiceProvider);

    final connection = RouterConnection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      host: host,
      port: port,
      username: username,
    );

    await cache.addSavedConnection(connection.toJson());

    // Refresh state by rebuilding
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> updateConnection(RouterConnection connection) async {
    final cache = ref.read(cacheServiceProvider);
    await cache.updateSavedConnection(connection.id, connection.toJson());

    // Refresh state by rebuilding
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> deleteConnection(String id) async {
    final cache = ref.read(cacheServiceProvider);
    await cache.deleteSavedConnection(id);

    // Refresh state by rebuilding
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// Interface Traffic Notifier
// Traffic rate service for calculating real-time rates
final _trafficRateService = TrafficRateService();

class InterfaceTrafficNotifier extends AsyncNotifier<List<InterfaceTraffic>> {
  @override
  Future<List<InterfaceTraffic>> build() async {
    // Keep the provider alive even when no listeners are attached
    ref.keepAlive();

    final service = ref.read(routerOSServiceProvider);

    // Check cache first for instant display (seamless UX)
    final cache = ref.read(cacheServiceProvider);
    final cachedTraffic = cache.getInterfaceTraffic();

    if (cachedTraffic != null && cachedTraffic.isNotEmpty) {
      // Convert cached maps back to InterfaceTraffic objects
      return cachedTraffic
          .map((data) => InterfaceTraffic.fromJson(data))
          .toList();
    }

    // No cache, fetch from API
    final client = service.client;
    if (client == null) {
      return [];
    }

    final interfacesData = await client.getInterfaceStats();
    final interfaces = interfacesData.map((data) {
      return InterfaceTraffic.fromJson(data);
    }).toList();

    // Calculate rates using historical data
    final result = _trafficRateService.calculateRates(interfaces);

    // Save to cache
    await cache.saveInterfaceTraffic(result.map((e) => e.toJson()).toList());

    return result;
  }

  Future<void> refresh() async {
    // Don't show loading - just refresh in background
    await silentRefresh();
  }

  /// Silent refresh - updates data without showing loading state
  Future<void> silentRefresh() async {
    final service = ref.read(routerOSServiceProvider);

    try {
      final client = service.client;
      if (client == null) {
        return;
      }

      final interfacesData = await client.getInterfaceStats();
      final interfaces = interfacesData.map((data) {
        return InterfaceTraffic.fromJson(data);
      }).toList();

      // Calculate rates using historical data
      final newData = _trafficRateService.calculateRates(interfaces);

      // Save to cache
      final cache = ref.read(cacheServiceProvider);
      await cache.saveInterfaceTraffic(newData.map((e) => e.toJson()).toList());

      // Update state directly without loading
      state = AsyncValue.data(newData);
    } catch (e) {
      // Silent fail - don't show error on auto-refresh
    }
  }
}

// Hotspot Hosts Provider
final hotspotHostsProvider =
    AsyncNotifierProvider<HotspotHostsNotifier, List<HotspotHost>>(() {
  return HotspotHostsNotifier();
});

class HotspotHostsNotifier extends AsyncNotifier<List<HotspotHost>> {
  bool _timerStarted = false;
  Timer? _refreshTimer;

  @override
  Future<List<HotspotHost>> build() async {
    ref.onDispose(() => _refreshTimer?.cancel());
    final hosts = await _fetchHosts();
    _startAutoRefresh();
    return hosts;
  }

  Future<List<HotspotHost>> _fetchHosts() async {
    final service = ref.read(routerOSServiceProvider);

    final client = service.client;
    if (client == null) {
      return [];
    }

    try {
      final hostsData = await client.getHotspotHosts();
      return hostsData.map((data) => HotspotHost.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  void _startAutoRefresh() {
    if (_timerStarted) return;
    _timerStarted = true;
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      refresh();
    });
  }

  Future<void> refresh() async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHosts());
  }
}

// DHCP Leases Provider
final dhcpLeasesProvider =
    AsyncNotifierProvider<DhcpLeasesNotifier, List<DhcpLease>>(() {
  return DhcpLeasesNotifier();
});

class DhcpLeasesNotifier extends AsyncNotifier<List<DhcpLease>> {
  bool _timerStarted = false;
  Timer? _refreshTimer;

  @override
  Future<List<DhcpLease>> build() async {
    ref.onDispose(() => _refreshTimer?.cancel());
    final leases = await _fetchLeases();
    _startAutoRefresh();
    return leases;
  }

  Future<List<DhcpLease>> _fetchLeases() async {
    final service = ref.read(routerOSServiceProvider);

    final client = service.client;
    if (client == null) {
      return [];
    }

    try {
      final leasesData = await client.getDhcpLeases();
      var leases = leasesData.map((data) => DhcpLease.fromJson(data)).toList();

      // Get hotspot hosts to get actual device names (OPPO, Samsung, etc)
      try {
        final hostsData = await client.getHotspotHosts();
        final macToDeviceName = <String, String>{};

        for (final host in hostsData) {
          final mac = host['mac-address'] as String? ?? '';
          final deviceName =
              host['device'] as String? ?? host['host-name'] as String? ?? '';
          if (mac.isNotEmpty && deviceName.isNotEmpty) {
            macToDeviceName[mac.toUpperCase()] = deviceName;
          }
        }

        // Update leases with device name from hotspot hosts
        if (macToDeviceName.isNotEmpty) {
          leases = leases.map((lease) {
            if (lease.macAddress != null) {
              final macKey = lease.macAddress!.toUpperCase();
              if (macToDeviceName.containsKey(macKey)) {
                return DhcpLease(
                  id: lease.id,
                  address: lease.address,
                  macAddress: lease.macAddress,
                  hostname: macToDeviceName[macKey],
                  status: lease.status,
                  server: lease.server,
                  isDynamic: lease.isDynamic,
                  comment: lease.comment,
                  expiresAt: lease.expiresAt,
                  bytesIn: lease.bytesIn,
                  bytesOut: lease.bytesOut,
                );
              }
            }
            return lease;
          }).toList();
        }
      } catch (e) {
        // If getting hotspot hosts fails, continue with DHCP leases only
      }

      // Also try to match with active hotspot users for username display
      leases = await _matchWithActiveUsers(leases);

      return leases;
    } catch (e) {
      return [];
    }
  }

  Future<List<DhcpLease>> _matchWithActiveUsers(List<DhcpLease> leases) async {
    try {
      // Get active hotspot users to match by IP
      final activeUsersAsync = ref.read(hotspotActiveUsersProvider);
      final activeUsers = activeUsersAsync.valueOrNull;

      if (activeUsers == null || activeUsers.users.isEmpty) {
        return leases;
      }

      // Build a map of IP -> username from raw Map data
      final ipToUsername = <String, String>{};
      for (final userMap in activeUsers.users) {
        final address = userMap['address'] as String? ?? '';
        final username = userMap['user'] as String? ?? '';
        if (address.isNotEmpty && username.isNotEmpty) {
          ipToUsername[address] = username;
        }
      }

      // Update leases with hotspot username if matched
      return leases.map((lease) {
        if (lease.address != null && ipToUsername.containsKey(lease.address)) {
          return DhcpLease(
            id: lease.id,
            address: lease.address,
            macAddress: lease.macAddress,
            hostname: ipToUsername[lease.address],
            status: lease.status,
            server: lease.server,
            isDynamic: lease.isDynamic,
            comment: lease.comment,
            expiresAt: lease.expiresAt,
            bytesIn: lease.bytesIn,
            bytesOut: lease.bytesOut,
          );
        }
        return lease;
      }).toList();
    } catch (e) {
      return leases;
    }
  }

  void _startAutoRefresh() {
    if (_timerStarted) return;
    _timerStarted = true;
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      silentRefresh();
    });
  }

  Future<void> silentRefresh() async {
    return refreshLock.synchronizedRefresh('dhcpLeases', () async {
      try {
        final leases = await _fetchLeases();
        state = AsyncValue.data(leases);
      } catch (e) {
        // Silent refresh failed
      }
    });
  }
}
