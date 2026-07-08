import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'routeros_api_client.dart';
import 'routeros_http_client.dart';
import 'mikrotik_client.dart';

class RouterOSService {
  static final RouterOSService _instance = RouterOSService._internal();
  factory RouterOSService() => _instance;
  RouterOSService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  MikrotikClient? _client;
  String? _currentConnectionId;

  // Store connection parameters for reconnect
  String? _lastHost;
  String? _lastPort;
  String? _lastUsername;
  String? _lastPassword;
  bool _lastUseRest = false;

  // Session State Management for persistence across network loss
  final _sessionMetadataKey = 'session_metadata';

  String? get currentConnectionId => _currentConnectionId;
  String? get lastHost => _lastHost;
  String? get lastPort => _lastPort;
  String? get lastUsername => _lastUsername;
  bool get lastUseRest => _lastUseRest;
  bool get hasMultipleConnections => _savedConnections != null && _savedConnections!.length > 1;

  List<Map<String, dynamic>>? _savedConnections;

  Future<void> saveSessionMetadata(Map<String, dynamic> metadata) async {
    await _storage.write(key: _sessionMetadataKey, value: jsonEncode(metadata));
  }

  Future<Map<String, dynamic>?> loadSessionMetadata() async {
    final data = await _storage.read(key: _sessionMetadataKey);
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  MikrotikClient? get client => _client;
  bool get isConnected => _client?.isConnected ?? false;

  // Load all saved connections from secure storage
  Future<List<Map<String, dynamic>>> loadSavedConnections() async {
    final data = await _storage.read(key: 'saved_connections');
    if (data != null) {
      _savedConnections = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      return _savedConnections!;
    }
    _savedConnections = [];
    return [];
  }

  // Get connections with passwords loaded from secure storage
  Future<List<Map<String, dynamic>>> getConnectionsWithPasswords() async {
    final connections = await loadSavedConnections();
    final result = <Map<String, dynamic>>[];

    for (final conn in connections) {
      final id = conn['id'] as String;
      final password = await _storage.read(key: 'conn_password_$id');
      result.add({
        ...conn,
        'password': password ?? '',
      });
    }

    return result;
  }

  // Save all connections
  Future<void> saveSavedConnections(List<Map<String, dynamic>> connections) async {
    _savedConnections = connections;
    await _storage.write(key: 'saved_connections', value: jsonEncode(connections));
  }

  // Add a new connection
  Future<void> addConnection(Map<String, dynamic> connection) async {
    final connections = await loadSavedConnections();
    connections.add(connection);
    await saveSavedConnections(connections);

    // Save password separately
    if (connection['password'] != null) {
      await _storage.write(
        key: 'conn_password_${connection['id']}',
        value: connection['password'],
      );
    }
  }

  // Update an existing connection
  Future<void> updateConnection(String id, Map<String, dynamic> connection) async {
    final connections = await loadSavedConnections();
    final index = connections.indexWhere((c) => c['id'] == id);
    if (index >= 0) {
      connections[index] = connection;
      await saveSavedConnections(connections);

      // Update password separately
      if (connection['password'] != null) {
        await _storage.write(key: 'conn_password_$id', value: connection['password']);
      }
    }
  }

  // Delete a connection
  Future<void> deleteConnection(String id) async {
    final connections = await loadSavedConnections();
    connections.removeWhere((c) => c['id'] == id);
    await saveSavedConnections(connections);
    await _storage.delete(key: 'conn_password_$id');
  }

  // Switch to a different router connection
  Future<MikrotikClient> switchConnection(Map<String, dynamic> connection) async {
    final id = connection['id'] as String;
    final host = connection['host'] as String;
    final port = connection['port'] as String? ?? '';
    final username = connection['username'] as String;
    final password = await _storage.read(key: 'conn_password_$id') ?? '';
    final useRest = connection['useRest'] as bool? ?? false;

    _currentConnectionId = id;

    // Disconnect existing client
    await disconnect();

    // Connect to new router
    if (useRest) {
      final apiPort = port.isEmpty ? '80' : port;
      final restClient = RouterOSHttpClient(
        host: host,
        port: apiPort,
        username: username,
        password: password,
      );
      await restClient.connect();
      _client = restClient;
    } else {
      final apiPort = port.isEmpty ? '8728' : port;
      final legacyClient = RouterOSClient(
        host: host,
        port: apiPort,
        username: username,
        password: password,
      );
      await legacyClient.connect();
      _client = legacyClient;
    }

    return _client!;
  }

  // Direct connection with provided credentials (for initial login)
  Future<MikrotikClient> connectWithCredentials({
    required String host,
    required String port,
    required String username,
    required String password,
    bool useRest = false,
    String? connectionId,
  }) async {
    // Store connection parameters for potential reconnect
    _lastHost = host;
    _lastPort = port;
    _lastUsername = username;
    _lastPassword = password;
    _lastUseRest = useRest;
    _currentConnectionId = connectionId;

    // Disconnect existing client if any
    await disconnect();

    if (useRest) {
      final apiPort = port.isEmpty ? '80' : port;
      final restClient = RouterOSHttpClient(
        host: host,
        port: apiPort,
        username: username,
        password: password,
      );
      await restClient.connect();
      _client = restClient;
    } else {
      final apiPort = port.isEmpty ? '8728' : port;
      final legacyClient = RouterOSClient(
        host: host,
        port: apiPort,
        username: username,
        password: password,
      );
      await legacyClient.connect();
      _client = legacyClient;
    }

    return _client!;
  }

  // Reconnect using last credentials or storage
  Future<MikrotikClient> connect() async {
    if (_client != null) {
      return _client!;
    }

    String? host = _lastHost;
    String? port = _lastPort;
    String? username = _lastUsername;
    String? password = _lastPassword;
    bool useRest = _lastUseRest;

    // If not available, try to read from storage
    if (host == null) {
      host = await _storage.read(key: 'host');
      port = await _storage.read(key: 'port');
      username = await _storage.read(key: 'username');
      password = await _storage.read(key: 'password');
      final useRestStr = await _storage.read(key: 'use_rest');
      useRest = useRestStr == 'true';
    }

    if (host != null && username != null && password != null) {
      return connectWithCredentials(
        host: host,
        port: port ?? '',
        username: username,
        password: password,
        useRest: useRest,
      );
    }

    throw Exception('No connection credentials available');
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'host');
    await _storage.delete(key: 'port');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');
    await _storage.delete(key: 'use_rest');
    _lastHost = null;
    _lastPort = null;
    _lastUsername = null;
    _lastPassword = null;
    _lastUseRest = false;
    _currentConnectionId = null;
  }

  Future<MikrotikClient> reconnect() async {
    await disconnect();
    return connect();
  }
}
