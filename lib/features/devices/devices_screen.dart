import 'package:flutter/material.dart';

import '../../data/models/device_info.dart';
import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key, required this.repository});

  final BackendRepository repository;

  Color _statusColor(String status) {
    switch (status) {
      case 'offline':
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
      child: FutureBuilder<List<DeviceInfo>>(
        future: repository.devices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingStateView();
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final devices = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'الأجهزة الميدانية (${devices.length})',
                action: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final statusColor = _statusColor(device.status);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: statusColor.withOpacity(.15), child: Icon(Icons.router, color: statusColor)),
                        title: Text(device.name),
                        subtitle: Text('${device.ip} · ${device.location}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${device.latencyMs.toStringAsFixed(1)} ms'),
                            Chip(
                              label: Text(device.status),
                              backgroundColor: statusColor.withOpacity(.15),
                              labelStyle: TextStyle(color: statusColor),
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
}
