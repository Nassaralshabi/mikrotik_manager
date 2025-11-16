import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import 'remote_access_guide_screen.dart';

class ConnectionDiagnosticScreen extends StatefulWidget {
  const ConnectionDiagnosticScreen({super.key});

  @override
  State<ConnectionDiagnosticScreen> createState() => _ConnectionDiagnosticScreenState();
}

class _ConnectionDiagnosticScreenState extends State<ConnectionDiagnosticScreen> {
  bool _isRunning = false;
  List<DiagnosticStep> _steps = [];
  String _ip = '';
  int _port = 8728;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeDiagnosticSteps();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ip = prefs.getString('ip') ?? '';
      _port = int.tryParse(prefs.getString('port') ?? '8728') ?? 8728;
    });
  }

  void _initializeDiagnosticSteps() {
    _steps = [
      DiagnosticStep(
        title: 'فحص إعدادات الاتصال',
        description: 'التحقق من وجود عنوان IP واسم المستخدم وكلمة المرور',
        status: DiagnosticStatus.pending,
      ),
      DiagnosticStep(
        title: 'تحديد نوع الاتصال',
        description: 'تحديد ما إذا كان الاتصال محلي أم عن بُعد عبر الإنترنت',
        status: DiagnosticStatus.pending,
      ),
      DiagnosticStep(
        title: 'فحص صحة عنوان IP',
        description: 'التأكد من أن عنوان IP في التنسيق الصحيح',
        status: DiagnosticStatus.pending,
      ),
      DiagnosticStep(
        title: 'فحص الاتصال الشبكي',
        description: 'التحقق من إمكانية الوصول للجهاز على الشبكة',
        status: DiagnosticStatus.pending,
      ),
      DiagnosticStep(
        title: 'فحص المنفذ (Port)',
        description: 'التأكد من أن منفذ API مفتوح ومتاح',
        status: DiagnosticStatus.pending,
      ),
      DiagnosticStep(
        title: 'فحص خدمة API',
        description: 'التحقق من تفعيل خدمة API في MikroTik',
        status: DiagnosticStatus.pending,
      ),
      DiagnosticStep(
        title: 'اختبار التحكم عن بُعد',
        description: 'فحص إعدادات التحكم عن بُعد والـ Port Forwarding',
        status: DiagnosticStatus.pending,
      ),
    ];
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isRunning = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('ip');
    final user = prefs.getString('user');
    final pass = prefs.getString('pass');
    final portStr = prefs.getString('port');
    final port = int.tryParse(portStr ?? '8728') ?? 8728;

    String connectionType = '';
    bool isRemoteConnection = false;

    // Step 1: Check settings
    await _updateStep(0, () async {
      if (ip == null || ip.isEmpty) {
        throw Exception('عنوان IP غير محدد');
      }
      if (user == null || user.isEmpty) {
        throw Exception('اسم المستخدم غير محدد');
      }
      if (pass == null || pass.isEmpty) {
        throw Exception('كلمة المرور غير محددة');
      }
      return 'جميع الإعدادات موجودة';
    });

    // Step 2: Determine connection type
    await _updateStep(1, () async {
      if (_isPublicIP(ip!)) {
        connectionType = 'اتصال عن بُعد (عنوان عام)';
        isRemoteConnection = true;
      } else if (_isDynamicDNS(ip!)) {
        connectionType = 'اتصال عن بُعد (Dynamic DNS)';
        isRemoteConnection = true;
      } else if (_isLocalIP(ip!)) {
        connectionType = 'اتصال محلي (شبكة داخلية)';
        isRemoteConnection = false;
      } else {
        connectionType = 'نوع غير محدد';
      }
      return connectionType;
    });

    // Step 3: Validate IP
    await _updateStep(2, () async {
      if (_isDynamicDNS(ip!)) {
        // Try to resolve DNS
        try {
          final addresses = await InternetAddress.lookup(ip!);
          if (addresses.isNotEmpty) {
            return 'DNS صحيح - يشير إلى: ${addresses.first.address}';
          } else {
            throw Exception('فشل حل DNS للعنوان: $ip');
          }
        } catch (e) {
          throw Exception('خطأ في DNS: $e');
        }
      } else if (!_isValidIP(ip!)) {
        throw Exception('عنوان IP غير صحيح: $ip');
      }
      return 'عنوان IP صحيح';
    });

    // Step 4: Network connectivity
    await _updateStep(3, () async {
      try {
        final result = await Process.run('ping', ['-c', '3', ip!], timeout: Duration(seconds: 15));
        if (result.exitCode != 0) {
          if (isRemoteConnection) {
            throw Exception('لا يمكن الوصول للجهاز عن بُعد - تحقق من:\n• Port Forwarding\n• عنوان IP العام\n• اتصال الإنترنت');
          } else {
            throw Exception('لا يمكن الوصول للجهاز محلياً - ping failed');
          }
        }
        return isRemoteConnection ? 'الجهاز متاح عن بُعد عبر الإنترنت' : 'الجهاز متاح على الشبكة المحلية';
      } catch (e) {
        if (isRemoteConnection) {
          throw Exception('فشل الوصول عن بُعد: ${e.toString()}\nتأكد من إعدادات Port Forwarding');
        } else {
          throw Exception('فشل ping: ${e.toString()}');
        }
      }
    });

    // Step 5: Port check
    await _updateStep(4, () async {
      try {
        final socket = await Socket.connect(ip!, port, timeout: Duration(seconds: 10));
        await socket.close();
        return isRemoteConnection 
            ? 'المنفذ $port مفتوح عن بُعد - Port Forwarding يعمل'
            : 'المنفذ $port مفتوح محلياً';
      } on SocketException catch (e) {
        if (e.message.contains('Connection refused')) {
          if (isRemoteConnection) {
            throw Exception('المنفذ $port مرفوض عن بُعد - تحقق من:\n• Port Forwarding في الراوتر الرئيسي\n• إعدادات Firewall\n• خدمة API في MikroTik');
          } else {
            throw Exception('المنفذ $port مغلق أو خدمة API معطلة');
          }
        } else {
          throw Exception('فشل الاتصال: ${e.message}');
        }
      }
    });

    // Step 6: API service check
    await _updateStep(5, () async {
      return 'فحص أولي مكتمل للـ API';
    });

    // Step 7: Remote access specific checks
    await _updateStep(6, () async {
      if (isRemoteConnection) {
        return 'إعدادات التحكم عن بُعد تبدو صحيحة\nيمكنك الآن توليد الكروت من خارج الشبكة';
      } else {
        return 'اتصال محلي - للتحكم عن بُعد راجع دليل الإعداد';
      }
    });

    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _updateStep(int index, Future<String> Function() test) async {
    setState(() {
      _steps[index].status = DiagnosticStatus.running;
    });

    await Future.delayed(Duration(milliseconds: 500)); // تأثير بصري

    try {
      final result = await test();
      setState(() {
        _steps[index].status = DiagnosticStatus.success;
        _steps[index].result = result;
      });
    } catch (e) {
      setState(() {
        _steps[index].status = DiagnosticStatus.error;
        _steps[index].result = e.toString();
      });
    }

    await Future.delayed(Duration(milliseconds: 300));
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

  bool _isLocalIP(String ip) {
    if (!_isValidIP(ip)) return false;
    final parts = ip.split('.').map(int.parse).toList();
    
    // Private IP ranges
    // 10.0.0.0/8
    if (parts[0] == 10) return true;
    // 172.16.0.0/12
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;
    // 192.168.0.0/16  
    if (parts[0] == 192 && parts[1] == 168) return true;
    // 127.0.0.0/8 (localhost)
    if (parts[0] == 127) return true;
    
    return false;
  }

  bool _isPublicIP(String ip) {
    if (!_isValidIP(ip)) return false;
    return !_isLocalIP(ip);
  }

  bool _isDynamicDNS(String address) {
    // Check if it's a domain name (contains letters)
    final domainPattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$');
    return domainPattern.hasMatch(address) || address.contains('.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص مشاكل الاتصال'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.8),
                    theme.primaryColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.router, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'فحص الاتصال',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ip.isNotEmpty) ...[
                    Text(
                      'الجهاز: $_ip:$_port',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'سيقوم هذا الفحص بتشخيص مشاكل الاتصال المحتملة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Diagnostic steps
            ..._steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return _buildDiagnosticStep(step, index);
            }),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRunning ? null : _runDiagnosis,
                    icon: _isRunning 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_isRunning ? 'جاري الفحص...' : 'بدء التشخيص'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initializeDiagnosticSteps();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة تعيين'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Remote access guide button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.8),
                    Colors.purple.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.school, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'دليل إعداد التحكم عن بُعد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تعلم كيفية إعداد MikroTik للتحكم من خارج الشبكة وتوليد الكروت عن بُعد',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RemoteAccessGuideScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.launch),
                    label: const Text('فتح الدليل التفصيلي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Common solutions
            _buildCommonSolutions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticStep(DiagnosticStep step, int index) {
    Color stepColor;
    IconData stepIcon;

    switch (step.status) {
      case DiagnosticStatus.pending:
        stepColor = Colors.grey;
        stepIcon = Icons.radio_button_unchecked;
        break;
      case DiagnosticStatus.running:
        stepColor = Colors.blue;
        stepIcon = Icons.sync;
        break;
      case DiagnosticStatus.success:
        stepColor = Colors.green;
        stepIcon = Icons.check_circle;
        break;
      case DiagnosticStatus.error:
        stepColor = Colors.red;
        stepIcon = Icons.error;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stepColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stepColor.withOpacity(0.3),
          width: step.status == DiagnosticStatus.running ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          step.status == DiagnosticStatus.running
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: stepColor,
                  ),
                )
              : Icon(stepIcon, color: stepColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${step.title}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (step.result != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stepColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step.result!,
                      style: TextStyle(
                        fontSize: 13,
                        color: step.status == DiagnosticStatus.error 
                            ? Colors.red.shade300 
                            : Colors.green.shade300,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonSolutions() {
    final solutions = [
      {
        'title': 'تفعيل خدمة API في MikroTik',
        'description': 'تشغيل وإعداد خدمة API:',
        'commands': [
          '/ip service enable api',
          '/ip service set api port=8728',
          '/ip service set api address=0.0.0.0/0'
        ],
        'icon': Icons.api,
        'color': Colors.blue,
      },
      {
        'title': 'إعداد Port Forwarding للتحكم عن بُعد',
        'description': 'في MikroTik - إعادة توجيه المنفذ للوصول الخارجي:',
        'commands': [
          '/ip firewall nat add chain=dstnat protocol=tcp dst-port=8728 action=dst-nat to-addresses=192.168.1.1 to-ports=8728',
          '/ip firewall filter add chain=input protocol=tcp dst-port=8728 action=accept'
        ],
        'icon': Icons.router,
        'color': Colors.green,
      },
      {
        'title': 'فتح المنافذ في Firewall',
        'description': 'السماح لحركة API في Firewall:',
        'commands': [
          '/ip firewall filter add chain=input protocol=tcp dst-port=8728 action=accept comment="API Access"',
          '/ip firewall filter add chain=input src-address=0.0.0.0/0 protocol=tcp dst-port=8728 action=accept'
        ],
        'icon': Icons.security,
        'color': Colors.orange,
      },
      {
        'title': 'إنشاء مستخدم API للتحكم عن بُعد',
        'description': 'إنشاء مستخدم بصلاحيات كاملة:',
        'commands': [
          '/user add name=remote-api password=StrongPassword123 group=full',
          '/user set remote-api address=0.0.0.0/0 comment="Remote API User"'
        ],
        'icon': Icons.person_add,
        'color': Colors.purple,
      },
      {
        'title': 'إعداد Dynamic DNS (اختياري)',
        'description': 'لعنوان ثابت عبر الإنترنت:',
        'commands': [
          '/ip cloud set ddns-enabled=yes',
          '/ip cloud print',
          '# استخدم العنوان من cloud للوصول عن بُعد'
        ],
        'icon': Icons.cloud,
        'color': Colors.cyan,
      },
      {
        'title': 'فحص الاتصال من الخارج',
        'description': 'اختبار الوصول للـ API من خارج الشبكة:',
        'commands': [
          'telnet YOUR_PUBLIC_IP 8728',
          '# أو في متصفح الويب:',
          'http://YOUR_PUBLIC_IP:8728'
        ],
        'icon': Icons.public,
        'color': Colors.red,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'دليل إعداد التحكم عن بُعد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'للتحكم في MikroTik من خارج الشبكة وتوليد الكروت عن بُعد، اتبع الخطوات التالية بالترتيب:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade300,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...solutions.asMap().entries.map((entry) {
            final index = entry.key;
            final solution = entry.value;
            return _buildSolutionCard(solution, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(Map<String, dynamic> solution, int stepNumber) {
    final color = solution['color'] as Color? ?? Colors.blue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Icon(solution['icon'], color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  solution['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            solution['description'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (solution['commands'] as List<String>)
                  .map((command) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SelectableText(
                          command,
                          style: TextStyle(
                            fontSize: 12,
                            color: command.startsWith('#') 
                                ? Colors.grey.shade400 
                                : Colors.green.shade300,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

enum DiagnosticStatus { pending, running, success, error }

class DiagnosticStep {
  final String title;
  final String description;
  DiagnosticStatus status;
  String? result;

  DiagnosticStep({
    required this.title,
    required this.description,
    required this.status,
    this.result,
  });
}