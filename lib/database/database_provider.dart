// ============================================================
//  Database Providers — Riverpod providers للوصول للـ database
//  يستخدم قاعدة بيانات واحدة (مُهيّأة في main.dart)
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/cards_dao.dart';
import 'daos/profiles_dao.dart';
import 'daos/ai_diagnostics_dao.dart';
import 'daos/executed_commands_dao.dart';

/// مرجع لقاعدة البيانات المُهيّأة في main.dart
/// يتم تعيينه عبر [setAppDatabase] قبل استخدام أي Provider
AppDatabase? _appDatabase;

/// يعيّن قاعدة البيانات (يُستدعى من main.dart بعد تهيئة AppDatabase)
/// هذا يضمن وجود اتصال واحد فقط بقاعدة البيانات
void setAppDatabase(AppDatabase db) {
  _appDatabase = db;
}

/// يرجع قاعدة البيانات المُهيّأة
AppDatabase _getDb() {
  final db = _appDatabase;
  assert(db != null, 'AppDatabase must be initialized before using Riverpod providers. '
      'Call setAppDatabase(db) in main.dart.');
  return db!;
}

/// Singleton للـ database (يبقى حياً طوال عمر التطبيق)
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return _getDb();
});

/// Provider لـ CardsDao
final cardsDaoProvider = Provider<CardsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.cardsDao;
});

/// Provider لـ ProfilesDao
final profilesDaoProvider = Provider<ProfilesDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.profilesDao;
});

/// Provider لـ AiDiagnosticsDao
final aiDiagnosticsDaoProvider = Provider<AiDiagnosticsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.aiDiagnosticsDao;
});

/// Provider لـ ExecutedCommandsDao
final executedCommandsDaoProvider = Provider<ExecutedCommandsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.executedCommandsDao;
});

// ============================================================
//  Stream Providers (reactive queries)
// ============================================================

/// Stream لكل الكروت (يتحدث تلقائياً عند تغيير البيانات)
final watchAllCardsProvider = StreamProvider<List<Card>>((ref) {
  final dao = ref.watch(cardsDaoProvider);
  return dao.watchAllCards();
});

/// Stream للكروت النشطة
final watchActiveCardsProvider = StreamProvider<List<Card>>((ref) {
  final dao = ref.watch(cardsDaoProvider);
  return dao.watchActiveCards();
});

/// Stream للملفات الشخصية
final watchAllProfilesProvider = StreamProvider<List<Profile>>((ref) {
  final dao = ref.watch(profilesDaoProvider);
  return dao.watchAllProfiles();
});

/// Stream لكل جلسات التشخيص
final watchAllDiagnosticsProvider = StreamProvider<List<AiDiagnostic>>((ref) {
  final dao = ref.watch(aiDiagnosticsDaoProvider);
  return dao.watchAllDiagnostics();
});

/// Stream للجلسات المفضلة
final watchFavoriteDiagnosticsProvider =
    StreamProvider<List<AiDiagnostic>>((ref) {
  final dao = ref.watch(aiDiagnosticsDaoProvider);
  return dao.watchFavoriteDiagnostics();
});

/// Stream للأوامر المنفّذة الأخيرة
final watchRecentCommandsProvider =
    StreamProvider<List<ExecutedCommand>>((ref) {
  final dao = ref.watch(executedCommandsDaoProvider);
  return dao.watchRecentCommands(50);
});

// ============================================================
//  Future Providers (one-time queries)
// ============================================================

/// إحصائيات الكروت (تحسب مرة واحدة ثم تُcache)
final cardsStatisticsProvider = FutureProvider<CardsStatistics>((ref) async {
  final dao = ref.watch(cardsDaoProvider);
  return dao.getStatistics();
});

/// إحصائيات الأوامر المنفّذة
final commandsStatisticsProvider = FutureProvider<CommandsStatistics>((ref) async {
  final dao = ref.watch(executedCommandsDaoProvider);
  return dao.getStatistics();
});

/// إحصائيات التشخيصات
final diagnosticsStatisticsProvider =
    FutureProvider<DiagnosticsStatistics>((ref) async {
  final dao = ref.watch(aiDiagnosticsDaoProvider);
  return dao.getStatistics();
});

/// التقرير الشهري للأوامر
final monthlyCommandsReportProvider =
    FutureProvider<List<MonthlyCommandReport>>((ref) async {
  final dao = ref.watch(executedCommandsDaoProvider);
  return dao.getMonthlyReport();
});
