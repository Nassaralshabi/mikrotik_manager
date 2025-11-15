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
import 'theme/app_theme.dart';
import 'theme/app_palette.dart';
import 'theme/app_gradients.dart';
// -----------------------------------------

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MqttService()),
        ChangeNotifierProvider(create: (_) => AppTheme()..initialize()),
      ],
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
      backgroundColor: AppPalette.error,
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
      backgroundColor: AppPalette.success,
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
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) => MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'MikroTik Manager',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Theme Provider يدير الوضع تلقائياً
        themeMode: themeProvider.themeMode,
        home: const LoginScreen(),
      ),
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
  final _remoteUserController = TextEditingController();
  final _remotePasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = true;
  bool _rememberMeRemote = false;
  bool _isPasswordObscured = true;
  bool _isRemotePasswordObscured = true;
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
        _rememberMe = true;
      });
    }
    if (prefs.getBool('remember_me_remote') ?? false) {
      setState(() {
        _remoteServerController.text = prefs.getString('remote_server') ?? '';
        _remotePortController.text = prefs.getString('remote_port') ?? '8728';
        _remoteUserController.text = prefs.getString('remote_user') ?? '';
        _remotePasswordController.text = prefs.getString('remote_pass') ?? '';
        _rememberMeRemote = true;
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
    } else {
      await prefs.remove('ip');
      await prefs.remove('user');
      await prefs.remove('pass');
      await prefs.remove('port');
    }
  }
  
  Future<void> _handleRemoteCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me_remote', _rememberMeRemote);
    if (_rememberMeRemote) {
      await prefs.setString('remote_server', _remoteServerController.text);
      await prefs.setString('remote_port', _remotePortController.text);
      await prefs.setString('remote_user', _remoteUserController.text);
      await prefs.setString('remote_pass', _remotePasswordController.text);
    } else {
      await prefs.remove('remote_server');
      await prefs.remove('remote_port');
      await prefs.remove('remote_user');
      await prefs.remove('remote_pass');
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
    _remoteUserController.dispose();
    _remotePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.softBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // المحتوى الرئيسي
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                Image.asset('assets/images/wifi_logo.png', width: 48, height: 48),
                const SizedBox(height: 24),
                Text(
                  'إدارة شبكتك بسهولة وأمان',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: context.theme.appColors.primary,
                    labelColor: context.theme.appColors.onSurface,
                    unselectedLabelColor: context.theme.appColors.muted,
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
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.theme.appColors.error,
                        fontSize: 12,
                      ),
                    ),
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
        ],
      ),
      // مفتاح تبديل الثيم في الزاوية العلوية اليسرى
      Positioned(
        top: 50,
        left: 20,
        child: Consumer<AppTheme>(
          builder: (context, themeProvider, child) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  key: ValueKey(themeProvider.isDarkMode),
                  color: themeProvider.isDarkMode ? Colors.amber[600] : Colors.indigo[600],
                  size: 26,
                ),
              ),
              tooltip: themeProvider.isDarkMode ? 'التبديل للثيم الفاتح' : 'التبديل للثيم الغامق',
              onPressed: () async {
                await themeProvider.toggleTheme();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            themeProvider.isDarkMode ? 'تم التبديل للثيم الغامق' : 'تم التبديل للثيم الفاتح',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
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

    if (_remoteUserController.text.isEmpty || _remotePasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم المستخدم وكلمة المرور للاتصال البعيد');
      return;
    }
    
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
      await _handleRemoteCredentials();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip', _remoteServerController.text);
      await prefs.setString('port', _remotePortController.text);
      await prefs.setString('user', _remoteUserController.text);
      await prefs.setString('pass', _remotePasswordController.text);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
              isVersion7OrNewer: true, 
              username: _remoteUserController.text,
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
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: context.theme.appColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isScanning
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        color: context.theme.appColors.primary,
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.search, color: context.theme.appColors.primary),
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
        ),
        CheckboxListTile(
          title: const Text("تذكرني"),
          value: _rememberMe,
          onChanged: (newValue) => setState(() => _rememberMe = newValue ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: context.theme.appColors.primary,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          child: _isLoading
              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: context.theme.appColors.onPrimary))
              : const Text('اتصال', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _launchPrivacyPolicy,
          child: Text(
            'سياسة الخصوصية',
            style: TextStyle(
              color: context.theme.appColors.onBackground.withOpacity(0.7),
              decoration: TextDecoration.underline,
              decorationColor: context.theme.appColors.onBackground.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 12),
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
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remoteUserController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remotePasswordController,
          obscureText: _isRemotePasswordObscured,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_isRemotePasswordObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isRemotePasswordObscured = !_isRemotePasswordObscured),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: Text('تذكرني', style: TextStyle(color: context.theme.appColors.onSurface)),
          value: _rememberMeRemote,
          onChanged: (bool? value) {
            setState(() {
              _rememberMeRemote = value ?? false;
            });
          },
          activeColor: context.theme.appColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
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
        Text(
          'جميع الحقوق محفوظة © م/نصار الشعبي',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.theme.appColors.muted, fontSize: 12),
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
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(context.theme.appColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: context.theme.appColors.onBackground.withOpacity(0.7),
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

  Map<String, dynamic>? _dashboardStatus;
  bool _isLoadingStatus = true;
  bool _isRefreshingStatus = false;
  String _statusError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchProfiles();
    _loadLinkStatus();
    _loadCachedDashboardStatus();
    _refreshDashboardStatus();
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

  Future<void> _loadCachedDashboardStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_dashboard_status') ?? prefs.getString('cached_stats');
    if (cached == null) return;
    try {
      final decoded = jsonDecode(cached);
      if (decoded is! Map<String, dynamic>) return;
      if (!mounted) return;
      setState(() {
        _dashboardStatus = {
          'cpuUsage': (decoded['cpuUsage'] as num?)?.toDouble() ?? 0.0,
          'memoryUsage': (decoded['memoryUsage'] as num?)?.toDouble() ?? 0.0,
          'uptime': decoded['uptime']?.toString() ?? 'غير متوفر',
          'dataDownloaded': (decoded['dataDownloaded'] as num?)?.toDouble() ?? 0.0,
          'dataUploaded': (decoded['dataUploaded'] as num?)?.toDouble() ?? 0.0,
          'activeUsers': (decoded['activeUsers'] as num?)?.toInt() ?? 0,
          'version': decoded['version']?.toString() ?? 'غير معروف',
        };
        _isLoadingStatus = false;
        _statusError = '';
      });
    } catch (_) {
      // ignore cache parse errors
    }
  }

  Future<void> _refreshDashboardStatus({bool silent = true}) async {
    if (!mounted) return;
    setState(() {
      _statusError = '';
      if (silent && _dashboardStatus != null) {
        _isRefreshingStatus = true;
      } else {
        _isLoadingStatus = true;
      }
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      final resourceResponse = await client.talk(['/system/resource/print']);
      Map<String, dynamic> resourceData = {};
      if (resourceResponse.isNotEmpty) {
        resourceData = Map<String, dynamic>.from(resourceResponse[0]);
      }

      final interfaceResponse = await client.talk([
        '/interface/print',
        '=.proplist=name,rx-byte,tx-byte',
        'stats',
      ]);
      double totalDownload = 0.0;
      double totalUpload = 0.0;
      for (var iface in interfaceResponse) {
        final rxBytes = double.tryParse(iface['rx-byte']?.toString() ?? '0') ?? 0.0;
        final txBytes = double.tryParse(iface['tx-byte']?.toString() ?? '0') ?? 0.0;
        totalDownload += rxBytes;
        totalUpload += txBytes;
      }

      List<Map<String, dynamic>> activeUsers = [];
      try {
        final activeResponse = await client.talk(['/ip/hotspot/active/print']);
        activeUsers = activeResponse.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        activeUsers = [];
      }

      final cpuLoad = double.tryParse(resourceData['cpu-load']?.toString() ?? '0') ?? 0.0;
      final totalMemory = double.tryParse(resourceData['total-memory']?.toString() ?? '0') ?? 0.0;
      final freeMemory = double.tryParse(resourceData['free-memory']?.toString() ?? '0') ?? 0.0;
      final memoryUsagePercent = totalMemory <= 0
          ? 0.0
          : ((totalMemory - freeMemory) / totalMemory * 100);

      final updatedStatus = {
        'cpuUsage': cpuLoad,
        'memoryUsage': memoryUsagePercent,
        'uptime': resourceData['uptime']?.toString() ?? 'غير متوفر',
        'dataDownloaded': totalDownload / (1024 * 1024),
        'dataUploaded': totalUpload / (1024 * 1024),
        'activeUsers': activeUsers.length,
        'version': resourceData['version']?.toString() ?? 'غير معروف',
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_dashboard_status', jsonEncode(updatedStatus));

      if (mounted) {
        setState(() {
          _dashboardStatus = updatedStatus;
          _isLoadingStatus = false;
          _isRefreshingStatus = false;
          _statusError = '';
        });
      }
    } on MikrotikCredentialsMissingException catch (e) {
      _handleStatusError('بيانات الدخول غير متوفرة: ${e.message}');
    } on MikrotikConnectionException catch (e) {
      _handleStatusError('تعذر الاتصال بالجهاز: ${e.message}');
    } catch (e) {
      _handleStatusError('فشل تحديث حالة MikroTik: ${e.toString()}');
    } finally {
      client?.close();
    }
  }

  void _handleStatusError(String message) {
    if (!mounted) return;
    setState(() {
      _statusError = message;
      _isLoadingStatus = false;
      _isRefreshingStatus = false;
    });
    showErrorSnackBar(context, message);
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
        color: AppPalette.primary,
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
        color: AppPalette.success,
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
        color: AppPalette.info,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const QahtaniLinkScreen()));
        },
      ),
      ServiceItem(
        title: 'الإحصائيات',
        icon: Icons.bar_chart_rounded,
        color: AppPalette.secondaryDark,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const StatsScreen()));
        },
      ),
      ServiceItem(
        title: 'طبيب الشبكة',
        icon: Icons.local_hospital_outlined,
        color: AppPalette.info,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const NetworkDoctorScreen()));
        },
      ),
      ServiceItem(
        title: 'الملفات المحفوظة',
        icon: Icons.folder_copy,
        color: AppPalette.warning,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const SavedFilesScreen()));
        },
      ),
      ServiceItem(
        title: 'إدارة قوالب PDF',
        icon: Icons.picture_as_pdf,
        color: AppPalette.muted,
        onTap: () {
          Navigator.of(context).push(
              CustomPageRoute(builder: (context) => PdfTemplatesScreen(profiles: _profiles)));
        },
      ),
      ServiceItem(
        title: 'استخراج الكروت',
        icon: Icons.document_scanner_outlined,
        color: AppPalette.error,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ExtractCardsScreen()));
        },
      ),
      ServiceItem(
        title: 'إحصائيات الكروت',
        icon: Icons.bar_chart,
        color: AppPalette.primary,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const CardsStatisticsScreen()));
        },
      ),
      ServiceItem(
        title: 'المستخدمين النشطين',
        icon: Icons.people_outline,
        color: AppPalette.secondary,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ActiveUsersScreen()));
        },
      ),
      ServiceItem(
        title: 'الملف الشخصي',
        icon: Icons.account_circle,
        color: AppPalette.secondaryLight,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const ProfileScreen()));
        },
      ),
      ServiceItem(
        title: 'النسخ الاحتياطي',
        icon: Icons.backup,
        color: AppPalette.info,
        onTap: () {
          Navigator.of(context)
              .push(CustomPageRoute(builder: (context) => const BackupSystemScreen()));
        },
      ),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.softBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: null,
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              child: Icon(Icons.person_outline, color: context.theme.appColors.onSurface),
            ),
          ),
          actions: [
            // مفتاح تبديل الثيم الفاتح/الغامق
            Consumer<AppTheme>(
              builder: (context, themeProvider, child) => IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey(themeProvider.isDarkMode),
                    color: themeProvider.isDarkMode ? Colors.amber : Colors.indigo,
                  ),
                ),
                tooltip: themeProvider.isDarkMode ? 'التبديل للثيم الفاتح' : 'التبديل للثيم الغامق',
                onPressed: () async {
                  await themeProvider.toggleTheme();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          themeProvider.isDarkMode ? 'تم التبديل للثيم الغامق' : 'تم التبديل للثيم الفاتح',
                          style: const TextStyle(fontSize: 14),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث الحالة',
              onPressed: _isRefreshingStatus ? null : () => _refreshDashboardStatus(silent: false),
            ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: _buildDashboardStatusCard(),
                    ),
                    if (_statusError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _statusError,
                          style: TextStyle(
                            color: context.theme.appColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // --- شبكة الخدمات الأفقية ---
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
      ),
    );
  }

  Widget _buildDashboardStatusCard() {
    if (_isLoadingStatus && _dashboardStatus == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white70,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Text('جاري تحديث حالة MikroTik...'),
          ],
        ),
      );
    }

    final status = _dashboardStatus ?? {
      'cpuUsage': 0.0,
      'memoryUsage': 0.0,
      'uptime': 'غير متوفر',
      'dataDownloaded': 0.0,
      'dataUploaded': 0.0,
      'activeUsers': 0,
      'version': 'غير معروف',
    };

    final cpuUsage = _asDouble(status['cpuUsage']);
    final memoryUsage = _asDouble(status['memoryUsage']);
    final downloadMb = _asDouble(status['dataDownloaded']);
    final uploadMb = _asDouble(status['dataUploaded']);
    final activeUsers = (status['activeUsers'] is num)
        ? (status['activeUsers'] as num).toInt()
        : int.tryParse(status['activeUsers']?.toString() ?? '') ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFB6C4FF),
            Color(0xFFD7C8FF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(gradient: AppGradients.cardOverlay),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isNetworkLinked && _clientName.isNotEmpty ? _clientName : 'حالة MikroTik',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الإصدار: ${status['version']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'وقت التشغيل: ${status['uptime']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.router,
                      size: 48,
                      color: const Color(0xFF6B3FA0).withOpacity(0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatusMetric(
                      label: 'المعالج',
                      value: '${cpuUsage.toStringAsFixed(1)}%',
                      icon: Icons.speed,
                      color: const Color(0xFF8254FF),
                    ),
                    _buildStatusMetric(
                      label: 'الذاكرة',
                      value: '${memoryUsage.toStringAsFixed(1)}%',
                      icon: Icons.memory,
                      color: const Color(0xFF00BFA5),
                    ),
                    _buildStatusMetric(
                      label: 'التحميل',
                      value: '${downloadMb.toStringAsFixed(1)} MB',
                      icon: Icons.download_rounded,
                      color: const Color(0xFF0288D1),
                    ),
                    _buildStatusMetric(
                      label: 'الرفع',
                      value: '${uploadMb.toStringAsFixed(1)} MB',
                      icon: Icons.upload_rounded,
                      color: const Color(0xFFFF7043),
                    ),
                    _buildStatusMetric(
                      label: 'المستخدمون النشطون',
                      value: '$activeUsers',
                      icon: Icons.wifi,
                      color: const Color(0xFF7C4DFF),
                    ),
                  ],
                ),
                if (_isRefreshingStatus)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
