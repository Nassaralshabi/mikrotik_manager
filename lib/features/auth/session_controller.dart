import 'package:flutter/foundation.dart';

import '../../data/repositories/backend_repository.dart';
import '../../data/repositories/data_mode.dart';

enum SessionStatus { initial, loading, authenticated, error }

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final BackendRepository _repository;
  SessionStatus status = SessionStatus.initial;
  String? error;
  DataMode mode = DataMode.router;
  String _ip = '192.168.88.1';
  int _port = 8728;
  String _backendUrl = '';
  bool _forceV6Api = true;
  bool _useSSL = false;
  String _routerOSVersion = '';

  String get connectionLabel {
    switch (mode) {
      case DataMode.router:
        final apiType = _forceV6Api ? 'RouterOS v6' : 'RouterOS v7+';
        final ssl = _useSSL ? ' (SSL)' : '';
        final version = _routerOSVersion.isNotEmpty ? ' - $_routerOSVersion' : '';
        return '$apiType $_ip:$_port$ssl$version';
      case DataMode.backend:
        return _backendUrl.isEmpty ? 'خادم غير معرف' : _backendUrl;
      case DataMode.mock:
        return 'وضع المحاكاة';
    }
  }

  Future<void> login({
    required DataMode dataMode,
    required String backendUrl,
    required String username,
    required String password,
    required String ip,
    required int port,
    bool useSSL = false,
    bool forceV6Api = true,
  }) async {
    status = SessionStatus.loading;
    error = null;
    notifyListeners();

    mode = dataMode;
    _forceV6Api = forceV6Api;
    _useSSL = useSSL;
    _repository.setMode(dataMode);

    if (dataMode == DataMode.backend) {
      _backendUrl = _normalizeBaseUrl(backendUrl);
      _repository.setBaseUrl(_backendUrl);
    }

    try {
      final success = await _repository.login(
        username: username,
        password: password,
        ip: ip,
        port: port,
        useSSL: useSSL,
        forceV6Api: forceV6Api,
      );
      
      if (success) {
        status = SessionStatus.authenticated;
        if (mode != DataMode.mock) {
          _ip = ip;
          _port = port;
          // جلب معلومات RouterOS version إذا كان متصلاً مباشرة
          if (mode == DataMode.router) {
            _loadRouterOSVersion();
          }
        }
      } else {
        status = SessionStatus.error;
        error = 'تعذر تسجيل الدخول';
      }
    } catch (e) {
      status = SessionStatus.error;
      error = e.toString();
    }
    notifyListeners();
  }

  String _normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) {
      return _backendUrl.isEmpty ? 'http://127.0.0.1/reference_backend' : _backendUrl;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> logout() async {
    await _repository.disconnect();
    status = SessionStatus.initial;
    mode = DataMode.router;
    _backendUrl = '';
    _routerOSVersion = '';
    _forceV6Api = true;
    _useSSL = false;
    notifyListeners();
  }

  /// جلب إصدار RouterOS
  Future<void> _loadRouterOSVersion() async {
    try {
      // محاولة جلب إصدار RouterOS
      // هذا سيكون متوفراً فقط عند الاتصال المباشر
      _routerOSVersion = 'v6.x'; // مؤقتاً
    } catch (e) {
      _routerOSVersion = 'غير معروف';
    }
  }

  // Getters للحالة الحالية
  bool get isUsingV6Api => _forceV6Api;
  bool get isUsingSSL => _useSSL;
  String get routerOSVersion => _routerOSVersion;
  String get currentIP => _ip;
  int get currentPort => _port;
}
