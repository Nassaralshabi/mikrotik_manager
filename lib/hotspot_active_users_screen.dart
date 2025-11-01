import 'dart:async';
import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

class HotspotActiveUsersScreen extends StatefulWidget {
  const HotspotActiveUsersScreen({super.key});

  @override
  State<HotspotActiveUsersScreen> createState() => _HotspotActiveUsersScreenState();
}

class _HotspotActiveUsersScreenState extends State<HotspotActiveUsersScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, Map<String, dynamic>> _previousData = {};
  Map<String, DateTime> _previousFetchTime = {};
  
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  
  bool _isLoading = false;
  bool _showSearch = false;
  int _activeUsersCount = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchActiveUsers();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isLoading) {
        _fetchActiveUsers();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchActiveUsers() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      final response = await client.talk(['/ip/hotspot/active/print']);
      
      final users = response.map((e) => Map<String, dynamic>.from(e)).toList();
      
      for (var user in users) {
        final username = user['user'] ?? '';
        if (username.isNotEmpty) {
          _previousData[username] = {
            'bytes-in': int.tryParse(user['bytes-in'] ?? '0') ?? 0,
            'bytes-out': int.tryParse(user['bytes-out'] ?? '0') ?? 0,
            'time': DateTime.now(),
          };
        }
      }
      
      if (mounted) {
        setState(() {
          _allUsers = users;
          _activeUsersCount = users.length;
          _filterUsers();
          _isLoading = false;
          _errorMessage = '';
        });
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
          _errorMessage = 'حدث خطأ: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      client?.close();
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((user) {
        final username = (user['user'] ?? '').toLowerCase();
        final mac = (user['mac-address'] ?? '').toLowerCase();
        final address = (user['address'] ?? '').toLowerCase();
        
        return username.contains(query) ||
               mac.contains(query) ||
               address.contains(query);
      }).toList();
    }
  }

  String _formatUptime(String uptime) {
    if (uptime.isEmpty || uptime == '0s') return '00:00:00';
    
    final regex = RegExp(r'(\d+)([wdhms])');
    final matches = regex.allMatches(uptime);
    
    int totalSeconds = 0;
    
    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2)!;
      
      switch (unit) {
        case 'w': totalSeconds += value * 604800; break;
        case 'd': totalSeconds += value * 86400; break;
        case 'h': totalSeconds += value * 3600; break;
        case 'm': totalSeconds += value * 60; break;
        case 's': totalSeconds += value; break;
      }
    }
    
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  String _calculateSpeed(String username, int currentBytes, bool isDownload) {
    if (!_previousData.containsKey(username)) {
      return '0';
    }
    
    final prevData = _previousData[username]!;
    final prevBytes = prevData[isDownload ? 'bytes-in' : 'bytes-out'] ?? 0;
    final prevTime = prevData['time'] as DateTime;
    
    final timeDiff = DateTime.now().difference(prevTime).inSeconds;
    if (timeDiff <= 0) return '0';
    
    final bytesDiff = (currentBytes - prevBytes).abs();
    final speedKBps = bytesDiff / timeDiff / 1024;
    
    if (speedKBps >= 1024) {
      return '${(speedKBps / 1024).toStringAsFixed(1)} م';
    }
    return speedKBps.toStringAsFixed(0);
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تفاصيل المستخدم',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الاسم', user['user'] ?? 'N/A'),
              _buildDetailRow('عنوان IP', user['address'] ?? 'N/A'),
              _buildDetailRow('MAC Address', user['mac-address'] ?? 'N/A'),
              _buildDetailRow('السيرفر', user['server'] ?? 'N/A'),
              _buildDetailRow('طريقة الدخول', user['login-by'] ?? 'N/A'),
              _buildDetailRow('وقت الاتصال', _formatUptime(user['uptime'] ?? '0s')),
              _buildDetailRow('وقت الخمول', user['idle-time'] ?? '0s'),
              _buildDetailRow('Keepalive', user['keepalive-timeout'] ?? 'N/A'),
              const Divider(color: Colors.white24),
              _buildDetailRow('Packets In', user['packets-in'] ?? '0'),
              _buildDetailRow('Packets Out', user['packets-out'] ?? '0'),
              _buildDetailRow('Bytes In', _formatBytes(user['bytes-in'] ?? '0')),
              _buildDetailRow('Bytes Out', _formatBytes(user['bytes-out'] ?? '0')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.purple)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnectUser(user);
            },
            child: const Text('قطع الاتصال', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(String bytesStr) {
    final bytes = int.tryParse(bytesStr) ?? 0;
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  Future<void> _disconnectUser(Map<String, dynamic> user) async {
    final id = user['.id'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن قطع الاتصال: معرّف المستخدم غير متوفر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      await client.talk([
        '/ip/hotspot/active/remove',
        '=.id=$id',
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم قطع اتصال ${user['user'] ?? 'المستخدم'} بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchActiveUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل قطع الاتصال: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      client?.close();
    }
  }

  void _showUserOptions(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user['user'] ?? 'المستخدم',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('عرض التفاصيل', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showUserDetails(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_off, color: Colors.red),
              title: const Text('قطع الاتصال', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _disconnectUser(user);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الأكتشف', style: TextStyle(fontSize: 20)),
            Text(
              'عدد الأكتشف $_activeUsersCount',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActiveUsers,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                _filterUsers();
              }
            },
            tooltip: 'بحث',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(),
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).cardColor,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _filterUsers();
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو MAC أو IP',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _filterUsers();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFB39DDB).withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading && _filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري تحميل المستخدمين النشطين...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
    
    if (_filteredUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchActiveUsers,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'لا يوجد مستخدمين نشطين'
                        : 'لا توجد نتائج للبحث',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _fetchActiveUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchActiveUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['user'] ?? 'N/A';
    final server = user['server'] ?? 'N/A';
    final macAddress = user['mac-address'] ?? 'N/A';
    final uptime = user['uptime'] ?? '0s';
    final bytesIn = int.tryParse(user['bytes-in'] ?? '0') ?? 0;
    final bytesOut = int.tryParse(user['bytes-out'] ?? '0') ?? 0;
    final address = user['address'] ?? 'N/A';
    
    final speedDown = _calculateSpeed(username, bytesIn, true);
    final speedUp = _calculateSpeed(username, bytesOut, false);
    
    final totalBytes = bytesIn + bytesOut;
    final totalMB = totalBytes / 1024 / 1024;
    
    final limitBytesIn = user['limit-bytes-in'] ?? '0';
    final limitBytesOut = user['limit-bytes-out'] ?? '0';
    final isUnlimited = (limitBytesIn == '0' || limitBytesIn == '4294967295') && 
                        (limitBytesOut == '0' || limitBytesOut == '4294967295');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB39DDB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatUptime(uptime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Text(
                          'ماك الجهاز: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB39DDB).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              macAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Text(
                          'السيرفر: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB39DDB).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            server,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Text(
                          'الاسم: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB39DDB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.data_usage, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        const Text(
                          'الحجم المستهلك: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB39DDB).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${totalMB.toStringAsFixed(1)} ميغا',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        const Text(
                          'السرعة: ',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB39DDB).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$speedDown ك/ثا',
                            style: const TextStyle(color: Colors.green, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUnlimited ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUnlimited ? 'غير\nمحدود' : 'محدود',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () => _showUserOptions(user),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
