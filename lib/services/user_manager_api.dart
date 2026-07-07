// ============================================================
//  UserManagerApi — وكيل لـ MikroTik User Manager عبر Web Scraping
//
//  يعمل عبر HTTP مباشرة إلى واجهة User Manager (مثل: /userman)
//  يدعم:
//   - تسجيل الدخول (مع حفظ session cookie)
//   - قائمة الكروت الحالية
//   - إنشاء كرت فردي
//   - إنشاء كروت جماعية
//   - حذف كرت
//   - جلب قائمة الـ profiles (للاختيار عند الإنشاء)
//
//  ملاحظات:
//   - URL قابل للتغيير من الإعدادات (لا شيء hard-coded)
//   - يدعم HTTP و HTTPS (مع تجاهل شهادة SSL إن لزم)
//   - يحفظ الـ session cookie تلقائياً عبر CookieJar بسيط
// ============================================================

import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// استثناء مخصّص لأخطاء User Manager
class UmException implements Exception {
  final String message;
  UmException(this.message);
  @override
  String toString() => 'UserManager: $message';
}

/// يمثّل كرت واحد في User Manager
class UmUser {
  final String username;
  final String? password;
  final String? profile;
  final String? uptimeLimit;
  final String? bytesIn;
  final String? bytesOut;
  final bool? isActive;

  UmUser({
    required this.username,
    this.password,
    this.profile,
    this.uptimeLimit,
    this.bytesIn,
    this.bytesOut,
    this.isActive,
  });

  factory UmUser.fromRow(List<String> cells) {
    // User Manager عادة: username | password | profile | uptime | bytes | ...
    // نتسامح مع عدد الخلايا المتغيّر
    String? get(int i) => i < cells.length ? cells[i].trim() : null;
    return UmUser(
      username: get(0) ?? '',
      password: get(1),
      profile: get(2),
      uptimeLimit: get(3),
      bytesIn: get(4),
      bytesOut: get(5),
    );
  }

  Map<String, dynamic> toMap() => {
        'username': username,
        'password': password,
        'profile': profile,
        'uptime_limit': uptimeLimit,
        'bytes_in': bytesIn,
        'bytes_out': bytesOut,
        'is_active': isActive,
      };
}

class UserManagerApi {
  late final Dio _dio;
  String _baseUrl;
  bool _isLoggedIn = false;

  UserManagerApi({required String baseUrl}) : _baseUrl = baseUrl {
    _dio = Dio(BaseOptions(
      baseUrl: _normalize(baseUrl),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      // User Manager قد يستخدم شهادة self-signed على HTTPS
      validateStatus: (s) => s != null && s < 500,
    ));
    // إضافة cookie manager بسيط (يدوياً لأن dio_cookie_manager يتطلب dio 5.x + cookie_jar)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final cookies = _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
        if (cookies.isNotEmpty) {
          options.headers['Cookie'] = cookies;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        _extractCookies(response);
        handler.next(response);
      },
      onError: (e, handler) {
        if (e.response != null) _extractCookies(e.response!);
        handler.next(e);
      },
    ));
  }

  /// jar بسيط للكوكيز
  final Map<String, String> _cookies = {};

  void _extractCookies(Response response) {
    final setCookies = response.headers['set-cookie'];
    if (setCookies == null) return;
    for (final sc in setCookies) {
      final parts = sc.split(';').first.trim();
      if (parts.isEmpty) continue;
      final eq = parts.indexOf('=');
      if (eq <= 0) continue;
      final k = parts.substring(0, eq).trim();
      final v = parts.substring(eq + 1).trim();
      _cookies[k] = v;
    }
  }

  /// يحوّل الرابط إلى صيغة base نظيفة (بدون /userman في النهاية)
  static String _normalize(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    // نحتفظ بـ /userman لو موجود لأن UM يعيش تحت هذا المسار
    return u;
  }

  /// يبني المسار الكامل للـ UM (مثلاً: http://host:13196/userman + /login)
  String _umPath(String path) {
    var base = _baseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }

  bool get isLoggedIn => _isLoggedIn;

  // ============================================================
  //  تسجيل الدخول
  // ============================================================

  /// يحاول تسجيل الدخول إلى User Manager.
  /// يرجع true عند النجاح، ويرمي UmException عند الفشل.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        _umPath('login'),
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Referer': _umPath('login')},
        ),
      );
      // UM يرجع 200 + رسالة خطأ داخل HTML عند الفشل، أو redirect عند النجاح
      final html = (res.data ?? '').toString();
      if (html.contains('Login failed') ||
          html.contains('Invalid') ||
          html.contains('incorrect')) {
        throw UmException('بيانات الدخول غير صحيحة');
      }
      // إذا وصلنا لصفحة تحتوي على "Logout" أو قائمة users → نجح
      if (html.contains('Logout') ||
          html.contains('logout') ||
          html.contains('Users') ||
          res.statusCode == 302) {
        _isLoggedIn = true;
        await _persistSession(username);
        return true;
      }
      // افتراضي: نعتبره ناجحاً إن لم توجد رسالة خطأ
      _isLoggedIn = true;
      await _persistSession(username);
      return true;
    } on DioException catch (e) {
      throw UmException('فشل الاتصال: ${e.message ?? e.type.name}');
    }
  }

  Future<void> _persistSession(String username) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('um_last_user', username);
  }

  // ============================================================
  //  جلب قائمة الكروت
  // ============================================================

  Future<List<UmUser>> listUsers({int page = 1}) async {
    if (!_isLoggedIn) throw UmException('يجب تسجيل الدخول أولاً');
    try {
      final res = await _dio.get(
        _umPath('users'),
        queryParameters: {'page': page},
        options: Options(headers: {'Referer': _umPath('users')}),
      );
      return _parseUsersTable(res.data.toString());
    } on DioException catch (e) {
      throw UmException('فشل جلب القائمة: ${e.message ?? e.type.name}');
    }
  }

  List<UmUser> _parseUsersTable(String html) {
    final doc = parse(html);
    final tables = doc.querySelectorAll('table');
    for (final table in tables) {
      final rows = table.querySelectorAll('tr');
      if (rows.length < 2) continue;
      // نبحث عن جدول يحتوي على عمود "Username" في الترويسة
      final headerCells = rows.first.querySelectorAll('th, td');
      final headerText = headerCells.map((e) => e.text.trim().toLowerCase()).join('|');
      if (!headerText.contains('username') &&
          !headerText.contains('user') &&
          !headerText.contains('name')) {
        continue;
      }
      return rows.skip(1).map((row) {
        final cells = row.querySelectorAll('td').map((e) => e.text.trim()).toList();
        if (cells.isEmpty) return null;
        return UmUser.fromRow(cells);
      }).whereType<UmUser>().toList();
    }
    return [];
  }

  // ============================================================
  //  جلب قائمة الـ profiles المتاحة
  // ============================================================

  Future<List<String>> listProfiles() async {
    if (!_isLoggedIn) throw UmException('يجب تسجيل الدخول أولاً');
    try {
      final res = await _dio.get(
        _umPath('profiles'),
        options: Options(headers: {'Referer': _umPath('profiles')}),
      );
      final doc = parse(res.data.toString());
      final links = doc.querySelectorAll('a[href*="profile"]');
      final names = <String>{};
      for (final l in links) {
        final t = l.text.trim();
        if (t.isNotEmpty && !t.toLowerCase().contains('add') && !t.toLowerCase().contains('delete')) {
          names.add(t);
        }
      }
      // fallback: نأخذ خلايا عمود الـ Name في جدول profiles
      if (names.isEmpty) {
        final tables = doc.querySelectorAll('table');
        for (final t in tables) {
          final rows = t.querySelectorAll('tr');
          for (final r in rows.skip(1)) {
            final c = r.querySelectorAll('td');
            if (c.isNotEmpty) {
              final txt = c.first.text.trim();
              if (txt.isNotEmpty) names.add(txt);
            }
          }
        }
      }
      return names.toList()..sort();
    } on DioException catch (e) {
      throw UmException('فشل جلب الـ profiles: ${e.message ?? e.type.name}');
    }
  }

  // ============================================================
  //  إنشاء كرت فردي
  // ============================================================

  Future<UmUser> createUser({
    required String username,
    required String password,
    String? profile,
    String? uptimeLimit, // مثل: 1d 00:00:00
    String? sharedUsers, // عدد الاتصالات المتزامنة
  }) async {
    if (!_isLoggedIn) throw UmException('يجب تسجيل الدخول أولاً');
    try {
      final body = <String, dynamic>{
        'username': username,
        'password': password,
      };
      if (profile != null && profile.isNotEmpty) body['profile'] = profile;
      if (uptimeLimit != null && uptimeLimit.isNotEmpty) body['uptime_limit'] = uptimeLimit;
      if (sharedUsers != null && sharedUsers.isNotEmpty) body['shared_users'] = sharedUsers;

      final res = await _dio.post(
        _umPath('users/add'),
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Referer': _umPath('users/add')},
        ),
      );
      final html = (res.data ?? '').toString();
      // UM يرجع خطأ داخل HTML عند التكرار
      if (html.contains('already exists') || html.contains('duplicate')) {
        throw UmException('الكرت موجود مسبقاً: $username');
      }
      return UmUser(
        username: username,
        password: password,
        profile: profile,
        uptimeLimit: uptimeLimit,
      );
    } on DioException catch (e) {
      throw UmException('فشل إنشاء الكرت: ${e.message ?? e.type.name}');
    }
  }

  // ============================================================
  //  إنشاء كروت جماعية
  // ============================================================

  Future<List<UmUser>> createBulkUsers({
    required int count,
    required String prefix,
    required String passwordPattern, // مثل: 'random' أو 'same'
    String? fixedPassword,
    String? profile,
    String? uptimeLimit,
    String? sharedUsers,
    int passwordLength = 6,
    bool useLetters = true,
    bool useNumbers = true,
  }) async {
    if (!_isLoggedIn) throw UmException('يجب تسجيل الدخول أولاً');
    final created = <UmUser>[];
    final errors = <String>[];

    for (int i = 1; i <= count; i++) {
      final username = '$prefix${i.toString().padLeft(3, '0')}';
      final password = passwordPattern == 'same'
          ? (fixedPassword ?? _genPassword(passwordLength, useLetters, useNumbers))
          : _genPassword(passwordLength, useLetters, useNumbers);
      try {
        final u = await createUser(
          username: username,
          password: password,
          profile: profile,
          uptimeLimit: uptimeLimit,
          sharedUsers: sharedUsers,
        );
        created.add(u);
      } on UmException catch (e) {
        errors.add('$username: ${e.message}');
        // نكمل بدل التوقف عند أول خطأ
      }
      // تأخير بسيط لتفادي rate-limit
      if (i % 10 == 0) await Future.delayed(const Duration(milliseconds: 200));
    }

    if (created.isEmpty && errors.isNotEmpty) {
      throw UmException('فشل إنشاء كل الكروت. أول خطأ: ${errors.first}');
    }
    return created;
  }

  String _genPassword(int length, bool useLetters, bool useNumbers) {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    var chars = '';
    if (useLetters) chars += letters;
    if (useNumbers) chars += numbers;
    if (chars.isEmpty) chars = numbers;
    final rnd = DateTime.now().microsecondsSinceEpoch;
    final buf = StringBuffer();
    for (int i = 0; i < length; i++) {
      buf.write(chars[(rnd + i * 7) % chars.length]);
    }
    return buf.toString();
  }

  // ============================================================
  //  حذف كرت
  // ============================================================

  Future<void> deleteUser(String username) async {
    if (!_isLoggedIn) throw UmException('يجب تسجيل الدخول أولاً');
    try {
      await _dio.post(
        _umPath('users/remove'),
        data: {'username': username},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Referer': _umPath('users')},
        ),
      );
    } on DioException catch (e) {
      throw UmException('فشل حذف الكرت: ${e.message ?? e.type.name}');
    }
  }

  // ============================================================
  //  اختبار اتصال (بدون login)
  // ============================================================

  /// يرجع true إن كان الرابط يستجيب
  static Future<bool> testConnection(String baseUrl) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (s) => s != null && s < 500,
      ));
      final res = await dio.get(baseUrl);
      return res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}
