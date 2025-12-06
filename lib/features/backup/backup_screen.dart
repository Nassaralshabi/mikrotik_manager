import 'package:flutter/material.dart';

import '../../data/models/backup_job.dart';
import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key, required this.repository});

  final BackendRepository repository;

  Color _chipColor(String status) {
    switch (status) {
      case 'failed':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<List<BackupJob>>(
        future: repository.backups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingStateView();
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final jobs = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'سجل النسخ الاحتياطية',
                action: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('تشغيل الآن'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final color = _chipColor(job.status);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.backup, color: color, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.type, style: Theme.of(context).textTheme.titleMedium),
                                  Text('آخر تشغيل: ${_format(job.lastRun)}'),
                                  Text('الحجم: ${job.sizeMb.toStringAsFixed(1)} MB'),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(job.status),
                              backgroundColor: color.withOpacity(.12),
                              labelStyle: TextStyle(color: color),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _format(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
