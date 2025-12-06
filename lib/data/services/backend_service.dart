import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backup_job.dart';
import '../models/device_info.dart';
import '../models/router_session.dart';
import '../models/service_card.dart';
import '../models/user_profile.dart';

class BackendService {
  BackendService({
    required String baseUrl,
    http.Client? client,
    this.useMockData = false,
  })  : _baseUrl = baseUrl,
        _client = client ?? http.Client();

  final http.Client _client;
  String _baseUrl;
  bool useMockData;

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String value) {
    _baseUrl = value;
  }

  void toggleMock(bool value) {
    useMockData = value;
  }

  Future<bool> login({
    required String username,
    required String password,
    required String ip,
    required int port,
  }) async {
    final uri = Uri.parse('$baseUrl/login.php');
    final response = await _client.post(uri, body: {
      'user': username,
      'pass': password,
      'ip': ip,
      'port': port.toString(),
      'login': 'true',
    });
    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.toLowerCase().contains('true')) {
        return true;
      }
      throw Exception(body.isEmpty ? 'فشل تسجيل الدخول' : body);
    }
    throw Exception('فشل الاتصال (${response.statusCode})');
  }

  Future<List<RouterSession>> fetchActiveSessions() async {
    final response = await _client.get(Uri.parse('$baseUrl/load_active.php'));
    final payload = _decodeList(response);
    return payload.map((json) => RouterSession.fromJson(json)).toList();
  }

  Future<List<UserProfile>> fetchProfiles() async {
    final response = await _client.get(Uri.parse('$baseUrl/load_profile.php'));
    final payload = _decodeList(response);
    return payload.map((json) => UserProfile.fromJson(json)).toList();
  }

  Future<List<ServiceCard>> fetchCards() async {
    final response = await _client.get(Uri.parse('$baseUrl/load_card_finished.php'));
    final payload = _decodeList(response);
    return payload.map((json) => ServiceCard.fromJson(json)).toList();
  }

  Future<List<DeviceInfo>> fetchDevices() async {
    final response = await _client.get(Uri.parse('$baseUrl/devices.php'));
    final payload = _decodeList(response);
    return payload.map((json) => DeviceInfo.fromJson(json)).toList();
  }

  Future<List<BackupJob>> fetchBackups() async {
    final response = await _client.get(Uri.parse('$baseUrl/backup.php'));
    final payload = _decodeList(response);
    return payload.map((json) => BackupJob.fromJson(json)).toList();
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final body = response.body.trim();
    if (body.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map && decoded['data'] is List) {
      return decoded['data'] as List;
    }
    throw Exception('تنسيق بيانات غير متوقع');
  }
}
