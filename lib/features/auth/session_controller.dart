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

  String get connectionLabel {
    switch (mode) {
      case DataMode.router:
        return 'RouterOS $_ip:$_port';
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
  }) async {
    status = SessionStatus.loading;
    error = null;
    notifyListeners();

    mode = dataMode;
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
      );
      if (success) {
        status = SessionStatus.authenticated;
        if (mode != DataMode.mock) {
          _ip = ip;
          _port = port;
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
    notifyListeners();
  }
}
