import 'dart:async';
import 'package:router_os_client/router_os_client.dart';
import 'mikrotik_connector.dart';

/// خدمة اتصال مركزية تدير اتصال MikroTik المشترك بين جميع الشاشات
/// تتجنب فتح وإغلاق الاتصال في كل عملية وتوفر إعادة اتصال تلقائية
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._();
  static ConnectionService get instance => _instance;
  ConnectionService._();

  RouterOSClient? _client;
  DateTime? _lastUsed;
  bool _isConnecting = false;

  /// مدة الخمول قبل قطع الاتصال تلقائياً
  static const _idleTimeout = Duration(minutes: 5);

  /// الحصول على اتصال نشط أو إنشاء واحد جديد
  Future<RouterOSClient> getClient() async {
    // إذا كان الاتصال جاري بالفعل، انتظر
    while (_isConnecting) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // تحقق من صلاحية الاتصال الحالي
    if (_client != null && _lastUsed != null &&
        DateTime.now().difference(_lastUsed!) < _idleTimeout) {
      _lastUsed = DateTime.now();
      return _client!;
    }

    // أغلق الاتصال القديم إن وجد
    await _closeExistingClient();

    // إنشاء اتصال جديد
    return _createNewClient();
  }

  Future<RouterOSClient> _createNewClient() async {
    _isConnecting = true;
    try {
      _client = await MikrotikConnector.connect();
      _lastUsed = DateTime.now();
      return _client!;
    } catch (e) {
      _client = null;
      _lastUsed = null;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _closeExistingClient() async {
    try {
      _client?.close();
    } catch (e) {
      // تجاهل أخطاء الإغلاق
    } finally {
      _client = null;
      _lastUsed = null;
    }
  }

  /// قطع الاتصال فوراً (عند تسجيل الخروج مثلاً)
  Future<void> disconnect() async {
    await _closeExistingClient();
  }

  /// تحديث وقت آخر استخدام لمنع الانتهاء التلقائي
  void keepAlive() {
    _lastUsed = DateTime.now();
  }

  /// التحقق مما إذا كان هناك اتصال نشط
  bool get isConnected => _client != null && _lastUsed != null &&
      DateTime.now().difference(_lastUsed!) < _idleTimeout;
}
