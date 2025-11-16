import 'dart:async';
import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';
import 'active_users_screen.dart';
import 'add_user_screen.dart';
import 'bulk_add_screen.dart';
import 'card_list_screen.dart';
import 'network_tools_screen.dart';
import 'network_map_screen.dart';
import 'network_doctor_screen.dart';
import 'rogue_dhcp_detector_screen.dart';
import 'cards_statistics_screen.dart';
import 'device_monitoring_screen.dart';
import 'backup_system_screen.dart';
import 'profile_screen.dart';
import 'cards_statistics_optimized_screen.dart';
import 'connection_diagnostic_screen.dart';
import 'remote_access_guide_screen.dart';
import 'remote_control_center.dart';

class SystemDashboardScreen extends StatefulWidget {
  const SystemDashboardScreen({super.key});

  @override
  State<SystemDashboardScreen> createState() => _SystemDashboardScreenState();
}

class _SystemDashboardScreenState extends State<SystemDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  Timer? _refreshTimer;
  bool _isLoading = false;
  String? _errorMessage;

  // System Resource data
  String _uptime = '';
  String _version = '';
  String _boardName = '';
  String _cpu = '';
  String _cpuCount = '';
  String _cpuFrequency = '';
  int _cpuLoad = 0;
  int _freeMemory = 0;
  int _totalMemory = 0;
  int _freeHddSpace = 0;
  int _totalHddSpace = 0;
  String _architectureName = '';
  String _platform = '';

  // System Health data
  String _voltage = 'غير متاح';
  String _temperature = 'غير متاح';

  // RouterBoard data
  String _model = '';
  String _serialNumber = '';
  String _firmwareType = '';
  String _factoryFirmware = '';
  String _currentFirmware = '';
  String _upgradeFirmware = '';

  // Interface Statistics
  int _rxBitsPerSecond = 0;
  int _txBitsPerSecond = 0;

  // Active Users
  int _activeUsers = 0;
  int _totalUsers = 0;

  // System Clock
  String _time = '';
  String _date = '';
  String _timeZoneName = '';

  // History for Charts (last 20 data points)
  List<FlSpot> _cpuHistory = [];
  List<FlSpot> _memoryHistory = [];
  int _dataPointIndex = 0;

  // Alert System
  bool _cpuAlert = false;
  bool _memoryAlert = false;
  bool _temperatureAlert = false;
  final double _cpuThreshold = 80.0;
  final double _memoryThreshold = 90.0;
  final double _temperatureThreshold = 70.0;
  
  // Track last alert times to avoid spam
  DateTime? _lastCpuAlertTime;
  DateTime? _lastMemoryAlertTime;
  DateTime? _lastTempAlertTime;
  
  // Update tracking
  DateTime? _lastUpdateTime;
  bool _isUpdating = false;
  int _updateCount = 0;
  
  // Connection info
  String _connectionType = '';
  String _currentIP = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _updateConnectionInfo();

    // تحديث تلقائي كل 10 ثواني (تحديث صامت بعد التحميل الأول)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchData(silentUpdate: true);
      }
    });
  }

  Future<void> _updateConnectionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip') ?? '';
    
    setState(() {
      _currentIP = ip;
      if (ip.isNotEmpty) {
        _connectionType = _isLocalIP(ip) ? 'محلي' : 'عن بُعد';
      } else {
        _connectionType = '';
      }
    });
  }

  bool _isLocalIP(String ip) {
    if (ip.isEmpty) return false;
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return false;
    
    final nums = parts.cast<int>();
    return (nums[0] == 10) ||
           (nums[0] == 172 && nums[1] >= 16 && nums[1] <= 31) ||
           (nums[0] == 192 && nums[1] == 168) ||
           (nums[0] == 127);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silentUpdate = false}) async {
    if (!mounted) return;

    setState(() {
      if (!silentUpdate) {
        _isLoading = true;
      } else {
        _isUpdating = true;
      }
      _errorMessage = null;
    });

    try {
      final client = await MikrotikConnector.connect();

      // جلب معلومات النظام والأداء
      await _fetchSystemResource(client);

      // جلب معلومات الفولتية والحرارة
      await _fetchSystemHealth(client);

      // جلب معلومات RouterBoard
      await _fetchRouterBoard(client);

      // جلب سرعة الإنترنت
      await _fetchInterfaceStats(client);

      // جلب عدد المستخدمين النشطين
      await _fetchActiveUsers(client);

      // جلب وقت الشبكة
      await _fetchSystemClock(client);

      // Update history for charts
      _updateChartHistory();

      // Check for alerts
      _checkAlerts();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUpdating = false;
          _lastUpdateTime = DateTime.now();
          _updateCount++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUpdating = false;
          
          // معالجة محسنة للأخطاء
          if (e is MikrotikConnectionException) {
            _errorMessage = e.message;
            if (e.solution != null) {
              _errorMessage = '$_errorMessage\n\nالحل المقترح:\n${e.solution}';
            }
          } else if (e is MikrotikCredentialsMissingException) {
            _errorMessage = e.message;
          } else {
            _errorMessage = 'فشل الاتصال بالراوتر: ${e.toString()}';
          }
        });
        if (!silentUpdate) {
          _showDetailedErrorSnackBar(context, _errorMessage ?? 'خطأ غير معروف');
        }
      }
    }
  }

  Future<void> _fetchSystemResource(RouterOSClient client) async {
    try {
      final response = await client.talk(['/system/resource/print']);
      if (response.isNotEmpty) {
        final data = response.first;
        _uptime = data['uptime'] ?? '';
        _version = data['version'] ?? '';
        _boardName = data['board-name'] ?? '';
        _cpu = data['cpu'] ?? '';
        _cpuCount = data['cpu-count'] ?? '';
        _cpuFrequency = data['cpu-frequency'] ?? '';
        _cpuLoad = int.tryParse(data['cpu-load']?.toString() ?? '0') ?? 0;
        _freeMemory = int.tryParse(data['free-memory']?.toString() ?? '0') ?? 0;
        _totalMemory = int.tryParse(data['total-memory']?.toString() ?? '0') ?? 0;
        _freeHddSpace = int.tryParse(data['free-hdd-space']?.toString() ?? '0') ?? 0;
        _totalHddSpace = int.tryParse(data['total-hdd-space']?.toString() ?? '0') ?? 0;
        _architectureName = data['architecture-name'] ?? '';
        _platform = data['platform'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching system resource: $e');
    }
  }

  Future<void> _fetchSystemHealth(RouterOSClient client) async {
    try {
      final response = await client.talk(['/system/health/print']);
      if (response.isNotEmpty) {
        final data = response.first;
        _voltage = data['voltage'] ?? 'غير متاح';
        _temperature = data['temperature'] ?? 'غير متاح';
      }
    } catch (e) {
      // بعض الأجهزة لا تدعم هذا الأمر
      _voltage = 'غير متاح';
      _temperature = 'غير متاح';
    }
  }

  Future<void> _fetchRouterBoard(RouterOSClient client) async {
    try {
      final response = await client.talk(['/system/routerboard/print']);
      if (response.isNotEmpty) {
        final data = response.first;
        _model = data['model'] ?? '';
        _serialNumber = data['serial-number'] ?? '';
        _firmwareType = data['firmware-type'] ?? '';
        _factoryFirmware = data['factory-firmware'] ?? '';
        _currentFirmware = data['current-firmware'] ?? '';
        _upgradeFirmware = data['upgrade-firmware'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching routerboard: $e');
    }
  }

  Future<void> _fetchInterfaceStats(RouterOSClient client) async {
    try {
      // جلب قائمة الـ interfaces
      final interfaces = await client.talk(['/interface/print']);
      
      // البحث عن Interface مناسب (ether1 أو أول interface نشط)
      String? targetInterface;
      for (var iface in interfaces) {
        final name = iface['name']?.toString() ?? '';
        if (name.toLowerCase().contains('ether1') || name.toLowerCase().contains('wan')) {
          targetInterface = name;
          break;
        }
      }

      // إذا لم نجد ether1 أو wan، نستخدم أول interface
      if (targetInterface == null && interfaces.isNotEmpty) {
        targetInterface = interfaces.first['name']?.toString();
      }

      if (targetInterface != null) {
        final response = await client.talk([
          '/interface/monitor-traffic',
          '=interface=$targetInterface',
          '=once=',
        ]).timeout(const Duration(seconds: 3));

        if (response.isNotEmpty) {
          final data = response.first;
          _rxBitsPerSecond = int.tryParse(data['rx-bits-per-second']?.toString() ?? '0') ?? 0;
          _txBitsPerSecond = int.tryParse(data['tx-bits-per-second']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching interface stats: $e');
      _rxBitsPerSecond = 0;
      _txBitsPerSecond = 0;
    }
  }

  Future<void> _fetchActiveUsers(RouterOSClient client) async {
    try {
      // جلب الجلسات النشطة من User Manager فقط
      final activeSessionsResponse = await client.talk(['/tool/user-manager/session/print']);
      _activeUsers = activeSessionsResponse.length;

      // جلب إجمالي المستخدمين من User Manager
      final allUsersResponse = await client.talk(['/tool/user-manager/user/print']);
      _totalUsers = allUsersResponse.length;
      
      debugPrint('User Manager: $_activeUsers active sessions, $_totalUsers total users');
      
    } catch (e) {
      debugPrint('Error fetching User Manager data: $e');
      _activeUsers = 0;
      _totalUsers = 0;
    }
  }

  Future<void> _fetchSystemClock(RouterOSClient client) async {
    try {
      final response = await client.talk(['/system/clock/print']);
      if (response.isNotEmpty) {
        final data = response.first;
        _time = data['time'] ?? '';
        _date = data['date'] ?? '';
        _timeZoneName = data['time-zone-name'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching system clock: $e');
    }
  }

  String _formatUptime(String uptimeRaw) {
    if (uptimeRaw.isEmpty) return 'غير متاح';

    final regex = RegExp(r'(\d+)([wdhms])');
    final matches = regex.allMatches(uptimeRaw);

    int weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0;

    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2)!;

      switch (unit) {
        case 'w':
          weeks = value;
          break;
        case 'd':
          days = value;
          break;
        case 'h':
          hours = value;
          break;
        case 'm':
          minutes = value;
          break;
        case 's':
          seconds = value;
          break;
      }
    }

    List<String> parts = [];
    if (weeks > 0) parts.add('$weeks أسبوع');
    if (days > 0) parts.add('$days يوم');
    if (hours > 0) parts.add('$hours ساعة');
    if (minutes > 0) parts.add('$minutes دقيقة');
    if (seconds > 0 && parts.isEmpty) parts.add('$seconds ثانية');

    return parts.take(2).join(' و ');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} ك.ب';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} م.ب';
    } else {
      return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} ج.ب';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'قبل ${difference.inSeconds} ث';
    } else if (difference.inMinutes < 60) {
      return 'قبل ${difference.inMinutes} د';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatSpeed(int bitsPerSecond) {
    final bytesPerSecond = bitsPerSecond / 8;

    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} ب/ثا';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} ك/ثا';
    } else {
      return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} م/ثا';
    }
  }

  double _calculatePercentage(int used, int total) {
    if (total == 0) return 0;
    return ((total - used) / total) * 100;
  }

  void _updateChartHistory() {
    final cpuValue = _cpuLoad.toDouble();
    final memoryUsedPercentage = _totalMemory > 0
        ? ((_totalMemory - _freeMemory) / _totalMemory) * 100
        : 0.0;

    _cpuHistory.add(FlSpot(_dataPointIndex.toDouble(), cpuValue));
    _memoryHistory.add(FlSpot(_dataPointIndex.toDouble(), memoryUsedPercentage));

    // Keep only last 20 data points using sublist to avoid repeated removals
    if (_cpuHistory.length > 20) {
      _cpuHistory = _cpuHistory.sublist(_cpuHistory.length - 20);
    }
    if (_memoryHistory.length > 20) {
      _memoryHistory = _memoryHistory.sublist(_memoryHistory.length - 20);
    }

    _dataPointIndex++;
  }

  void _checkAlerts() {
    final now = DateTime.now();
    
    // Check CPU Alert
    if (_cpuLoad >= _cpuThreshold) {
      _cpuAlert = true;
      if (_lastCpuAlertTime == null || 
          now.difference(_lastCpuAlertTime!).inMinutes >= 5) {
        _showAlert(
          'تحذير: استخدام المعالج مرتفع!',
          'استخدام المعالج وصل إلى $_cpuLoad% (الحد: ${_cpuThreshold.toInt()}%)',
          Icons.warning_amber_rounded,
          Colors.orange,
        );
        _lastCpuAlertTime = now;
      }
    } else {
      _cpuAlert = false;
    }

    // Check Memory Alert
    final memoryUsedPercentage = _totalMemory > 0
        ? ((_totalMemory - _freeMemory) / _totalMemory) * 100
        : 0.0;
    
    if (memoryUsedPercentage >= _memoryThreshold) {
      _memoryAlert = true;
      if (_lastMemoryAlertTime == null || 
          now.difference(_lastMemoryAlertTime!).inMinutes >= 5) {
        _showAlert(
          'تحذير: الذاكرة ممتلئة!',
          'استخدام الذاكرة وصل إلى ${memoryUsedPercentage.toStringAsFixed(1)}% (الحد: ${_memoryThreshold.toInt()}%)',
          Icons.memory,
          Colors.red,
        );
        _lastMemoryAlertTime = now;
      }
    } else {
      _memoryAlert = false;
    }

    // Check Temperature Alert (if available)
    if (_temperature != 'غير متاح') {
      final temp = double.tryParse(_temperature);
      if (temp != null && temp >= _temperatureThreshold) {
        _temperatureAlert = true;
        if (_lastTempAlertTime == null || 
            now.difference(_lastTempAlertTime!).inMinutes >= 5) {
          _showAlert(
            'تحذير: حرارة الجهاز مرتفعة!',
            'درجة الحرارة وصلت إلى $temp°C (الحد: ${_temperatureThreshold.toInt()}°C)',
            Icons.thermostat,
            Colors.red,
          );
          _lastTempAlertTime = now;
        }
      } else {
        _temperatureAlert = false;
      }
    }
  }

  void _showAlert(String title, String message, IconData icon, Color color) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المعلومات'),
          centerTitle: true,
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.router_outlined,
                    size: 64,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'تفاصيل الخطأ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _fetchData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const ConnectionDiagnosticScreen()),
                        );
                      },
                      icon: const Icon(Icons.troubleshoot),
                      label: const Text('تشخيص المشكلة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const RemoteAccessGuideScreen()),
                        );
                      },
                      icon: const Icon(Icons.school),
                      label: const Text('دليل التحكم عن بُعد'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        foregroundColor: Colors.cyan,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('الإعدادات'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        foregroundColor: theme.primaryColor,
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لوحة المعلومات'),
            if (_connectionType.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _connectionType == 'محلي' 
                      ? Colors.blue.withOpacity(0.2) 
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectionType == 'محلي' ? Colors.blue : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _connectionType == 'محلي' ? Icons.home : Icons.public,
                      size: 14,
                      color: _connectionType == 'محلي' ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _connectionType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _connectionType == 'محلي' ? Colors.blue : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (_isUpdating)
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : () => _fetchData(),
              tooltip: 'تحديث',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchData(),
        backgroundColor: theme.primaryColor,
        color: Colors.white,
        displacement: 60,
        strokeWidth: 3,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Auto-update status banner
              if (_isUpdating || (_lastUpdateTime != null && DateTime.now().difference(_lastUpdateTime!).inSeconds < 30))
                _buildUpdateStatusBanner(theme),
              if (_isUpdating || (_lastUpdateTime != null && DateTime.now().difference(_lastUpdateTime!).inSeconds < 30))
                const SizedBox(height: 12),
              
              // Alert Banner
              if (_cpuAlert || _memoryAlert || _temperatureAlert)
                _buildAlertBanner(),
              if (_cpuAlert || _memoryAlert || _temperatureAlert)
                const SizedBox(height: 16),
              
              // بطاقة معلومات النظام الرئيسية
              _buildMainSystemCard(theme),
              const SizedBox(height: 16),

              // Charts Section
              if (_cpuHistory.length > 1) ...[
                _buildChartCard(
                  title: 'استخدام المعالج (CPU)',
                  data: _cpuHistory,
                  color: _cpuAlert ? Colors.red : Colors.purple,
                  unit: '%',
                  isAlert: _cpuAlert,
                ),
                const SizedBox(height: 16),
                _buildChartCard(
                  title: 'استخدام الذاكرة (RAM)',
                  data: _memoryHistory,
                  color: _memoryAlert ? Colors.red : Colors.blue,
                  unit: '%',
                  isAlert: _memoryAlert,
                ),
                const SizedBox(height: 16),
              ],

              // ListView الأفقي للبطاقات الفرعية
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildInfoCardHorizontal(
                      'مدة التشغيل',
                      _formatUptime(_uptime),
                      Icons.timer,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCardHorizontal(
                      'المستخدمين النشطين',
                      '$_activeUsers من $_totalUsers',
                      Icons.people,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCardHorizontal(
                      'سرعة النت',
                      '${_formatSpeed(_rxBitsPerSecond)} ⬇\n${_formatSpeed(_txBitsPerSecond)} ⬆',
                      Icons.speed,
                      Colors.cyan,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoCardHorizontal(
                      'التخزين',
                      '${_formatBytes(_totalHddSpace - _freeHddSpace)} من ${_formatBytes(_totalHddSpace)}\n${_calculatePercentage(_freeHddSpace, _totalHddSpace).toStringAsFixed(1)}%',
                      Icons.storage,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // بطاقة وقت الشبكة
              _buildNetworkTimeCard(),
              const SizedBox(height: 24),

              // قسم "البحث عن المشاكل"
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 28, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    const Text(
                      'البحث عن المشاكل',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // GridView للأزرار
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
                children: [
                  _buildActionButtonGrid('المستخدمين النشطين', Icons.people_alt, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ActiveUsersScreen()));
                  }),
                  _buildActionButtonGrid('إضافة مستخدم', Icons.person_add, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUserScreen()));
                  }),
                  _buildActionButtonGrid('إضافة جماعية', Icons.group_add, Colors.teal, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkAddScreen()));
                  }),
                  _buildActionButtonGrid('قائمة الكروت', Icons.credit_card, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CardListScreen()));
                  }),
                  _buildActionButtonGrid('أدوات الشبكة', Icons.build, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NetworkToolsScreen()));
                  }),
                  _buildActionButtonGrid('خريطة الشبكة', Icons.device_hub, Colors.cyan, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NetworkMapScreen()));
                  }),
                  _buildActionButtonGrid('فحص الشبكة', Icons.health_and_safety, Colors.green.shade700, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NetworkDoctorScreen()));
                  }),
                  _buildActionButtonGrid('كشف DHCP', Icons.security, Colors.red, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RogueDhcpDetectorScreen()));
                  }),
                  _buildActionButtonGrid('إحصائيات الكروت', Icons.analytics, Colors.indigo, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CardsStatisticsOptimizedScreen()));
                  }),
                  _buildActionButtonGrid('مراقبة الأجهزة', Icons.monitor, Colors.deepOrange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DeviceMonitoringScreen()));
                  }),
                  _buildActionButtonGrid('النسخ الاحتياطي', Icons.backup, Colors.blueGrey, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupSystemScreen()));
                  }),
                  _buildActionButtonGrid('التحكم عن بُعد', Icons.public, Colors.indigo, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RemoteControlCenter()));
                  }),
                  _buildActionButtonGrid('الإعدادات', Icons.settings, theme.primaryColor, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainSystemCard(ThemeData theme) {
    final lastUpdateText = _lastUpdateTime != null 
        ? 'آخر تحديث: ${_formatTime(_lastUpdateTime!)}'
        : 'جاري التحديث...';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.8),
            theme.primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Header with update indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_isUpdating)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white70,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.router, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _boardName.isEmpty ? _model : _boardName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (_isUpdating) const SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _version,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          // Last update time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isUpdating ? Icons.sync : Icons.access_time,
                  size: 14,
                  color: Colors.white60,
                ),
                const SizedBox(width: 4),
                Text(
                  lastUpdateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
                if (_updateCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_updateCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Enhanced stats with animations
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEnhancedMiniInfoCard(
                  'الفولت',
                  _voltage,
                  Icons.bolt,
                  Colors.yellow,
                  false,
                ),
                Container(width: 1, height: 50, color: Colors.white30),
                _buildEnhancedMiniInfoCard(
                  'الحرارة',
                  _temperature == 'غير متاح' ? _temperature : '$_temperature°',
                  Icons.thermostat,
                  _temperatureAlert ? Colors.red : Colors.orange,
                  _temperatureAlert,
                ),
                Container(width: 1, height: 50, color: Colors.white30),
                _buildEnhancedMiniInfoCard(
                  'المعالج',
                  '$_cpuLoad%',
                  Icons.memory,
                  _cpuAlert ? Colors.red : Colors.purple,
                  _cpuAlert,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfoCard(String label, String value, IconData icon, Color color, bool isAlert) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Icon(icon, size: 32, color: color),
              if (isAlert)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAlert ? context.theme.appColors.error.withOpacity(0.9) : context.theme.appColors.secondary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isAlert ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMiniInfoCard(String label, String value, IconData icon, Color color, bool isAlert) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulse effect for updates
                if (_isUpdating)
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.2),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: isAlert ? Border.all(color: Colors.red, width: 2) : null,
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                // Alert indicator
                if (isAlert)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isAlert 
                    ? Colors.red.withOpacity(0.9) 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: isAlert ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: _isUpdating ? 2 : 1,
        ),
        boxShadow: _isUpdating ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ] : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              if (_isUpdating)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.theme.appColors.secondary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardHorizontal(String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB39DDB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTimeCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _isUpdating 
            ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isUpdating ? 0.2 : 0.1),
            blurRadius: _isUpdating ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: _isUpdating ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(
                Icons.access_time, 
                color: Colors.black54,
                size: _isUpdating ? 22 : 20,
              ),
              if (_isUpdating)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.6),
                          blurRadius: 3,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  'وقت الشبكة: $_date $_time',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isUpdating) ...[
                  const SizedBox(height: 4),
                  Text(
                    'جاري تحديث الوقت...',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonGrid(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required List<FlSpot> data,
    required Color color,
    required String unit,
    bool isAlert = false,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final minY = data.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final currentValue = data.isNotEmpty ? data.last.y : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(isAlert ? 0.8 : 0.3),
          width: isAlert ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isAlert ? 0.3 : 0.1),
            blurRadius: isAlert ? 15 : 10,
            offset: const Offset(0, 4),
            spreadRadius: isAlert ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (isAlert) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.warning_rounded,
                      color: color,
                      size: 24,
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isAlert ? color.withOpacity(0.9) : context.theme.appColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isAlert ? color : Colors.black).withOpacity(0.3),
                      blurRadius: isAlert ? 6 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${currentValue.toStringAsFixed(1)}$unit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}$unit',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black45,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 45,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                minX: data.first.x,
                maxX: data.last.x,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(1)}$unit',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildChartStat('الحد الأدنى', minY, unit, Colors.green),
              _buildChartStat('الحد الأقصى', maxY, unit, Colors.red),
              _buildChartStat('المتوسط', 
                data.map((e) => e.y).reduce((a, b) => a + b) / data.length, 
                unit, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner() {
    final alerts = <Map<String, dynamic>>[];
    
    if (_cpuAlert) {
      alerts.add({
        'title': 'استخدام المعالج مرتفع',
        'value': '$_cpuLoad%',
        'icon': Icons.memory,
        'color': Colors.orange,
      });
    }
    
    if (_memoryAlert) {
      final memoryUsedPercentage = _totalMemory > 0
          ? ((_totalMemory - _freeMemory) / _totalMemory) * 100
          : 0.0;
      alerts.add({
        'title': 'الذاكرة ممتلئة',
        'value': '${memoryUsedPercentage.toStringAsFixed(1)}%',
        'icon': Icons.storage,
        'color': Colors.red,
      });
    }
    
    if (_temperatureAlert) {
      alerts.add({
        'title': 'الحرارة مرتفعة',
        'value': '$_temperature°C',
        'icon': Icons.thermostat,
        'color': Colors.red,
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade700,
            Colors.orange.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيه أداء النظام',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تم الكشف عن مشكلات في الأداء',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    alert['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert['value'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildUpdateStatusBanner(ThemeData theme) {
    if (_isUpdating) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.cyan.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'جاري تحديث بيانات النظام...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'تلقائي - كل 10 ث',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show recent update success
    if (_lastUpdateTime != null && 
        DateTime.now().difference(_lastUpdateTime!).inSeconds < 30) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.8),
              Colors.teal.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تم التحديث بنجاح - ${_formatTime(_lastUpdateTime!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'التحديث #$_updateCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _showDetailedErrorSnackBar(BuildContext context, String errorMessage) {
    final lines = errorMessage.split('\n');
    final mainError = lines.first;
    final hasDetails = lines.length > 1;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'خطأ في الاتصال',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(mainError, style: const TextStyle(fontSize: 14)),
            if (hasDetails) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lines.skip(1).map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: const TextStyle(fontSize: 13, color: Colors.white90),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'الإعدادات',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ),
    );
  }
}
