import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CommandCenterRouter {
  final String name;
  final String address;
  final int cpu;
  final int trafficMbps;
  final int onlineUsers;
  CommandCenterRouter({required this.name, required this.address, required this.cpu, required this.trafficMbps, required this.onlineUsers});
}

class CommandCenterScreen extends StatelessWidget {
  CommandCenterScreen({super.key});

  final List<CommandCenterRouter> _sampleRouters = [
    CommandCenterRouter(name: 'Router A', address: '192.168.1.1:8728', cpu: 23, trafficMbps: 120, onlineUsers: 12),
    CommandCenterRouter(name: 'Router B', address: '192.168.2.1:8728', cpu: 41, trafficMbps: 260, onlineUsers: 28),
    CommandCenterRouter(name: 'Router C', address: '192.168.3.1:8728', cpu: 15, trafficMbps: 90, onlineUsers: 7),
  ];

  @override
  Widget build(BuildContext context) {
    final routers = _sampleRouters;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Center'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: routers.length,
        itemBuilder: (context, index) {
          final r = routers[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(r.address, style: TextStyle(color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatChip(label: 'CPU', value: '${r.cpu}%', color: AppTheme.primaryColor),
                    _StatChip(label: 'Traffic', value: '${r.trafficMbps} Mbps', color: AppTheme.secondaryColor),
                    _StatChip(label: 'Online', value: '${r.onlineUsers}', color: AppTheme.successColor),
                  ],
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text('$label: $value', style: TextStyle(color: color)),
    );
  }
}
