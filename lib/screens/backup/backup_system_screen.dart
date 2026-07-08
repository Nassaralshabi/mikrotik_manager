// ============================================================
//  BackupSystemScreen — نظام النسخ الاحتياطي للراوتر
//
//  المزايا:
//   - إنشاء نسخة احتياطية على الراوتر
//   - عرض قائمة النسخ الموجودة على الراوتر
//   - تنزيل نسخة من الراوتر للتخزين المحلي
//   - استعادة نسخة احتياطية
//   - حذف نسخة
//   - تصدير الإعدادات (export config)
// ============================================================

import 'package:flutter/material.dart';
import '../../services/backup_service.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/translations.dart';

class BackupSystemScreen extends StatefulWidget {
  const BackupSystemScreen({super.key});

  @override
  State<BackupSystemScreen> createState() => _BackupSystemScreenState();
}

class _BackupSystemScreenState extends State<BackupSystemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = BackupService();

  List<BackupEntry> _routerBackups = [];
  List<BackupEntry> _localBackups = [];
  bool _isLoadingRouter = false;
  bool _isLoadingLocal = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged();
      }
    });
    _loadRouterBackups();
    _loadLocalBackups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && _routerBackups.isEmpty) {
      _loadRouterBackups();
    } else if (_tabController.index == 1 && _localBackups.isEmpty) {
      _loadLocalBackups();
    }
  }

  Future<void> _loadRouterBackups() async {
    setState(() {
      _isLoadingRouter = true;
      _error = null;
    });
    try {
      final backups = await _service.listRouterBackups();
      if (mounted) {
        setState(() {
          _routerBackups = backups;
          _isLoadingRouter = false;
        });
      }
    } on BackupException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoadingRouter = false;
        });
      }
    }
  }

  Future<void> _loadLocalBackups() async {
    setState(() => _isLoadingLocal = true);
    try {
      final backups = await _service.listLocalBackups();
      if (mounted) {
        setState(() {
          _localBackups = backups;
          _isLoadingLocal = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocal = false);
    }
  }

  Future<void> _createBackup() async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s.createBackup),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: context.s.backupName,
            hintText: 'backup_2026-07-08',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.label),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(context.s.createBackup),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري إنشاء النسخة الاحتياطية...'),
            ],
          ),
        ),
      );
    }

    try {
      await _service.createBackup(name: name);
      if (mounted) Navigator.pop(context); // dismiss loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.backupCreatedSuccessfully)),
        );
      }
      await _loadRouterBackups();
    } on BackupException catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadBackup(BackupEntry entry) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري التنزيل...'),
            ],
          ),
        ),
      );
    }

    try {
      await _service.downloadBackup(entry.name);
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم التنزيل بنجاح')),
        );
      }
      await _loadLocalBackups();
    } on BackupException catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreBackup(BackupEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s.restoreBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.s.restoreFromThisBackup),
            const SizedBox(height: 8),
            Text('"${entry.name}"',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.s.thisWillOverwriteCurrentRouterConfiguration,
                      style:
                          TextStyle(color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.s.restoreBackup),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري الاستعادة...'),
            ],
          ),
        ),
      );
    }

    try {
      await _service.restoreBackup(entry.name);
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.backupRestoredSuccessfully)),
        );
      }
    } on BackupException catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteBackup(BackupEntry entry, bool isLocal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s.deleteBackup),
        content: Text('${context.s.deleteBackup}? "${entry.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      if (isLocal) {
        await _service.deleteLocalBackup(entry.name);
        await _loadLocalBackups();
      } else {
        await _service.deleteRouterBackup(entry.name);
        await _loadRouterBackups();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.s.backupDeletedSuccessfully)),
        );
      }
    } on BackupException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportConfig() async {
    final compact = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصدير الإعدادات'),
        content: const Text('اختر صيغة التصدير:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('كامل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('مضغوط'),
          ),
        ],
      ),
    );

    if (compact == null) return;

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري التصدير...'),
            ],
          ),
        ),
      );
    }

    try {
      final config = await _service.exportConfig(compact: compact);
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('الإعدادات المُصدّرة'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: SelectableText(
                  config,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.s.close),
              ),
            ],
          ),
        );
      }
    } on BackupException catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.backupSystem),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportConfig,
            tooltip: 'تصدير الإعدادات',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadRouterBackups();
              } else {
                _loadLocalBackups();
              }
            },
            tooltip: s.refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'الراوتر', icon: const Icon(Icons.router)),
            Tab(text: 'محلي', icon: const Icon(Icons.phone_android)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRouterTab(),
          _buildLocalTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBackup,
        icon: const Icon(Icons.add),
        label: Text(s.createBackup),
      ),
    );
  }

  Widget _buildRouterTab() {
    if (_isLoadingRouter) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadRouterBackups,
              child: Text(context.s.retry),
            ),
          ],
        ),
      );
    }
    if (_routerBackups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.backup, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(context.s.noBackupsFound,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _routerBackups.length,
      itemBuilder: (context, i) => _buildBackupCard(_routerBackups[i], false),
    );
  }

  Widget _buildLocalTab() {
    if (_isLoadingLocal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_localBackups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(context.s.noBackupsFound,
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(
              'نزّل نسخة من تبويب الراوتر',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _localBackups.length,
      itemBuilder: (context, i) => _buildBackupCard(_localBackups[i], true),
    );
  }

  Widget _buildBackupCard(BackupEntry entry, bool isLocal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLocal ? Colors.green : Colors.blue,
          child: Icon(
            isLocal ? Icons.phone_android : Icons.router,
            color: Colors.white,
          ),
        ),
        title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.storage, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(entry.sizeStr, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    entry.createdAt,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'download':
                _downloadBackup(entry);
                break;
              case 'restore':
                _restoreBackup(entry);
                break;
              case 'delete':
                _deleteBackup(entry, isLocal);
                break;
            }
          },
          itemBuilder: (_) => [
            if (!isLocal)
              PopupMenuItem(
                value: 'download',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(context.s.downloadBackup),
                  dense: true,
                ),
              ),
            PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: Text(context.s.restoreBackup),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(context.s.delete,
                    style: const TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
