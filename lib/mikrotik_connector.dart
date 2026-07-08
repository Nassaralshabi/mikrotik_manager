import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MikrotikCredentialsMissingException implements Exception {
  final String message;
  MikrotikCredentialsMissingException(this.message);

  @override
  String toString() => 'MikrotikCredentialsMissingException: $message';
}

class MikrotikConnectionException implements Exception {
  final String message;
  final dynamic originalException;
  MikrotikConnectionException(this.message, [this.originalException]);

  @override
  String toString() => 'MikrotikConnectionException: $message';
}

/// مُوصل MikroTik مع تجمع اتصالات مستمر لتسريع العمليات
class MikrotikConnector {
  static RouterOSClient? _cachedClient;
  static DateTime? _lastUsed;
  static String? _currentIp;
  static String? _currentUser;
  static int _currentPort = 8728;
  static const _maxIdle = Duration(minutes: 3);
  static const _connectTimeout = Duration(seconds: 15);
  static bool _isConnecting = false;

  /// معلومات الاتصال الحالي (للاستخدام في UI والتشخيص)
  static String? get currentIp => _currentIp;
  static String? get currentUser => _currentUser;
  static int get currentPort => _currentPort;
  static bool get isCached => _cachedClient != null;

  /// الحصول على اتصال MikroTik - يعيد الاتصال المخزّن إذا كان نشطاً
  /// أو ينشئ اتصالاً جديداً عند الحاجة فقط
  static Future<RouterOSClient> connect() async {
    // التحقق مما إذا كان الاتصال المخزّن لا يزال صالحاً
    if (_cachedClient != null &&
        _lastUsed != null &&
        DateTime.now().difference(_lastUsed!) < _maxIdle &&
        !_isConnecting) {
      _lastUsed = DateTime.now();
      return _cachedClient!;
    }

    // إذا كان هناك اتصال قديم، أغلقها
    try {
      _cachedClient?.close();
    } catch (_) {}
    _cachedClient = null;

    // قراءة بيانات الاعتماد
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    final pass = prefs.getString('pass');
    final portString = prefs.getString('port');
    final port = portString != null ? (int.tryParse(portString) ?? 8728) : 8728;

    if (ip == null || user == null || pass == null) {
      throw MikrotikCredentialsMissingException(
          'IP address, username, or password are not set.');
    }

    // تجنب إنشاء اتصال مكرر إذا كان جارياً بالفعل
    if (_isConnecting) {
      // انتظر حتى يكتمل الاتصال الحالي
      for (int i = 0; i < 50; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_cachedClient != null && !_isConnecting) {
          _lastUsed = DateTime.now();
          return _cachedClient!;
        }
      }
      throw MikrotikConnectionException('Connection already in progress.');
    }

    _isConnecting = true;
    try {
      final client = RouterOSClient(
        address: ip,
        user: user,
        password: pass,
        port: port,
        verbose: false,
      );

      final bool loggedIn =
          await client.login().timeout(_connectTimeout);
      if (loggedIn) {
        _cachedClient = client;
        _lastUsed = DateTime.now();
        _currentIp = ip;
        _currentUser = user;
        _currentPort = port;
        debugPrint('MikroTik: New connection established to $ip:$port');
        return client;
      } else {
        throw MikrotikConnectionException('Login failed.');
      }
    } on TimeoutException {
      throw MikrotikConnectionException('Connection timed out.');
    } catch (e) {
      _cachedClient = null;
      if (e is MikrotikConnectionException ||
          e is MikrotikCredentialsMissingException) {
        rethrow;
      }
      throw MikrotikConnectionException(
          'An unexpected error occurred.', e);
    } finally {
      _isConnecting = false;
    }
  }

  /// إغلاق الاتصال المخزّن بشكل صريح
  static void forceDisconnect() {
    try {
      _cachedClient?.close();
    } catch (_) {}
    _cachedClient = null;
    _lastUsed = null;
    _isConnecting = false;
    debugPrint('MikroTik: Connection forced closed.');
  }

  /// التحقق مما إذا كان هناك اتصال نشط
  static bool get hasActiveConnection =>
      _cachedClient != null && !_isConnecting;
}
