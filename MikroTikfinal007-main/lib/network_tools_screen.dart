import 'package:flutter/material.dart';
import 'network_map_screen.dart';
import 'device_monitoring_screen.dart';

class NetworkToolsScreen extends StatelessWidget {
  const NetworkToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات الشبكة'),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.map_outlined, size: 28),
              label: const Text('خريطة الشبكة'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NetworkMapScreen()));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.devices_other, size: 28),
              label: const Text('مراقبة الأجهزة'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DeviceMonitoringScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
