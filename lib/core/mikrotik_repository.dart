// ============================================================
//  MikrotikRepository — الواجهة الموحّدة للتواصل مع MikroTik
//
//  يدمج: RouterService (talk/talkPaged) + MikrotikConnector (cache/connection)
//  المزايا:
//  - Riverpod Provider للـ DI
//  - Connection pool مع idle timeout 3min
//  - Retry مع exponential backoff
//  - Error handling موحّد
//  - اختبارات (Mockable Interface)
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';

import 'secure_credentials.dart';

// ============================================================
//  أنوع الأخطاء الموحّدة
// ============================================================

sealed class MikrotikFailure {
  final String message;
  final Object? cause;
  const MikrotikFailure(this.message, [this.cause]);
}

class ConnectionFailure extends MikrotikFailure {
  const ConnectionFailure(super.message, [super.cause]);
}

class AuthenticationFailure extends MikrotikFailure {
  const AuthenticationFailure(super.message, [super.cause]);
}

class CredentialsNotFound extends MikrotikFailure {
  const CredentialsNotFound() : super('بيانات اعتماد MikroTik غير موجودة. سجّل الدخول أولاً.');
}

class TimeoutFailure extends MikrotikFailure {
  const TimeoutFailure([String? cause]) : super('انتهت مهلة الاتصال بـ MikroTik', cause);
}

class CommandFailure extends MikrotikFailure {
  const CommandFailure(super.message, [super.cause]);
}

// ============================================================
//  واجهة قابلة للاختبار
// ============================================================

abstract class IMikrotikRepository {
  Future<List<Map<String, dynamic>>> talk(List<String> args);
  Future<List<Map<String, dynamic>>> talkPaged({
    required String path,
    required String proplist,
    int limit = 20,
    int skip = 0,
  });
  Future<void> reconnect();
  Future<void> close();
  bool get isConnected;
}

// ============================================================
//  التنفيذ الفعلي
// ============================================================

class MikrotikRepository implements IMikrotikRepository {
  RouterOSClient? _client;
  DateTime? _lastUsed;
  static const _maxIdle = Duration(minutes: 3);
  static const _connectTimeout = Duration(seconds: 5);
  bool _isConnecting = false;

  // ============================================================
  //  Public API
  // ============================================================

  @override
  bool get isConnected => _client != null && !_isConnecting;

  @override
  Future<List<Map<String, dynamic>>> talk(List<String> args) async {
    final client = await _getClient();
    try {
      final res = await client
          .talk(args)
          .timeout(const Duration(seconds: 15));
      _lastUsed = DateTime.now();
      return res.map((e) => Map<String, dynamic>.from(e)).toList();
    } on TimeoutException {
      _client = null;
      throw const TimeoutFailure();
    } catch (e) {
      _client = null;
      throw CommandFailure('فشل تنفيذ الأمر: $e', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> talkPaged({
    required String path,
    required String proplist,
    int limit = 20,
    int skip = 0,
  }) async {
    final args = [
      path,
      '=.proplist=$proplist',
      '=.limit=$limit',
      '=.skip=$skip',
    ];
    try {
      return await talk(args);
    } catch (e) {
      // Fallback without paging
      return await talk([path, '=.proplist=$proplist']);
    }
  }

  @override
  Future<void> reconnect() async {
    await close();
    await _connect();
  }

  @override
  Future<void> close() async {
    try {
      _client?.close();
    } catch (_) {}
    _client = null;
    _lastUsed = null;
    _isConnecting = false;
  }

  // ============================================================
  //  Connection Management
  // ============================================================

  Future<RouterOSClient> _getClient() async {
    // إعادة استخدام الاتصال المخزّن إذا كان نشطاً
    if (_client != null && _lastUsed != null &&
        DateTime.now().difference(_lastUsed!) < _maxIdle &&
        !_isConnecting) {
      _lastUsed = DateTime.now();
      return _client!;
    }

    return _connect();
  }

  Future<RouterOSClient> _connect() async {
    if (_isConnecting) {
      // انتظر الاتصال الحالي
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_client != null && !_isConnecting) {
          return _client!;
        }
      }
      throw const ConnectionFailure('اتصال آخر قيد التنفيذ.');
    }

    _isConnecting = true;
    try {
      final creds = await SecureCredentials.instance.loadMikrotikCreds();
      if (creds.ip.isEmpty || creds.user.isEmpty || creds.pass.isEmpty) {
        throw const CredentialsNotFound();
      }

      debugPrint('[MikrotikRepository] Connecting to ${creds.ip}:${creds.port}');
      final client = RouterOSClient(
        address: creds.ip,
        user: creds.user,
        password: creds.pass,
        port: creds.port,
        verbose: false,
      );

      final ok = await client.login().timeout(_connectTimeout);
      if (!ok) {
        throw const AuthenticationFailure('فشل تسجيل الدخول إلى MikroTik');
      }

      _client = client;
      _lastUsed = DateTime.now();
      return client;
    } on TimeoutException {
      throw const TimeoutFailure();
    } on MikrotikFailure {
      rethrow;
    } catch (e) {
      throw ConnectionFailure('فشل الاتصال: $e', e);
    } finally {
      _isConnecting = false;
    }
  }

  // ============================================================
  //  Helper — safe call with retry
  // ============================================================

  /// ينفذ عملية مع retry (exponential backoff)
  Future<T> safeCall<T>({
    required Future<T> Function() action,
    int retries = 3,
  }) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        return await action();
      } on ConnectionFailure catch (_) {
        if (attempt == retries) rethrow;
        await Future.delayed(
          Duration(seconds: pow(2, attempt).toInt()),
        );
        await reconnect();
      } on TimeoutFailure catch (_) {
        if (attempt == retries) rethrow;
        await Future.delayed(
          Duration(seconds: pow(2, attempt).toInt()),
        );
      }
    }
    throw ConnectionFailure('فشل بعد $retries محاولات');
  }
}

/// double.pow مستعارة من dart:math
double pow(double x, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= x;
  }
  return result;
}

// ============================================================
//  Riverpod Provider
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider رئيسي — يحقن MikrotikRepository في كل التطبيق
final mikrotikRepositoryProvider = Provider<IMikrotikRepository>((ref) {
  final repo = MikrotikRepository();
  ref.onDispose(() => repo.close());
  return repo;
});
