import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'mikrotik_client.dart';

class RouterOSHttpClient implements MikrotikClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Dio? _dio;

  // Enable debug logging
  static const bool _debug = true;

  void _log(String message) {
    if (_debug) {
      debugPrint('[RouterOS HTTP] $message');
    }
  }

  RouterOSHttpClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  bool get isConnected => _isConnected;

  String get _baseUrl => 'http://$host:$port/rest';

  Future<void> connect() async {
    try {
      _log('=== Starting HTTP connection ===');
      _log('Host: $host:$port');
      _log('Username: $username');

      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ));

      // Test connection by fetching system resources
      await getSystemResources();
      _isConnected = true;
      _log('✓ HTTP Connection successful!');
    } catch (e) {
      _log('✗ HTTP Connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  @override
  void close() {
    _dio?.close();
    _isConnected = false;
  }

  @override
  Future<Map<String, dynamic>> getSystemResources() async {
    final response = await _dio!.get('/system/resource');
    if (response.data is List && (response.data as List).isNotEmpty) {
      return response.data[0] as Map<String, dynamic>;
    }
    if (response.data is Map) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getInterfaceStats() async {
    final response = await _dio!.get('/interface');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotUsers() async {
    final response = await _dio!.get('/ip/hotspot/user');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotActiveUsers() async {
    final response = await _dio!.get('/ip/hotspot/active');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotHosts() async {
    final response = await _dio!.get('/ip/hotspot/host');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotProfiles() async {
    final response = await _dio!.get('/ip/hotspot/user/profile');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> addUser(Map<String, dynamic> user) async {
    try {
      await _dio!.post('/ip/hotspot/user', data: user);
    } on DioException catch (e) {
      _log('Failed to add user: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> user) async {
    try {
      await _dio!.patch('/ip/hotspot/user/$id', data: user);
    } on DioException catch (e) {
      _log('Failed to update user $id: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    await _dio!.delete('/ip/hotspot/user/$id');
  }

  @override
  Future<void> deleteUserByName(String username) async {
    try {
      final response = await _dio!.get('/ip/hotspot/user');
      
      if (response.data is List) {
        final List<dynamic> users = response.data;
        for (final user in users) {
          if (user is Map && user['name'] == username) {
            final id = user['.id'] ?? user['id'];
            if (id != null) {
              await _dio!.delete('/ip/hotspot/user/$id');
              _log('✓ Deleted user $username with ID $id');
              return;
            }
          }
        }
      }
      _log('! User $username not found for deletion');
    } catch (e) {
      _log('Failed to delete user by name: $e');
    }
  }

  @override
  Future<void> toggleUserStatus(String id, bool disabled) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: {'disabled': disabled});
  }

  @override
  Future<void> setHotspotUserProfile(String id, String profile) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: {'profile': profile});
  }

  @override
  Future<void> logoutUser(String id) async {
    await _dio!.delete('/ip/hotspot/active/$id');
  }

  @override
  Future<void> logoutUserByName(String username) async {
    try {
      final response = await _dio!.get('/ip/hotspot/active');
      
      if (response.data is List) {
        final List<dynamic> activeUsers = response.data;
        int count = 0;
        for (final user in activeUsers) {
          if (user is Map && user['user'] == username) {
            final id = user['.id'] ?? user['id'];
            if (id != null) {
              await _dio!.delete('/ip/hotspot/active/$id');
              count++;
            }
          }
        }
        if (count > 0) {
          _log('✓ Logged out $count active sessions for user $username');
        }
      }
    } catch (e) {
      _log('Failed to logout user by name: $e');
    }
  }

  @override
  Future<void> logoutHotspotUser(String id) async => logoutUser(id);

  @override
  Future<void> setHotspotUserStatus(String id, bool disabled) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: {'disabled': disabled});
  }

  @override
  Future<List<Map<String, dynamic>>> getDhcpLeases() async {
    final response = await _dio!.get('/ip/dhcp-server/lease');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> addHotspotUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
    String? validity,
    String? dataLimit,
  }) async {
    await addUser({
      'name': username,
      'password': password,
      'profile': profile,
      if (comment != null) 'comment': comment,
      if (validity != null) 'limit-uptime': validity,
      if (dataLimit != null) 'limit-bytes-total': dataLimit,
    });
  }

  @override
  Future<void> updateHotspotUser({
    required String id,
    required String username,
    required String profile,
    String? comment,
  }) async {
    await updateUser(id, {
      'name': username,
      'profile': profile,
      if (comment != null) 'comment': comment,
    });
  }

  @override
  Future<void> removeHotspotUser(String id) async => deleteUser(id);

  @override
  Future<void> addProfile(Map<String, dynamic> profile) async {
    try {
      // For maximum compatibility, send everything as string first
      final processedData = Map<String, dynamic>.from(profile);
      if (processedData.containsKey('shared-users')) {
        processedData['shared-users'] = processedData['shared-users'].toString();
      }

      // 1. Try bulk add (standard)
      await _dio!.post('/ip/hotspot/user/profile', data: processedData);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      _log('Initial addProfile failed: $errorData');
      
      if (errorData is Map && errorData['message'] == 'unknown parameter') {
        _log('Attempting step-by-step add to isolate failing parameter...');
        
        // 2. Try creating with just the name
        final nameStr = profile['name']?.toString() ?? 'unknown';
        final nameOnly = {'name': nameStr};
        try {
          await _dio!.post('/ip/hotspot/user/profile', data: nameOnly);
          _log('✓ Created profile with name only');
          
          // Now try to update other fields one by one to find the culprit
          for (var entry in profile.entries) {
            if (entry.key == 'name') continue;
            try {
              final profiles = await getHotspotProfiles();
              final newProfile = profiles.firstWhere(
                (p) => p['name'] == nameStr,
                orElse: () => <String, dynamic>{},
              );
              final id = newProfile['.id'] ?? newProfile['id'];
              if (id == null) {
                _log('! Could not find ID for profile $nameStr to set ${entry.key}');
                continue;
              }
              
              await _dio!.patch('/ip/hotspot/user/profile/$id', data: {entry.key: entry.value.toString()});
              _log('✓ Set parameter: ${entry.key}');
            } catch (e2) {
              _log('✗ FAILED to set parameter "${entry.key}": $e2');
            }
          }
          return; // Success! Return early
        } catch (e3) {
          _log('✗ FAILED to create even with name only: $e3');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<void> updateProfile(String id, Map<String, dynamic> profile) async {
    final processedData = Map<String, dynamic>.from(profile);
    if (processedData.containsKey('shared-users')) {
      processedData['shared-users'] = processedData['shared-users'].toString();
    }
    await _dio!.patch('/ip/hotspot/user/profile/$id', data: processedData);
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _dio!.delete('/ip/hotspot/user/profile/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> getFiles() async {
    final response = await _dio!.get('/file');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> deleteFile(String id) async {
    await _dio!.delete('/file/$id');
  }

  @override
  Future<void> createBackup(String name) async {
    await _dio!.post('/system/backup/save', data: {'name': name});
  }

  @override
  Future<void> exportConfig(String name) async {
    await _dio!.post('/export', data: {'file': name});
  }

  @override
  Future<String> downloadFile(String name) async {
    final response = await _dio!.get('/file/$name');
    if (response.data is Map) {
      return response.data['contents'] ?? '';
    }
    return '';
  }
}
