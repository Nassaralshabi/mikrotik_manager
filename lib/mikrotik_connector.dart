import 'dart:async';
import 'dart:io';

import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MikrotikCredentialsMissingException implements Exception {
  final String message;
  MikrotikCredentialsMissingException(this.message);

  @override
  String toString() => 'MikrotikCredentialsMissingException: $message';
}

class MikrotikConnectionException implements Exception {
  final String message;
  final String? solution;
  final dynamic originalException;
  MikrotikConnectionException(this.message, [this.originalException, this.solution]);

  @override
  String toString() => solution != null 
      ? 'MikrotikConnectionException: $message\nالحل المقترح: $solution'
      : 'MikrotikConnectionException: $message';
}

class MikrotikConnector {
  static Future<RouterOSClient> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    final pass = prefs.getString('pass');
    final portString = prefs.getString('port');
    final port = portString != null ? (int.tryParse(portString) ?? 8728) : 8728;

    if (ip == null || user == null || pass == null) {
      throw MikrotikCredentialsMissingException('عنوان IP أو اسم المستخدم أو كلمة المرور غير محددة.');
    }

    // فحص صحة عنوان IP
    if (!_isValidIP(ip)) {
      throw MikrotikConnectionException(
        'عنوان IP غير صحيح: $ip',
        null,
        'تأكد من صحة عنوان IP (مثال: 192.168.1.1)'
      );
    }

    // فحص الاتصال الشبكي أولاً
    try {
      await _testNetworkConnectivity(ip, port);
    } catch (e) {
      throw MikrotikConnectionException(
        'فشل الوصول للجهاز على $ip:$port',
        e,
        'تأكد من:\n• الجهاز متصل بالشبكة\n• المنفذ $port مفتوح\n• لا يوجد firewall يحجب الاتصال'
      );
    }

    final client = RouterOSClient(
      address: ip,
      user: user,
      password: pass,
      port: port,
      verbose: false,
    );

    try {
      final bool loggedIn = await client.login().timeout(const Duration(seconds: 10));
      if (loggedIn) {
        return client;
      } else {
        throw MikrotikConnectionException(
          'فشل تسجيل الدخول للمستخدم: $user',
          null,
          'تأكد من:\n• صحة اسم المستخدم وكلمة المرور\n• المستخدم له صلاحية API\n• خدمة API مفعلة في MikroTik'
        );
      }
    } on TimeoutException {
      throw MikrotikConnectionException(
        'انتهت مهلة الاتصال (${10}s)',
        null,
        'الجهاز لا يستجيب. تأكد من:\n• الجهاز يعمل بشكل طبيعي\n• خدمة API مفعلة\n• الشبكة مستقرة'
      );
    } on SocketException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw MikrotikConnectionException(
          'رفض الاتصال على المنفذ $port',
          e,
          'خدمة API غير مفعلة أو المنفذ خاطئ.\nفي MikroTik:\n/ip service enable api\n/ip service set api port=$port'
        );
      } else if (e.message.contains('Network is unreachable')) {
        throw MikrotikConnectionException(
          'الشبكة غير متاحة - لا يمكن الوصول لـ $ip',
          e,
          'تأكد من:\n• اتصالك بالإنترنت أو الشبكة المحلية\n• عنوان IP صحيح\n• لا يوجد firewall يحجب الاتصال'
        );
      } else {
        throw MikrotikConnectionException(
          'خطأ في الشبكة: ${e.message}',
          e,
          'مشكلة في الاتصال الشبكي'
        );
      }
    } on Exception catch (e) {
      String errorMessage = e.toString();
      String? solution;
      
      if (errorMessage.contains('Authentication failed') || errorMessage.contains('invalid credentials')) {
        solution = 'اسم المستخدم أو كلمة المرور خاطئة';
      } else if (errorMessage.contains('Permission denied')) {
        solution = 'المستخدم لا يملك صلاحية الوصول للـ API';
      } else if (errorMessage.contains('Connection reset')) {
        solution = 'انقطع الاتصال. تأكد من استقرار الشبكة';
      } else if (errorMessage.contains('SSL') || errorMessage.contains('TLS')) {
        solution = 'مشكلة في الـ SSL. جرب المنفذ 8728 بدلاً من 8729';
      }
      
      throw MikrotikConnectionException(
        'خطأ في الاتصال: ${e.toString()}',
        e,
        solution ?? 'تأكد من إعدادات الاتصال والشبكة'
      );
    }
  }
  
  static bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (String part in parts) {
      final int? num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }
  
  static Future<void> _testNetworkConnectivity(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      await socket.close();
    } on SocketException catch (e) {
      if (e.message.contains('Connection refused')) {
        throw Exception('المنفذ $port مغلق أو خدمة API معطلة');
      } else if (e.message.contains('Network is unreachable')) {
        throw Exception('لا يمكن الوصول للجهاز على $host');
      } else if (e.message.contains('Host is down')) {
        throw Exception('الجهاز غير متاح أو مغلق');
      } else {
        throw Exception('فشل الاتصال: ${e.message}');
      }
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال - الجهاز لا يستجيب');
    }
  }
}