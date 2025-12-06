import 'package:flutter/material.dart';

import '../models/backup_job.dart';
import '../models/device_info.dart';
import '../models/router_session.dart';
import '../models/service_card.dart';
import '../models/user_profile.dart';

class MockDataSource {
  List<RouterSession> getActiveSessions() {
    return const [
      RouterSession(
        username: 'ahmed.pro',
        ipAddress: '10.10.0.14',
        uptime: Duration(hours: 12, minutes: 21),
        downloadMbps: 85.3,
        uploadMbps: 12.7,
      ),
      RouterSession(
        username: 'fiber.x',
        ipAddress: '10.10.0.27',
        uptime: Duration(hours: 6, minutes: 11),
        downloadMbps: 64.8,
        uploadMbps: 9.1,
      ),
      RouterSession(
        username: 'guest-lab',
        ipAddress: '10.10.0.92',
        uptime: Duration(hours: 2, minutes: 4),
        downloadMbps: 23.6,
        uploadMbps: 4.4,
      ),
    ];
  }

  List<UserProfile> getProfiles() {
    return const [
      UserProfile(
        id: '501',
        username: 'hana_fiber',
        password: '****',
        profileName: '200 Mbps / 1 TB',
        customerName: 'Hana Fiber',
        isActive: true,
        isSuspended: false,
        downloadUsed: 0,
        uploadUsed: 0,
        activeSessions: 2,
        totalSessions: 5,
        pricePerSession: 42.0,
      ),
      UserProfile(
        id: '502',
        username: 'num_guest',
        password: '****',
        profileName: '50 Mbps / 200 GB',
        customerName: 'NUM Guest',
        isActive: false,
        isSuspended: true,
        downloadUsed: 0,
        uploadUsed: 0,
        activeSessions: 1,
        totalSessions: 3,
        pricePerSession: -12.5,
      ),
      UserProfile(
        id: '503',
        username: 'qahtani_hq',
        password: '****',
        profileName: '500 Mbps / 5 TB',
        customerName: 'Qahtani HQ',
        isActive: true,
        isSuspended: false,
        downloadUsed: 0,
        uploadUsed: 0,
        activeSessions: 4,
        totalSessions: 12,
        pricePerSession: 310.0,
      ),
    ];
  }

  List<ServiceCard> getCards() {
    return const [
      ServiceCard(id: 'P1', title: 'بطاقة 5 جيجابايت', quota: '5 GB', price: 5, status: 'متاحة'),
      ServiceCard(id: 'P2', title: 'بطاقة 50 جيجابايت', quota: '50 GB', price: 25, status: 'متاحة'),
      ServiceCard(id: 'P3', title: 'بطاقة غير محدودة 7 أيام', quota: 'غير محدود', price: 40, status: 'موقوفة'),
    ];
  }

  List<DeviceInfo> getDevices() {
    return const [
      DeviceInfo(
        id: 'SW-01',
        name: 'Core Switch',
        ip: '192.168.88.1',
        location: 'غرفة الشبكة',
        status: 'online',
        latencyMs: 1.7,
      ),
      DeviceInfo(
        id: 'AP-03',
        name: 'Lobby AP',
        ip: '192.168.88.45',
        location: 'الاستقبال',
        status: 'warning',
        latencyMs: 8.9,
      ),
      DeviceInfo(
        id: 'CPE-19',
        name: 'Customer CPE',
        ip: '10.20.5.19',
        location: 'مكتب المبيعات',
        status: 'offline',
        latencyMs: 0,
      ),
    ];
  }

  List<BackupJob> getBackups() {
    return [
      BackupJob(
        id: 'BKP-01',
        type: 'System Snapshot',
        lastRun: DateTime.now().subtract(const Duration(hours: 4)),
        sizeMb: 128.4,
        status: 'success',
      ),
      BackupJob(
        id: 'BKP-02',
        type: 'User Database',
        lastRun: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        sizeMb: 342.1,
        status: 'warning',
      ),
      BackupJob(
        id: 'BKP-03',
        type: 'Cards Archive',
        lastRun: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
        sizeMb: 98.2,
        status: 'failed',
      ),
    ];
  }

  List<double> throughputSeries() {
    return const [68, 72, 65, 80, 95, 88, 102, 97, 90, 110, 118, 125];
  }

  List<Color> loadHeat() {
    return const [
      Color(0xFF54C5F8),
      Color(0xFF3A8DFF),
      Color(0xFF004AAD),
    ];
  }
}
