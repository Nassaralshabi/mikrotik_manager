// ============================================================
//  MikrotikDataCollector — يجمع بيانات التشخيص من MikroTik
//
//  يدعم طريقتين:
//  1) RouterOS API (موجود مسبقاً عبر router_os_client)
//  2) SSH (عبر dartssh2) — أكثر مرونة، ينفذ أوامر نصية كاملة
// ============================================================

import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mikrotik_connector.dart';
import 'diagnostics_models.dart';

class MikrotikDataCollector {
  MikrotikDataCollector._();

  // ============================================================
  //  الطريقة 1: SSH (الأكثر مرونة)
  // ============================================================

  /// يجمع البيانات عبر SSH (ينفذ أوامر RouterOS النصية)
  static Future<MikrotikSnapshot> collectViaSSH({
    required String host,
    required String username,
    required String password,
    int port = 22,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    SSHClient? client;
    SSHSocket? socket;
    try {
      debugPrint('[MikrotikDataCollector] Connecting via SSH to $host:$port');
      socket = await SSHSocket.connect(
        host,
        port,
        timeout: timeout,
      );
      client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // تنفيذ الأوامر بالتوازي (Future.wait) لتقليل زمن الانتظار
      final results = await Future.wait([
        _executeSafely(client, 'system resource print'),
        _executeSafely(client, 'interface print'),
        _executeSafely(client, 'ip route print'),
        _executeSafely(client, 'ip firewall filter print'),
        _executeSafely(client, 'log print where topics~"error" or topics~"warning"'),
      ]);

      final snapshot = MikrotikSnapshot(
        system: results[0],
        interfaces: results[1],
        routes: results[2],
        firewall: results[3],
        logs: results[4],
        ipAddress: host,
        collectedAt: DateTime.now(),
      );

      debugPrint('[MikrotikDataCollector] SSH collection done, '
          '${snapshot.system.length} chars system, ${snapshot.interfaces.length} chars interfaces');
      return snapshot;
    } catch (e) {
      debugPrint('[MikrotikDataCollector] SSH error: $e');
      rethrow;
    } finally {
      client?.close();
    }
  }

  /// ينفذ أمراً واحداً عبر SSH ويتحمل الأخطاء
  static Future<String> _executeSafely(SSHClient client, String command) async {
    try {
      final result = await client.execute(command);
      // result قد يكون Object أو String حسب الإصدار — نحوّل بأمان
      return result.toString();
    } catch (e) {
      return 'ERROR executing "$command": $e';
    }
  }

  // ============================================================
  //  الطريقة 2: RouterOS API (موجود مسبقاً)
  // ============================================================

  /// يجمع البيانات عبر RouterOS API
  /// يستخدم SharedPreferences للحصول على بيانات الاعتماد المخزّنة
  static Future<MikrotikSnapshot> collectViaRouterOS({
    RouterOSClient? client,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    RouterOSClient? internalClient = client;
    bool createdInternally = false;

    try {
      if (internalClient == null) {
        // استخدم الاتصال المُخزّن من MikrotikConnector أولاً
        try {
          internalClient = await MikrotikConnector.connect();
          debugPrint('[MikrotikDataCollector] Reusing cached connection');
        } catch (e) {
          debugPrint('[MikrotikDataCollector] Cache miss, creating new connection: $e');
          // إذا فشل الاتصال المُخزّن، أنشئ اتصالاً جديداً
          final prefs = await SharedPreferences.getInstance();
          final ip = prefs.getString('ip');
          final user = prefs.getString('user');
          final pass = prefs.getString('pass');
          final portStr = prefs.getString('port') ?? '8728';
          final port = int.tryParse(portStr) ?? 8728;

          if (ip == null || user == null || pass == null) {
            throw Exception('بيانات اعتماد MikroTik غير موجودة. سجّل الدخول أولاً.');
          }

          debugPrint('[MikrotikDataCollector] Connecting via RouterOS API to $ip:$port');
          internalClient = RouterOSClient(
            address: ip,
            user: user,
            password: pass,
            port: port,
            verbose: false,
          );
          final ok = await internalClient.login().timeout(timeout);
          if (!ok) {
            throw Exception('فشل تسجيل الدخول إلى MikroTik');
          }
          createdInternally = true;
        }
      }

      // تنفيذ أوامر RouterOS API
      // كل أمر هو list من المسار + الـ proplist
      final results = await Future.wait([
        _talkSafely(internalClient, ['/system/resource/print']),
        _talkSafely(internalClient, [
          '/interface/print',
          '=.proplist=name,type,running,mac-address,mtu,rx-byte,tx-byte',
        ]),
        _talkSafely(internalClient, [
          '/ip/route/print',
          '=.proplist=dst-address,gateway,distance,active',
        ]),
        _talkSafely(internalClient, [
          '/ip/firewall/filter/print',
          '=.proplist=chain,action,protocol,src-address,dst-address,comment',
        ]),
        _talkSafely(internalClient, ['/log/print']),
      ]);

      final snapshot = MikrotikSnapshot(
        system: _formatMapList(results[0]),
        interfaces: _formatMapList(results[1]),
        routes: _formatMapList(results[2]),
        firewall: _formatMapList(results[3]),
        logs: _formatMapList(results[4]),
        ipAddress: internalClient.address,
        collectedAt: DateTime.now(),
      );

      debugPrint('[MikrotikDataCollector] RouterOS API collection done');
      return snapshot;
    } finally {
      if (createdInternally && internalClient != null) {
        // لا نغلق العميل إذا كان مُمرّراً من خارج (يُديره MikrotikConnector)
        // لكن نغلق الذي أنشأناه داخلياً
        try {
          internalClient.close();
        } catch (_) {}
      }
    }
  }

  /// ينفذ أمر RouterOS ويتحمل الأخطاء
  static Future<List<Map<String, dynamic>>> _talkSafely(
    RouterOSClient client,
    List<String> args,
  ) async {
    try {
      final res = await client.talk(args).timeout(const Duration(seconds: 30));
      return res.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('[MikrotikDataCollector] talk error for $args: $e');
      return [];
    }
  }

  /// يحوّل list من maps إلى نص قابل للقراءة
  static String _formatMapList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '(empty)';
    final buffer = StringBuffer();
    for (final item in data) {
      final entries = item.entries
          .where((e) => !e.key.startsWith('.id'))
          .map((e) => '${e.key}=${e.value}');
      buffer.writeln(entries.join('  '));
    }
    return buffer.toString();
  }

  // ============================================================
  //  Dispatcher — يختار الطريقة المناسبة حسب الإعدادات
  // ============================================================

  static Future<MikrotikSnapshot> collect({
    required MikrotikConnectionMethod method,
    RouterOSClient? routerOSClient,
    // لـ SSH:
    String? sshHost,
    String? sshUsername,
    String? sshPassword,
    int sshPort = 22,
  }) async {
    switch (method) {
      case MikrotikConnectionMethod.routerOS:
        return collectViaRouterOS(client: routerOSClient);
      case MikrotikConnectionMethod.ssh:
        if (sshHost == null || sshUsername == null || sshPassword == null) {
          throw Exception('بيانات SSH غير مكتملة');
        }
        return collectViaSSH(
          host: sshHost,
          username: sshUsername,
          password: sshPassword,
          port: sshPort,
        );
    }
  }
}
