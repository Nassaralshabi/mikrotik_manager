import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'mikrotik_connector.dart';

class RemoteLoginScreen extends StatefulWidget {
  const RemoteLoginScreen({super.key});

  @override
  State<RemoteLoginScreen> createState() => _RemoteLoginScreenState();
}

class _RemoteLoginScreenState extends State<RemoteLoginScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  
  // Controllers
  final _localIpController = TextEditingController();
  final _remoteAddressController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '8728');
  
  // State
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String _connectionStatus = '';
  ConnectionType _selectedType = ConnectionType.local;
  bool _saveCredentials = true;
  bool _autoConnect = false;
  
  // Saved profiles
  List<ConnectionProfile> _savedProfiles = [];
  ConnectionProfile? _selectedProfile;
  
  // Connection test results
  Map<String, dynamic> _testResults = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _tabController = TabController(length: 2, vsync: this);
    
    _loadSavedProfiles();
    _loadLastUsedSettings();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _localIpController.dispose();
    _remoteAddressController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getStringList('connection_profiles') ?? [];
    
    setState(() {
      _savedProfiles = profilesJson
          .map((json) => ConnectionProfile.fromJson(json))
          .toList();
    });
  }

  Future<void> _loadLastUsedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _localIpController.text = prefs.getString('local_ip') ?? '';
      _remoteAddressController.text = prefs.getString('remote_address') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _portController.text = prefs.getString('port') ?? '8728';
      _selectedType = ConnectionType.values[prefs.getInt('connection_type') ?? 0];
      _saveCredentials = prefs.getBool('save_credentials') ?? true;
      _autoConnect = prefs.getBool('auto_connect') ?? false;
      
      // Set tab based on connection type
      _tabController.index = _selectedType == ConnectionType.local ? 0 : 1;
    });
  }

  Future<void> _saveCurrentProfile() async {
    if (_usernameController.text.isEmpty) return;
    
    final name = await _showSaveProfileDialog();
    if (name == null) return;
    
    final profile = ConnectionProfile(
      name: name,
      type: _selectedType,
      address: _selectedType == ConnectionType.local 
          ? _localIpController.text 
          : _remoteAddressController.text,
      username: _usernameController.text,
      password: _saveCredentials ? _passwordController.text : '',
      port: int.tryParse(_portController.text) ?? 8728,
      isDefault: false,
    );
    
    final prefs = await SharedPreferences.getInstance();
    _savedProfiles.add(profile);
    
    final profilesJson = _savedProfiles.map((p) => p.toJson()).toList();
    await prefs.setStringList('connection_profiles', profilesJson);
    
    setState(() {});
    
    _showSuccessSnackBar('تم حفظ الملف الشخصي: $name');
  }

  Future<String?> _showSaveProfileDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حفظ الملف الشخصي'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'اسم الملف الشخصي',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _loadProfile(ConnectionProfile profile) {
    setState(() {
      _selectedProfile = profile;
      _selectedType = profile.type;
      _usernameController.text = profile.username;
      _passwordController.text = profile.password;
      _portController.text = profile.port.toString();
      
      if (profile.type == ConnectionType.local) {
        _localIpController.text = profile.address;
        _tabController.index = 0;
      } else {
        _remoteAddressController.text = profile.address;
        _tabController.index = 1;
      }
    });
    
    _showSuccessSnackBar('تم تحميل الملف الشخصي: ${profile.name}');
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = 'جاري اختبار الاتصال...';
      _testResults.clear();
    });

    final address = _selectedType == ConnectionType.local 
        ? _localIpController.text.trim()
        : _remoteAddressController.text.trim();
    final port = int.tryParse(_portController.text) ?? 8728;

    try {
      // Test 1: Address validation
      setState(() {
        _testResults['address'] = {'status': 'testing', 'message': 'فحص العنوان...'};
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (address.isEmpty) {
        throw Exception('العنوان فارغ');
      }
      
      bool isValidAddress = false;
      String resolvedIP = address;
      
      if (_isValidIP(address)) {
        isValidAddress = true;
        setState(() {
          _testResults['address'] = {
            'status': 'success', 
            'message': 'عنوان IP صحيح: $address'
          };
        });
      } else {
        // Try DNS resolution
        try {
          final addresses = await InternetAddress.lookup(address);
          if (addresses.isNotEmpty) {
            resolvedIP = addresses.first.address;
            isValidAddress = true;
            setState(() {
              _testResults['address'] = {
                'status': 'success', 
                'message': 'DNS صحيح: $address → $resolvedIP'
              };
            });
          }
        } catch (e) {
          setState(() {
            _testResults['address'] = {
              'status': 'error', 
              'message': 'خطأ في DNS: $e'
            };
          });
        }
      }

      if (!isValidAddress) return;

      // Test 2: Network connectivity  
      setState(() {
        _testResults['network'] = {'status': 'testing', 'message': 'اختبار الشبكة...'};
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      try {
        final result = await Process.run('ping', ['-c', '2', resolvedIP], 
            timeout: const Duration(seconds: 8));
        
        if (result.exitCode == 0) {
          setState(() {
            _testResults['network'] = {
              'status': 'success', 
              'message': 'الجهاز متاح على الشبكة'
            };
          });
        } else {
          setState(() {
            _testResults['network'] = {
              'status': 'warning', 
              'message': 'Ping فاشل - قد يكون الجهاز يحجب ICMP'
            };
          });
        }
      } catch (e) {
        setState(() {
          _testResults['network'] = {
            'status': 'warning', 
            'message': 'فشل ping - سنحاول الاتصال المباشر'
          };
        });
      }

      // Test 3: Port connectivity
      setState(() {
        _testResults['port'] = {'status': 'testing', 'message': 'فحص المنفذ...'};
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      try {
        final socket = await Socket.connect(resolvedIP, port, 
            timeout: const Duration(seconds: 8));
        await socket.close();
        
        setState(() {
          _testResults['port'] = {
            'status': 'success', 
            'message': 'المنفذ $port مفتوح ومتاح'
          };
        });
      } catch (e) {
        setState(() {
          _testResults['port'] = {
            'status': 'error', 
            'message': 'فشل الاتصال بالمنفذ $port: ${e.toString()}'
          };
        });
        return;
      }

      // Test 4: API Authentication
      if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
        setState(() {
          _testResults['auth'] = {'status': 'testing', 'message': 'اختبار المصادقة...'};
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          // Save temporary settings
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ip', address);
          await prefs.setString('user', _usernameController.text);
          await prefs.setString('pass', _passwordController.text);
          await prefs.setString('port', _portController.text);
          
          final client = await MikrotikConnector.connect();
          client.close();
          
          setState(() {
            _testResults['auth'] = {
              'status': 'success', 
              'message': 'تم تسجيل الدخول بنجاح!'
            };
            _connectionStatus = _selectedType == ConnectionType.local 
                ? 'اتصال محلي جاهز'
                : 'اتصال عن بُعد جاهز';
          });
          
        } catch (e) {
          setState(() {
            _testResults['auth'] = {
              'status': 'error', 
              'message': 'فشل المصادقة: ${e.toString()}'
            };
          });
        }
      } else {
        setState(() {
          _testResults['auth'] = {
            'status': 'warning', 
            'message': 'لم يتم اختبار المصادقة - بيانات الدخول فارغة'
          };
          _connectionStatus = 'فحص الشبكة مكتمل - أدخل بيانات الدخول';
        });
      }

    } catch (e) {
      setState(() {
        _connectionStatus = 'فشل الاختبار: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _connect() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    final address = _selectedType == ConnectionType.local 
        ? _localIpController.text.trim()
        : _remoteAddressController.text.trim();
        
    if (address.isEmpty) {
      _showErrorSnackBar('يرجى إدخال عنوان الاتصال');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save connection settings
      await prefs.setString('ip', address);
      await prefs.setString('user', _usernameController.text);
      await prefs.setString('pass', _passwordController.text);
      await prefs.setString('port', _portController.text);
      
      // Save UI settings
      if (_saveCredentials) {
        if (_selectedType == ConnectionType.local) {
          await prefs.setString('local_ip', _localIpController.text);
        } else {
          await prefs.setString('remote_address', _remoteAddressController.text);
        }
        await prefs.setString('username', _usernameController.text);
        await prefs.setString('password', _passwordController.text);
      }
      
      await prefs.setString('port', _portController.text);
      await prefs.setInt('connection_type', _selectedType.index);
      await prefs.setBool('save_credentials', _saveCredentials);
      await prefs.setBool('auto_connect', _autoConnect);
      
      // Test connection
      final client = await MikrotikConnector.connect();
      client.close();
      
      // Success - navigate to main app
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
      
    } catch (e) {
      _showErrorSnackBar('فشل الاتصال: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (String part in parts) {
      final int? num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.8),
              theme.primaryColor.withOpacity(0.4),
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(theme),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Connection type tabs
                        _buildConnectionTypeTabs(theme),
                        
                        const SizedBox(height: 24),
                        
                        // Connection form
                        _buildConnectionForm(theme),
                        
                        const SizedBox(height: 24),
                        
                        // Test results
                        if (_testResults.isNotEmpty) _buildTestResults(theme),
                        
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        _buildActionButtons(theme),
                        
                        const SizedBox(height: 20),
                        
                        // Saved profiles
                        if (_savedProfiles.isNotEmpty) _buildSavedProfiles(theme),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.router,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MikroTik Remote Manager',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحكم في جهازك من أي مكان في العالم',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTypeTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedType = index == 0 ? ConnectionType.local : ConnectionType.remote;
          });
        },
        indicator: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(
            icon: Icon(Icons.home_work),
            text: 'اتصال محلي',
          ),
          Tab(
            icon: Icon(Icons.public),
            text: 'اتصال عن بُعد',
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection status
          if (_connectionStatus.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _connectionStatus.contains('جاهز') 
                    ? Colors.green.withOpacity(0.2)
                    : _connectionStatus.contains('فشل')
                      ? Colors.red.withOpacity(0.2) 
                      : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _connectionStatus.contains('جاهز') 
                      ? Colors.green
                      : _connectionStatus.contains('فشل')
                        ? Colors.red 
                        : Colors.blue,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _connectionStatus.contains('جاهز') 
                        ? Icons.check_circle
                        : _connectionStatus.contains('فشل')
                          ? Icons.error
                          : Icons.info,
                    color: _connectionStatus.contains('جاهز') 
                        ? Colors.green
                        : _connectionStatus.contains('فشل')
                          ? Colors.red 
                          : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _connectionStatus,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Address field
          Text(
            _selectedType == ConnectionType.local ? 'عنوان IP المحلي' : 'العنوان العام أو DNS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _selectedType == ConnectionType.local 
                ? _localIpController 
                : _remoteAddressController,
            decoration: InputDecoration(
              hintText: _selectedType == ConnectionType.local 
                  ? '192.168.1.1' 
                  : 'your-domain.com or 203.0.113.1',
              prefixIcon: Icon(
                _selectedType == ConnectionType.local ? Icons.home : Icons.public,
                color: theme.primaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: _selectedType == ConnectionType.local 
                ? TextInputType.number 
                : TextInputType.text,
          ),
          
          const SizedBox(height: 16),
          
          // Username and password row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اسم المستخدم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'admin',
                        prefixIcon: Icon(Icons.person, color: theme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'كلمة المرور',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock, color: theme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Port field
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المنفذ (Port)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        hintText: '8728',
                        prefixIcon: Icon(Icons.settings_ethernet, color: theme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Options
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('حفظ بيانات الدخول', style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: _saveCredentials,
                      onChanged: (value) => setState(() => _saveCredentials = value ?? true),
                      activeColor: theme.primaryColor,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text('اتصال تلقائي', style: TextStyle(color: Colors.white, fontSize: 14)),
                      value: _autoConnect,
                      onChanged: (value) => setState(() => _autoConnect = value ?? false),
                      activeColor: theme.primaryColor,
                      checkColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'نتائج اختبار الاتصال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ..._testResults.entries.map((entry) => _buildTestResultItem(
            entry.key,
            entry.value['status'],
            entry.value['message'],
          )),
        ],
      ),
    );
  }

  Widget _buildTestResultItem(String title, String status, String message) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'testing':
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case 'success':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'warning':
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case 'error':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          status == 'testing'
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTestTitle(title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTestTitle(String key) {
    switch (key) {
      case 'address':
        return 'فحص العنوان';
      case 'network':
        return 'اختبار الشبكة';
      case 'port':
        return 'فحص المنفذ';
      case 'auth':
        return 'اختبار المصادقة';
      default:
        return key;
    }
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isTestingConnection ? null : _testConnection,
                icon: _isTestingConnection
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isTestingConnection ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.primaryColor),
                  foregroundColor: theme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _connect,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login),
                label: Text(_isLoading ? 'جاري الاتصال...' : 'اتصال'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        TextButton.icon(
          onPressed: _saveCurrentProfile,
          icon: const Icon(Icons.bookmark_add),
          label: const Text('حفظ كملف شخصي'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedProfiles(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'الملفات الشخصية المحفوظة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...(_savedProfiles.take(3)).map((profile) => _buildProfileItem(profile, theme)),
          
          if (_savedProfiles.length > 3)
            TextButton(
              onPressed: () {
                // Show all profiles dialog
              },
              child: Text('عرض جميع الملفات (${_savedProfiles.length})'),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(ConnectionProfile profile, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          profile.type == ConnectionType.local ? Icons.home : Icons.public,
          color: theme.primaryColor,
        ),
        title: Text(
          profile.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${profile.username}@${profile.address}:${profile.port}',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _loadProfile(profile),
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: 'استخدام',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _savedProfiles.remove(profile);
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'حذف',
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
      ),
    );
  }
}

enum ConnectionType { local, remote }

class ConnectionProfile {
  final String name;
  final ConnectionType type;
  final String address;
  final String username;
  final String password;
  final int port;
  final bool isDefault;

  ConnectionProfile({
    required this.name,
    required this.type,
    required this.address,
    required this.username,
    required this.password,
    required this.port,
    required this.isDefault,
  });

  String toJson() {
    return '${type.index}|$name|$address|$username|$password|$port|$isDefault';
  }

  static ConnectionProfile fromJson(String json) {
    final parts = json.split('|');
    return ConnectionProfile(
      type: ConnectionType.values[int.parse(parts[0])],
      name: parts[1],
      address: parts[2],
      username: parts[3],
      password: parts[4],
      port: int.parse(parts[5]),
      isDefault: parts[6] == 'true',
    );
  }
}