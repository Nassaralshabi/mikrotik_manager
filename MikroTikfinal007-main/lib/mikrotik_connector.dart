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
  final dynamic originalException;
  MikrotikConnectionException(this.message, [this.originalException]);

  @override
  String toString() => 'MikrotikConnectionException: $message';
}

class MikrotikConnector {
  /// زمن المهلة للاتصال (15 ثانية بدلاً من 5)
  static const Duration _connectionTimeout = Duration(seconds: 15);

  /// زمن المهلة لعمليات talk (30 ثانية)
  static const Duration _operationTimeout = Duration(seconds: 30);

  /// الاتصال بجهاز MikroTik باستخدام البيانات المحفوظة في SharedPreferences
  static Future<RouterOSClient> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    final pass = prefs.getString('pass');
    final portString = prefs.getString('port');
    final port = portString != null ? (int.tryParse(portString) ?? 8728) : 8728;

    // التحقق من وجود البيانات المطلوبة
    if (ip == null || ip.trim().isEmpty) {
      throw MikrotikCredentialsMissingException('عنوان IP غير محدد. الرجاء إدخال عنوان الراوتر.');
    }
    if (user == null || user.trim().isEmpty) {
      throw MikrotikCredentialsMissingException('اسم المستخدم غير محدد.');
    }
    if (pass == null) {
      throw MikrotikCredentialsMissingException('كلمة المرور غير محددة.');
    }

    // التحقق من صحة المنفذ
    if (port < 1 || port > 65535) {
      throw MikrotikCredentialsMissingException('رقم المنفذ غير صالح: $port');
    }

    // تحديد ما إذا كان الاتصال يستخدم SSL/TLS (المنفذ 8729)
    final bool useSsl = (port == 8729);

    final client = RouterOSClient(
      address: ip.trim(),
      user: user.trim(),
      password: pass,
      port: port,
      verbose: false,
      useSsl: useSsl,
    );

    try {
      final bool loggedIn = await client.login().timeout(_connectionTimeout);
      if (loggedIn) {
        return client;
      } else {
        throw MikrotikConnectionException(
          'فشل تسجيل الدخول. تأكد من صحة اسم المستخدم وكلمة المرور.',
        );
      }
    } on TimeoutException {
      throw MikrotikConnectionException(
        'انتهت مهلة الاتصال (${_connectionTimeout.inSeconds} ثانية).\n'
        'تأكد من:\n'
        '• أن الراوتر يعمل ومتوصل بالشبكة\n'
        '• أن المنفذ $port مفتوح وصحيح\n'
        '• أن جهازك متصل بنفس الشبكة (اتصال محلي)',
      );
    } on SocketException catch (e) {
      throw MikrotikConnectionException(
        'تعذر الوصول إلى الراوتر على العنوان $ip:$port.\n'
        'الخطأ: ${e.message}\n'
        'تأكد من أن الراوتر يعمل وأن المنفذ $port مفتوح.',
        e,
      );
    } on HandshakeException catch (e) {
      throw MikrotikConnectionException(
        'فشل الاتصال الآمن (SSL/TLS).\n'
        'تأكد من أن الراوتر يدعم الاتصال المشفر على المنفذ $port.',
        e,
      );
    } catch (e) {
      if (e is MikrotikCredentialsMissingException ||
          e is MikrotikConnectionException) {
        rethrow;
      }
      throw MikrotikConnectionException(
        'حدث خطأ غير متوقع أثناء الاتصال: ${e.toString()}',
        e,
      );
    }
  }
}
