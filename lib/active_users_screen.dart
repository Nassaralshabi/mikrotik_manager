import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'dart:async';
import 'mikrotik_connector.dart';
import 'theme/app_theme.dart';

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  List<Map<String, dynamic>> _activeUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalUsers = 0;
  int _activeCount = 0;
  Timer? _refreshTimer;
  bool _isHotspotMode = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _fetchActiveUsers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveUsers() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      try {
        final hotspotResponse = await client.talk(['/ip/hotspot/active/print']);
        _activeUsers = hotspotResponse.map((e) => Map<String, dynamic>.from(e)).toList();
        _activeCount = _activeUsers.length;
        _isHotspotMode = true;
      } catch (e) {
        try {
          final userManagerResponse = await client.talk(['/tool/user-manager/session/print']);
          _activeUsers = userManagerResponse.map((e) => Map<String, dynamic>.from(e)).toList();
          _activeCount = _activeUsers.length;
          _isHotspotMode = false;
        } catch (e) {
          _activeUsers = [];
          _activeCount = 0;
        }
      }

      try {
        final allUsers = await client.talk(['/tool/user-manager/user/print']);
        _totalUsers = allUsers.length;
      } catch (e) {
        _totalUsers = 0;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في بيانات الدخول: ${e.message}';
          _isLoading = false;
        });
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ في الاتصال: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ: ${e.toString()}';
          _isLoading = false;
        });
      }
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
            onPressed: _isLoading ? null : _fetchActiveUsers,
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
              Icon(Icons.error_outline, size: 64, color: context.theme.appColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.appColors.error, fontSize: 12),
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
            context.theme.appColors.primary.withOpacity(0.8),
            context.theme.appColors.primary.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.theme.appColors.primary.withOpacity(0.3),
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
            color: context.theme.appColors.onPrimary,
          ),
          Container(
            width: 1,
            height: 60,
            color: context.theme.appColors.onSurface.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Icons.group,
            label: 'إجمالي المستخدمين',
            value: '$_totalUsers',
            color: context.theme.appColors.onPrimary,
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
                color: context.theme.appColors.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد مستخدمين نشطين حالياً',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              Text(
                'المتصلين حالياً',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.theme.appColors.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.theme.appColors.primary.withOpacity(0.2),
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
          itemCount: _activeUsers.length,
          itemBuilder: (context, index) {
            final user = _activeUsers[index];
            return _buildUserCard(user, index);
          },
        ),
      ],
    );
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
          color: context.theme.appColors.primary.withOpacity(0.2),
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
                  child: Icon(
                    Icons.person,
                    color: context.theme.appColors.onPrimary,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.theme.appColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: context.theme.appColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ipAddress,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.theme.appColors.secondary,
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
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: context.theme.appColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatUptime(uptime),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.theme.appColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.theme.appColors.onSurface.withOpacity(0.3),
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
                  Text(
                    'تفاصيل المستخدم',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.theme.appColors.onSurface,
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
                            color: context.theme.appColors.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: context.theme.appColors.onSurface,
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
