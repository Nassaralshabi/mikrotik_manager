import 'dart:async';

import 'package:intl/intl.dart';
import 'package:router_os_client/router_os_client.dart';

import '../models/backup_job.dart';
import '../models/device_info.dart';
import '../models/router_session.dart';
import '../models/service_card.dart';
import '../models/user_profile.dart';

class RouterService {
  RouterOSClient? _client;
  String? endpointLabel;
  List<double> _lastThroughput = const [];

  Future<void> connect({
    required String ip,
    required String username,
    required String password,
    required int port,
  }) async {
    _client?.close();
    final client = RouterOSClient(
      address: ip,
      user: username,
      password: password,
      port: port,
      timeout: const Duration(seconds: 8),
    );
    final loggedIn = await client.login().timeout(const Duration(seconds: 10));
    if (!loggedIn) {
      client.close();
      throw Exception('فشل تسجيل الدخول إلى الراوتر');
    }
    _client = client;
    endpointLabel = '$ip:$port';
  }

  Future<void> disconnect() async {
    _client?.close();
    _client = null;
    endpointLabel = null;
  }

  Future<List<RouterSession>> fetchActiveSessions() async {
    final rows = await _talk(['/ip/hotspot/active/print']);
    final sessions = rows.map((row) {
      final uptime = _parseDuration(row['uptime'] as String?);
      final downloadMbps = _calculateMbps(row['bytes-out'], uptime);
      final uploadMbps = _calculateMbps(row['bytes-in'], uptime);
      return RouterSession(
        username: (row['user'] as String?)?.trim().isNotEmpty == true ? row['user'] as String : 'مجهول',
        ipAddress: (row['address'] as String?) ?? (row['mac-address'] as String?) ?? 'غير معروف',
        uptime: uptime,
        downloadMbps: downloadMbps,
        uploadMbps: uploadMbps,
      );
    }).toList();
    _lastThroughput = sessions.map((s) => s.downloadMbps).toList();
    return sessions;
  }

  Future<List<UserProfile>> fetchProfiles() async {
    final rows = await _talk(['/ip/hotspot/user/print']);
    return rows.map((row) {
      final comment = (row['comment'] as String?) ?? '';
      final balance = _extractNumber(comment);
      return UserProfile(
        id: (row['.id'] as String?) ?? row['name']?.toString() ?? '',
        name: (row['name'] as String?) ?? 'غير معروف',
        plan: (row['profile'] as String?) ?? 'خطة افتراضية',
        balance: balance,
        activeSessions: 0,
        isSuspended: (row['disabled'] as String?) == 'true',
      );
    }).toList();
  }

  Future<List<ServiceCard>> fetchCards() async {
    final rows = await _talk(['/ip/hotspot/user/profile/print']);
    return rows.map((row) {
      final quota = (row['rate-limit'] as String?) ?? (row['session-timeout'] as String?) ?? 'غير محدود';
      final price = _extractNumber(row['comment'] as String? ?? '');
      return ServiceCard(
        id: (row['.id'] as String?) ?? row['name']?.toString() ?? '',
        title: (row['name'] as String?) ?? 'ملف غير مسمى',
        quota: quota,
        price: price,
        status: (row['disabled'] as String?) == 'true' ? 'موقوفة' : 'متاحة',
      );
    }).toList();
  }

  Future<List<DeviceInfo>> fetchDevices() async {
    final rows = await _talk(['/interface/print']);
    return rows.map((row) {
      final status = (row['running'] as String?) == 'true'
          ? 'online'
          : ((row['disabled'] as String?) == 'true' ? 'offline' : 'warning');
      return DeviceInfo(
        id: (row['.id'] as String?) ?? row['name']?.toString() ?? '',
        name: (row['name'] as String?) ?? 'Interface',
        ip: (row['mac-address'] as String?) ?? (row['comment'] as String?) ?? 'غير متاح',
        location: (row['comment'] as String?) ?? 'غير محدد',
        status: status,
        latencyMs: _parseDouble(row['actual-mtu']) / 10,
      );
    }).toList();
  }

  Future<List<BackupJob>> fetchBackups() async {
    try {
      final rows = await _talk(['/system/backup/print']);
      return rows.map((row) {
        final sizeMb = _parseSizeMb(row['size']);
        final status = (row['disabled'] as String?) == 'true'
            ? 'failed'
            : 'success';
        return BackupJob(
          id: (row['.id'] as String?) ?? row['name']?.toString() ?? '',
          type: (row['name'] as String?) ?? 'Backup',
          lastRun: _parseRouterDate(row['creation-time'] as String?),
          sizeMb: sizeMb,
          status: status,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  List<double> throughputSeries() => _lastThroughput;

  Future<List<Map<String, dynamic>>> _talk(List<String> command) async {
    final client = _client;
    if (client == null) {
      throw Exception('غير متصل بالراوتر');
    }
    final response = await client.talk(command);
    return response.cast<Map<String, dynamic>>();
  }

  Duration _parseDuration(String? value) {
    if (value == null || value.isEmpty) {
      return Duration.zero;
    }
    final regex = RegExp(r'(\d+)([wdhms])');
    int weeks = 0, days = 0, hours = 0, minutes = 0, seconds = 0;
    for (final match in regex.allMatches(value)) {
      final number = int.tryParse(match.group(1) ?? '') ?? 0;
      switch (match.group(2)) {
        case 'w':
          weeks = number;
          break;
        case 'd':
          days = number;
          break;
        case 'h':
          hours = number;
          break;
        case 'm':
          minutes = number;
          break;
        case 's':
          seconds = number;
          break;
      }
    }
    return Duration(
      days: days + weeks * 7,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  double _calculateMbps(dynamic bytesValue, Duration uptime) {
    final bytes = _parseDouble(bytesValue);
    final seconds = uptime.inSeconds <= 0 ? 1 : uptime.inSeconds;
    final bits = bytes * 8;
    return bits / seconds / 1000000;
  }

  double _parseDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  double _parseSizeMb(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble() / (1024 * 1024);
    }
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower.endsWith('kb') || lower.endsWith('k')) {
        final numValue = double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        return numValue / 1024;
      }
      if (lower.endsWith('mb') || lower.endsWith('m')) {
        return double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
      if (lower.endsWith('gb') || lower.endsWith('g')) {
        return (double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0) * 1024;
      }
      return double.tryParse(lower.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    }
    return 0;
  }

  DateTime _parseRouterDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now();
    }
    try {
      final format = DateFormat('MMM/dd/yyyy HH:mm:ss', 'en_US');
      return format.parseUtc(value).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  double _extractNumber(String? source) {
    if (source == null) {
      return 0;
    }
    final match = RegExp(r'-?[0-9]+(\.[0-9]+)?').firstMatch(source);
    if (match == null) {
      return 0;
    }
    return double.tryParse(match.group(0)!) ?? 0;
  }
}
