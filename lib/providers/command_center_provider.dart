import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/mikrotik_client.dart';
import '../services/routeros_service.dart';
import '../services/routeros_http_client.dart';
import '../services/routeros_api_client.dart';

class RouterStats {
  final String routerId;
  final String routerName;
  final String address;
  final bool isConnected;
  final int? cpuLoad;
  final int? trafficTxMbps;
  final int? trafficRxMbps;
  final int? onlineUsers;
  final String? errorMessage;

  const RouterStats({
    required this.routerId,
    required this.routerName,
    required this.address,
    this.isConnected = false,
    this.cpuLoad,
    this.trafficTxMbps,
    this.trafficRxMbps,
    this.onlineUsers,
    this.errorMessage,
  });
}

class CommandCenterState {
  final List<RouterStats> routers;
  final bool isLoading;
  final String? error;

  const CommandCenterState({
    this.routers = const [],
    this.isLoading = false,
    this.error,
  });

  CommandCenterState copyWith({
    List<RouterStats>? routers,
    bool? isLoading,
    String? error,
  }) {
    return CommandCenterState(
      routers: routers ?? this.routers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get totalOnlineUsers => routers.fold(0, (sum, r) => sum + (r.onlineUsers ?? 0));
  double get avgCpuLoad {
    final connected = routers.where((r) => r.isConnected && r.cpuLoad != null);
    if (connected.isEmpty) return 0;
    return connected.map((r) => r.cpuLoad!).reduce((a, b) => a + b) / connected.length;
  }
  int get totalRouters => routers.length;
  int get onlineRouters => routers.where((r) => r.isConnected).length;
}

class _RouterHistoricalData {
  final int totalTx;
  final int totalRx;
  final DateTime timestamp;
  _RouterHistoricalData(this.totalTx, this.totalRx, this.timestamp);
}

class CommandCenterNotifier extends StateNotifier<CommandCenterState> {
  final Ref _ref;
  final _secureStorage = const FlutterSecureStorage();
  final Map<String, _RouterHistoricalData> _history = {};
  Timer? _refreshTimer;

  CommandCenterNotifier(this._ref) : super(const CommandCenterState()) {
    refresh();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    // Refresh more frequently for command center (every 10s)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<MikrotikClient> _createTemporaryClient(Map<String, dynamic> conn) async {
    final routerId = conn['id'] as String;

    if (routerId == '__active__') {
      final service = _ref.read(routerOSServiceProvider);
      final client = service.client;
      if (client != null && service.isConnected) {
        return client;
      }
      throw Exception('No active connection');
    }

    final host = conn['host'] as String;
    final port = conn['port'] as String? ?? '';
    final username = conn['username'] as String;
    final password = await _secureStorage.read(key: 'conn_password_$routerId') ?? '';
    final useRest = conn['useRest'] as bool? ?? false;

    if (useRest) {
      final apiPort = port.isEmpty ? '80' : port;
      final client = RouterOSHttpClient(host: host, port: apiPort, username: username, password: password);
      await client.connect();
      return client;
    } else {
      final apiPort = port.isEmpty ? '8728' : port;
      final client = RouterOSClient(host: host, port: apiPort, username: username, password: password);
      await client.connect();
      return client;
    }
  }

  Future<List<Map<String, dynamic>>> _buildActiveConnectionMap(RouterOSService service) async {
    return [{
      'id': '__active__',
      'name': 'Current Router',
      'host': service.lastHost ?? '',
      'port': service.lastPort ?? '',
      'username': service.lastUsername ?? '',
      'useRest': service.lastUseRest,
    }];
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: state.routers.isEmpty);

    final service = _ref.read(routerOSServiceProvider);
    final connections = await service.loadSavedConnections();
    final results = <RouterStats>[];
    List<Map<String, dynamic>> routersToMonitor = List.from(connections);

    if (routersToMonitor.isEmpty && service.isConnected) {
      routersToMonitor = await _buildActiveConnectionMap(service);
    }

    if (routersToMonitor.isEmpty) {
      state = state.copyWith(isLoading: false, routers: []);
      return;
    }

    for (final conn in routersToMonitor) {
      final routerId = conn['id'] as String;
      final routerName = conn['name'] as String? ?? 'Router';
      final host = conn['host'] as String;
      final port = conn['port'] as String? ?? '';
      final address = '$host:${port.isEmpty ? "8728" : port}';

      MikrotikClient? client;
      final isActiveSession = routerId == '__active__';

      try {
        client = await _createTemporaryClient(conn);
        final resources = await client.getSystemResources();
        final activeUsers = await client.getHotspotActiveUsers();
        final interfaces = await client.getInterfaceStats();

        final cpuLoad = int.tryParse(resources['cpu-load']?.toString().replaceAll('%', '') ?? '');

        int totalTx = 0;
        int totalRx = 0;
        for (final iface in interfaces) {
          totalTx += int.tryParse(iface['tx-byte']?.toString() ?? '0') ?? 0;
          totalRx += int.tryParse(iface['rx-byte']?.toString() ?? '0') ?? 0;
        }

        // Calculate Rate
        final now = DateTime.now();
        final previous = _history[routerId];
        double txMbps = 0;
        double rxMbps = 0;

        if (previous != null) {
          final seconds = now.difference(previous.timestamp).inSeconds;
          if (seconds > 0) {
            // (delta bytes * 8 bits) / seconds / 1M
            txMbps = ((totalTx - previous.totalTx) * 8) / seconds / 1000000;
            rxMbps = ((totalRx - previous.totalRx) * 8) / seconds / 1000000;
          }
        }
        _history[routerId] = _RouterHistoricalData(totalTx, totalRx, now);

        results.add(RouterStats(
          routerId: routerId,
          routerName: routerName,
          address: address,
          isConnected: true,
          cpuLoad: cpuLoad,
          trafficTxMbps: txMbps.round().clamp(0, 10000),
          trafficRxMbps: rxMbps.round().clamp(0, 10000),
          onlineUsers: activeUsers.length,
        ));
      } catch (e) {
        results.add(RouterStats(
          routerId: routerId,
          routerName: routerName,
          address: address,
          isConnected: false,
          errorMessage: e.toString(),
        ));
      } finally {
        if (!isActiveSession) client?.close();
      }
    }

    state = state.copyWith(isLoading: false, routers: results);
  }
}

final commandCenterProvider =
    StateNotifierProvider<CommandCenterNotifier, CommandCenterState>((ref) {
  return CommandCenterNotifier(ref);
});

final routerOSServiceProvider = Provider<RouterOSService>((ref) {
  return RouterOSService();
});