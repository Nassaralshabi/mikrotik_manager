// main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'v2/providers/mqtt_provider.dart';
import 'perf/device_capability.dart';
import 'database/app_database.dart' as db;
import 'database/sync_service.dart';
import 'core/services/card_save_service.dart';
import 'database/database_provider.dart';
import 'database/migration_service.dart';
import 'ai/diagnostics_history.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

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
  CardSaveService.setDatabase(appDatabase);
  setAppDatabase(appDatabase);
  
  // تشغيل الترحيل في الخلفية (لا يمنع التطبيق)
  MigrationService.instance.migrateIfNeeded(appDatabase).catchError((e) {
    debugPrint('[main] Migration error: $e');
  });

  runApp(
    ProviderScope(
      overrides: [
        // تمرير scaffoldMessengerKey إلى MqttService عبر Riverpod
        scaffoldMessengerKeyProvider.overrideWithValue(scaffoldMessengerKey),
      ],
      child: const MyApp(),
    ),
  );
}

// A global key for the ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/* snackbar helpers moved to snackbar_helpers.dart */
// showErrorSnackBar — موجودة في snackbar_helpers.dart

// showSuccessSnackBar — موجودة في snackbar_helpers.dart

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MikroTik Manager',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

// صفحة انتقال مخصصة مع animation — محسّنة للأجهزة الضعيفة
// CustomPageRoute مستخرج إلى core/router/custom_page_route.dart

// LoginScreen — مستخرج إلى features/auth/presentation/pages/login_screen.dart
// CustomLoadingIndicator — مستخرج إلى shared/widgets/custom_loading_indicator.dart

