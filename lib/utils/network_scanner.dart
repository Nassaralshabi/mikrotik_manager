import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class NetworkScannerResult {
  final String ip;
  final int port;
  final bool isRestApi;

  const NetworkScannerResult({
    required this.ip,
    required this.port,
    required this.isRestApi,
  });
}

class NetworkScanner {
  static const _timeout = Duration(milliseconds: 800);
  static const _maxConcurrent = 50;

  /// Mendapatkan subnet prefix dari IP WiFi HP saat ini
  /// Contoh: HP punya IP 192.168.100.5 → return "192.168.100"
  static Future<String> _getCurrentSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            final parts = ip.split('.');
            parts.removeLast();
            return parts.join('.');
          }
        }
      }
    } catch (e) {
      debugPrint('[Scanner] Gagal dapat IP: $e');
    }
    return '';
  }

  /// Scan 1 IP spesifik di port 8728 (API RouterOS)
  static Future<bool> _checkIp(String ip) async {
    try {
      final socket = await Socket.connect(ip, 8728, timeout: _timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Scan semua IP di subnet yang sama dengan WiFi HP
  /// Priority: gateway (.1) dulu, baru 2-254
  static Future<List<NetworkScannerResult>> scanForRouters() async {
    final subnet = await _getCurrentSubnet();
    if (subnet.isEmpty) return [];

    final results = <NetworkScannerResult>[];
    final foundIps = <String>{};

    // Cek gateway dulu (paling sering jadi IP router)
    final gateway = '$subnet.1';
    if (await _checkIp(gateway)) {
      results.add(NetworkScannerResult(
        ip: gateway, port: 8728, isRestApi: false,
      ));
      foundIps.add(gateway);
    }

    // Scan semua IP 2-254
    final semaphore = Semaphore(_maxConcurrent);
    final futures = <Future<void>>[];

    for (var i = 2; i <= 254; i++) {
      futures.add(semaphore.acquire().then((_) async {
        final ip = '$subnet.$i';
        try {
          final socket = await Socket.connect(ip, 8728, timeout: _timeout);
          socket.destroy();
          if (!foundIps.contains(ip)) {
            foundIps.add(ip);
            results.add(NetworkScannerResult(
              ip: ip, port: 8728, isRestApi: false,
            ));
          }
        } catch (_) {}
        semaphore.release();
      }));
    }

    await Future.wait(futures);
    return results;
  }
}

class Semaphore {
  final int maxPermits;
  int _permits;
  final _queue = <Completer<void>>[];

  Semaphore(this.maxPermits) : _permits = maxPermits;

  Future<void> acquire() async {
    if (_permits > 0) {
      _permits--;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      final completer = _queue.removeAt(0);
      completer.complete();
    } else {
      _permits++;
    }
  }
}
