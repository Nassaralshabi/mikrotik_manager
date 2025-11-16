import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

enum TimeRange { all, today, week, month, custom }
enum CardStatusFilter { all, active, disabled, expired, withSessions }

// Data classes for isolate communication
class StatisticsData {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> sessions;
  final TimeRange timeRange;
  final CardStatusFilter statusFilter;
  final String? selectedProfile;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  StatisticsData({
    required this.users,
    required this.sessions,
    required this.timeRange,
    required this.statusFilter,
    this.selectedProfile,
    this.customStartDate,
    this.customEndDate,
  });
}

class StatisticsResult {
  final int totalCards;
  final int activeCards;
  final int disabledCards;
  final int expiredCards;
  final int cardsWithSessions;
  final int totalSessions;
  final double totalUploadGB;
  final double totalDownloadGB;
  final Map<String, int> cardsByProfile;
  final List<Map<String, dynamic>> filteredUsers;

  StatisticsResult({
    required this.totalCards,
    required this.activeCards,
    required this.disabledCards,
    required this.expiredCards,
    required this.cardsWithSessions,
    required this.totalSessions,
    required this.totalUploadGB,
    required this.totalDownloadGB,
    required this.cardsByProfile,
    required this.filteredUsers,
  });
}

class CardsStatisticsOptimizedScreen extends StatefulWidget {
  const CardsStatisticsOptimizedScreen({super.key});

  @override
  State<CardsStatisticsOptimizedScreen> createState() => _CardsStatisticsOptimizedScreenState();
}

class _CardsStatisticsOptimizedScreenState extends State<CardsStatisticsOptimizedScreen> 
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  
  // Statistics data
  int _totalCards = 0;
  int _activeCards = 0;
  int _disabledCards = 0;
  int _expiredCards = 0;
  int _cardsWithSessions = 0;
  int _totalSessions = 0;
  double _totalUploadGB = 0.0;
  double _totalDownloadGB = 0.0;
  Map<String, int> _cardsByProfile = {};
  
  // Filter states
  TimeRange _selectedRange = TimeRange.all;
  CardStatusFilter _statusFilter = CardStatusFilter.all;
  String? _selectedProfile;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  // Raw data - cached longer
  List<Map<String, dynamic>> _usersRaw = [];
  List<Map<String, dynamic>> _sessionsRaw = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  
  // Enhanced caching with separate timestamps
  DateTime? _lastUsersFetchTime;
  DateTime? _lastSessionsFetchTime;
  static const _usersCacheDuration = Duration(minutes: 10); // Longer cache for users
  static const _sessionsCacheDuration = Duration(minutes: 2); // Shorter for active sessions
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showFilters = false;
  
  // Progressive loading states
  bool _usersLoaded = false;
  bool _sessionsLoaded = false;
  
  // Isolate for heavy computations
  Isolate? _computeIsolate;
  ReceivePort? _receivePort;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _computeIsolate?.kill();
    _receivePort?.close();
    super.dispose();
  }

  Future<void> _fetchStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _usersLoaded = false;
      _sessionsLoaded = false;
    });

    try {
      // Fetch users and sessions concurrently with smart caching
      final futures = <Future>[];
      
      // Users - cache for longer period
      if (_shouldFetchUsers()) {
        futures.add(_fetchUsers());
      } else {
        setState(() => _usersLoaded = true);
      }
      
      // Sessions - cache for shorter period (more dynamic)
      if (_shouldFetchSessions()) {
        futures.add(_fetchSessions());
      } else {
        setState(() => _sessionsLoaded = true);
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      
      // Process data in isolate
      await _processDataInIsolate();
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'فشل تحميل الإحصائيات: ${e.toString()}';
        });
      }
    }
  }

  bool _shouldFetchUsers() {
    return _lastUsersFetchTime == null || 
           DateTime.now().difference(_lastUsersFetchTime!) > _usersCacheDuration ||
           _usersRaw.isEmpty;
  }

  bool _shouldFetchSessions() {
    return _lastSessionsFetchTime == null || 
           DateTime.now().difference(_lastSessionsFetchTime!) > _sessionsCacheDuration ||
           _sessionsRaw.isEmpty;
  }

  Future<void> _fetchUsers() async {
    final client = await MikrotikConnector.connect();
    try {
      final response = await client.talk(['/tool/user-manager/user/print'])
          .timeout(const Duration(seconds: 15));
      
      _usersRaw = response.map((e) => Map<String, dynamic>.from(e)).toList();
      _lastUsersFetchTime = DateTime.now();
      
      if (mounted) {
        setState(() => _usersLoaded = true);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _fetchSessions() async {
    final client = await MikrotikConnector.connect();
    try {
      final response = await client.talk(['/tool/user-manager/session/print'])
          .timeout(const Duration(seconds: 10));
      
      _sessionsRaw = response.map((e) => Map<String, dynamic>.from(e)).toList();
      _lastSessionsFetchTime = DateTime.now();
      
      if (mounted) {
        setState(() => _sessionsLoaded = true);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _processDataInIsolate() async {
    if (!_usersLoaded || !_sessionsLoaded) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Prepare data for isolate
      final data = StatisticsData(
        users: _usersRaw,
        sessions: _sessionsRaw,
        timeRange: _selectedRange,
        statusFilter: _statusFilter,
        selectedProfile: _selectedProfile,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
      );
      
      // Process in isolate (or fallback to compute if isolate fails)
      final result = await compute(_processStatisticsData, data);
      
      // Update UI with results
      if (mounted) {
        setState(() {
          _totalCards = result.totalCards;
          _activeCards = result.activeCards;
          _disabledCards = result.disabledCards;
          _expiredCards = result.expiredCards;
          _cardsWithSessions = result.cardsWithSessions;
          _totalSessions = result.totalSessions;
          _totalUploadGB = result.totalUploadGB;
          _totalDownloadGB = result.totalDownloadGB;
          _cardsByProfile = result.cardsByProfile;
          _filteredUsers = result.filteredUsers;
          
          _isLoading = false;
          _isProcessing = false;
        });
        
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
          _errorMessage = 'فشل معالجة البيانات: ${e.toString()}';
        });
      }
    }
  }

  // Static method for isolate processing
  static StatisticsResult _processStatisticsData(StatisticsData data) {
    // Apply filters
    List<Map<String, dynamic>> filteredUsers = List.from(data.users);
    
    // Date range filtering
    DateTime? startDate;
    DateTime? endDate = DateTime.now();
    
    switch (data.timeRange) {
      case TimeRange.today:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case TimeRange.week:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case TimeRange.month:
        startDate = endDate.subtract(const Duration(days: 30));
        break;
      case TimeRange.custom:
        startDate = data.customStartDate;
        endDate = data.customEndDate ?? DateTime.now();
        break;
      case TimeRange.all:
        startDate = null;
        break;
    }

    // Status filtering with optimized operations
    if (data.statusFilter != CardStatusFilter.all) {
      final Set<String> usersWithSessions = data.sessions
          .map((s) => s['user'] as String?)
          .where((user) => user != null)
          .cast<String>()
          .toSet();
      
      filteredUsers = filteredUsers.where((user) {
        switch (data.statusFilter) {
          case CardStatusFilter.active:
            return user['disabled'] != 'true';
          case CardStatusFilter.disabled:
            return user['disabled'] == 'true';
          case CardStatusFilter.expired:
            return _isCardExpired(user);
          case CardStatusFilter.withSessions:
            return usersWithSessions.contains(user['username']);
          case CardStatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Profile filtering
    if (data.selectedProfile != null && data.selectedProfile!.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        return user['actual-profile'] == data.selectedProfile;
      }).toList();
    }

    // Calculate statistics with optimizations
    int totalCards = filteredUsers.length;
    int activeCards = 0;
    int disabledCards = 0;
    int expiredCards = 0;
    Map<String, int> cardsByProfile = <String, int>{};
    
    double allTimeUploadBytes = 0.0;
    double allTimeDownloadBytes = 0.0;

    // Single pass through filtered users
    for (final user in filteredUsers) {
      // Status counts
      final disabled = user['disabled'] == 'true';
      if (disabled) {
        disabledCards++;
      } else {
        activeCards++;
      }
      
      if (_isCardExpired(user)) {
        expiredCards++;
      }

      // Data usage
      final uploadUsed = double.tryParse(user['upload-used']?.toString() ?? '0') ?? 0.0;
      final downloadUsed = double.tryParse(user['download-used']?.toString() ?? '0') ?? 0.0;
      allTimeUploadBytes += uploadUsed;
      allTimeDownloadBytes += downloadUsed;

      // Profile distribution
      final profile = user['actual-profile']?.toString() ?? 'غير محدد';
      cardsByProfile[profile] = (cardsByProfile[profile] ?? 0) + 1;
    }

    // Session processing
    List<Map<String, dynamic>> filteredSessions = data.sessions;
    
    if (startDate != null) {
      filteredSessions = filteredSessions.where((s) {
        final DateTime? st = _inferSessionStartTime(s);
        if (st == null) return false;
        return st.isAfter(startDate!) && st.isBefore(endDate!);
      }).toList();
    }
    
    // Filter sessions by filtered users
    final filteredUsernames = filteredUsers
        .map((u) => u['username'] as String?)
        .where((username) => username != null)
        .cast<String>()
        .toSet();
    
    filteredSessions = filteredSessions
        .where((s) => filteredUsernames.contains(s['user']))
        .toList();

    final Set<String> usersWithSessions = <String>{};
    double periodUploadBytes = 0.0;
    double periodDownloadBytes = 0.0;

    for (final s in filteredSessions) {
      final u = s['user'];
      if (u != null) usersWithSessions.add(u);
      
      final su = double.tryParse(s['upload']?.toString() ?? '0') ?? 0.0;
      final sd = double.tryParse(s['download']?.toString() ?? '0') ?? 0.0;
      periodUploadBytes += su;
      periodDownloadBytes += sd;
    }

    int cardsWithSessions = usersWithSessions.length;
    int totalSessions = filteredSessions.length;

    // Determine final upload/download values based on time range
    double totalUploadGB, totalDownloadGB;
    if (data.timeRange == TimeRange.all || startDate == null) {
      totalUploadGB = allTimeUploadBytes / (1024 * 1024 * 1024);
      totalDownloadGB = allTimeDownloadBytes / (1024 * 1024 * 1024);
    } else {
      totalUploadGB = periodUploadBytes / (1024 * 1024 * 1024);
      totalDownloadGB = periodDownloadBytes / (1024 * 1024 * 1024);
    }

    return StatisticsResult(
      totalCards: totalCards,
      activeCards: activeCards,
      disabledCards: disabledCards,
      expiredCards: expiredCards,
      cardsWithSessions: cardsWithSessions,
      totalSessions: totalSessions,
      totalUploadGB: totalUploadGB,
      totalDownloadGB: totalDownloadGB,
      cardsByProfile: cardsByProfile,
      filteredUsers: filteredUsers,
    );
  }

  static bool _isCardExpired(Map<String, dynamic> user) {
    final uptimeLimit = user['uptime-limit'];
    final uptimeUsed = user['uptime-used'];
    
    if (uptimeLimit == null || uptimeUsed == null) return false;
    
    try {
      final limitDuration = _parseRosDuration(uptimeLimit.toString());
      final usedDuration = _parseRosDuration(uptimeUsed.toString());
      
      return usedDuration.inSeconds >= limitDuration.inSeconds && limitDuration.inSeconds > 0;
    } catch (e) {
      return false;
    }
  }

  static DateTime? _inferSessionStartTime(Map<String, dynamic> session) {
    final uptimeStr = session['uptime'];
    if (uptimeStr is String && uptimeStr.isNotEmpty) {
      final d = _parseRosDuration(uptimeStr);
      return DateTime.now().subtract(d);
    }
    final st = session['start-time'];
    if (st is String && st.isNotEmpty) {
      try {
        return DateTime.parse(st);
      } catch (_) {}
    }
    return null;
  }

  static Duration _parseRosDuration(String s) {
    int weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0;
    String num = '';
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (RegExp(r'\d').hasMatch(ch)) {
        num += ch;
      } else {
        final v = int.tryParse(num) ?? 0;
        switch (ch) {
          case 'w': weeks = v; break;
          case 'd': days = v; break;
          case 'h': hours = v; break;
          case 'm': minutes = v; break;
          case 's': seconds = v; break;
        }
        num = '';
      }
    }
    return Duration(days: (weeks * 7) + days, hours: hours, minutes: minutes, seconds: seconds);
  }

  Future<void> _onFiltersChanged() async {
    if (_usersRaw.isNotEmpty && _sessionsRaw.isNotEmpty) {
      await _processDataInIsolate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('إحصائيات الكروت (محسن)', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'الفلاتر',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isProcessing ? null : _fetchStatistics,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingWidget(theme);
    }
    
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    
    return _buildMainContent(theme);
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            _isProcessing 
                ? 'جاري معالجة البيانات...' 
                : 'جاري تحميل الإحصائيات...',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          // Progress indicators
          if (_usersLoaded || _sessionsLoaded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _usersLoaded ? Icons.check_circle : Icons.hourglass_empty,
                  color: _usersLoaded ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'المستخدمين',
                  style: TextStyle(
                    fontSize: 12,
                    color: _usersLoaded ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  _sessionsLoaded ? Icons.check_circle : Icons.hourglass_empty,
                  color: _sessionsLoaded ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'الجلسات',
                  style: TextStyle(
                    fontSize: 12,
                    color: _sessionsLoaded ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.redAccent.withOpacity(0.8)),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _fetchStatistics,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _fetchStatistics,
        color: theme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick summary card at top
              _buildQuickSummaryCard(theme),
              const SizedBox(height: 16),
              
              if (_showFilters) ...[
                _buildFiltersSection(theme),
                const SizedBox(height: 20),
              ],
              
              // Main statistics content...
              Text(
                'إجمالي الكروت: $_totalCards',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'آخر تحديث: ${_lastUsersFetchTime?.toString().substring(11, 19) ?? "غير متاح"}',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSummaryCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.8),
            theme.primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat('الكل', _totalCards, Icons.credit_card),
          _buildQuickStat('مفعل', _activeCards, Icons.check_circle),
          _buildQuickStat('معطل', _disabledCards, Icons.cancel),
          _buildQuickStat('منتهي', _expiredCards, Icons.hourglass_empty),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    // Simplified filters for now
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'فلاتر محسنة قيد التطوير...',
        style: TextStyle(color: Colors.white60),
      ),
    );
  }
}