// ============================================================
//  AppRouter — GoRouter مع Riverpod Auth State
//
//  المزايا:
//  - Type-safe paths
//  - Auth redirect تلقائي
//  - Transition animations موحّدة
//  - Riverpod Provider للـ DI
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../perf/device_capability.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';

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
  static const addCard = '/cards/add';
  static const bulkAdd = '/cards/bulk-add';
  static const search = '/cards/search';
  static const stats = '/stats';
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
  static const users = '/users';
  static const savedFiles = '/saved-files';
  static const qahtaniLink = '/qahtani-link';
  static const rogueDhcp = '/security/rogue-dhcp';
  static const processImage = '/tools/ocr';
}

// ============================================================
//  GoRouter Config
// ============================================================

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
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.diagnostics,
        name: 'diagnostics',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.backup,
        name: 'backup',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const SizedBox.shrink(),
      ),
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
