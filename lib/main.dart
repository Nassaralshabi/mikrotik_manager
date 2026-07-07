// main.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- افترض أن هذه الملفات موجودة في مشروعك ---
import 'add_user_screen.dart';
import 'bulk_add_screen.dart';
import 'saved_files_screen.dart';
import 'mqtt_service.dart';
import 'qahtani_link_screen.dart';
import 'profile_screen.dart';
import 'pdf_templates_screen.dart';
import 'network_doctor_screen.dart';
import 'extract_cards_screen.dart';
import 'cards_statistics_screen.dart';
import 'stats_screen.dart';
import 'mikrotik_connector.dart';
import 'backup_system_screen.dart';
import 'active_users_screen.dart';
import 'perf/device_capability.dart';
import 'perf/dio_cache_service.dart';
import 'ai_diagnostics_screen.dart';
import 'database/app_database.dart' as db;
import 'database/sync_service.dart';
import 'monthly_report_screen.dart';
import 'card_search_screen.dart';
import 'ai/diagnostics_history.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
// -----------------------------------------

/// قاعدة البيانات العامة (Singleton — تُستخدم عبر كل التطبيق)
late final db.AppDatabase appDatabase;

/// إقلاع محسّن:
/// 1) تهيئة قدرة الجهاز (low/mid/high) قبل runApp
/// 2) تهيئة قاعدة بيانات SQLite (drift)
/// 3) تمرير MqttService عبر Provider كالمعتاد
void main() async {
  // تهيئة Flutter binding (مطلوبة لـ SharedPreferences و path_provider)
  WidgetsFlutterBinding.ensureInitialized();

  await DeviceCapability.instance.init();

  // تهيئة قاعدة البيانات
  appDatabase = db.AppDatabase();
  DiagnosticsHistoryService.instance.setDao(appDatabase.aiDiagnosticsDao);
  SyncService.setDatabase(appDatabase);

  runApp(
    ChangeNotifierProvider(
      create: (_) => MqttService(scaffoldMessengerKey: scaffoldMessengerKey),
      child: const MyApp(),
    ),
  );
}

// A global key for the ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/* snackbar helpers moved to snackbar_helpers.dart */
// showErrorSnackBar — موجودة في snackbar_helpers.dart

// showSuccessSnackBar — موجودة في snackbar_helpers.dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MikroTik Manager',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}

// صفحة انتقال مخصصة مع animation — محسّنة للأجهزة الضعيفة
// CustomPageRoute مستخرج إلى core/router/custom_page_route.dart

// LoginScreen — مستخرج إلى features/auth/presentation/pages/login_screen.dart
// CustomLoadingIndicator — مستخرج إلى shared/widgets/custom_loading_indicator.dart

