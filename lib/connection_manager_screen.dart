import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_login_screen.dart';
import 'connection_diagnostic_screen.dart';

class ConnectionManagerScreen extends StatefulWidget {
  const ConnectionManagerScreen({super.key});

  @override
  State<ConnectionManagerScreen> createState() => _ConnectionManagerScreenState();
}

class _ConnectionManagerScreenState extends State<ConnectionManagerScreen> {
  String _currentConnection = '';
  bool _isConnected = false;
  String _connectionType = '';
  String _lastConnected = '';
  
  @override
  void initState() {
    super.initState();
    _checkCurrentConnection();
  }

  Future<void> _checkCurrentConnection() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      final ip = prefs.getString('ip') ?? '';
      final user = prefs.getString('user') ?? '';
      final port = prefs.getString('port') ?? '8728';
      
      if (ip.isNotEmpty && user.isNotEmpty) {
        _currentConnection = '$user@$ip:$port';
        _isConnected = true;
        _connectionType = _isLocalIP(ip) ? 'محلي' : 'عن بُعد';
        _lastConnected = 'متصل الآن';
      } else {
        _currentConnection = 'غير متصل';
        _isConnected = false;
        _connectionType = '';
        _lastConnected = '';
      }
    });
  }

  bool _isLocalIP(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return false;
    
    final nums = parts.cast<int>();
    return (nums[0] == 10) ||
           (nums[0] == 172 && nums[1] >= 16 && nums[1] <= 31) ||
           (nums[0] == 192 && nums[1] == 168) ||
           (nums[0] == 127);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الاتصالات'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current connection status
            _buildCurrentConnectionCard(theme),
            
            const SizedBox(height: 24),
            
            // Connection options
            const Text(
              'خيارات الاتصال',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Local connection
            _buildConnectionOptionCard(
              title: 'اتصال محلي',
              description: 'للاستخدام داخل الشبكة المحلية',
              icon: Icons.home_work,
              color: Colors.blue,
              isRecommended: _connectionType == 'محلي',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemoteLoginScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Remote connection
            _buildConnectionOptionCard(
              title: 'التحكم عن بُعد',
              description: 'للوصول من خارج الشبكة عبر الإنترنت',
              icon: Icons.public,
              color: Colors.green,
              isRecommended: _connectionType == 'عن بُعد',
              isNew: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RemoteLoginScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Tools section
            const Text(
              'أدوات مساعدة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Diagnostic tool
            _buildToolCard(
              title: 'تشخيص مشاكل الاتصال',
              description: 'فحص وحل مشاكل الاتصال التقنية',
              icon: Icons.troubleshoot,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConnectionDiagnosticScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Setup guide
            _buildToolCard(
              title: 'دليل إعداد التحكم عن بُعد',
              description: 'تعلم كيفية إعداد MikroTik للوصول الخارجي',
              icon: Icons.school,
              color: Colors.purple,
              onTap: () {
                Navigator.pushNamed(context, '/remote-guide');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions
            if (_isConnected) _buildQuickActionsCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConnectionCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [Colors.green.withOpacity(0.8), Colors.teal.withOpacity(0.6)]
              : [Colors.grey.withOpacity(0.8), Colors.blueGrey.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.grey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected ? 'متصل' : 'غير متصل',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_connectionType.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'اتصال $_connectionType',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isConnected)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          if (_currentConnection.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'تفاصيل الاتصال:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentConnection,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isRecommended = false,
    bool isNew = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? color : color.withOpacity(0.3),
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'الحالي',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (isNew) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white60,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(ThemeData theme) {
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
              Icon(Icons.flash_on, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'إجراءات سريعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'قطع الاتصال',
                  Icons.logout,
                  Colors.red,
                  () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    setState(() {
                      _isConnected = false;
                      _currentConnection = 'غير متصل';
                      _connectionType = '';
                    });
                    _showSuccessSnackBar('تم قطع الاتصال');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'اختبار الاتصال',
                  Icons.wifi_tethering,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConnectionDiagnosticScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
}