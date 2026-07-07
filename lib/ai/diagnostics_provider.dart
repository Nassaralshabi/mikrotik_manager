// ============================================================
//  Diagnostics Provider — Riverpod state management
//  يدير: الإعدادات + المحادثة + التشخيص
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diagnostics_models.dart';
import 'mikrotik_data_collector.dart';
import 'ai_service.dart';
import 'ai_settings_service.dart';
import 'command_executor.dart';
import 'diagnostics_history.dart';

// ============================================================
//  Providers أساسية
// ============================================================

/// يحمّل الإعدادات المحفوظة عند بدء التطبيق
final aiSettingsProvider = FutureProvider<AiSettings>((ref) async {
  return await AiSettingsService.instance.load();
});

/// StateNotifier لإدارة إعدادات الـ AI
final aiSettingsNotifierProvider =
    StateNotifierProvider<AiSettingsNotifier, AsyncValue<AiSettings>>((ref) {
  final initial = ref.watch(aiSettingsProvider);
  return AiSettingsNotifier(initial);
});

class AiSettingsNotifier extends StateNotifier<AsyncValue<AiSettings>> {
  AiSettingsNotifier(super.initial);

  Future<void> update(AiSettings settings) async {
    state = AsyncData(settings);
    await AiSettingsService.instance.save(settings);
  }

  Future<void> setApiKey(String apiKey) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(apiKey: apiKey);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setProvider(AiProvider provider) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    // عند تغيير المزود، نضبط الموديل على الافتراضي للمزود الجديد
    final newSettings = current.copyWith(
      provider: provider,
      model: provider.defaultModel,
    );
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setModel(String model) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(model: model);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setConnectionMethod(MikrotikConnectionMethod method) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(connectionMethod: method);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
  }

  Future<void> setMode(DiagnosticMode mode) async {
    final current = state.valueOrNull ?? AiSettings.default_;
    final newSettings = current.copyWith(mode: mode);
    state = AsyncData(newSettings);
    await AiSettingsService.instance.save(newSettings);
    debugPrint('[AiSettingsNotifier] Mode changed to: ${mode.name}');
  }
}

// ============================================================
//  History Provider — يحمّل الجلسات السابقة
// ============================================================

final diagnosticsHistoryProvider =
    FutureProvider<List<DiagnosticSession>>((ref) async {
  return await DiagnosticsHistoryService.instance.loadAll();
});

/// StateNotifier لإدارة الجلسات المحفوظة (تحديث بعد الحذف/الحفظ)
final historyManagerProvider =
    StateNotifierProvider<HistoryManager, AsyncValue<List<DiagnosticSession>>>(
        (ref) {
  return HistoryManager();
});

class HistoryManager extends StateNotifier<AsyncValue<List<DiagnosticSession>>> {
  HistoryManager() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await DiagnosticsHistoryService.instance.loadAll();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => _load();

  Future<void> deleteSession(String id) async {
    await DiagnosticsHistoryService.instance.delete(id);
    await _load();
  }

  Future<void> clearAll() async {
    await DiagnosticsHistoryService.instance.clearAll();
    await _load();
  }
}

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsNotifier, DiagnosticsState>((ref) {
  return DiagnosticsNotifier(ref);
});

class DiagnosticsNotifier extends StateNotifier<DiagnosticsState> {
  final Ref _ref;
  DiagnosticSession? _currentSession;

  DiagnosticsNotifier(this._ref)
      : super(DiagnosticsState.initial(AiSettings.default_)) {
    // Load settings and listen for changes
    _initSettings();
  }

  Future<void> _initSettings() async {
    final settings = _ref.read(aiSettingsNotifierProvider).valueOrNull ?? AiSettings.default_;
    // Update settings regardless (even if apiKey is empty, other fields may have changed)
    state = state.copyWith(settings: settings);
    if (_currentSession == null) {
      _currentSession = DiagnosticSession.start(
        mode: settings.mode,
        mikrotikIp: null,
      );
    }
    // Listen for future settings changes without recreating the notifier
    _ref.listenManual(aiSettingsNotifierProvider, (_, next) {
      final newSettings = next.valueOrNull;
      if (newSettings != null) {
        updateSettings(newSettings);
      }
    });
  }

  /// الجلسة الحالية (للوصول من UI)
  DiagnosticSession? get currentSession => _currentSession;

  /// ينفذ أمر RouterOS مباشرة
  Future<CommandResult> executeCommand(String command) async {
    if (state.isLoading) {
      throw Exception('جاري تنفيذ عملية أخرى. انتظر...');
    }

    state = state.copyWith(
      isLoading: true,
      loadingStage: 'جاري تنفيذ الأمر...',
      clearLastCommandResult: true,
    );

    try {
      final result = await CommandExecutor.execute(
        command: command,
        method: state.settings.connectionMethod,
      );

      // أضف رسالة بنتيجة الأمر للمحادثة
      final resultMessage = result.success
          ? DiagnosticMessage.assistant(
              '✅ تم تنفيذ الأمر بنجاح (${result.elapsed.inMilliseconds}ms):\n\n'
              '```\n$command\n```\n\n'
              '**المخرجات:**\n```\n${result.output.isEmpty ? "(لا مخرجات)" : result.output}\n```',
              commands: [command],
            )
          : DiagnosticMessage.error(
              '❌ فشل تنفيذ الأمر:\n\n'
              '```\n$command\n```\n\n'
              '**الخطأ:** ${result.error ?? "غير معروف"}',
            );

      state = state.copyWith(
        messages: [...state.messages, resultMessage],
        isLoading: false,
        clearLoadingStage: true,
        lastCommandResult: result,
      );

      // أضف الأمر للجلسة
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          executedCommands: [..._currentSession!.executedCommands, result],
        );
        await _saveSession();
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearLoadingStage: true,
      );
      rethrow;
    }
  }

  /// يحفظ الجلسة الحالية
  Future<void> _saveSession() async {
    if (_currentSession == null) return;
    final session = _currentSession!.copyWith(
      messages: state.messages,
      endedAt: DateTime.now(),
    );
    await DiagnosticsHistoryService.instance.save(session);
  }

  /// يجمع بيانات MikroTik ثم يحللها بالـ AI
  Future<void> runDiagnostics({String? userQuery}) async {
    if (state.isLoading) return;

    final query = userQuery ?? 'حلل حالة الجهاز وحدد أي مشاكل محتملة.';

    // أضف رسالة المستخدم
    state = state.copyWith(
      messages: [...state.messages, DiagnosticMessage.user(query)],
      isLoading: true,
      loadingStage: 'جاري جمع البيانات من MikroTik...',
    );

    try {
      // 1) جمع البيانات
      final settings = state.settings;
      MikrotikSnapshot snapshot;

      if (settings.connectionMethod == MikrotikConnectionMethod.ssh) {
        // SSH: نحتاج بيانات اعتماد من SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final ip = prefs.getString('ip') ?? '';
        final user = prefs.getString('user') ?? '';
        final pass = prefs.getString('pass') ?? '';
        snapshot = await MikrotikDataCollector.collectViaSSH(
          host: ip,
          username: user,
          password: pass,
        );
      } else {
        // RouterOS API
        snapshot = await MikrotikDataCollector.collectViaRouterOS();
      }

      state = state.copyWith(
        lastSnapshot: snapshot,
        loadingStage: 'جاري التحليل بالـ AI...',
      );

      // 2) تحليل بالـ AI
      final result = await AiService.analyze(
        settings: settings,
        userQuery: query,
        snapshotContext: snapshot.toAiContext(),
        conversationHistory: state.messages,
      );

      // 3) أضف رد الـ AI
      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.assistant(
            result.content,
            commands: result.suggestedCommands,
          ),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    } catch (e) {
      debugPrint('[DiagnosticsNotifier] Error: $e');
      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.error('فشل التشخيص: $e'),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    }
  }

  /// يرسل سؤال متابعة بدون جمع بيانات جديدة (يستخدم آخر snapshot)
  Future<void> askFollowUp(String question) async {
    if (state.isLoading) return;
    if (state.lastSnapshot == null) {
      // لا يوجد snapshot — نشغّل تشخيص كامل
      await runDiagnostics(userQuery: question);
      return;
    }

    state = state.copyWith(
      messages: [...state.messages, DiagnosticMessage.user(question)],
      isLoading: true,
      loadingStage: 'جاري التحليل بالـ AI...',
    );

    try {
      final result = await AiService.analyze(
        settings: state.settings,
        userQuery: question,
        snapshotContext: state.lastSnapshot!.toAiContext(),
        conversationHistory: state.messages,
      );

      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.assistant(
            result.content,
            commands: result.suggestedCommands,
          ),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          DiagnosticMessage.error('فشل التحليل: $e'),
        ],
        isLoading: false,
        clearLoadingStage: true,
      );
    }
  }

  /// يمسح المحادثة ويبدأ جلسة جديدة
  Future<void> clearChat() async {
    // احفظ الجلسة الحالية قبل بدء جديدة
    if (_currentSession != null && _currentSession!.messages.isNotEmpty) {
      await _saveSession();
    }
    // ابدأ جلسة جديدة
    _currentSession = DiagnosticSession.start(
      mode: state.settings.mode,
      mikrotikIp: state.lastSnapshot?.ipAddress,
    );
    state = DiagnosticsState.initial(state.settings);
  }

  /// يحدّث الإعدادات (عند تغييرها من شاشة الإعدادات)
  void updateSettings(AiSettings settings) {
    state = state.copyWith(settings: settings);
    // DiagnosticSession.copyWith لا يقبل mode أو mikrotikIp بشكل منفصل
    // نُنشئ جلسة جديدة بالـ mode الجديد عند الحاجة (يحدث في clearChat)
  }
}
