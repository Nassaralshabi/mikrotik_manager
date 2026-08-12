import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'mikrotik_connector.dart';
import 'snackbar_helpers.dart';

enum DeviceStatus { online, offline }

class Device {
  String id;
  String name;
  String ip;
  DeviceStatus status;

  Device({required this.id, required this.name, required this.ip, this.status = DeviceStatus.offline});

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'ip': ip, 'status': status.toString().split('.').last,
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'], name: json['name'], ip: json['ip'],
        status: json['status'] == 'online' ? DeviceStatus.online : DeviceStatus.offline,
      );
}

class DeviceMonitoringScreen extends StatefulWidget {
  const DeviceMonitoringScreen({super.key});

  @override
  State<DeviceMonitoringScreen> createState() => _DeviceMonitoringScreenState();
}

class _DeviceMonitoringScreenState extends State<DeviceMonitoringScreen> {
  List<Device> _allDevices = [];
  List<Device> _displayedDevices = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();
  bool _showingDisconnectedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() { _isLoading = true; });
    final prefs = await SharedPreferences.getInstance();
    final String? devicesJson = prefs.getString('monitored_devices');
    if (devicesJson != null) {
      final List<dynamic> decodedData = jsonDecode(devicesJson);
      _allDevices = decodedData.map((json) => Device.fromJson(json)).toList();
    }
    _displayedDevices = List.from(_allDevices);
    setState(() { _isLoading = false; });
  }

  Future<void> _saveDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String devicesJson = jsonEncode(_allDevices.map((device) => device.toJson()).toList());
    await prefs.setString('monitored_devices', devicesJson);
  }

  /// الإصلاح: إنشاء اتصال خاص بدلاً من استخدام client من الخارج
  Future<void> _fetchDevices() async {
    setState(() { _isLoading = true; });
    try {
      final client = await MikrotikConnector.connect();
      try {
        final neighborResponse = await client.talk(['/ip/neighbor/print']);
        Set<String> currentOnlineIps = {};

        for (var neighbor in neighborResponse) {
          final String? ip = neighbor['address'];
          final String? macAddress = neighbor['mac-address'];
          final String? identity = neighbor['identity'];

          if (ip != null) {
            currentOnlineIps.add(ip);
            bool found = false;
            for (var device in _allDevices) {
              if (device.ip == ip) { device.status = DeviceStatus.online; found = true; break; }
            }
            if (!found) {
              _allDevices.add(Device(id: _uuid.v4(), name: identity ?? macAddress ?? 'Unknown Device', ip: ip, status: DeviceStatus.online));
            }
          }
        }

        for (var device in _allDevices) {
          device.status = currentOnlineIps.contains(device.ip) ? DeviceStatus.online : DeviceStatus.offline;
        }

        await _saveDevices();
        if (mounted) showSuccessSnackBar(context, 'تم جلب الأجهزة بنجاح.');
      } finally {
        client.close();
      }
    } on MikrotikCredentialsMissingException catch (e) {
      if (mounted) showErrorSnackBar(context, 'خطأ: ${e.message}');
    } on MikrotikConnectionException catch (e) {
      if (mounted) showErrorSnackBar(context, 'خطأ في الاتصال: ${e.message}');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'فشل جلب الأجهزة. تحقق من الاتصال بالشبكة.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _displayedDevices = _showingDisconnectedOnly
              ? _allDevices.where((device) => device.status == DeviceStatus.offline).toList()
              : List.from(_allDevices);
        });
      }
    }
  }

  void _showDisconnectedDevices() {
    setState(() {
      _displayedDevices = _allDevices.where((device) => device.status == DeviceStatus.offline).toList();
      _showingDisconnectedOnly = true;
      if (_displayedDevices.isEmpty) showErrorSnackBar(context, 'لا توجد أجهزة غير متصلة حالياً.');
    });
  }

  void _showAllDevices() {
    setState(() {
      _displayedDevices = List.from(_allDevices);
      _showingDisconnectedOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقبة الأجهزة'),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _isLoading ? null : _fetchDevices, tooltip: 'جلب الأجهزة'),
          IconButton(icon: const Icon(Icons.link_off), onPressed: _isLoading ? null : _showDisconnectedDevices, tooltip: 'عرض الأجهزة غير المتصلة'),
          PopupMenuButton<String>(
            onSelected: (value) { if (value == 'all') _showAllDevices(); },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'all', child: ListTile(leading: Icon(Icons.devices), title: Text('جميع الأجهزة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displayedDevices.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.devices_other, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد أجهزة للمراقبة', style: TextStyle(fontSize: 22, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('اضغط على زر التحديث لجلب الأجهزة', style: TextStyle(color: Colors.white)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _displayedDevices.length,
                  itemBuilder: (context, index) {
                    final device = _displayedDevices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      color: device.status == DeviceStatus.online ? Colors.green.shade800.withAlpha((255 * 0.8).round()) : Colors.grey.shade700.withAlpha((255 * 0.8).round()),
                      child: ListTile(
                        leading: Icon(device.status == DeviceStatus.online ? Icons.circle : Icons.circle_outlined, color: device.status == DeviceStatus.online ? Colors.greenAccent : Colors.grey),
                        title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(device.ip, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(device.status == DeviceStatus.online ? 'متصل' : 'غير متصل', style: TextStyle(color: device.status == DeviceStatus.online ? Colors.greenAccent : Colors.grey, fontWeight: FontWeight.bold)),
                          if (device.status == DeviceStatus.offline)
                            IconButton(icon: const Icon(Icons.refresh, color: Colors.orange), onPressed: () => _checkSingleDevice(device), tooltip: 'فحص الجهاز'),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _checkSingleDevice(Device device) async {
    setState(() { _isLoading = true; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('جاري فحص ${device.name}...')));

    try {
      final client = await MikrotikConnector.connect();
      try {
        final neighborResponse = await client.talk(['/ip/neighbor/print']);
        Set<String> onlineIps = {};
        for (var neighbor in neighborResponse) {
          if (neighbor['address'] != null) onlineIps.add(neighbor['address']!);
        }
        final newStatus = onlineIps.contains(device.ip) ? DeviceStatus.online : DeviceStatus.offline;
        final deviceIndex = _allDevices.indexWhere((d) => d.id == device.id);
        if (deviceIndex != -1) _allDevices[deviceIndex].status = newStatus;

        if (mounted) {
          setState(() {
            if (_showingDisconnectedOnly) {
              _displayedDevices = _allDevices.where((d) => d.status == DeviceStatus.offline).toList();
            } else {
              _displayedDevices = List.from(_allDevices);
            }
          });
          if (newStatus == DeviceStatus.online) showSuccessSnackBar(context, 'تم فحص ${device.name}: متصل');
          else showErrorSnackBar(context, 'تم فحص ${device.name}: غير متصل');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'فشل فحص الجهاز.');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }
}
