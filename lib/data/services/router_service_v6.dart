import 'package:router_os_client/router_os_client.dart';

import '../models/device_info.dart';
import '../models/router_session.dart';
import '../models/service_card.dart';
import '../models/user_profile.dart';
import 'mikrotik_v6_api.dart';

class RouterService {
  RouterOSClient? _client;
  MikroTikV6Api? _v6Api;
  bool _useV6Api = false;
  String _lastHost = '';
  int _lastPort = 8728;
  String _lastUsername = '';
  String _lastPassword = '';
  bool _isConnected = false;

  /// تسجيل الدخول مع دعم RouterOS v6 و v7
  Future<bool> login({
    required String host,
    required String username,
    required String password,
    int port = 8728,
    bool useSSL = false,
    bool forceV6Api = false,
  }) async {
    try {
      _lastHost = host;
      _lastPort = port;
      _lastUsername = username;
      _lastPassword = password;
      _useV6Api = forceV6Api;

      if (_useV6Api || await _shouldUseV6Api(host, port)) {
        // استخدام API المخصص لـ RouterOS v6
        _v6Api = MikroTikV6Api();
        await _v6Api!.connect(host: host, port: port);
        final success = await _v6Api!.login(username, password);
        _isConnected = success;
        return success;
      } else {
        // استخدام المكتبة العادية لـ RouterOS v7+
        _client = RouterOSClient();
        await _client!.connect(
          host: host,
          port: port,
          username: username,
          password: password,
          useSSL: useSSL,
        );
        _isConnected = true;
        return true;
      }
    } catch (e) {
      _isConnected = false;
      throw Exception('فشل تسجيل الدخول في MikroTik: $e');
    }
  }

  /// فحص إذا كان يجب استخدام V6 API
  Future<bool> _shouldUseV6Api(String host, int port) async {
    try {
      // محاولة اتصال سريع للتحقق من الإصدار
      final testApi = MikroTikV6Api();
      await testApi.connect(host: host, port: port);
      await testApi.disconnect();
      return true; // إذا نجح الاتصال، استخدم V6 API
    } catch (e) {
      return false; // إذا فشل، استخدم المكتبة العادية
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    try {
      if (_useV6Api && _v6Api != null) {
        await _v6Api!.disconnect();
      } else if (_client != null) {
        await _client!.disconnect();
      }
    } catch (e) {
      // تجاهل أخطاء القطع
    } finally {
      _isConnected = false;
    }
  }

  /// الحصول على المستخدمين النشطين
  Future<List<RouterSession>> getActiveSessions() async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        final sessions = await _v6Api!.getActiveSessions();
        return sessions.map((session) => RouterSession.fromMikroTikV6(session)).toList();
      } else {
        // استخدام المكتبة العادية
        final result = await _client!.runCommand(['/tool/user-manager/session/print', '?active=yes']);
        return result.map((session) => RouterSession.fromJson(session)).toList();
      }
    } catch (e) {
      throw Exception('خطأ في جلب الجلسات النشطة: $e');
    }
  }

  /// الحصول على جميع المستخدمين
  Future<List<UserProfile>> getAllUsers() async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        final users = await _v6Api!.getAllUsers();
        return users.map((user) => UserProfile.fromMikroTikV6(user)).toList();
      } else {
        final result = await _client!.runCommand(['/tool/user-manager/user/print']);
        return result.map((user) => UserProfile.fromJson(user)).toList();
      }
    } catch (e) {
      throw Exception('خطأ في جلب المستخدمين: $e');
    }
  }

  /// إضافة مستخدم جديد
  Future<bool> addUser({
    required String username,
    required String password,
    String? customer,
    String? profile,
    bool? callerIdBind,
  }) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        final result = await _v6Api!.addUser(
          username: username,
          password: password,
          customer: customer,
          profile: profile,
          callerIdBind: callerIdBind,
        );
        return result.isNotEmpty;
      } else {
        final cmd = ['/tool/user-manager/user/add'];
        cmd.add('=username=$username');
        cmd.add('=password=$password');
        
        if (customer != null) cmd.add('=customer=$customer');
        if (profile != null) cmd.add('=profile=$profile');
        if (callerIdBind != null) {
          cmd.add('=caller-id-bind-on-first-use=${callerIdBind ? \"yes\" : \"no\"}');
        }

        await _client!.runCommand(cmd);
        return true;
      }
    } catch (e) {
      throw Exception('خطأ في إضافة المستخدم: $e');
    }
  }

  /// إنشاء وتفعيل بروفايل
  Future<bool> createAndActivateProfile({
    required String userId,
    required String profile,
    required String customer,
  }) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        final result = await _v6Api!.createAndActivateProfile(
          userId: userId,
          profile: profile,
          customer: customer,
        );
        return result.isNotEmpty;
      } else {
        await _client!.runCommand([
          '/tool/user-manager/user/create-and-activate-profile',
          '=.id=$userId',
          '=profile=$profile',
          '=customer=$customer'
        ]);
        return true;
      }
    } catch (e) {
      throw Exception('خطأ في تفعيل البروفايل: $e');
    }
  }

  /// حذف مستخدم
  Future<bool> removeUser(String userId) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.removeUser(userId);
      } else {
        await _client!.runCommand(['/tool/user-manager/user/remove', '=.id=$userId']);
        return true;
      }
    } catch (e) {
      throw Exception('خطأ في حذف المستخدم: $e');
    }
  }

  /// تفعيل/تعطيل مستخدم
  Future<bool> enableDisableUser(String userId, bool enable) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.enableDisableUser(userId, enable);
      } else {
        await _client!.runCommand([
          '/tool/user-manager/user/set',
          '=.id=$userId',
          '=disabled=${enable ? \"no\" : \"yes\"}'
        ]);
        return true;
      }
    } catch (e) {
      throw Exception('خطأ في تعديل حالة المستخدم: $e');
    }
  }

  /// الحصول على البروفايلات
  Future<List<Map<String, dynamic>>> getProfiles() async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.getProfiles();
      } else {
        return await _client!.runCommand(['/tool/user-manager/profile/print']);
      }
    } catch (e) {
      throw Exception('خطأ في جلب البروفايلات: $e');
    }
  }

  /// الحصول على العملاء
  Future<List<Map<String, dynamic>>> getCustomers() async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.getCustomers();
      } else {
        return await _client!.runCommand(['/tool/user-manager/customer/print']);
      }
    } catch (e) {
      throw Exception('خطأ في جلب العملاء: $e');
    }
  }

  /// الحصول على معلومات النظام
  Future<Map<String, dynamic>> getSystemInfo() async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.getSystemInfo();
      } else {
        final result = await _client!.runCommand(['/system/resource/print']);
        return result.isNotEmpty ? result.first : {};
      }
    } catch (e) {
      throw Exception('خطأ في جلب معلومات النظام: $e');
    }
  }

  /// البحث عن مستخدم
  Future<List<Map<String, dynamic>>> findUser(String field, String value) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.findUser(field, value);
      } else {
        return await _client!.runCommand([
          '/tool/user-manager/user/print',
          '?$field=$value'
        ]);
      }
    } catch (e) {
      throw Exception('خطأ في البحث عن المستخدم: $e');
    }
  }

  /// إعادة الاتصال
  Future<bool> reconnect() async {
    if (_lastHost.isNotEmpty) {
      await disconnect();
      return await login(
        host: _lastHost,
        username: _lastUsername,
        password: _lastPassword,
        port: _lastPort,
        forceV6Api: _useV6Api,
      );
    }
    return false;
  }

  /// فحص حالة الاتصال
  Future<bool> checkConnection() async {
    if (!_isConnected) return false;
    
    try {
      await getSystemInfo();
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// تنفيذ أمر مخصص
  Future<List<Map<String, dynamic>>> runCustomCommand(List<String> command) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      if (_useV6Api && _v6Api != null) {
        return await _v6Api!.command(command);
      } else {
        return await _client!.runCommand(command);
      }
    } catch (e) {
      throw Exception('خطأ في تنفيذ الأمر: $e');
    }
  }

  /// الحصول على إصدار RouterOS
  Future<String> getRouterOSVersion() async {
    try {
      final systemInfo = await getSystemInfo();
      return systemInfo['version'] ?? 'غير معروف';
    } catch (e) {
      return 'غير متاح';
    }
  }

  /// اختبار الاتصال
  static Future<bool> testConnection({
    required String host,
    int port = 8728,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final testApi = MikroTikV6Api();
      await testApi.connect(host: host, port: port, timeout: timeout);
      await testApi.disconnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Getters
  bool get isConnected => _isConnected;
  String get connectionInfo => _useV6Api 
    ? 'MikroTik RouterOS v6 - $_lastHost:$_lastPort'
    : 'MikroTik RouterOS v7+ - $_lastHost:$_lastPort';
  bool get isUsingV6Api => _useV6Api;
  String get lastHost => _lastHost;
  int get lastPort => _lastPort;
}"