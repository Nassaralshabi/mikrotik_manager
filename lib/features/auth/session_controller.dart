import 'package:flutter/foundation.dart';

import '../../data/repositories/backend_repository.dart';

enum SessionStatus { initial, loading, authenticated, error }

class SessionController extends ChangeNotifier {
  SessionController(this._repository);

  final BackendRepository _repository;
  SessionStatus status = SessionStatus.initial;
  String? error;
  bool offlineMode = false;
  String _ip = '127.0.0.1';
  int _port = 8728;
  String _serverUrl = 'http://127.0.0.1/reference_backend';

  String get connectionLabel {
    return offlineMode ? 'وضع غير متصل' : _serverUrl;
  }

  Future<void> login({
    required String backendUrl,
    required String username,
    required String password,
    required String ip,
    required int port,
    bool offline = false,
  }) async {
    status = SessionStatus.loading;
    error = null;
    notifyListeners();
    offlineMode = offline;
    _repository.setMockMode(offline);
    _serverUrl = _normalizeBaseUrl(backendUrl);
    _repository.setBaseUrl(_serverUrl);
    try {
      final success = await _repository.login(
        username: username,
        password: password,
        ip: ip,
        port: port,
      );
      if (success) {
        status = SessionStatus.authenticated;
        _ip = ip;
        _port = port;
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
      return _serverUrl;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  void logout() {
    status = SessionStatus.initial;
    offlineMode = true;
    notifyListeners();
  }
}
