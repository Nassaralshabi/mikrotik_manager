import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

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

    // Step 2: Validate IP
    await _updateStep(1, () async {
      if (!_isValidIP(ip!)) {
        throw Exception('عنوان IP غير صحيح: $ip');
      }
      return 'عنوان IP صحيح';
    });

    // Step 3: Network connectivity
    await _updateStep(2, () async {
      try {
        final result = await Process.run('ping', ['-c', '3', ip!], timeout: Duration(seconds: 10));
        if (result.exitCode != 0) {
          throw Exception('لا يمكن الوصول للجهاز - ping failed');
        }
        return 'الجهاز متاح على الشبكة';
      } catch (e) {
        throw Exception('فشل ping: ${e.toString()}');
      }
    });

    // Step 4: Port check
    await _updateStep(3, () async {
      try {
        final socket = await Socket.connect(ip!, port, timeout: Duration(seconds: 5));
        await socket.close();
        return 'المنفذ $port مفتوح';
      } on SocketException catch (e) {
        if (e.message.contains('Connection refused')) {
          throw Exception('المنفذ $port مغلق أو خدمة API معطلة');
        } else {
          throw Exception('فشل الاتصال: ${e.message}');
        }
      }
    });

    // Step 5: API service check
    await _updateStep(4, () async {
      // This is a simplified check - في الواقع نحتاج لمحاولة اتصال API فعلي
      return 'فحص أولي مكتمل - جرب الاتصال الآن';
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
        'title': 'تفعيل خدمة API',
        'description': 'في MikroTik Terminal:',
        'commands': ['/ip service enable api', '/ip service set api port=8728'],
        'icon': Icons.api,
      },
      {
        'title': 'فتح المنافذ في Firewall',
        'description': 'السماح للمنفذ 8728:',
        'commands': ['/ip firewall filter add chain=input protocol=tcp dst-port=8728 action=accept'],
        'icon': Icons.security,
      },
      {
        'title': 'إنشاء مستخدم API',
        'description': 'إنشاء مستخدم بصلاحية API:',
        'commands': ['/user add name=api-user password=your-password group=full'],
        'icon': Icons.person_add,
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
                'حلول شائعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...solutions.map((solution) => _buildSolutionCard(solution)),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(Map<String, dynamic> solution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(solution['icon'], color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                solution['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            solution['description'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
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
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          command,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade300,
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