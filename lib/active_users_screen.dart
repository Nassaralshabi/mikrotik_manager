import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'dart:async';
import 'dart:math' as math;
import 'mikrotik_connector.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  List<Map<String, dynamic>> _activeUsers = [];
  DateTime? _lastActiveFetch;
  static const Duration _minRefreshGap = Duration(seconds: 20);
  static const Duration _cacheDuration = Duration(minutes: 2);
  int _page = 0;
  static const int _pageSize = 20;
  int? _totalActiveCount;
  bool _serverPaging = false;
  int _backoffExp = 0;
  static const Duration _baseInterval = Duration(seconds: 20);
  static const Duration _maxInterval = Duration(minutes: 2);
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalUsers = 0;
  int _activeCount = 0;
  Timer? _refreshTimer;
  DateTime? _lastTotalUsersFetch;
  bool _isHotspotMode = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveUsers();
    _scheduleNextFetch();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  void _scheduleNextFetch([Duration? delay]) {
    _refreshTimer?.cancel();
    final d = delay ?? _baseInterval;
    _refreshTimer = Timer(d, () {
      if (!mounted) return;
      _fetchActiveUsers();
    });
  }

  Future<void> _fetchActiveUsers({bool force = false}) async {
    if (!mounted) return;
    
    if (!force && _lastActiveFetch != null && DateTime.now().difference(_lastActiveFetch!) < _minRefreshGap) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      try {
        final args = [
          '/ip/hotspot/active/print',
          '=.proplist=user,address,uptime',
          '=.limit=${_pageSize}',
          '=.skip=${_page * _pageSize}',
        ];
        final hotspotResponse = await client.talk(args);
        _serverPaging = true;
        _activeUsers = hotspotResponse.map((e) => Map<String, dynamic>.from(e)).toList();
        _activeCount = _activeUsers.length;
        _isHotspotMode = true;
      } catch (e) {
        try {
          _serverPaging = false;
          final hotspotResponse = await client.talk([
            '/ip/hotspot/active/print',
            '=.proplist=user,address,uptime',
          ]);
          _activeUsers = hotspotResponse.map((e) => Map<String, dynamic>.from(e)).toList();
          _activeCount = _activeUsers.length;
          _isHotspotMode = true;
        } catch (e) {
          try {
            final argsUm = [
              '/tool/user-manager/session/print',
              '=.proplist=user,session-time-left,framed-ip-address,uptime',
              '=.limit=${_pageSize}',
              '=.skip=${_page * _pageSize}',
            ];
            final userManagerResponse = await client.talk(argsUm);
            _serverPaging = true;
            _activeUsers = userManagerResponse.map((e) => Map<String, dynamic>.from(e)).toList();
            _activeCount = _activeUsers.length;
            _isHotspotMode = false;
          } catch (e) {
            try {
              _serverPaging = false;
              final userManagerResponse = await client.talk([
                '/tool/user-manager/session/print',
                '=.proplist=user,session-time-left,framed-ip-address,uptime',
              ]);
              _activeUsers = userManagerResponse.map((e) => Map<String, dynamic>.from(e)).toList();
              _activeCount = _activeUsers.length;
              _isHotspotMode = false;
            } catch (e) {
              _activeUsers = [];
              _activeCount = 0;
            }
          }
        }
      }

      try {
        if (_lastTotalUsersFetch == null || DateTime.now().difference(_lastTotalUsersFetch!) > const Duration(seconds: 90)) {
          final allUsers = await client.talk([
            '/tool/user-manager/user/print',
            '=.proplist=.id',
          ]);
          _totalUsers = allUsers.length;
          _lastTotalUsersFetch = DateTime.now();
        }
      } catch (e) {
        // لا تحدّث الرقم في حال الفشل لتجنّب وميض الواجهة
      }

      _lastActiveFetch = DateTime.now();
      _backoffExp = 0;
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _scheduleNextFetch();
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في بيانات الدخول: ${e.message}';
          _isLoading = false;
        });
      }
      _backoffExp = math.min(_backoffExp + 1, 5);
      final factor = math.pow(2, _backoffExp).toInt();
      final secs = (_baseInterval.inSeconds * factor).clamp(0, _maxInterval.inSeconds);
      final next = Duration(seconds: secs);
      _scheduleNextFetch(next);
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في الاتصال: ${e.message}';
          _isLoading = false;
        });
      }
      _backoffExp = math.min(_backoffExp + 1, 5);
      final factor = math.pow(2, _backoffExp).toInt();
      final secs = (_baseInterval.inSeconds * factor).clamp(0, _maxInterval.inSeconds);
      final next = Duration(seconds: secs);
      _scheduleNextFetch(next);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ: ${e.toString()}';
          _isLoading = false;
        });
      }
      _backoffExp = math.min(_backoffExp + 1, 5);
      final factor = math.pow(2, _backoffExp).toInt();
      final secs = (_baseInterval.inSeconds * factor).clamp(0, _maxInterval.inSeconds);
      final next = Duration(seconds: secs);
      _scheduleNextFetch(next);
    } finally {
      client?.close();
    }
  }

  String _formatUptime(String? uptime) {
    if (uptime == null || uptime.isEmpty) return 'غير متاح';
    final hours = RegExp(r'(\d+)h').firstMatch(uptime)?.group(1);
    final minutes = RegExp(r'(\d+)m').firstMatch(uptime)?.group(1);
    final seconds = RegExp(r'(\d+)s').firstMatch(uptime)?.group(1);
    final parts = <String>[];
    if (hours != null && int.parse(hours) > 0) parts.add('${hours}س');
    if (minutes != null && int.parse(minutes) > 0) parts.add('${minutes}د');
    if (seconds != null && int.parse(seconds) > 0) parts.add('${seconds}ث');
    return parts.isEmpty ? uptime : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: const Text('المستخدمين النشطين', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () => _fetchActiveUsers(force: true),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _activeUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _activeUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchActiveUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchActiveUsers,
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildUsersList(),
            const SizedBox(height: 12),
            _buildPager(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people,
            label: 'النشطين الآن',
            value: '$_activeCount',
            color: Colors.white,
          ),
          Container(
            width: 1,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Icons.group,
            label: 'إجمالي المستخدمين',
            value: '$_totalUsers',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 40),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    if (_activeUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد مستخدمين نشطين حالياً',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalPages = (_activeUsers.length + _pageSize - 1) ~/ _pageSize;
    if (_page >= totalPages) _page = math.max(0, totalPages - 1);
    final start = _page * _pageSize;
    final end = math.min(start + _pageSize, _activeUsers.length);
    final current = _activeUsers.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              const Text(
                'المتصلين حالياً',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isHotspotMode ? 'Hotspot' : 'User Manager',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: current.length,
          itemBuilder: (context, idx) {
            final user = current[idx];
            return _buildUserCard(user, start + idx);
          },
        ),
      ],
    );
  }

  Widget _buildPager() {
    if (_activeUsers.isEmpty) return const SizedBox.shrink();

    if (_serverPaging) {
      final isLast = _activeUsers.length < _pageSize;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: _page > 0
                ? () {
                    setState(() => _page = _page - 1);
                    _fetchActiveUsers(force: true);
                  }
                : null,
            child: const Text('السابق'),
          ),
          const SizedBox(width: 12),
          Text('صفحة ${_page + 1}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: isLast
                ? null
                : () {
                    setState(() => _page = _page + 1);
                    _fetchActiveUsers(force: true);
                  },
            child: const Text('التالي'),
          ),
        ],
      );
    } else {
      final totalPages = (_activeUsers.length + _pageSize - 1) ~/ _pageSize;
      if (totalPages <= 1) return const SizedBox.shrink();
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: _page > 0
                ? () => setState(() => _page = _page - 1)
                : null,
            child: const Text('السابق'),
          ),
          const SizedBox(width: 12),
          Text('صفحة ${_page + 1} من $totalPages', style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: (_page + 1) < totalPages
                ? () => setState(() => _page = _page + 1)
                : null,
            child: const Text('التالي'),
          ),
        ],
      );
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final username = user['user'] ?? user['name'] ?? 'غير محدد';
    final ipAddress = user['address'] ?? user['framed-ip-address'] ?? 'غير متاح';
    final uptime = user['uptime'] ?? user['session-time-left'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showUserDetails(user);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Color(0xFFB39DDB),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ipAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFB39DDB),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF81C784),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatUptime(uptime),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF81C784),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'تفاصيل المستخدم',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...user.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
