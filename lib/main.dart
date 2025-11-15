// main.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// --- افترض أن هذه الملفات موجودة في مشروعك ---
import 'add_user_screen.dart';
import 'bulk_add_screen.dart';
import 'saved_files_screen.dart';
import 'mqtt_service.dart';
import 'qahtani_link_screen.dart';
import 'profile_screen.dart';
import 'pdf_templates_screen.dart';
import 'network_doctor_screen.dart';
import 'extract_cards_screen.dart';
import 'cards_statistics_screen.dart';
import 'stats_screen.dart';
import 'mikrotik_connector.dart';
import 'backup_system_screen.dart';
import 'active_users_screen.dart';
import 'snackbar_helpers.dart';
// -----------------------------------------

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MqttService(),
      child: const MyApp(),
    ),
  );
}

// A global key for the ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/* snackbar helpers moved to snackbar_helpers.dart */
void showErrorSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      action: SnackBarAction(
        label: 'إغلاق',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF4CAF50),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MikroTik Manager',
      theme: ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6b3fa0),
  scaffoldBackgroundColor: const Color(0xFF1a1329),
  fontFamily: 'Tajawal',
  cardColor: const Color(0xFF2d213f),
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF6b3fa0),
    secondary: const Color(0xFFB39DDB),
    surface: const Color(0xFF2d213f),
    background: const Color(0xFF1a1329),
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      height: 1.4,
    ),
    displayMedium: TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      height: 1.4,
    ),
    displaySmall: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    headlineLarge: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      height: 1.5,
    ),
    headlineMedium: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    headlineSmall: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleLarge: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleMedium: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    bodyLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.6,
    ),
    bodySmall: TextStyle(
      color: Colors.white,
      fontSize: 12,
      height: 1.6,
    ),
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6b3fa0),
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFB39DDB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    labelStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.5,
    ),
    hintStyle: TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 14,
      height: 1.5,
    ),
    iconColor: Colors.white,
    prefixIconColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF2d213f),
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.all(8),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2d213f),
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Tajawal',
      height: 1.5,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
  ),
  iconTheme: const IconThemeData(
    color: Color(0xFFB0A8C1),
    size: 24,
  ),
  dividerTheme: DividerThemeData(
    color: Colors.white.withOpacity(0.1),
    thickness: 1,
    space: 16,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF2d213f),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontFamily: 'Tajawal',
      height: 1.5,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 4,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: const Color(0xFF2d213f),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 8,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Tajawal',
      height: 1.5,
    ),
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontFamily: 'Tajawal',
      height: 1.6,
    ),
  ),
),
      home: const LoginScreen(),
    );
  }
}

// صفحة انتقال مخصصة مع animation
class CustomPageRoute<T> extends MaterialPageRoute<T> {
  CustomPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _ipController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '8728');
  final _remoteServerController = TextEditingController();
  final _remotePortController = TextEditingController(text: '8728');

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = true;
  bool _isPasswordObscured = true;
  bool _isScanning = false;

  final String telegramBotToken = '';
  final String telegramChatId = '';

  // --- جميع الدوال والوظائف الأصلية تبقى كما هي ---
  Future<void> _sendTelegramMessage(String message) async {
    final dio = Dio();
    final url = 'https://api.telegram.org/bot$telegramBotToken/sendMessage';
    try {
      await dio.post(url, data: {'chat_id': telegramChatId, 'text': message});
    } catch (e) {
      // Failed to send Telegram message
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    // تم تعطيل رابط سياسة الخصوصية
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadSavedCredentials();
      await _discoverGateway();
    } catch (e, s) {
      debugPrint('Error in initState: $e\n$s');
    }
  }

  Future<void> _discoverGateway() async {
    if (_ipController.text.isNotEmpty) {
      return;
    }
    await _forceDiscoverGateway();
  }

  Future<void> _forceDiscoverGateway() async {
    setState(() {
      _isScanning = true;
      _errorMessage = 'جاري البحث عن بوابة الشبكة...';
    });
    try {
      final gatewayIp = await NetworkInfo().getWifiGatewayIP();
      if (gatewayIp != null && gatewayIp.isNotEmpty) {
        if (mounted) {
          setState(() {
            _ipController.text = gatewayIp;
            _errorMessage = 'تم العثور على بوابة الشبكة!';
          });
        }
      } else {
        if (mounted) setState(() => _errorMessage = 'لم يتم العثور على بوابة. تأكد من اتصالك بشبكة Wi-Fi.');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ أثناء محاولة اكتشاف الشبكة.');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') ?? false) {
      setState(() {
        _ipController.text = prefs.getString('ip') ?? '';
        _userController.text = prefs.getString('user') ?? '';
        _passwordController.text = prefs.getString('pass') ?? '';
        _portController.text = prefs.getString('port') ?? '8728';
        _remoteServerController.text = prefs.getString('remote_server') ?? '';
        _remotePortController.text = prefs.getString('remote_port') ?? '8728';
        _rememberMe = true;
      });
    }
  }

  Future<void> _handleCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('ip', _ipController.text);
      await prefs.setString('user', _userController.text);
      await prefs.setString('pass', _passwordController.text);
      await prefs.setString('port', _portController.text);
      await prefs.setString('remote_server', _remoteServerController.text);
      await prefs.setString('remote_port', _remotePortController.text);
    } else {
      await prefs.remove('ip');
      await prefs.remove('user');
      await prefs.remove('pass');
      await prefs.remove('port');
      await prefs.remove('remote_server');
      await prefs.remove('remote_port');
    }
  }

  Future<void> _login() async {
    if (_ipController.text.isEmpty || _userController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال IP واسم المستخدم');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    RouterOSClient? client;
    try {
      await _handleCredentials();
      client = await MikrotikConnector.connect();
      _sendTelegramMessage('تم الدخول إلى التطبيق بنجاح عبر عنوان IP: ${_ipController.text}');
      final response = await client.talk(['/system/resource/print']);
      bool isVersion7OrNewer = false;
      if (response.isNotEmpty && response[0]['version'] != null) {
        final version = response[0]['version'] as String;
        try {
          isVersion7OrNewer = int.parse(version.split('.').first) >= 7;
        } catch (e) {
          isVersion7OrNewer = false;
        }
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(isVersion7OrNewer: isVersion7OrNewer, username: _userController.text),
          ),
        );
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في بيانات الدخول: ${e.message}');
        showErrorSnackBar(context, 'خطأ في بيانات الدخول: ${e.message}');
      }
    } on MikrotikConnectionException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'خطأ في الاتصال: ${e.message}');
        showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'فشل الاتصال. تحقق من البيانات أو الشبكة.\n(الخطأ: ${e.toString()})');
        showErrorSnackBar(context, 'فشل الاتصال. تحقق من البيانات أو الشبكة.');
      }
    } finally {
      client?.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _remoteServerController.dispose();
    _remotePortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Image.asset('assets/images/wifi_logo.png', width: 48, height: 48),
              const SizedBox(height: 24),
              Text('إدارة شبكتك بسهولة وأمان', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).primaryColor,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.lan),
                      text: 'اتصال محلي',
                    ),
                    Tab(
                      icon: Icon(Icons.cloud),
                      text: 'اتصال عن بعد',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
                ),

              SizedBox(
                height: 550,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildLocalLoginForm(),
                    _buildRemoteLoginForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _remoteConnect() async {
    if (_remoteServerController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال عنوان الخادم البعيد');
      return;
    }
    
    // التحقق من أن الإدخال هو Domain وليس IP
    final input = _remoteServerController.text.trim();
    final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipPattern.hasMatch(input)) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم النطاق (Domain) وليس عنوان IP');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await _handleCredentials();
      
      // حفظ عنوان الخادم البعيد والبورت في SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip', _remoteServerController.text);
      await prefs.setString('port', _remotePortController.text);
      
      // الانتقال مباشرة إلى الشاشة الرئيسية بدون توثيق
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => const HomeScreen(
              isVersion7OrNewer: true, 
              username: 'Remote User'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'فشل الاتصال: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLocalLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: 'IP Address', prefixIcon: Icon(Icons.lan)),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isScanning
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF6b3fa0),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF6b3fa0)),
                      onPressed: _forceDiscoverGateway,
                      tooltip: 'بحث عن البوابة',
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _userController,
          decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _isPasswordObscured,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
            ),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        CheckboxListTile(
          title: const Text("تذكرني"),
          value: _rememberMe,
          onChanged: (newValue) => setState(() => _rememberMe = newValue ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : const Text('اتصال', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _launchPrivacyPolicy,
          child: Text(
            'سياسة الخصوصية',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              decoration: TextDecoration.underline,
              decorationColor: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF5A5278), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRemoteLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _remoteServerController,
          decoration: const InputDecoration(
            labelText: 'عنوان الخادم البعيد (Domain)',
            hintText: 'mikrotik.example.com',
            prefixIcon: Icon(Icons.cloud),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remotePortController,
          decoration: const InputDecoration(
            labelText: 'Port',
            hintText: '8728',
            prefixIcon: Icon(Icons.numbers),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _remoteConnect,
          child: _isLoading
              ? const SizedBox(
                  height: 24, 
                  width: 24, 
                  child: CircularProgressIndicator(
                    strokeWidth: 3, 
                    color: Colors.white
                  )
                )
              : const Text('الدخول', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 16),
        const Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF5A5278), fontSize: 12),
        ),
      ],
    );
  }
}

class CustomLoadingIndicator extends StatelessWidget {
  final String? message;
  const CustomLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6b3fa0)),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// --- HomeScreen with new UI ---
enum MikrotikMode { userManager, hotspot }

class HomeScreen extends StatefulWidget {
  final bool isVersion7OrNewer;
  final String username;

  const HomeScreen({
    super.key,
    required this.isVersion7OrNewer,
    required this.username,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// --- Data class for Service items ---
class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ServiceItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoadingProfiles = true;
  final MikrotikMode _selectedMode = MikrotikMode.userManager;
  bool _isNetworkLinked = false;
  String _clientName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
  }

  Future<void> _loadLinkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final isLinked = prefs.getBool('is_network_linked') ?? false;
      String clientName = '';
      if (isLinked) {
        final dataString = prefs.getString('qahtani_linked_data');
        if (dataString != null) {
          try {
            final data = jsonDecode(dataString);
            clientName = data['client_info']?['name'] ?? '';
          } catch (e) {
            debugPrint('Error decoding qahtani_linked_data: $e');
          }
        }
      }
      setState(() {
        _isNetworkLinked = isLinked;
        _clientName = clientName;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (!mounted) return;
      _loadLinkStatus(); // Reload status on resume
      context.read<MqttService>().checkAndReconnect();
      final isLinked = _isNetworkLinked; // Use the state variable
      if (isLinked) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          context.read<MqttService>().publish({'command': 'get_latest_network_details'});
        });
      }
    }
  }

  Future<void> _fetchProfiles() async {
    setState(() => _isLoadingProfiles = true);
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final command = _selectedMode == MikrotikMode.userManager
          ? '/tool/user-manager/profile/print'
          : '/ip/hotspot/user/profile/print';
      final response = await client.talk([command]);
      if (mounted) {
        setState(() {
          _profiles = response.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'حدث خطأ أثناء جلب البيانات: ${e.toString()}');
      }
    } finally {
      client?.close();
      if (mounted) setState(() => _isLoadingProfiles = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- قائمة الخدمات لتسهيل إدارتها ---
    final List<ServiceItem> services = [
      ServiceItem(
        title: 'إضافة كرت فردي',
        icon: Icons.person_add_alt_1,
        color: const Color(0xFF5C6BC0), // Indigo
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) =>
                AddUserScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, customer: widget.username),
          ));
        },
      ),
      ServiceItem(
        title: 'إضافة كروت جماعية',
        icon: Icons.groups,
        color: const Color(0xFF4CAF50), // Green
        onTap: () {
          Navigator.of(context).push(CustomPageRoute(
            builder: (context) =>
                BulkAddScreen(profiles: _profiles, isVersion7OrNewer: widget.isVersion7OrNewer, username: widget.username),
          ));
        },
      ),
      ServiceItem(
        title: 'ربط الشبكة',
        icon: Icons.link,
        color: const Color(0xFF42A5F5), // Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const QahtaniLinkScreen()));
        },
      ),
      ServiceItem(
        title: 'الإحصائيات',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF26A69A), // Teal
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const StatsScreen()));
        },
      ),
      ServiceItem(
        title: 'طبيب الشبكة',
        icon: Icons.local_hospital_outlined,
        color: const Color(0xFF42A5F5), // Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const NetworkDoctorScreen()));
        },
      ),
      ServiceItem(
        title: 'الملفات المحفوظة',
        icon: Icons.folder_copy,
        color: const Color(0xFFFFA726), // Orange
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const SavedFilesScreen()));
        },
      ),
      ServiceItem(
        title: 'إدارة قوالب PDF',
        icon: Icons.picture_as_pdf,
        color: const Color(0xFF78909C), // Blue Grey
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => PdfTemplatesScreen(profiles: _profiles)));
        },
      ),
      ServiceItem(
        title: 'استخراج الكروت',
        icon: Icons.document_scanner_outlined,
        color: const Color(0xFFEF5350), // Red
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ExtractCardsScreen()));
        },
      ),
      ServiceItem(
        title: 'إحصائيات الكروت',
        icon: Icons.bar_chart,
        color: const Color(0xFF9C27B0), // Purple
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const CardsStatisticsScreen()));
        },
      ),
      ServiceItem(
        title: 'المستخدمين النشطين',
        icon: Icons.people_outline,
        color: const Color(0xFF00ACC1), // Cyan
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ActiveUsersScreen()));
        },
      ),
      ServiceItem(
        title: 'الملف الشخصي',
        icon: Icons.account_circle,
        color: const Color(0xFF29B6F6), // Light Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ProfileScreen()));
        },
      ),
      ServiceItem(
        title: 'النسخ الاحتياطي',
        icon: Icons.backup,
        color: const Color(0xFF2196F3), // Blue
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const BackupSystemScreen()));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).cardColor,
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
              tooltip: 'الإشعارات'),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                CustomPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoadingProfiles
          ? const CustomLoadingIndicator(message: 'جاري التحميل...')
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- بطاقة الحالة ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isNetworkLinked && _clientName.isNotEmpty ? 'العميل' : 'مرحباً بك',
                              style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isNetworkLinked && _clientName.isNotEmpty
                                      ? _clientName
                                      : 'لوحة تحكم MikroTik',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis, // to handle long names
                                ),
                              ),
                              const Icon(Icons.settings_ethernet, color: Colors.white70, size: 28),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- عنوان قسم الخدمات ---
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0, right: 24.0, left: 24.0, bottom: 12.0),
                    child: Text(
                      'الخدمات الأساسية',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),

                  // --- شبكة الخدمات ---
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.35,
                          margin: const EdgeInsets.only(right: 12),
                          child: RepaintBoundary(
                            child: _buildServiceGridItem(
                              title: service.title,
                              icon: service.icon,
                              iconBgColor: service.color,
                              onTap: service.onTap,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceGridItem({
    required String title,
    required IconData icon,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        // --- التغيير هنا: تم استخدام لون الأيقونة مع شفافية لخلفية الزر ---
        color: iconBgColor.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // --- التغيير هنا: تم زيادة وضوح خلفية الأيقونة للتباين ---
                color: iconBgColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: iconBgColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
