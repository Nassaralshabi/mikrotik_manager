import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:provider/provider.dart';
import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';
import 'theme/app_theme.dart';
import 'theme/app_palette.dart';
import 'theme/app_gradients.dart';

class DatabaseCleanupScreen extends StatefulWidget {
  const DatabaseCleanupScreen({super.key});

  @override
  State<DatabaseCleanupScreen> createState() => _DatabaseCleanupScreenState();
}

class _DatabaseCleanupScreenState extends State<DatabaseCleanupScreen> {
  bool _isRunning = false;
  int _currentStep = 0;
  List<String> _stepLogs = [];
  bool _backupCreated = false;
  Map<String, int> _beforeStats = {};
  Map<String, int> _afterStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  final List<CleanupStep> _steps = [
    CleanupStep(
      title: 'إيقاف Hotspot مؤقتاً',
      description: 'سيتم إيقاف الهوتسبوت لجعل الشبكة مجانية مؤقتاً',
      command: '/ip hotspot disable [find ]',
      icon: Icons.wifi_off,
      color: Colors.orange,
    ),
    CleanupStep(
      title: 'حذف المستخدمين المنتهية صلاحيتهم',
      description: 'سيتم حذف جميع الكروت المنتهية الصلاحية',
      command: '/tool user-manager user remove [find where !actual-profile and uptime-used>0s]',
      icon: Icons.person_remove,
      color: Colors.red,
    ),
    CleanupStep(
      title: 'إغلاق الجلسات النشطة',
      description: 'سيتم إغلاق جميع جلسات المستخدمين',
      command: '/tool user-manager session close-session [find ]',
      icon: Icons.exit_to_app,
      color: Colors.purple,
    ),
    CleanupStep(
      title: 'حذف سجلات الجلسات',
      description: 'سيتم حذف جميع سجلات الجلسات القديمة',
      command: '/tool user-manager session remove [find ]',
      icon: Icons.delete_sweep,
      color: Colors.deepOrange,
    ),
    CleanupStep(
      title: 'حذف سجلات النظام',
      description: 'سيتم حذف جميع سجلات User Manager',
      command: '/tool user-manager log remove [find ]',
      icon: Icons.clear_all,
      color: Colors.red,
    ),
    CleanupStep(
      title: 'إعادة بناء قاعدة البيانات',
      description: 'سيتم إعادة بناء قاعدة بيانات User Manager',
      command: '/tool user-manager database rebuild',
      icon: Icons.build,
      color: Colors.blue,
      requiresConfirmation: true,
      delay: 20,
    ),
    CleanupStep(
      title: 'إعادة بناء سجلات قاعدة البيانات',
      description: 'سيتم إعادة بناء سجلات قاعدة البيانات',
      command: '/tool user-manager database rebuild-log',
      icon: Icons.refresh,
      color: Colors.indigo,
      requiresConfirmation: true,
      delay: 20,
    ),
    CleanupStep(
      title: 'تشغيل Hotspot',
      description: 'سيتم إعادة تشغيل الهوتسبوت',
      command: '/ip hotspot enable [find ]',
      icon: Icons.wifi,
      color: Colors.green,
      delay: 5,
    ),
    CleanupStep(
      title: 'إعادة تشغيل النظام',
      description: 'سيتم إعادة تشغيل MikroTik للتأكد من تطبيق التغييرات',
      command: '/system reboot',
      icon: Icons.restart_alt,
      color: Colors.green,
      requiresConfirmation: true,
      isReboot: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'تنظيف قاعدة البيانات',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? AppGradients.darkBackground(Theme.of(context).colorScheme)
              : AppGradients.softBackground(Theme.of(context).colorScheme),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarningCard(),
              const SizedBox(height: 24),
              _buildBackupCard(),
              const SizedBox(height: 24),
              _buildStepsCard(),
              const SizedBox(height: 24),
              _buildControlButtons(),
              if (_stepLogs.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildLogCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.error, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تحذيرات مهمة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ هذه العملية ستؤثر على جميع بيانات User Manager\n'
              '⚠️ سيتم حذف جميع الكروت المنتهية الصلاحية\n'
              '⚠️ سيتم حذف جميع السجلات والجلسات\n'
              '⚠️ ستتم إعادة تشغيل MikroTik في النهاية\n'
              '⚠️ تأكد من عمل Backup كامل قبل المتابعة',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard() {
    return Card(
      color: _backupCreated ? Colors.green.shade50 : Colors.orange.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _backupCreated ? Icons.check_circle : Icons.backup,
                  color: _backupCreated ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _backupCreated ? 'تم إنشاء النسخة الاحتياطية' : 'النسخة الاحتياطية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _backupCreated ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_backupCreated) ...[
              const Text(
                'يُنصح بشدة بإنشاء نسخة احتياطية قبل تشغيل عملية التنظيف',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('إنشاء نسخة احتياطية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ] else ...[
              const Text(
                '✅ تم إنشاء النسخة الاحتياطية بنجاح',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'خطوات التنظيف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                final isCompleted = _isRunning && index < _currentStep;
                final isCurrent = _isRunning && index == _currentStep;
                final isPending = !_isRunning || index > _currentStep;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade50
                        : isCurrent
                            ? step.color.withOpacity(0.1)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? step.color
                              : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isCurrent
                                  ? step.color
                                  : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : step.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isCompleted ? Colors.green.shade700 : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isRunning || !_backupCreated ? null : _showConfirmationDialog,
          icon: const Icon(Icons.cleaning_services),
          label: const Text(
            'بدء عملية التنظيف',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.error,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        if (_isRunning)
          ElevatedButton.icon(
            onPressed: _stopCleanup,
            icon: const Icon(Icons.stop),
            label: const Text('إيقاف العملية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
      ],
    );
  }

  Widget _buildLogCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'سجل العمليات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _stepLogs
                    .map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            log,
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() {
      _stepLogs.add('💾 بدء إنشاء النسخة الاحتياطية...');
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      // إنشاء اسم للنسخة الاحتياطية
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final backupName = 'backup-before-cleanup-$timestamp';
      
      await client.talk(['/system/backup/save', '=name=$backupName']);
      
      setState(() {
        _backupCreated = true;
        _stepLogs.add('✅ تم إنشاء النسخة الاحتياطية: $backupName');
      });

      if (mounted) {
        showSuccessSnackBar(context, 'تم إنشاء النسخة الاحتياطية بنجاح');
      }
    } catch (e) {
      setState(() {
        _stepLogs.add('❌ فشل إنشاء النسخة الاحتياطية: $e');
      });
      if (mounted) {
        showErrorSnackBar(context, 'فشل في إنشاء النسخة الاحتياطية: $e');
      }
    } finally {
      client?.close();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('تأكيد نهائي'),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من بدء عملية تنظيف قاعدة البيانات؟\n\n'
            '⚠️ هذه العملية لا يمكن التراجع عنها\n'
            '⚠️ سيتم إعادة تشغيل MikroTik\n'
            '⚠️ تأكد من وجود نسخة احتياطية\n\n'
            'اكتب "تأكيد" للمتابعة:',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startCleanup();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد البدء'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startCleanup() async {
    setState(() {
      _isRunning = true;
      _currentStep = 0;
      _stepLogs.add('🚀 بدء عملية تنظيف قاعدة البيانات...');
    });

    for (int i = 0; i < _steps.length; i++) {
      if (!_isRunning) break;

      setState(() {
        _currentStep = i;
        _stepLogs.add('⏳ تنفيذ: ${_steps[i].title}');
      });

      await _executeStep(_steps[i]);

      if (_steps[i].delay > 0) {
        setState(() {
          _stepLogs.add('⏰ انتظار ${_steps[i].delay} ثانية...');
        });
        await Future.delayed(Duration(seconds: _steps[i].delay));
      }

      setState(() {
        _stepLogs.add('✅ مكتمل: ${_steps[i].title}');
      });
    }

    // عرض إحصائيات ما بعد التنظيف
    await _loadAfterStats();

    setState(() {
      _isRunning = false;
      _currentStep = _steps.length;
      _stepLogs.add('═══════════════════════════════════════');
      _stepLogs.add('🎉 اكتملت عملية التنظيف بنجاح!');
      _stepLogs.add('📊 ملخص النتائج:');
      if (_beforeStats.isNotEmpty && _afterStats.isNotEmpty) {
        final deletedUsers = _beforeStats['users']! - _afterStats['users']!;
        final deletedSessions = _beforeStats['sessions']! - _afterStats['sessions']!;
        final deletedLogs = _beforeStats['logs']! - _afterStats['logs']!;
        _stepLogs.add('🗑️ حُذف $deletedUsers مستخدم');
        _stepLogs.add('🗑️ حُذف $deletedSessions جلسة');
        _stepLogs.add('🗑️ حُذف $deletedLogs سجل');
      }
      _stepLogs.add('═══════════════════════════════════════');
    });

    if (mounted) {
      showSuccessSnackBar(context, 'اكتملت عملية التنظيف بنجاح! 🎉');
    }
  }

  Future<void> _executeStep(CleanupStep step) async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      if (step.isReboot) {
        await client.talk([step.command]);
        setState(() {
          _stepLogs.add('🔄 تم إرسال أمر إعادة التشغيل...');
        });
        return;
      }

      final response = await client.talk([step.command]);
      
      if (step.requiresConfirmation) {
        // إرسال تأكيد للأوامر التي تحتاج تأكيد
        await client.talk(['/y']);
      }

      setState(() {
        _stepLogs.add('📝 النتيجة: ${response.length} استجابة');
      });

    } catch (e) {
      setState(() {
        _stepLogs.add('⚠️ خطأ: $e');
      });
    } finally {
      client?.close();
    }
  }

  Future<void> _loadAfterStats() async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      final usersResponse = await client.talk(['/tool/user-manager/user/print']);
      final sessionsResponse = await client.talk(['/tool/user-manager/session/print']);
      final logsResponse = await client.talk(['/tool/user-manager/log/print']);
      
      setState(() {
        _afterStats = {
          'users': usersResponse.length,
          'sessions': sessionsResponse.length,
          'logs': logsResponse.length,
        };
      });
      
    } catch (e) {
      setState(() {
        _stepLogs.add('⚠️ فشل في جلب الإحصائيات النهائية: $e');
      });
    } finally {
      client?.close();
    }
  }

  void _stopCleanup() {
    setState(() {
      _isRunning = false;
      _stepLogs.add('⏹️ تم إيقاف العملية من قبل المستخدم');
    });
  }

  Future<void> _loadDatabaseInfo() async {
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      
      // الحصول على معلومات User Manager
      final usersResponse = await client.talk(['/tool/user-manager/user/print']);
      final sessionsResponse = await client.talk(['/tool/user-manager/session/print']);
      final logsResponse = await client.talk(['/tool/user-manager/log/print']);
      
      setState(() {
        _beforeStats = {
          'users': usersResponse.length,
          'sessions': sessionsResponse.length,
          'logs': logsResponse.length,
        };
        _stepLogs.add('📊 إحصائيات قاعدة البيانات الحالية:');
        _stepLogs.add('👥 عدد المستخدمين: ${usersResponse.length}');
        _stepLogs.add('🔗 عدد الجلسات: ${sessionsResponse.length}');
        _stepLogs.add('📝 عدد السجلات: ${logsResponse.length}');
        _stepLogs.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      });
      
    } catch (e) {
      setState(() {
        _stepLogs.add('❌ فشل في جلب معلومات قاعدة البيانات: $e');
      });
    } finally {
      client?.close();
    }
  }

}

class CleanupStep {
  final String title;
  final String description;
  final String command;
  final IconData icon;
  final Color color;
  final bool requiresConfirmation;
  final int delay;
  final bool isReboot;

  CleanupStep({
    required this.title,
    required this.description,
    required this.command,
    required this.icon,
    required this.color,
    this.requiresConfirmation = false,
    this.delay = 0,
    this.isReboot = false,
  });
}