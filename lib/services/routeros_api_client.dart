import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'mikrotik_client.dart';

class RouterOSClient implements MikrotikClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Socket? _socket;
  Completer<List<Map<String, dynamic>>>? _responseCompleter;
  final List<int> _readBuffer = [];
  final List<Map<String, dynamic>> _currentResponse = [];
  Map<String, dynamic>? _currentItem;
  bool _awaitingDone = false;

  static const bool _debug = true;

  void _log(String message) {
    if (_debug) {
      debugPrint('[RouterOS] $message');
    }
  }

  RouterOSClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  bool get isConnected => _isConnected;

  Future<void> _ensureConnected() async {
    if (_socket == null || !_isConnected) {
      _log('Auto-reconnecting...');
      await connect();
    }
  }

  Future<void> connect() async {
    try {
      _log('=== Starting connection ===');
      _log('Host: $host:$port');
      _log('Username: $username');
      _log('Password: ${password.isNotEmpty ? "***" : "(empty)"}');

      _socket = await Socket.connect(host, int.parse(port))
          .timeout(const Duration(seconds: 10));

      _log('✓ Socket connected successfully');

      _setupSocketListener();

      // RouterOS v6.43+ login - send in one sentence
      _writeWord('/login');
      _writeWord('=name=$username');
      _writeWord('=password=$password');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      _log('Login response received: ${response.length} items');

      // Check for error
      for (final item in response) {
        if (item.containsKey('message')) {
          throw Exception('Authentication failed: ${item['message']}');
        }
      }

      _isConnected = true;
      _log('✓ Connection successful!');
    } catch (e) {
      _log('✗ Connection failed: $e');
      _isConnected = false;
      await disconnect();
      rethrow;
    }
  }

  void _setupSocketListener() {
    _socket?.listen(
      (data) {
        _readBuffer.addAll(data);
        _log(
            'Received ${data.length} bytes, buffer size: ${_readBuffer.length}');
        _processBuffer();
      },
      onError: (error) {
        _log('Socket error: $error');
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.completeError(error);
        }
        _isConnected = false;
        _awaitingDone = false;
      },
      onDone: () {
        _log('Socket closed by server');
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(List.from(_currentResponse));
        }
        _isConnected = false;
        _awaitingDone = false;
      },
    );
  }

  void _processBuffer() {
    while (_readBuffer.isNotEmpty) {
      final length = _readLength();
      if (length == null) {
        _log('Need more data to read length');
        return;
      }

      // Check if we have the full word
      if (_readBuffer.length < _encodedLength(length) + length) {
        _log(
            'Need more data: have ${_readBuffer.length}, need ${_encodedLength(length) + length}');
        return;
      }

      // Remove the length bytes
      final lengthBytes = _encodedLength(length);
      _readBuffer.removeRange(0, lengthBytes);

      // Extract the word
      final wordBytes = _readBuffer.sublist(0, length);
      String word;
      try {
        word = utf8.decode(wordBytes, allowMalformed: true);
      } catch (_) {
        word = latin1.decode(wordBytes);
      }
      _readBuffer.removeRange(0, length);

      _log('Read word: "$word" (${word.length} chars)');

      // Empty word - end of sentence
      if (word.isEmpty) {
        _log('Received empty word (end of sentence)');
        continue;
      }

      // Process the word
      _processWord(word);
    }
  }

  int? _readLength() {
    if (_readBuffer.isEmpty) return null;

    final firstByte = _readBuffer[0];

    if (firstByte < 0x80) {
      // 1 byte length
      return firstByte;
    } else if (firstByte < 0xC0) {
      // 2 byte length
      if (_readBuffer.length < 2) return null;
      return ((_readBuffer[0] & 0x3F) << 8) | _readBuffer[1];
    } else if (firstByte < 0xE0) {
      // 3 byte length
      if (_readBuffer.length < 3) return null;
      return ((_readBuffer[0] & 0x1F) << 16) |
          (_readBuffer[1] << 8) |
          _readBuffer[2];
    } else if (firstByte < 0xF0) {
      // 4 byte length
      if (_readBuffer.length < 4) return null;
      return ((_readBuffer[0] & 0x0F) << 24) |
          (_readBuffer[1] << 16) |
          (_readBuffer[2] << 8) |
          _readBuffer[3];
    } else if (firstByte == 0xF0) {
      // 5 byte length
      if (_readBuffer.length < 5) return null;
      return (_readBuffer[1] << 24) |
          (_readBuffer[2] << 16) |
          (_readBuffer[3] << 8) |
          _readBuffer[4];
    }

    // Control byte - not supported
    _log('Unknown control byte: $firstByte');
    return null;
  }

  int _encodedLength(int length) {
    if (length < 0x80) return 1;
    if (length < 0x4000) return 2;
    if (length < 0x200000) return 3;
    if (length < 0x10000000) return 4;
    return 5;
  }

  void _encodeLength(int length, List<int> buffer) {
    if (length < 0x80) {
      buffer.add(length);
    } else if (length < 0x4000) {
      buffer.add(0x80 | (length >> 8));
      buffer.add(length & 0xFF);
    } else if (length < 0x200000) {
      buffer.add(0xC0 | (length >> 16));
      buffer.add((length >> 8) & 0xFF);
      buffer.add(length & 0xFF);
    } else if (length < 0x10000000) {
      buffer.add(0xE0 | (length >> 24));
      buffer.add((length >> 16) & 0xFF);
      buffer.add((length >> 8) & 0xFF);
      buffer.add(length & 0xFF);
    } else {
      buffer.add(0xF0);
      buffer.add((length >> 24) & 0xFF);
      buffer.add((length >> 16) & 0xFF);
      buffer.add((length >> 8) & 0xFF);
      buffer.add(length & 0xFF);
    }
  }

  void _processWord(String word) {
    if (word.startsWith('!re')) {
      // New record starting
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
      }
      _currentItem = {};
      _log('Starting new record');
    } else if (word.startsWith('!done')) {
      // End of response
      _log('Received !done');
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
        _currentItem = null;
      }
      if (_awaitingDone &&
          _responseCompleter != null &&
          !_responseCompleter!.isCompleted) {
        _responseCompleter!.complete(List.from(_currentResponse));
        _currentResponse.clear();
        _awaitingDone = false;
        _responseCompleter = null;
      }
    } else if (word.startsWith('!trap')) {
      // Error response
      _log('Received !trap (error)');
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
      }
      _currentItem = {}; // Start collecting error attributes
    } else if (word.startsWith('!fatal')) {
      // Fatal error
      _log('Received !fatal (fatal error)');
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
      }
      _currentItem = {}; // Start collecting fatal error attributes
    } else if (word.startsWith('=')) {
      // Attribute
      if (_currentItem != null) {
        final equalIndex = word.indexOf('=', 1);
        if (equalIndex > 1) {
          final key = word.substring(1, equalIndex);
          final value = word.substring(equalIndex + 1);
          _currentItem![key] = value;
          _log('  $key = $value');
        } else {
          final key = word.substring(1);
          _currentItem![key] = '';
          _log('  $key = (empty)');
        }
      }
    } else if (word.startsWith('.tag=')) {
      // Tag attribute (for queries)
      if (_currentItem != null) {
        final value = word.substring(5);
        _currentItem!['.tag'] = value;
      }
    }
  }

  void _writeWord(String word) {
    if (_socket == null) {
      throw Exception('Not connected to RouterOS');
    }

    final bytes = utf8.encode(word);
    final length = bytes.length;

    final data = <int>[];
    _encodeLength(length, data);
    data.addAll(bytes);

    _socket!.add(data);
    _log('Wrote word: "$word" ($length bytes)');
  }

  Future<List<Map<String, dynamic>>> _readResponse() async {
    _currentResponse.clear();
    _currentItem = null;
    _awaitingDone = true;
    _responseCompleter = Completer<List<Map<String, dynamic>>>();

    return _responseCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _log('Response timeout after 10 seconds');
        _awaitingDone = false;
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(List.from(_currentResponse));
        }
        return List.from(_currentResponse);
      },
    );
  }

  @override
  void close() => disconnect();

  @override
  Future<Map<String, dynamic>> getSystemResources() async {
    try {
      await _ensureConnected();
      _writeWord('/system/resource/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('System resources response: ${response.length} items');
      if (response.isNotEmpty) {
        return response.first;
      }
      return {};
    } catch (e) {
      _log('Failed to fetch system resources: $e');
      throw Exception('Failed to fetch system resources: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotUsers() async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} hotspot users');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch hotspot users list: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotActiveUsers() async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/active/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} active users');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch active hotspot users: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotProfiles() async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} user profiles');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profiles: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getInterfaceStats() async {
    try {
      await _ensureConnected();
      _writeWord('/interface/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} interface stats');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch interface stats: $e');
    }
  }

  @override
  Future<void> addUser(Map<String, dynamic> user) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/add');
      for (var entry in user.entries) {
        _writeWord('=${entry.key}=${entry.value.toString()}');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to add user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to add user: $e');
    }
  }

  @override
  Future<void> updateUser(String id, Map<String, dynamic> user) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/set');
      _writeWord('=.id=$id');
      for (var entry in user.entries) {
        _writeWord('=${entry.key}=${entry.value.toString()}');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to update user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/remove');
      _writeWord('=.id=$id');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to delete user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to delete hotspot user: $e');
    }
  }

  @override
  Future<void> deleteUserByName(String username) async {
    try {
      await _ensureConnected();
      
      // 1. Find the user record
      _writeWord('/ip/hotspot/user/print');
      _writeWord('?name=$username');
      _writeWord('');
      
      final printResponse = await _readResponse();
      if (_hasError(printResponse)) {
        throw Exception('Failed to find user to delete: ${printResponse.first}');
      }
      
      // Filter in Dart to be absolutely sure
      final targetUsers = printResponse.where((u) => u['name'] == username).toList();
      
      if (targetUsers.isEmpty) {
        _log('! User $username not found on router for deletion');
        return;
      }
      
      // 2. Remove the user
      for (final user in targetUsers) {
        final userId = user['.id'];
        if (userId != null) {
          _writeWord('/ip/hotspot/user/remove');
          _writeWord('=.id=$userId');
          _writeWord('');
          
          final removeResponse = await _readResponse();
          if (_hasError(removeResponse)) {
            _log('✗ Failed to remove user $username ($userId): ${removeResponse.first}');
          } else {
            _log('✓ Successfully removed user $username ($userId)');
          }
        }
      }
    } catch (e) {
      _log('✗ Failed to delete user $username from router: $e');
      throw Exception('Failed to delete user $username from router: $e');
    }
  }

  @override
  Future<void> toggleUserStatus(String id, bool disabled) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/set');
      _writeWord('=.id=$id');
      _writeWord('=disabled=${disabled ? "yes" : "no"}');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to set user status: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to set hotspot user status: $e');
    }
  }

  @override
  Future<void> logoutUser(String id) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/active/remove');
      _writeWord('=.id=$id');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to logout user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to logout hotspot user: $e');
    }
  }

  @override
  Future<void> logoutUserByName(String username) async {
    try {
      await _ensureConnected();
      
      // 1. Find the active session ID for this username
      _writeWord('/ip/hotspot/active/print');
      _writeWord('?user=$username');
      _writeWord('');
      
      final printResponse = await _readResponse();
      if (_hasError(printResponse)) {
        throw Exception('Failed to find active user: ${printResponse.first}');
      }
      
      final activeUsers = printResponse;
      if (activeUsers.isEmpty) {
        // User is not currently logged in, nothing to do
        return;
      }
      
      // 2. Remove all active sessions for this user (usually just one)
      for (final activeUser in activeUsers) {
        final activeId = activeUser['.id'];
        if (activeId != null) {
          _writeWord('/ip/hotspot/active/remove');
          _writeWord('=.id=$activeId');
          _writeWord('');
          
          final removeResponse = await _readResponse();
          if (_hasError(removeResponse)) {
            _log('Failed to remove active session $activeId: ${removeResponse.first}');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to logout user by name: $e');
    }
  }

  @override
  Future<void> logoutHotspotUser(String id) async => logoutUser(id);

  @override
  Future<void> setHotspotUserStatus(String id, bool disabled) async =>
      toggleUserStatus(id, disabled);

  @override
  Future<List<Map<String, dynamic>>> getDhcpLeases() async {
    try {
      await _ensureConnected();
      _writeWord('/ip/dhcp-server/lease/print');
      _writeWord('');
      return await _readResponse();
    } catch (e) {
      throw Exception('Failed to fetch DHCP leases: $e');
    }
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
      // 1. Try standard add
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/add');
      for (var entry in profile.entries) {
        _writeWord('=${entry.key}=${entry.value}');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        final error = response.first['message'] ?? response.first['detail'] ?? 'Unknown error';
        _log('Initial addProfile failed: $error');
        
        if (error.toString().contains('unknown parameter')) {
          _log('Attempting step-by-step add to isolate failing parameter...');
          
          // 2. Try adding with just name
          _writeWord('/ip/hotspot/user/profile/add');
          _writeWord('=name=${profile["name"]}');
          _writeWord('');
          final addResponse = await _readResponse();
          
          if (!_hasError(addResponse)) {
            _log('✓ Created profile with name only');
            
            // Now try to set each parameter one by one
            for (var entry in profile.entries) {
              if (entry.key == 'name') continue;
              
              _writeWord('/ip/hotspot/user/profile/set');
              _writeWord('=.id=${profile["name"]}'); // In API, we can often use name as ID for profiles
              _writeWord('=${entry.key}=${entry.value}');
              _writeWord('');
              
              final setResponse = await _readResponse();
              if (_hasError(setResponse)) {
                _log('✗ FAILED to set parameter "${entry.key}": ${setResponse.first}');
              } else {
                _log('✓ Set parameter: ${entry.key}');
              }
            }
            return; // Success! Return early
          } else {
             throw Exception('Failed to add profile even with name only: ${addResponse.first}');
          }
        } else {
          throw Exception('Failed to add user profile: $error');
        }
      }
    } catch (e) {
      _log('Error in addProfile: $e');
      throw Exception('Failed to add user profile: $e');
    }
  }

  @override
  Future<void> updateProfile(String id, Map<String, dynamic> profile) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/set');
      _writeWord('=.id=$id');
      for (var entry in profile.entries) {
        _writeWord('=${entry.key}=${entry.value.toString()}');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        final error = response.first['message'] ?? response.first['detail'] ?? 'Unknown error';
        _log('Initial updateProfile failed: $error');
        
        if (error.toString().contains('unknown parameter')) {
          _log('Attempting step-by-step update to isolate failing parameter...');
          for (var entry in profile.entries) {
            try {
              await _ensureConnected();
              _writeWord('/ip/hotspot/user/profile/set');
              _writeWord('=.id=$id');
              _writeWord('=${entry.key}=${entry.value.toString()}');
              _writeWord('');
              final stepResponse = await _readResponse();
              if (_hasError(stepResponse)) {
                _log('✗ FAILED to set parameter "${entry.key}": ${stepResponse.first}');
              } else {
                _log('✓ Set parameter: ${entry.key}');
              }
            } catch (e) {
              _log('Error setting ${entry.key}: $e');
            }
          }
        } else {
          throw Exception('Failed to update user profile: $error');
        }
      }
    } catch (e) {
      _log('Error in updateProfile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Future<void> deleteProfile(String id) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/remove');
      _writeWord('=.id=$id');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to remove user profile: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to remove user profile: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotHosts() async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/host/print');
      _writeWord('');
      final response = await _readResponse();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch hotspot hosts: $e');
    }
  }

  @override
  Future<void> setHotspotUserProfile(String id, String profile) async {
    try {
      await _ensureConnected();
      _writeWord('/ip/hotspot/user/set');
      _writeWord('=.id=$id');
      _writeWord('=profile=$profile');
      _writeWord('');
      await _readResponse();
    } catch (e) {
      throw Exception('Failed to set user profile: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFiles() async {
    try {
      await _ensureConnected();
      _writeWord('/file/print');
      _writeWord('');
      return await _readResponse();
    } catch (e) {
      throw Exception('Failed to fetch files: $e');
    }
  }

  @override
  Future<void> deleteFile(String id) async {
    try {
      await _ensureConnected();
      _writeWord('/file/remove');
      _writeWord('=.id=$id');
      _writeWord('');
      await _readResponse();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  @override
  Future<void> createBackup(String name) async {
    try {
      await _ensureConnected();
      _writeWord('/system/backup/save');
      _writeWord('=name=$name');
      _writeWord('');
      await _readResponse();
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  @override
  Future<void> exportConfig(String name) async {
    try {
      await _ensureConnected();
      _writeWord('/export');
      _writeWord('=file=$name');
      _writeWord('');
      await _readResponse();
    } catch (e) {
      throw Exception('Failed to export configuration: $e');
    }
  }

  @override
  Future<String> downloadFile(String name) async {
    try {
      await _ensureConnected();
      _writeWord('/file/get');
      _writeWord('=name=$name');
      _writeWord('');
      final response = await _readResponse();
      if (response.isEmpty) {
        throw Exception('File not found: $name');
      }
      final content = response.first['contents'] ?? '';
      return content.toString();
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  bool _hasError(List<Map<String, dynamic>> response) {
    for (final item in response) {
      if (item.containsKey('message') || item.containsKey('detail')) {
        return true;
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    _awaitingDone = false;
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete([]);
    }
    _responseCompleter = null;
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _readBuffer.clear();
    _currentResponse.clear();
    _currentItem = null;
    _log('Disconnected');
  }
}
