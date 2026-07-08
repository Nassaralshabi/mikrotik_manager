import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';
import 'notification_service.dart';
import 'connection_service.dart';
import 'home_screen.dart';
import 'custom_page_route.dart';

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

  bool _isLoading = false;
  String _errorMessage = '';
  bool _rememberMe = true;
  bool _isPasswordObscured = true;
  bool _isScanning = false;

  // --- Regex للتحقق من صيغة IP ---
  static final _ipRegex = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

  String? _validateIpAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'الرجاء إدخال عنوان IP';
    final match = _ipRegex.firstMatch(value.trim());
    if (match == null) return 'صيغة IP غير صحيحة\nالمثال: 192.168.1.1';
    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match.group(i)!);
      if (octet == null || octet < 0 || octet > 255) {
        return 'كل جزء من IP يجب أن يكون بين 0 و 255';
      }
    }
    return null;
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
    if (_ipController.text.isNotEmpty) return;
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
      if (mounted) {
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
    // التحقق من صيغة IP
    final ipError = _validateIpAddress(_ipController.text);
    if (ipError != null) {
      setState(() => _errorMessage = ipError);
      return;
    }
    if (_userController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم المستخدم');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _handleCredentials();
      final client = await MikrotikConnector.connect();

      // إرسال إشعار Telegram عبر الخدمة المركزية
      NotificationService.instance.notifyLogin(ipAddress: _ipController.text);

      final response = await client.talk(['/system/resource/print']);
      bool isVersion7OrNewer = false;
      String versionStr = '6';
      if (response.isNotEmpty && response[0]['version'] != null) {
        versionStr = response[0]['version'] as String;
        try {
          isVersion7OrNewer = int.parse(versionStr.split('.').first) >= 7;
        } catch (e) {
          isVersion7OrNewer = false;
        }
      }

      // حفظ إصدار RouterOS في SharedPreferences لاستخدامه في الشاشات الأخرى
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mikrotik_version', versionStr);
      await prefs.setBool('is_version7_plus', isVersion7OrNewer);

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
    _remotePassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formMaxHeight = MediaQuery.of(context).size.height * 0.65;
    final formMinHeight = formMaxHeight < 400 ? formMaxHeight : 400.0;

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
                    Tab(icon: Icon(Icons.lan), text: 'اتصال محلي'),
                    Tab(icon: Icon(Icons.cloud), text: 'اتصال عن بعد'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                ),

              // استخدام MediaQuery لجعل الارتفاع متجاوباً بدلاً من 550 ثابت
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: formMaxHeight,
                  minHeight: formMinHeight,
                ),
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
    if (_remoteServerController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال عنوان الخادم البعيد');
      return;
    }
    if (_remoteUserController.text.trim().isEmpty || _remotePassController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    // التحقق من صيغة IP أو Domain
    final serverValue = _remoteServerController.text.trim();
    if (!_ipRegex.hasMatch(serverValue) && !_isValidDomain(serverValue)) {
      setState(() => _errorMessage = 'صيغة العنوان غير صحيحة\nأدخل IP أو اسم نطاق صحيح');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ip', serverValue);
      await prefs.setString('user', _remoteUserController.text.trim());
      await prefs.setString('pass', _remotePassController.text);
      await prefs.setString('port', _remotePortController.text.trim().isEmpty ? '8728' : _remotePortController.text.trim());

      RouterOSClient? client;
      try {
        client = await MikrotikConnector.connect();
      } finally {
        client?.close();
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

  /// تحقق بسيط من صحة اسم النطاق
  bool _isValidDomain(String value) {
    final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$');
    return domainRegex.hasMatch(value);
  }

  Widget _buildLocalLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _ipController,
                  decoration: const InputDecoration(labelText: 'IP Address', prefixIcon: Icon(Icons.lan)),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  validator: _validateIpAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(labelText: 'Port'),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final port = int.tryParse(v ?? '');
                    if (port == null || port < 1 || port > 65535) return 'منفذ غير صالح';
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        child: CircularProgressIndicator(color: Color(0xFF6b3fa0)),
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
          TextFormField(
            controller: _userController,
            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
            style: const TextStyle(color: Colors.white),
            validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال اسم المستخدم' : null,
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
            onPressed: () {}, // سياسة الخصوصية معطلة
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
      ),
    );
  }

  Widget _buildRemoteLoginForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _remoteServerController,
            decoration: const InputDecoration(
              labelText: 'عنوان الخادم البعيد (Domain أو IP)',
              hintText: 'router.example.com أو 1.2.3.4',
              prefixIcon: Icon(Icons.cloud),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.url,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'الرجاء إدخال العنوان';
              if (!_ipRegex.hasMatch(v.trim()) && !_isValidDomain(v.trim())) return 'صيغة العنوان غير صحيحة';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remotePortController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '8728 أو 8729',
              prefixIcon: Icon(Icons.numbers),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              final port = int.tryParse(v ?? '');
              if (port == null || port < 1 || port > 65535) return 'منفذ غير صالح';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
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
                    height: 24, width: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
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
      ),
    );
  }
}
