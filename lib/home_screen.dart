import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connection_service.dart';
import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';
import 'mqtt_service.dart';
import 'custom_page_route.dart';
import 'add_user_screen.dart';
import 'bulk_add_screen.dart';
import 'saved_files_screen.dart';
import 'qahtani_link_screen.dart';
import 'profile_screen.dart';
import 'pdf_templates_screen.dart';
import 'network_doctor_screen.dart';
import 'extract_cards_screen.dart';
import 'cards_statistics_screen.dart';
import 'stats_screen.dart';
import 'backup_system_screen.dart';
import 'active_users_screen.dart';

enum MikrotikMode { userManager, hotspot }

class HomeScreen extends StatefulWidget {
  final bool isVersion7OrNewer;
  final String username;

  const HomeScreen({
    super.key,
    required this.isVersion7OrNewer,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;

  // --- الإصلاح: جعل _selectedMode متغيراً قابلاً للتغيير ---
  MikrotikMode _selectedMode = MikrotikMode.userManager;
  bool _isNetworkLinked = false;
  String _clientName = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      await ConnectionService.instance.getClient();
      if (mounted) setState(() => _isConnected = true);
    } catch (e) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  Future<void> _loadLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final isLinked = prefs.getBool('is_network_linked') ?? false;
      String clientName = '';
      if (isLinked) {
        final dataString = prefs.getString('qahtani_linked_data');
        if (dataString != null) {
          try {
            final data = jsonDecode(dataString);
            clientName = data['client_info']?['name'] ?? '';
          } catch (e) {
            debugPrint('Error decoding qahtani_linked_data: $e');
          }
        }
      }
      setState(() {
        _isNetworkLinked = isLinked;
        _clientName = clientName;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _loadLinkStatus();
      _checkConnection();
      context.read<MqttService>().checkAndReconnect();
      final isLinked = _isNetworkLinked;
      if (isLinked) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          context.read<MqttService>().publish({'command': 'get_latest_network_details'});
        });
      }
    }
  }

  Future<void> _fetchProfiles() async {
    setState(() => _isLoadingProfiles = true);
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final command = _selectedMode == MikrotikMode.userManager
          ? '/tool/user-manager/profile/print'
          : '/ip/hotspot/user/profile/print';
      final response = await client.talk([command]);
      if (mounted) {
        setState(() {
          _profiles = response.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'حدث خطأ أثناء جلب البيانات: ${e.toString()}');
      }
    } finally {
      client?.close();
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  /// تبديل وضع إدارة المستخدمين
  void _switchMode(MikrotikMode newMode) {
    if (newMode == _selectedMode) return;
    setState(() {
      _selectedMode = newMode;
      _isLoadingProfiles = true;
    });
    _fetchProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final screenWith = MediaQuery.of(context).size.width;
    // --- الإصلاح: عدد الأعمدة ديناميكي حسب عرض الشاشة ---
    final crossAxisCount = screenWith > 700 ? 4 : screenWith > 500 ? 3 : 2;

    final List<ServiceItem> services = [
      ServiceItem(title: 'إضافة كرت فردي', icon: Icons.person_add_alt_1, color: const Color(0xFF5C6BC0),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => AddUserScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, customer: widget.username))); },
      ),
      ServiceItem(title: 'إضافة كروت جماعية', icon: Icons.groups, color: const Color(0xFF4CAF50),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => BulkAddScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, username: widget.username))); },
      ),
      ServiceItem(title: 'ربط الشبكة', icon: Icons.link, color: const Color(0xFF42A5F5),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const QahtaniLinkScreen())); },
      ),
      ServiceItem(title: 'الإحصائيات', icon: Icons.bar_chart_rounded, color: const Color(0xFF26A69A),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const StatsScreen())); },
      ),
      ServiceItem(title: 'طبيب الشبكة', icon: Icons.local_hospital_outlined, color: const Color(0xFF42A5F5),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const NetworkDoctorScreen())); },
      ),
      ServiceItem(title: 'الملفات المحفوظة', icon: Icons.folder_copy, color: const Color(0xFFFFA726),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const SavedFilesScreen())); },
      ),
      ServiceItem(title: 'إدارة قوالب PDF', icon: Icons.picture_as_pdf, color: const Color(0xFF78909C),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => PdfTemplatesScreen(profiles: _profiles))); },
      ),
      ServiceItem(title: 'استخراج الكروت', icon: Icons.document_scanner_outlined, color: const Color(0xFFEF5350),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const ExtractCardsScreen())); },
      ),
      ServiceItem(title: 'إحصائيات الكروت', icon: Icons.bar_chart, color: const Color(0xFF9C27B0),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const CardsStatisticsScreen())); },
      ),
      ServiceItem(title: 'المستخدمين النشطين', icon: Icons.people_outline, color: const Color(0xFF00ACC1),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const ActiveUsersScreen())); },
      ),
      ServiceItem(title: 'الملف الشخصي', icon: Icons.account_circle, color: const Color(0xFF29B6F6),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const ProfileScreen())); },
      ),
      ServiceItem(title: 'النسخ الاحتياطي', icon: Icons.backup, color: const Color(0xFF2196F3),
        onTap: () { Navigator.of(context).push(CustomPageRoute(builder: (context) => const BackupSystemScreen())); },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            // مؤشر حالة الاتصال
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: (_isConnected ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () {}, tooltip: 'الإشعارات'),
          IconButton(
            icon: const Icon(Icons.logout), tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await ConnectionService.instance.disconnect();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: _isLoadingProfiles
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  // --- الإصلاح: زر تبديل الوضع ---
                  _buildModeSwitcher(),
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0, right: 24.0, left: 24.0, bottom: 12.0),
                    child: Text('الخدمات الأساسية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  // --- الإصلاح: عدد الأعمدة ديناميكي ---
                  GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: services.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return RepaintBoundary(
                        child: _buildServiceGridItem(title: service.title, icon: service.icon, iconBgColor: service.color, onTap: service.onTap),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6b3fa0))),
          const SizedBox(height: 16),
          Text('جاري التحميل...', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isNetworkLinked && _clientName.isNotEmpty ? 'العميل' : 'مرحباً بك',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isNetworkLinked && _clientName.isNotEmpty ? _clientName : 'لوحة تحكم MikroTik',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.settings_ethernet, color: Colors.white70, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// زر تبديل بين وضع UserManager و Hotspot
  Widget _buildModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildModeButton(
                title: 'User Manager',
                icon: Icons.person_outline,
                isSelected: _selectedMode == MikrotikMode.userManager,
                onTap: () => _switchMode(MikrotikMode.userManager),
              ),
            ),
            Expanded(
              child: _buildModeButton(
                title: 'Hotspot',
                icon: Icons.wifi_tethering,
                isSelected: _selectedMode == MikrotikMode.hotspot,
                onTap: () => _switchMode(MikrotikMode.hotspot),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6b3fa0) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.white54),
              const SizedBox(width: 6),
              Flexible(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Colors.white54), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceGridItem({required String title, required IconData icon, required Color iconBgColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: iconBgColor.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: iconBgColor),
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

/// مكون مؤشر التحميل المخصص (منقول من main.dart)
class CustomLoadingIndicator extends StatelessWidget {
  final String? message;
  const CustomLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6b3fa0))),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
