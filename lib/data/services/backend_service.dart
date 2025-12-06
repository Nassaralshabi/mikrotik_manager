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

  Future<bool> addCards(Map<String, dynamic> cardData) async {
    final uri = Uri.parse('$baseUrl/AddCards.php');
    final response = await _client.post(uri, body: {
      'cards': jsonEncode([cardData]),
    });
    
    if (response.statusCode == 200) {
      final body = response.body.trim();
      return body.contains('done');
    }
    throw Exception('فشل في إضافة البطاقات (${response.statusCode})');
  }

  Future<List<ServiceCard>> fetchFinishedCards({
    String? profile,
    String? hours,
    String? download,
  }) async {
    final body = <String, String>{};
    if (profile != null) body['profile'] = profile;
    if (hours != null) body['hoer'] = hours;
    if (download != null) body['down'] = download;
    if (profile == null && hours == null && download == null) {
      body['p'] = '1'; // جلب جميع البطاقات المنتهية
    }
    
    final response = await _client.post(
      Uri.parse('$baseUrl/load_card_finished.php'),
      body: body,
    );
    final payload = _decodeList(response);
    return payload.map((json) => ServiceCard.fromJson({
      'id': json['user'] ?? '',
      'title': 'بطاقة منتهية',
      'quota': json['down'] ?? 'غير محدد',
      'price': 0.0,
      'status': 'منتهية',
      'username': json['user'],
      'uptime': json['uptime'],
    })).toList();
  }

  Future<bool> blockCard(String cardId) async {
    final uri = Uri.parse('$baseUrl/Block.php');
    final response = await _client.post(uri, body: {
      'id': cardId,
    });
    
    if (response.statusCode == 200) {
      return response.body.trim().contains('done');
    }
    throw Exception('فشل في حظر البطاقة (${response.statusCode})');
  }

  Future<Map<String, dynamic>> getAllUserManagerData() async {
    final response = await _client.get(Uri.parse('$baseUrl/getAllDataUserManager.php'));
    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.isNotEmpty) {
        final decoded = jsonDecode(body);
        return decoded as Map<String, dynamic>;
      }
    }
    return {};
  }

  Future<bool> removeProfile(String profileId) async {
    final uri = Uri.parse('$baseUrl/remove_profile.php');
    final response = await _client.post(uri, body: {
      'id': profileId,
    });
    
    if (response.statusCode == 200) {
      return response.body.trim().contains('done');
    }
    throw Exception('فشل في حذف البروفايل (${response.statusCode})');
  }

  Future<bool> editProfile(Map<String, dynamic> profileData) async {
    final uri = Uri.parse('$baseUrl/edit_profile.php');
    final response = await _client.post(uri, body: profileData);
    
    if (response.statusCode == 200) {
      return response.body.trim().contains('success');
    }
    throw Exception('فشل في تعديل البروفايل (${response.statusCode})');
  }

  Future<bool> addProfile(Map<String, dynamic> profileData) async {
    final uri = Uri.parse('$baseUrl/add_profile.php');
    final response = await _client.post(uri, body: profileData);
    
    if (response.statusCode == 200) {
      return response.body.trim().contains('success');
    }
    throw Exception('فشل في إضافة البروفايل (${response.statusCode})');
  }

  Future<List<dynamic>> getCustomers() async {
    final response = await _client.get(Uri.parse('$baseUrl/customer.php'));
    final payload = _decodeList(response);
    return payload;
  }

  Future<bool> removeUsersFinished() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/remove_users_finished.php'),
      body: {},
    );
    
    if (response.statusCode == 200) {
      return response.body.trim().contains('done');
    }
    throw Exception('فشل في حذف المستخدمين المنتهيين (${response.statusCode})');
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
