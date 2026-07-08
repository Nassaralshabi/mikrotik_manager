import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/files/files_screen.dart';
import '../screens/hotspot_users/hotspot_users_screen.dart';
import '../screens/hotspot_users/user_profiles_screen.dart';
import '../screens/hotspot_users/hotspot_hosts_screen.dart';
import '../screens/hotspot_users/hotspot_host_detail_screen.dart';
import '../screens/hotspot_users/dhcp_leases_screen.dart';
import '../screens/settings/pdf_templates_editor_screen.dart';
import '../screens/tools/process_image_screen.dart';
import '../screens/backup/backup_system_screen.dart';
import '../services/models.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String usersRoute = '/users';
  static const String profilesRoute = '/profiles';
  static const String hostsRoute = '/hosts';
  static const String dhcpLeasesRoute = '/dhcp-leases';
  static const String settingsRoute = '/settings';
  static const String hostDetailRoute = '/hosts/:id';
  static const String filesRoute = '/files';
  static const String pdfTemplatesEditorRoute = '/settings/pdf-templates';
  static const String processImageRoute = '/tools/process-image';
  static const String backupSystemRoute = '/backup';

  static final router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: initialRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: WelcomeScreen()),
      ),
      GoRoute(
        path: loginRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: LoginScreen()),
      ),
      GoRoute(
        path: dashboardRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: DashboardScreen()),
      ),
      GoRoute(
        path: usersRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: HotspotUsersScreen()),
      ),
      GoRoute(
        path: profilesRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: UserProfilesScreen()),
      ),
      GoRoute(
        path: hostsRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: HotspotHostsScreen()),
      ),
      GoRoute(
        path: hostDetailRoute,
        pageBuilder: (context, state) {
          final host = state.extra as HotspotHost?;
          if (host == null) {
            return const MaterialPage(
                child: Scaffold(body: Center(child: Text('Host not found'))));
          }
          return MaterialPage(child: HotspotHostDetailScreen(host: host));
        },
      ),
      GoRoute(
        path: dhcpLeasesRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: DhcpLeasesScreen()),
      ),
      GoRoute(
        path: filesRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: FilesScreen()),
      ),
      GoRoute(
        path: pdfTemplatesEditorRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: PdfTemplatesEditorScreen()),
      ),
      GoRoute(
        path: processImageRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: ProcessImageScreen()),
      ),
      GoRoute(
        path: backupSystemRoute,
        pageBuilder: (context, state) =>
            const MaterialPage(child: BackupSystemScreen()),
      ),
    ],
  );
}
