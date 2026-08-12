import 'package:dio/dio.dart';

/// خدمة إشعارات مركزية توفر إرسال رسائل Telegram من مكان واحد
/// بدلاً من تكرار الدالة في كل شاشة
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;
  NotificationService._();

  String _telegramBotToken = '';
  String _telegramChatId = '';

  Dio? _dio;

  /// تهيئة الخدمة ببيانات Telegram (يُستدعى من الشاشة الرئيسية)
  void initialize({required String botToken, required String chatId}) {
    _telegramBotToken = botToken;
    _telegramChatId = chatId;
  }

  /// تحقق مما إذا كانت الخدمة مهيأة بشكل صحيح
  bool get isConfigured =>
      _telegramBotToken.isNotEmpty && _telegramChatId.isNotEmpty;

  /// إرسال رسالة Telegram
  Future<bool> sendTelegramMessage(String message) async {
    if (!isConfigured) return false;

    try {
      _dio ??= Dio();
      final url = 'https://api.telegram.org/bot$_telegramBotToken/sendMessage';
      await _dio!.post(url, data: {
        'chat_id': _telegramChatId,
        'text': message,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// إرسال إشعار إضافة كرت فردي
  Future<void> notifySingleCardAdded({
    required String username,
    required String? profile,
    required String address,
  }) async {
    await sendTelegramMessage(
      "تم إضافة كرت فردي جديد بنجاح!\n"
      "IP: $address\n"
      "اسم المستخدم: $username\n"
      "الفئة: ${profile ?? 'غير محدد'}",
    );
  }

  /// إرسال إشعار إضافة كروت جماعية
  Future<void> notifyBulkCardsAdded({
    required int count,
    required String? profile,
    required String address,
  }) async {
    await sendTelegramMessage(
      "تم إضافة $count كرت جديد بنجاح!\n"
      "IP: $address\n"
      "الفئة: ${profile ?? 'غير محدد'}",
    );
  }

  /// إرسال إشعار تسجيل دخول
  Future<void> notifyLogin({required String ipAddress}) async {
    await sendTelegramMessage(
      'تم الدخول إلى التطبيق بنجاح عبر عنوان IP: $ipAddress',
    );
  }
}
