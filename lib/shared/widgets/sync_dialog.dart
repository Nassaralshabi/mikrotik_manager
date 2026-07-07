// ============================================================
//  SyncDialog — نافذة مزامنة الكروت من MikroTik إلى قاعدة البيانات
//
//  تعرض التقدم (0% → 100%) مع حالة كل خطوة
//  تعرض النتيجة النهائية (X كرت، Y ملف شخصي، Z جلسة)
// ============================================================

import 'package:flutter/material.dart';
import '../../database/sync_service.dart';

/// يعرض نافذة المزامنة مع progress
Future<SyncResult?> showSyncDialog(BuildContext context) {
  return showDialog<SyncResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _SyncDialogContent(),
  );
}

class _SyncDialogContent extends StatefulWidget {
  const _SyncDialogContent();

  @override
  State<_SyncDialogContent> createState() => _SyncDialogContentState();
}

class _SyncDialogContentState extends State<_SyncDialogContent> {
  double _progress = 0.0;
  String _status = 'جارٍ التجهيز...';
  bool _isComplete = false;
  SyncResult? _result;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      final result = await SyncService.instance.syncAll(
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _status = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isComplete = true;
          _hasError = !result.success;
          if (result.success) {
            _status = result.summary;
          } else {
            _status = result.error ?? 'فشلت المزامنة';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isComplete = true;
          _hasError = true;
          _status = 'حدث خطأ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          _isComplete
              ? Icon(
                  _hasError ? Icons.error_outline : Icons.check_circle,
                  color: _hasError ? Colors.red : Colors.green,
                  size: 28,
                )
              : const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
          const SizedBox(width: 12),
          Text(
            _isComplete
                ? (_hasError ? 'فشلت المزامنة' : 'اكتملت المزامنة')
                : 'مزامنة الكروت...',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar
            if (!_isComplete) ...[
              LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
            ],

            // Status text
            Text(
              _status,
              style: TextStyle(
                fontSize: 14,
                color: _hasError ? Colors.redAccent : Colors.white70,
              ),
            ),
            const SizedBox(height: 8),

            // Result details
            if (_result != null && _result!.success) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              _buildStatRow('الكروت', _result!.cardsSynced.toString(), Icons.person),
              _buildStatRow('الملفات الشخصية', _result!.profilesSynced.toString(), Icons.folder),
              _buildStatRow('الجلسات النشطة', _result!.sessionsSynced.toString(), Icons.wifi),
              _buildStatRow('الوقت', _formatDuration(_result!.durationMs), Icons.timer),
            ],
          ],
        ),
      ),
      actions: [
        if (_isComplete)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_result),
            child: const Text('تم'),
          ),
        if (!_isComplete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white54)),
          ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              )),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
}
