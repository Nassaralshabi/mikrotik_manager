import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'theme/app_theme.dart';
import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';

class BackupSystemScreen extends StatefulWidget {
  const BackupSystemScreen({super.key});

  @override
  State<BackupSystemScreen> createState() => _BackupSystemScreenState();
}

class _BackupSystemScreenState extends State<BackupSystemScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();
      final response = await client.talk(['/file/print']);
      
      if (mounted) {
        setState(() {
          _backups = response
              .where((file) {
                final type = file['type']?.toString() ?? '';
                return type == 'backup' || type == 'user manager database';
              })
              .map((file) => Map<String, dynamic>.from(file))
              .toList();
          
          _backups.sort((a, b) {
            final timeA = a['creation-time']?.toString() ?? '';
            final timeB = b['creation-time']?.toString() ?? '';
            return timeB.compareTo(timeA);
          });
        });
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشل تحميل النسخ الاحتياطية.');
      }
    } finally {
      client?.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createNewBackup() async {
    final backupName = await _showBackupNameDialog();
    if (backupName == null || backupName.isEmpty) return;

    setState(() => _isCreatingBackup = true);

    final snackBar = ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('جاري إنشاء النسخة الاحتياطية...'),
          ],
        ),
        duration: Duration(minutes: 5),
      ),
    );

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      await client.talk([
        '/system/backup/save',
        '=name=$backupName',
        '=dont-encrypt=yes',
      ]);

      await Future.delayed(const Duration(seconds: 3));

      await _loadBackups();

      snackBar.close();
      if (mounted) {
        showSuccessSnackBar(context, 'تم إنشاء النسخة الاحتياطية بنجاح');
      }
    } catch (e) {
      snackBar.close();
      if (mounted) {
        showErrorSnackBar(context, 'فشل إنشاء النسخة.');
      }
    } finally {
      client?.close();
      if (mounted) setState(() => _isCreatingBackup = false);
    }
  }

  Future<String?> _showBackupNameDialog() async {
    final TextEditingController controller = TextEditingController(
      text: 'backup_${DateTime.now().day}-${DateTime.now().month}_${DateTime.now().hour}-${DateTime.now().minute}',
    );

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اسم النسخة الاحتياطية'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'الاسم',
            hintText: 'backup_01-11_10-30',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  void _showBackupOptions(Map<String, dynamic> backup) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('معلومات النسخة'),
              onTap: () {
                Navigator.pop(context);
                _showBackupInfo(backup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('استعادة النسخة'),
              onTap: () {
                Navigator.pop(context);
                _restoreBackup(backup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف النسخة'),
              onTap: () {
                Navigator.pop(context);
                _deleteBackup(backup);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showBackupInfo(Map<String, dynamic> backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات النسخة الاحتياطية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('الاسم', backup['name'] ?? 'غير معروف'),
            const SizedBox(height: 8),
            _buildInfoRow('النوع', backup['type'] ?? 'غير معروف'),
            const SizedBox(height: 8),
            _buildInfoRow('الحجم', '${backup['size'] ?? '0'} بايت'),
            const SizedBox(height: 8),
            _buildInfoRow('تاريخ الإنشاء', backup['creation-time'] ?? 'غير معروف'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('تحذير'),
          ],
        ),
        content: const Text(
          'استعادة النسخة الاحتياطية سيعيد تشغيل الراوتر ويستبدل الإعدادات الحالية. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('استعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      await client.talk([
        '/system/backup/load',
        '=name=${backup['name']}',
      ]);

      if (mounted) {
        showSuccessSnackBar(context, 'تم بدء عملية الاستعادة. سيعيد الراوتر التشغيل الآن...');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشلت عملية الاستعادة.');
      }
    } finally {
      client?.close();
    }
  }

  Future<void> _deleteBackup(Map<String, dynamic> backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النسخة'),
        content: Text('هل تريد حذف "${backup['name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      await client.talk([
        '/file/remove',
        '=numbers=${backup['name']}',
      ]);

      await _loadBackups();

      if (mounted) {
        showSuccessSnackBar(context, 'تم حذف النسخة الاحتياطية');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'فشل حذف النسخة الاحتياطية.');
      }
    } finally {
      client?.close();
    }
  }

  String _calculateTimeAgo(String creationTime) {
    try {
      final parts = creationTime.split(' ');
      if (parts.length != 2) return creationTime;

      final dateParts = parts[0].split('/');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return creationTime;

      final months = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      final month = months[dateParts[0].toLowerCase()] ?? 1;
      final day = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = int.parse(timeParts[2]);

      final backupTime = DateTime(year, month, day, hour, minute, second);
      final now = DateTime.now();
      final difference = now.difference(backupTime);

      if (difference.inSeconds < 60) {
        return 'منذ ${difference.inSeconds} ثانية';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return 'منذ ${difference.inDays} يوم';
      }
    } catch (e) {
      return creationTime;
    }
  }

  Widget _buildBackupCard(Map<String, dynamic> backup) {
    final name = backup['name'] ?? '';
    final size = backup['size'] ?? '0';
    final creationTime = backup['creation-time'] ?? '';
    final type = backup['type'] ?? '';

    final isUserManager = type == 'user manager database';
    final backupType = isUserManager ? 'يوزر متجر' : 'ويوكس';
    final typeColor = isUserManager ? Colors.green : Colors.purple;

    final timeAgo = _calculateTimeAgo(creationTime);

    final sizeKB = (int.tryParse(size) ?? 0) / 1024;
    final sizeText = sizeKB >= 1024
        ? '${(sizeKB / 1024).toStringAsFixed(2)} م.ب'
        : '${sizeKB.toStringAsFixed(2)} ك.ب';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBackupOptions(backup),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUserManager ? Icons.group : Icons.router,
                      color: Colors.white,
                      size: 28,
                    ),
                    Text(
                      backupType,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.theme.appColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.data_usage,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.theme.appColors.secondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sizeText,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                onPressed: () => _showBackupOptions(backup),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(theme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('جاري تحميل النسخ الاحتياطية...'),
          ],
        ),
      );
    }

    if (_backups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.backup, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'لا توجد نسخ احتياطية',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط على الزر أدناه لإنشاء نسخة جديدة',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBackups,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _backups.length,
        itemBuilder: (context, index) {
          final backup = _backups[index];
          return _buildBackupCard(backup);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام النسخ الاحتياطي الكامل'),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isCreatingBackup
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _createNewBackup,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء نسخة جديدة'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }
}
