// ============================================================
//  LoginScreen — شاشة تسجيل الدخول إلى MikroTik
//  استُخرجت من main.dart لتقليل حجمه
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mikrotik_manager/add_user_screen.dart';
import 'package:mikrotik_manager/bulk_add_screen.dart';
import 'package:mikrotik_manager/saved_files_screen.dart';
import 'package:mikrotik_manager/mqtt_service.dart';
import 'package:mikrotik_manager/qahtani_link_screen.dart';
import 'package:mikrotik_manager/profile_screen.dart';
import 'package:mikrotik_manager/pdf_templates_screen.dart';
import 'package:mikrotik_manager/network_doctor_screen.dart';
import 'package:mikrotik_manager/extract_cards_screen.dart';
import 'package:mikrotik_manager/cards_statistics_screen.dart';
import 'package:mikrotik_manager/stats_screen.dart';
import 'package:mikrotik_manager/mikrotik_connector.dart';
import 'package:mikrotik_manager/backup_system_screen.dart';
import 'package:mikrotik_manager/active_users_screen.dart';
import 'package:mikrotik_manager/perf/device_capability.dart';
import 'package:mikrotik_manager/perf/dio_cache_service.dart';
import 'package:mikrotik_manager/ai_diagnostics_screen.dart';
import 'package:mikrotik_manager/database/app_database.dart' as db;
import 'package:mikrotik_manager/database/sync_service.dart';
import 'package:mikrotik_manager/monthly_report_screen.dart';
import 'package:mikrotik_manager/card_search_screen.dart';
import 'package:mikrotik_manager/snackbar_helpers.dart';
import 'package:mikrotik_manager/core/theme/app_theme.dart';
import 'package:mikrotik_manager/core/router/custom_page_route.dart';

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
  final _remotePassController = TextEditingController();
  bool _remoteObscured = true;

  // بيانات اعتماد MQTT
  final _mqttUsernameController = TextEditingController();
  final _mqttPasswordController = TextEditingController();
  bool _showMqttSettings = false;
  bool _mqttPasswordObscured = true;

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = true;
  bool _isPasswordObscured = true;
  bool _isScanning = false;

  final String telegramBotToken = '';
  final String telegramChatId = '';

  // --- جميع الدوال والوظائف الأصلية تبقى كما هي ---
  Future<void> _sendTelegramMessage(String message) async {
    // استخدام Dio مع cache لتقليل استهلاك الشبكة والبطارية
    final dio = await createCachedDio(
      maxAge: const Duration(minutes: 5),
      maxStale: const Duration(hours: 1),
    );
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
    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _errorMessage = 'جاري البحث عن بوابة الشبكة...';
    });
    try {
      final gatewayIp = await NetworkInfo()
          .getWifiGatewayIP()
          .timeout(const Duration(seconds: 5));
      if (gatewayIp != null && gatewayIp.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _ipController.text = gatewayIp;
          _errorMessage = 'تم العثور على بوابة الشبكة!';
        });
      } else {
        if (!mounted) return;
        setState(() => _errorMessage = 'لم يتم العثور على بوابة. تأكد من اتصالك بشبكة Wi-Fi.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'حدث خطأ أثناء محاولة اكتشاف الشبكة.');
    } finally {
      if (!mounted) return;
      setState(() => _isScanning = false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') ?? false) {
      if (!mounted) return;
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
    // تحميل بيانات اعتماد MQTT وتكوين الخدمة
    final mqttUsername = prefs.getString('mqtt_username') ?? '';
    final mqttPassword = prefs.getString('mqtt_password') ?? '';
    if (mqttUsername.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _mqttUsernameController.text = mqttUsername;
        _mqttPasswordController.text = mqttPassword;
      });
      if (mounted) {
        context.read<MqttService>().configure(mqttUsername, mqttPassword);
      }
    }
  }

  Future<void> _handleCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    // كتابة جميع القيم بشكل متوازي لتسريع العملية
    final futures = <Future<void>>[
      prefs.setBool('remember_me', _rememberMe),
    ];
    if (_rememberMe) {
      futures.addAll([
        prefs.setString('ip', _ipController.text),
        prefs.setString('user', _userController.text),
        prefs.setString('pass', _passwordController.text),
        prefs.setString('port', _portController.text),
        prefs.setString('remote_server', _remoteServerController.text),
        prefs.setString('remote_port', _remotePortController.text),
      ]);
      // حفظ بيانات اعتماد MQTT
      if (_mqttUsernameController.text.isNotEmpty) {
        futures.addAll([
          prefs.setString('mqtt_username', _mqttUsernameController.text.trim()),
          prefs.setString('mqtt_password', _mqttPasswordController.text.trim()),
        ]);
      }
      await Future.wait(futures);
      if (mounted && _mqttUsernameController.text.isNotEmpty) {
        context.read<MqttService>().configure(
          _mqttUsernameController.text.trim(),
          _mqttPasswordController.text.trim(),
        );
      }
    } else {
      futures.addAll([
        prefs.remove('ip'),
        prefs.remove('user'),
        prefs.remove('pass'),
        prefs.remove('port'),
        prefs.remove('remote_server'),
        prefs.remove('remote_port'),
      ]);
      await Future.wait(futures);
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
      // لا نغلق الاتصال - تجمع الاتصالات يديره تلقائياً
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _mqttUsernameController.dispose();
    _mqttPasswordController.dispose();
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
              Image.asset('assets/images/wifi_logo.png', width: 48, height: 48,
                cacheWidth: 96,  // 2x للأجهزة عالية الدقة
                filterQuality: DeviceCapability.instance.isLowEnd ? FilterQuality.low : FilterQuality.medium,
                gaplessPlayback: true,
              ),
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
    if (_remoteUserController.text.isEmpty || _remotePassController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم المستخدم وكلمة المرور');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip', _remoteServerController.text.trim());
      await prefs.setString('user', _remoteUserController.text.trim());
      await prefs.setString('pass', _remotePassController.text);
      await prefs.setString('port', _remotePortController.text.trim().isEmpty ? '8728' : _remotePortController.text.trim());

      try {
        await MikrotikConnector.connect();
      } finally {
        // لا نغلق الاتصال - تجمع الاتصالات يديره تلقائياً
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            builder: (context) => HomeScreen(
              isVersion7OrNewer: true,
              username: _remoteUserController.text.trim(),
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
        const SizedBox(height: 8),
        // إعدادات MQTT
        GestureDetector(
          onTap: () => setState(() => _showMqttSettings = !_showMqttSettings),
          child: Row(
            children: [
              Icon(_showMqttSettings ? Icons.expand_less : Icons.expand_more, color: Colors.white54, size: 20),
              const SizedBox(width: 4),
              const Text('إعدادات MQTT', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
        ),
        if (_showMqttSettings) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _mqttUsernameController,
            decoration: const InputDecoration(labelText: 'MQTT Username', prefixIcon: Icon(Icons.cloud_outlined)),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mqttPasswordController,
            obscureText: _mqttPasswordObscured,
            decoration: InputDecoration(
              labelText: 'MQTT Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_mqttPasswordObscured ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _mqttPasswordObscured = !_mqttPasswordObscured),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
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
          child: const Text(
            'سياسة الخصوصية',
            style: TextStyle(
              color: Color(0xB3FFFFFF),
              decoration: TextDecoration.underline,
              decorationColor: Color(0xB3FFFFFF),
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
            labelText: 'عنوان الخادم البعيد (Domain أو IP)',
            hintText: 'router.example.com أو 1.2.3.4',
            prefixIcon: Icon(Icons.cloud),
          ),
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _remotePortController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8728 أو 8729',
                  prefixIcon: Icon(Icons.numbers),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remoteUserController,
          decoration: const InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person_outline),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _remotePassController,
          obscureText: _remoteObscured,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_remoteObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _remoteObscured = !_remoteObscured),
            ),
          ),
          style: const TextStyle(color: Colors.white),
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
                    color: Colors.white,
                  ),
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
              style: const TextStyle(
                color: Color(0xB3FFFFFF),
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