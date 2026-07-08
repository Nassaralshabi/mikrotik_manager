// ============================================================
//  HomeScreen — الشاشة الرئيسية بعد تسجيل الدخول
//  استُخرجت من main.dart لتقليل حجمه
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikrotik_manager/add_user_screen.dart';
import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/saved_files_screen.dart';
import 'package:mikrotik_manager/mqtt_service.dart';
import 'package:mikrotik_manager/v2/providers/mqtt_provider.dart';
import 'package:mikrotik_manager/qahtani_link_screen.dart';
import 'package:mikrotik_manager/profile_screen.dart';
import 'package:mikrotik_manager/pdf_templates_screen.dart';
import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/extract_cards_screen.dart';
import 'package:mikrotik_manager/cards_statistics_screen.dart';
import 'package:mikrotik_manager/stats_screen.dart';
import 'package:mikrotik_manager/mikrotik_connector.dart';
import 'package:mikrotik_manager/backup_system_screen.dart';
import 'package:mikrotik_manager/active_users_screen.dart';
import 'package:mikrotik_manager/ai_diagnostics_screen.dart';
import 'package:mikrotik_manager/database/app_database.dart' as db;
import 'package:mikrotik_manager/database/sync_service.dart';
import 'package:mikrotik_manager/monthly_report_screen.dart';
import 'package:mikrotik_manager/card_search_screen.dart';
import 'package:mikrotik_manager/snackbar_helpers.dart';
import 'package:mikrotik_manager/v2/ui/active_users_v2.dart';
import 'package:mikrotik_manager/shared/widgets/sync_dialog.dart';
import 'package:mikrotik_manager/v2/ui/cards_statistics_v2.dart';
import 'package:mikrotik_manager/perf/device_capability.dart';
import 'package:mikrotik_manager/core/router/custom_page_route.dart';
import 'package:mikrotik_manager/shared/widgets/custom_loading_indicator.dart';
import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/network_tools_screen.dart';
import 'package:mikrotik_manager/network_map_screen.dart';
import 'package:mikrotik_manager/rogue_dhcp_detector_screen.dart';
import 'package:mikrotik_manager/system_dashboard_screen.dart';
import 'package:mikrotik_manager/device_monitoring_screen.dart';
import 'package:mikrotik_manager/edit_pdf_template_screen.dart';
import 'package:mikrotik_manager/process_image_screen.dart';
import 'package:mikrotik_manager/features/auth/presentation/pages/login_screen.dart';
import 'package:mikrotik_manager/screens/user_manager_screen.dart';

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

// --- Data class for Service items ---
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

enum MikrotikMode { userManager, hotspot }

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;
  final MikrotikMode _selectedMode = MikrotikMode.userManager;
  bool _isNetworkLinked = false;
  String _clientName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _loadLinkStatus(); // Reload status on resume
      context.read(mqttServiceProvider).checkAndReconnect();
      final isLinked = _isNetworkLinked; // Use the state variable
      if (isLinked) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          context.read(mqttServiceProvider).publish({'command': 'get_latest_network_details'});
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
      // لا نغلق الاتصال يدوياً - تجمع الاتصالات يديره تلقائياً
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- قائمة الخدمات لتسهيل إدارتها ---
    final List<ServiceItem> services = [
      ServiceItem(
        title: 'إضافة كرت فردي',
        icon: Icons.person_add_alt_1,
        color: const Color(0xFF5C6BC0), // Indigo
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) =>
                AddUserScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, customer: widget.username),
          ));
        },
      ),
      ServiceItem(
        title: 'إضافة كروت جماعية',
        icon: Icons.groups,
        color: const Color(0xFF4CAF50), // Green
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) =>
                BulkAddScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, username: widget.username),
          ));
        },
      ),
      ServiceItem(
        title: 'ربط الشبكة',
        icon: Icons.link,
        color: const Color(0xFF42A5F5), // Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const QahtaniLinkScreen()));
        },
      ),
      ServiceItem(
        title: 'الإحصائيات',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF26A69A), // Teal
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const StatsScreen()));
        },
      ),
      ServiceItem(
        title: 'طبيب الشبكة',
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFF42A5F5), // Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const NetworkDoctorScreen()));
        },
      ),
      ServiceItem(
        title: 'الملفات المحفوظة',
        icon: Icons.folder_copy,
        color: const Color(0xFFFFA726), // Orange
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const SavedFilesScreen()));
        },
      ),
      ServiceItem(
        title: 'إدارة قوالب PDF',
        icon: Icons.picture_as_pdf,
        color: const Color(0xFF78909C), // Blue Grey
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => PdfTemplatesScreen(profiles: _profiles)));
        },
      ),
      ServiceItem(
        title: 'استخراج الكروت',
        icon: Icons.document_scanner_outlined,
        color: const Color(0xFFEF5350), // Red
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ExtractCardsScreen()));
        },
      ),
      ServiceItem(
        title: 'إحصائيات الكروت',
        icon: Icons.bar_chart,
        color: const Color(0xFF9C27B0), // Purple
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const CardsStatisticsScreen()));
        },
      ),
      ServiceItem(
        title: 'كروت عن بُعد (User Manager)',
        icon: Icons.cloud_done_outlined,
        color: const Color(0xFF6A1B9A), // Deep Purple
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const UserManagerScreen()));
        },
      ),
      ServiceItem(
        title: 'المستخدمين النشطين',
        icon: Icons.people_outline,
        color: const Color(0xFF00ACC1), // Cyan
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ActiveUsersScreen()));
        },
      ),
      ServiceItem(
        title: 'الملف الشخصي',
        icon: Icons.account_circle,
        color: const Color(0xFF29B6F6), // Light Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ProfileScreen()));
        },
      ),
      ServiceItem(
        title: 'تشخيص AI',
        icon: Icons.psychology,
        color: const Color(0xFF00BCD4), // Cyan
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const AiDiagnosticsScreen()));
        },
      ),
      ServiceItem(
        title: 'بحث الكروت',
        icon: Icons.search,
        color: const Color(0xFF4CAF50), // Green
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const CardSearchScreen()));
        },
      ),
      ServiceItem(
        title: 'التقارير',
        icon: Icons.assessment,
        color: const Color(0xFFFF9800), // Orange
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const MonthlyReportScreen()));
        },
      ),
      ServiceItem(
        title: 'النسخ الاحتياطي',
        icon: Icons.backup,
        color: const Color(0xFF2196F3), // Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const BackupSystemScreen()));
        },
      ),
      ServiceItem(
        title: 'مزامنة الكروت',
        icon: Icons.sync,
        color: const Color(0xFF66BB6A), // Light Green
        onTap: () async {
          await showSyncDialog(context);
          // بعد المزامنة، أعد تحميل الملفات الشخصية
          _fetchProfiles();
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
              tooltip: 'الإشعارات'),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoadingProfiles
          ? CustomLoadingIndicator(message: 'جاري التحميل...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- بطاقة الحالة ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isNetworkLinked && _clientName.isNotEmpty ? 'العميل' : 'مرحباً بك',
                              style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isNetworkLinked && _clientName.isNotEmpty
                                      ? _clientName
                                      : 'لوحة تحكم MikroTik',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis, // to handle long names
                                ),
                              ),
                              const Icon(Icons.settings_ethernet, color: Colors.white70, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- عنوان قسم الخدمات ---
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0, right: 24.0, left: 24.0, bottom: 12.0),
                    child: Text(
                      'الخدمات الأساسية',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),

                  // --- شبكة الخدمات ---
                  GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 أعمدة لمظهر أفضل على معظم الشاشات
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9, // تعديل النسبة لتناسب المحتوى
                    ),
                    itemCount: services.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return RepaintBoundary(
                        child: _buildServiceGridItem(
                          title: service.title,
                          icon: service.icon,
                          iconBgColor: service.color,
                          onTap: service.onTap,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceGridItem({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        // --- التغيير هنا: تم استخدام لون الأيقونة مع شفافية لخلفية الزر ---
        color: Color.alphaBlend(iconBgColor.withValues(alpha: 0.1), Colors.transparent),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // --- التغيير هنا: تم زيادة وضوح خلفية الأيقونة للتباين ---
                color: Color.alphaBlend(iconBgColor.withValues(alpha: 0.25), Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: iconBgColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
