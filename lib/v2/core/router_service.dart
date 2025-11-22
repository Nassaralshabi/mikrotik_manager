import 'dart:async';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouterService {
  RouterOSClient? _client;
  final _lock = AsyncMemoizer<void>();
  int port = 8728;

  static final RouterService _instance = RouterService._internal();
  RouterService._internal();
  factory RouterService() => _instance;

  Future<void> ensureConnected() async {
    await _lock.runOnce(() async {
      if (_client != null) return;
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('ip');
      final user = prefs.getString('user');
      final pass = prefs.getString('pass');
      final p = int.tryParse(prefs.getString('port') ?? '') ?? 8728;
      port = p;
      if (ip == null || user == null || pass == null) {
        throw Exception('Credentials missing');
      }
      final c = RouterOSClient(address: ip, user: user, password: pass, port: port, verbose: false);
      final ok = await c.login().timeout(const Duration(seconds: 5));
      if (!ok) {
        throw Exception('Login failed');
      }
      _client = c;
    });
  }

  Future<List<Map<String, dynamic>>> talk(List<String> args) async {
    await ensureConnected();
    final res = await _client!.talk(args).timeout(const Duration(seconds: 10));
    return res.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> talkPaged({
    required String path,
    required String proplist,
    int limit = 20,
    int skip = 0,
  }) async {
    final args = [path, '=.proplist=$proplist', '=.limit=$limit', '=.skip=$skip'];
    try {
      return await talk(args);
    } catch (_) {
      return await talk([path, '=.proplist=$proplist']);
    }
  }

  Future<void> reconnect() async {
    await close();
    _lock.future.catchError((_) {});
    _lock = AsyncMemoizer<void>();
    await ensureConnected();
  }

  Future<void> close() async {
    _client?.close();
    _client = null;
  }
}

class AsyncMemoizer<T> {
  Future<T>? _future;
  Future<T> runOnce(Future<T> Function() computation) {
    _future ??= computation();
    return _future!;
  }
  Future<T> get future => _future ?? Future.error(StateError('No future'));
}