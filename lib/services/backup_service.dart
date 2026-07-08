// ============================================================
//  BackupService — نظام النسخ الاحتياطي لراوتر MikroTik
//
//  يستخدم RouterOSClient الذي يحوي توابع جاهزة:
//   - createBackup(name)
//   - exportConfig(name)
//   - downloadFile(name)
//   - getFiles()
//   - deleteFile(id)
// ============================================================

import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'routeros_api_client.dart';

// ============================================================
//  نموذج النسخة الاحتياطية
// ============================================================

class BackupEntry {
  final String name;
  final int size;
  final String createdAt;
  final bool isLocal;

  BackupEntry({
    required this.name,
    required this.size,
    required this.createdAt,
    this.isLocal = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'size': size,
        'createdAt': createdAt,
        'isLocal': isLocal,
      };

  factory BackupEntry.fromMap(Map<dynamic, dynamic> map) => BackupEntry(
        name: map['name'] as String,
        size: map['size'] as int? ?? 0,
        createdAt: map['createdAt'] as String? ?? '',
        isLocal: map['isLocal'] as bool? ?? false,
      );

  String get sizeStr {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

// ============================================================
//  Service
// ============================================================

class BackupService {
  static const _boxName = 'backups';
  Box? _box;

  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  /// الـ client الحالي للاتصال بـ MikroTik
  RouterOSClient? _client;
  RouterOSClient? get client => _client;
  set client(RouterOSClient? c) => _client = c;

  // ─── Create backup on router ───

  Future<BackupEntry> createBackup({String? name}) async {
    final backupName = name ?? 'backup_${DateTime.now().millisecondsSinceEpoch}';
    if (_client == null) throw BackupException('غير متصل بالراوتر');

    try {
      await _client!.createBackup(backupName);
      await Future.delayed(const Duration(seconds: 2));

      // Fetch files to find the backup
      final files = await _client!.getFiles();
      final file = files.firstWhere(
        (f) => f['name']?.toString() == '$backupName.backup',
        orElse: () => <String, dynamic>{},
      );

      int size = int.tryParse(file['size']?.toString() ?? '0') ?? 0;
      String createdAt = file['creation-time']?.toString() ??
          DateTime.now().toIso8601String();

      return BackupEntry(
        name: '$backupName.backup',
        size: size,
        createdAt: createdAt,
        isLocal: false,
      );
    } catch (e) {
      throw BackupException('فشل إنشاء النسخة الاحتياطية: $e');
    }
  }

  // ─── List backups on router ───

  Future<List<BackupEntry>> listRouterBackups() async {
    if (_client == null) throw BackupException('غير متصل بالراوتر');
    try {
      final files = await _client!.getFiles();
      return files
          .where((r) => (r['name']?.toString() ?? '').endsWith('.backup'))
          .map((r) => BackupEntry(
                name: r['name']?.toString() ?? '',
                size: int.tryParse(r['size']?.toString() ?? '0') ?? 0,
                createdAt: r['creation-time']?.toString() ?? '',
                isLocal: false,
              ))
          .toList();
    } catch (e) {
      throw BackupException('فشل جلب النسخ: $e');
    }
  }

  // ─── Download backup content ───

  Future<String> downloadBackup(String backupName) async {
    if (_client == null) throw BackupException('غير متصل بالراوتر');
    try {
      final content = await _client!.downloadFile(backupName);
      // Save to local file
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/$backupName';
      final file = File(localPath);
      await file.writeAsString(content);

      // Save info to Hive
      final entry = BackupEntry(
        name: backupName,
        size: file.lengthSync(),
        createdAt: DateTime.now().toIso8601String(),
        isLocal: true,
      );
      await saveLocalBackupInfo(entry);

      return localPath;
    } catch (e) {
      throw BackupException('فشل تنزيل النسخة: $e');
    }
  }

  // ─── Restore backup on router ───

  Future<void> restoreBackup(String backupName) async {
    if (_client == null) throw BackupException('غير متصل بالراوتر');
    try {
      // RouterOS backup load command
      await _client!.createBackup('restore_${DateTime.now().millisecondsSinceEpoch}');
      // Note: actual restore requires /system/backup/load which is interactive
      // For now, we save the backup name and let user restore via Winbox
      throw BackupException(
          'استعادة النسخة تتطلب Winbox/WebFig. استخدم المسار: /system/backup/load name=$backupName');
    } catch (e) {
      throw BackupException('فشل استعادة النسخة: $e');
    }
  }

  // ─── Delete backup from router ───

  Future<void> deleteRouterBackup(String backupName) async {
    if (_client == null) throw BackupException('غير متصل بالراوتر');
    try {
      // Find the file id first
      final files = await _client!.getFiles();
      final file = files.firstWhere(
        (f) => f['name']?.toString() == backupName,
        orElse: () => <String, dynamic>{},
      );
      final id = file['.id']?.toString();
      if (id != null) {
        await _client!.deleteFile(id);
      }
    } catch (e) {
      throw BackupException('فشل حذف النسخة: $e');
    }
  }

  // ─── Local backup management ───

  Future<List<BackupEntry>> listLocalBackups() async {
    final box = await _getBox();
    final entries = <BackupEntry>[];
    for (final key in box.keys) {
      final map = box.get(key) as Map?;
      if (map != null) {
        entries.add(BackupEntry.fromMap(map));
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> deleteLocalBackup(String name) async {
    final box = await _getBox();
    await box.delete(name);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  Future<void> saveLocalBackupInfo(BackupEntry entry) async {
    final box = await _getBox();
    await box.put(entry.name, entry.toMap());
  }

  // ─── Export config (text-based) ───

  Future<String> exportConfig({bool compact = false}) async {
    if (_client == null) throw BackupException('غير متصل بالراوتر');
    try {
      final name = 'export_${DateTime.now().millisecondsSinceEpoch}.rsc';
      await _client!.exportConfig(name);
      final content = await _client!.downloadFile(name);
      return content;
    } catch (e) {
      throw BackupException('فشل تصدير الإعدادات: $e');
    }
  }
}

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}
