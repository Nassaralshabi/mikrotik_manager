import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

/// دعم MikroTik RouterOS v6 API
class MikroTikV6Api {
  late Socket _socket;
  bool _isConnected = false;
  String _host = '';
  int _port = 8728;
  Duration _timeout = const Duration(seconds: 30);

  /// الاتصال بـ MikroTik Router
  Future<bool> connect({
    required String host,
    int port = 8728,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      _host = host;
      _port = port;
      _timeout = timeout;

      _socket = await Socket.connect(host, port, timeout: timeout);
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      throw Exception('فشل الاتصال بـ MikroTik: $e');
    }
  }

  /// تسجيل الدخول
  Future<bool> login(String username, String password) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      // إرسال أمر تسجيل الدخول
      await _sendCommand(['/login']);
      final response = await _readResponse();
      
      if (response.isEmpty) {
        throw Exception('لا يوجد رد من الراوتر');
      }

      // التحقق من نوع المصادقة
      if (response['!trap'] != null) {
        throw Exception('خطأ في تسجيل الدخول: ${response['message'] ?? 'غير معروف'}');
      }

      // RouterOS v6 - تسجيل دخول مباشر
      if (response['!done'] != null) {
        await _sendCommand([
          '/login',
          '=name=$username',
          '=password=$password'
        ]);
        
        final loginResponse = await _readResponse();
        
        if (loginResponse['!done'] != null) {
          return true;
        } else if (loginResponse['!trap'] != null) {
          throw Exception('فشل تسجيل الدخول: ${loginResponse['message'] ?? 'بيانات خاطئة'}');
        }
      }
      
      // RouterOS v6.43+ with challenge
      if (response['ret'] != null) {
        final challenge = response['ret'];
        final hashedPassword = _md5Challenge(challenge, password);
        
        await _sendCommand([
          '/login',
          '=name=$username',
          '=response=00$hashedPassword'
        ]);
        
        final challengeResponse = await _readResponse();
        
        if (challengeResponse['!done'] != null) {
          return true;
        } else if (challengeResponse['!trap'] != null) {
          throw Exception('فشل تسجيل الدخول: ${challengeResponse['message'] ?? 'بيانات خاطئة'}');
        }
      }

      return false;
    } catch (e) {
      throw Exception('خطأ في تسجيل الدخول: $e');
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    if (_isConnected) {
      try {
        await _socket.close();
      } catch (e) {
        // تجاهل أخطاء القطع
      }
      _isConnected = false;
    }
  }

  /// تنفيذ أمر على MikroTik
  Future<List<Map<String, dynamic>>> command(List<String> cmd) async {
    if (!_isConnected) {
      throw Exception('غير متصل بالراوتر');
    }

    try {
      await _sendCommand(cmd);
      return await _readAllResponses();
    } catch (e) {
      throw Exception('خطأ في تنفيذ الأمر: $e');
    }
  }

  /// الحصول على جميع المستخدمين النشطين
  Future<List<Map<String, dynamic>>> getActiveUsers() async {
    return await command(['/tool/user-manager/user/print', '?active-sessions=>0']);
  }

  /// الحصول على جميع المستخدمين
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await command(['/tool/user-manager/user/print']);
  }

  /// الحصول على البروفايلات
  Future<List<Map<String, dynamic>>> getProfiles() async {
    return await command(['/tool/user-manager/profile/print']);
  }

  /// الحصول على العملاء
  Future<List<Map<String, dynamic>>> getCustomers() async {
    return await command(['/tool/user-manager/customer/print']);
  }

  /// الحصول على الجلسات النشطة
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    return await command(['/tool/user-manager/session/print', '?active=yes']);
  }

  /// الحصول على جميع الجلسات
  Future<List<Map<String, dynamic>>> getAllSessions() async {
    return await command(['/tool/user-manager/session/print']);
  }

  /// الحصول على المدفوعات
  Future<List<Map<String, dynamic>>> getPayments() async {
    return await command(['/tool/user-manager/payment/print']);
  }

  /// إضافة مستخدم جديد
  Future<Map<String, dynamic>> addUser({
    required String username,
    required String password,
    String? customer,
    String? profile,
    bool? callerIdBind,
  }) async {
    final cmd = ['/tool/user-manager/user/add'];
    cmd.add('=username=$username');
    cmd.add('=password=$password');
    
    if (customer != null) cmd.add('=customer=$customer');
    if (profile != null) cmd.add('=profile=$profile');
    if (callerIdBind != null) {
      cmd.add('=caller-id-bind-on-first-use=${callerIdBind ? \"yes\" : \"no\"}');
    }

    final response = await command(cmd);
    return response.isNotEmpty ? response.first : {};
  }

  /// إنشاء وتفعيل بروفايل للمستخدم
  Future<Map<String, dynamic>> createAndActivateProfile({
    required String userId,
    required String profile,
    required String customer,
  }) async {
    final response = await command([
      '/tool/user-manager/user/create-and-activate-profile',
      '=.id=$userId',
      '=profile=$profile',
      '=customer=$customer'
    ]);
    return response.isNotEmpty ? response.first : {};
  }

  /// حذف مستخدم
  Future<bool> removeUser(String userId) async {
    try {
      await command(['/tool/user-manager/user/remove', '=.id=$userId']);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// تعطيل/تفعيل مستخدم
  Future<bool> enableDisableUser(String userId, bool enable) async {
    try {
      await command([
        '/tool/user-manager/user/set',
        '=.id=$userId',
        '=disabled=${enable ? \"no\" : \"yes\"}'
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إضافة بروفايل جديد
  Future<Map<String, dynamic>> addProfile({
    required String name,
    String? validity,
    String? price,
    String? overrideSharedUsers,
    String? sharedUsers,
    String? rateLimitRx,
    String? rateLimitTx,
  }) async {
    final cmd = ['/tool/user-manager/profile/add'];
    cmd.add('=name=$name');
    
    if (validity != null) cmd.add('=validity=$validity');
    if (price != null) cmd.add('=price=$price');
    if (overrideSharedUsers != null) cmd.add('=override-shared-users=$overrideSharedUsers');
    if (sharedUsers != null) cmd.add('=shared-users=$sharedUsers');
    if (rateLimitRx != null) cmd.add('=rate-limit-rx=$rateLimitRx');
    if (rateLimitTx != null) cmd.add('=rate-limit-tx=$rateLimitTx');

    final response = await command(cmd);
    return response.isNotEmpty ? response.first : {};
  }

  /// إضافة عميل جديد
  Future<Map<String, dynamic>> addCustomer({
    required String login,
    required String password,
    String? permissions,
    String? paypalAccount,
  }) async {
    final cmd = ['/tool/user-manager/customer/add'];
    cmd.add('=login=$login');
    cmd.add('=password=$password');
    
    if (permissions != null) cmd.add('=permissions=$permissions');
    if (paypalAccount != null) cmd.add('=paypal-account=$paypalAccount');

    final response = await command(cmd);
    return response.isNotEmpty ? response.first : {};
  }

  /// الحصول على معلومات النظام
  Future<Map<String, dynamic>> getSystemInfo() async {
    final response = await command(['/system/resource/print']);
    return response.isNotEmpty ? response.first : {};
  }

  /// الحصول على هوية الراوتر
  Future<Map<String, dynamic>> getIdentity() async {
    final response = await command(['/system/identity/print']);
    return response.isNotEmpty ? response.first : {};
  }

  /// البحث عن مستخدم
  Future<List<Map<String, dynamic>>> findUser(String field, String value) async {
    return await command([
      '/tool/user-manager/user/print',
      '?$field=$value'
    ]);
  }

  /// البحث عن دفع
  Future<List<Map<String, dynamic>>> findPayment(String field, String value) async {
    return await command([
      '/tool/user-manager/payment/print',
      '?$field=$value'
    ]);
  }

  /// تحديث بيانات الدفع
  Future<bool> updatePayment(String paymentId, Map<String, String> data) async {
    try {
      final cmd = ['/tool/user-manager/payment/set', '=.id=$paymentId'];
      data.forEach((key, value) {
        cmd.add('=$key=$value');
      });
      await command(cmd);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إرسال أمر إلى MikroTik
  Future<void> _sendCommand(List<String> command) async {
    for (String word in command) {
      await _sendWord(word);
    }
    await _sendWord(''); // نهاية الأمر
  }

  /// إرسال كلمة
  Future<void> _sendWord(String word) async {
    final bytes = utf8.encode(word);
    final length = bytes.length;
    
    // إرسال طول الكلمة
    await _sendLength(length);
    
    // إرسال الكلمة
    if (length > 0) {
      _socket.add(bytes);
      await _socket.flush();
    }
  }

  /// إرسال الطول
  Future<void> _sendLength(int length) async {
    if (length < 0x80) {
      _socket.add([length]);
    } else if (length < 0x4000) {
      _socket.add([0x80 | (length >> 8), length & 0xFF]);
    } else if (length < 0x200000) {
      _socket.add([0xC0 | (length >> 16), (length >> 8) & 0xFF, length & 0xFF]);
    } else if (length < 0x10000000) {
      _socket.add([0xE0 | (length >> 24), (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF]);
    } else {
      _socket.add([0xF0, (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF]);
    }
    await _socket.flush();
  }

  /// قراءة رد
  Future<Map<String, dynamic>> _readResponse() async {
    final result = <String, dynamic>{};
    
    while (true) {
      final word = await _readWord();
      if (word.isEmpty) break;
      
      if (word.startsWith('!')) {
        result[word] = true;
      } else if (word.startsWith('=')) {
        final parts = word.substring(1).split('=');
        if (parts.length >= 2) {
          result[parts[0]] = parts.sublist(1).join('=');
        }
      }
    }
    
    return result;
  }

  /// قراءة جميع الردود
  Future<List<Map<String, dynamic>>> _readAllResponses() async {
    final responses = <Map<String, dynamic>>[];
    
    while (true) {
      final response = await _readResponse();
      if (response.isEmpty) break;
      
      if (response['!done'] != null) break;
      if (response['!trap'] != null) {
        throw Exception('خطأ من MikroTik: ${response['message'] ?? 'غير معروف'}');
      }
      
      if (response['!re'] != null) {
        responses.add(response);
      }
    }
    
    return responses;
  }

  /// قراءة كلمة
  Future<String> _readWord() async {
    final length = await _readLength();
    if (length == 0) return '';
    
    final bytes = <int>[];
    while (bytes.length < length) {
      final data = await _socket.first;
      bytes.addAll(data.take(length - bytes.length));
    }
    
    return utf8.decode(bytes);
  }

  /// قراءة الطول
  Future<int> _readLength() async {
    final firstByte = await _readByte();
    
    if ((firstByte & 0x80) == 0) {
      return firstByte;
    } else if ((firstByte & 0xC0) == 0x80) {
      return ((firstByte & 0x3F) << 8) + await _readByte();
    } else if ((firstByte & 0xE0) == 0xC0) {
      return ((firstByte & 0x1F) << 16) + (await _readByte() << 8) + await _readByte();
    } else if ((firstByte & 0xF0) == 0xE0) {
      return ((firstByte & 0x0F) << 24) + (await _readByte() << 16) + (await _readByte() << 8) + await _readByte();
    } else {
      await _readByte(); // تجاهل البايت الأول
      return (await _readByte() << 24) + (await _readByte() << 16) + (await _readByte() << 8) + await _readByte();
    }
  }

  /// قراءة بايت واحد
  Future<int> _readByte() async {
    final data = await _socket.first;
    return data.first;
  }

  /// تشفير كلمة المرور مع التحدي (MD5)
  String _md5Challenge(String challenge, String password) {
    // يحتاج تنفيذ MD5 - يمكن استخدام مكتبة crypto
    // هذا مثال مبسط
    return password; // مؤقتاً
  }

  /// فحص حالة الاتصال
  bool get isConnected => _isConnected;

  /// معلومات الاتصال
  String get connectionInfo => '$_host:$_port';
}

/// فئة مساعدة للاستعلامات المعقدة
class MikroTikV6QueryBuilder {
  final List<String> _conditions = [];
  
  /// إضافة شرط
  MikroTikV6QueryBuilder where(String field, String operator, dynamic value) {
    _conditions.add('?$field$operator$value');
    return this;
  }
  
  /// شرط المساواة
  MikroTikV6QueryBuilder equals(String field, dynamic value) {
    return where(field, '=', value);
  }
  
  /// شرط عدم المساواة
  MikroTikV6QueryBuilder notEquals(String field, dynamic value) {
    return where(field, '!=', value);
  }
  
  /// شرط أكبر من
  MikroTikV6QueryBuilder greaterThan(String field, dynamic value) {
    return where(field, '>', value);
  }
  
  /// شرط أصغر من
  MikroTikV6QueryBuilder lessThan(String field, dynamic value) {
    return where(field, '<', value);
  }
  
  /// شرط يحتوي على
  MikroTikV6QueryBuilder contains(String field, String value) {
    return where(field, '~', value);
  }
  
  /// بناء الاستعلام
  List<String> build(String basePath) {
    final query = [basePath];
    query.addAll(_conditions);
    return query;
  }
}

/// استثناءات MikroTik
class MikroTikException implements Exception {
  final String message;
  final String? code;
  
  const MikroTikException(this.message, [this.code]);
  
  @override
  String toString() {
    return code != null ? 'MikroTikException ($code): $message' : 'MikroTikException: $message';
  }
}

/// حالات الاتصال
enum MikroTikConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  error
}"