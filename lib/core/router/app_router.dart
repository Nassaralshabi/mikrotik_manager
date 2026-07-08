// ============================================================
//  AppRouter — GoRouter مع Riverpod Auth State
//
//  Routes لكل شاشات التطبيق مع Type-safe paths.
//  الشاشات التي لا تزال تستخدم Navigator.push القديم تعمل بالتوازي.
//  عند الحاجة، استخدم context.pushNamed(AppRoutes.xxx) أو context.goNamed()
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../perf/device_capability.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../ai_diagnostics_screen.dart';
import '../../ai/ai_settings_screen.dart';
import '../../ai/diagnostics_history_screen.dart';
import '../../backup_system_screen.dart';
import '../../profile_screen.dart';
import '../../active_users_screen.dart';
import '../../add_user_screen.dart';
import '../../bulk_add_screen.dart';
import '../../card_search_screen.dart';
import '../../card_list_screen.dart';
import '../../cards_statistics_screen.dart';
import '../../stats_screen.dart';
import '../../saved_files_screen.dart';
import '../../monthly_report_screen.dart';
import '../../network_doctor_screen.dart';
import '../../network_tools_screen.dart';
import '../../network_map_screen.dart';
import '../../rogue_dhcp_detector_screen.dart';
import '../../device_monitoring_screen.dart';
import '../../system_dashboard_screen.dart';
import '../../pdf_templates_screen.dart';
import '../../edit_pdf_template_screen.dart';
import '../../process_image_screen.dart';
import '../../qahtani_link_screen.dart';
import '../../extract_cards_screen.dart';
import '../../screens/user_manager_screen.dart';

// ============================================================
//  Auth State Provider
// ============================================================

/// Auth state provider — يتحقق مما إذا كان المستخدم مسجّل الدخول
final authStateProvider = StateProvider<bool>((ref) => false);

// ============================================================
//  Routes Constants (Type-safe paths)
// ============================================================

class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const diagnostics = '/diagnostics';
  static const diagnosticsHistory = '/diagnostics/history';
  static const diagnosticsSettings = '/diagnostics/settings';
  static const backup = '/backup';
  static const cards = '/cards';
  static const cardsList = '/cards/list';
  static const addCard = '/cards/add';
  static const bulkAdd = '/cards/bulk-add';
  static const search = '/cards/search';
  static const stats = '/stats';
  static const cardsStats = '/cards/stats';
  static const network = '/network';
  static const networkDoctor = '/network/doctor';
  static const networkMap = '/network/map';
  static const networkTools = '/network/tools';
  static const profile = '/profile';
  static const pdfTemplates = '/pdf/templates';
  static const pdfEdit = '/pdf/edit/:id';
  static const monthlyReport = '/report/monthly';
  static const systemDashboard = '/system/dashboard';
  static const deviceMonitor = '/system/monitor';
  static const activeUsers = '/users/active';
  static const savedFiles = '/saved-files';
  static const qahtaniLink = '/qahtani-link';
  static const rogueDhcp = '/security/rogue-dhcp';
  static const processImage = '/tools/ocr';
  static const extractCards = '/tools/extract-cards';
  static const userManager = '/user-manager';
}

// ============================================================
//  GoRouter Config
// ============================================================

/// يُنشئ صفحة مع custom transition (FadeSlideTransition)
Page<dynamic> _buildPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (DeviceCapability.instance.isLowEnd) {
        return FadeTransition(opacity: animation, child: child);
      }
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
  );
}

/// مساعد لإنشاء GoRoute مع CustomTransitionPage
GoRoute _r(String path, String name, Widget Function() builder) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => _buildPage(builder()),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: isLoggedIn ? AppRoutes.home : AppRoutes.login,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final onLogin = state.matchedLocation == AppRoutes.login;
      if (!isLoggedIn && !onLogin) return AppRoutes.login;
      if (isLoggedIn && onLogin) return AppRoutes.home;
      return null;
    },

    routes: [
      _r(AppRoutes.login, 'login', () => const LoginScreen()),
      _r(AppRoutes.home, 'home', () => const HomeScreen()),
      _r(AppRoutes.diagnostics, 'diagnostics', () => const AiDiagnosticsScreen()),
      _r(AppRoutes.diagnosticsSettings, 'diagnostics-settings', () => const AiSettingsScreen()),
      _r(AppRoutes.diagnosticsHistory, 'diagnostics-history', () => const DiagnosticsHistoryScreen()),
      _r(AppRoutes.backup, 'backup', () => const BackupSystemScreen()),
      _r(AppRoutes.profile, 'profile', () => const ProfileScreen()),
      _r(AppRoutes.activeUsers, 'active-users', () => const ActiveUsersScreen()),
      _r(AppRoutes.cardsList, 'cards-list', () => const CardListScreen()),
      _r(AppRoutes.search, 'search', () => const CardSearchScreen()),
      _r(AppRoutes.cardsStats, 'cards-stats', () => const CardsStatisticsScreen()),
      _r(AppRoutes.stats, 'stats', () => const StatsScreen()),
      _r(AppRoutes.savedFiles, 'saved-files', () => const SavedFilesScreen()),
      _r(AppRoutes.monthlyReport, 'monthly-report', () => const MonthlyReportScreen()),
      _r(AppRoutes.networkDoctor, 'network-doctor', () => const NetworkDoctorScreen()),
      _r(AppRoutes.networkTools, 'network-tools', () => const NetworkToolsScreen()),
      _r(AppRoutes.networkMap, 'network-map', () => const NetworkMapScreen()),
      _r(AppRoutes.rogueDhcp, 'rogue-dhcp', () => const RogueDhcpDetectorScreen()),
      _r(AppRoutes.deviceMonitor, 'device-monitor', () => const DeviceMonitoringScreen()),
      _r(AppRoutes.systemDashboard, 'system-dashboard', () => const SystemDashboardScreen()),
      _r(AppRoutes.pdfTemplates, 'pdf-templates', () => const PdfTemplatesScreen()),
      _r(AppRoutes.processImage, 'process-image', () => const ProcessImageScreen()),
      _r(AppRoutes.qahtaniLink, 'qahtani-link', () => const QahtaniLinkScreen()),
      _r(AppRoutes.extractCards, 'extract-cards', () => const ExtractCardsScreen()),
      _r(AppRoutes.userManager, 'user-manager', () => const UserManagerScreen()),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('الصفحة غير موجودة')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('المسار: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});
