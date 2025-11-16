import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_login_screen.dart';
import 'connection_diagnostic_screen.dart';
import 'remote_access_guide_screen.dart';
import 'system_dashboard_screen.dart';

class RemoteControlCenter extends StatefulWidget {
  const RemoteControlCenter({super.key});

  @override
  State<RemoteControlCenter> createState() => _RemoteControlCenterState();
}

class _RemoteControlCenterState extends State<RemoteControlCenter> 
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isConnected = false;
  String _connectionType = '';
  String _currentConnection = '';
  String _lastActivity = '';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    _checkConnectionStatus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      final ip = prefs.getString('ip') ?? '';
      final user = prefs.getString('user') ?? '';
      final port = prefs.getString('port') ?? '8728';
      
      if (ip.isNotEmpty && user.isNotEmpty) {
        _currentConnection = '$user@$ip:$port';
        _isConnected = true;
        _connectionType = _isLocalIP(ip) ? 'محلي' : 'عن بُعد';
        _lastActivity = 'نشط الآن';
      } else {
        _currentConnection = 'غير متصل';
        _isConnected = false;
        _connectionType = '';
        _lastActivity = '';
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.8),
              theme.primaryColor.withOpacity(0.3),
              Colors.black.withOpacity(0.9),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: FadeTransition(
              opacity: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(theme),
                    
                    const SizedBox(height: 32),
                    
                    // Current connection status
                    _buildConnectionStatusCard(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Main actions
                    _buildMainActionsGrid(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Quick access
                    if (_isConnected) _buildQuickAccessSection(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Features preview
                    _buildFeaturesSection(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.public,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'مركز التحكم عن بُعد',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'إدارة MikroTik من أي مكان في العالم',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [Colors.green.withOpacity(0.8), Colors.teal.withOpacity(0.6)]
              : [Colors.orange.withOpacity(0.8), Colors.red.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.orange).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isConnected 
                      ? (_connectionType == 'محلي' ? Icons.home_work : Icons.public)
                      : Icons.wifi_off,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConnected ? 'متصل' : 'غير متصل',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_connectionType.isNotEmpty)
                      Text(
                        'اتصال $_connectionType',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.white : Colors.red.shade300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isConnected ? Colors.white : Colors.red.shade300).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_currentConnection.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تفاصيل الاتصال:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentConnection,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (_lastActivity.isNotEmpty)
                          Text(
                            _lastActivity,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                          ),
                      ],
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

  Widget _buildMainActionsGrid(ThemeData theme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          title: _isConnected ? 'تغيير الاتصال' : 'اتصال جديد',
          subtitle: 'محلي أو عن بُعد',
          icon: Icons.login,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RemoteLoginScreen()),
            );
          },
        ),
        
        _buildActionCard(
          title: 'تشخيص المشاكل',
          subtitle: 'حل مشاكل الاتصال',
          icon: Icons.troubleshoot,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConnectionDiagnosticScreen()),
            );
          },
        ),
        
        _buildActionCard(
          title: 'دليل الإعداد',
          subtitle: 'تعلم التحكم عن بُعد',
          icon: Icons.school,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RemoteAccessGuideScreen()),
            );
          },
        ),
        
        _buildActionCard(
          title: _isConnected ? 'لوحة التحكم' : 'الواجهة الرئيسية',
          subtitle: 'العودة للتطبيق',
          icon: Icons.dashboard,
          color: theme.primaryColor,
          onTap: () {
            if (_isConnected) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SystemDashboardScreen()),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(ThemeData theme) {
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
                'وصول سريع',
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
                  'لوحة التحكم',
                  Icons.dashboard,
                  Colors.blue,
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SystemDashboardScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'إضافة كروت',
                  Icons.add_card,
                  Colors.green,
                  () {
                    Navigator.pushReplacementNamed(context, '/add-user');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  'المستخدمين',
                  Icons.people,
                  Colors.purple,
                  () {
                    Navigator.pushReplacementNamed(context, '/active-users');
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

  Widget _buildFeaturesSection(ThemeData theme) {
    final features = [
      {
        'title': 'تشخيص ذكي',
        'description': 'فحص تلقائي لمشاكل الاتصال مع حلول مقترحة',
        'icon': Icons.auto_fix_high,
        'color': Colors.cyan,
      },
      {
        'title': 'حفظ الملفات الشخصية',
        'description': 'حفظ عدة اتصالات والتبديل بينها بسهولة',
        'icon': Icons.bookmark_added,
        'color': Colors.indigo,
      },
      {
        'title': 'اختبار تلقائي',
        'description': 'فحص الاتصال قبل الحفظ لضمان العمل',
        'icon': Icons.verified,
        'color': Colors.green,
      },
      {
        'title': 'دليل شامل',
        'description': 'تعليمات تفصيلية لإعداد Port Forwarding',
        'icon': Icons.menu_book,
        'color': Colors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ميزات التحكم عن بُعد',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        ...features.map((feature) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (feature['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (feature['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: feature['color'] as Color,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}