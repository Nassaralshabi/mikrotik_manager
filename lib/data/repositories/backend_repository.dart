import '../models/backup_job.dart';
import '../models/device_info.dart';
import '../models/router_session.dart';
import '../models/service_card.dart';
import '../models/user_profile.dart';
import '../services/backend_service.dart';
import '../services/mock_data_source.dart';

class BackendRepository {
  BackendRepository({required this.service, required this.mock});

  final BackendService service;
  final MockDataSource mock;

  void setBaseUrl(String value) {
    service.updateBaseUrl(value);
  }

  void setMockMode(bool value) {
    service.toggleMock(value);
  }

  Future<bool> login({
    required String username,
    required String password,
    required String ip,
    required int port,
  }) async {
    if (service.useMockData) {
      await Future.delayed(const Duration(seconds: 1));
      return username.isNotEmpty && password.isNotEmpty;
    }
    return service.login(username: username, password: password, ip: ip, port: port);
  }

  Future<List<RouterSession>> activeSessions() async {
    if (service.useMockData) {
      return mock.getActiveSessions();
    }
    return service.fetchActiveSessions();
  }

  Future<List<UserProfile>> profiles() async {
    if (service.useMockData) {
      return mock.getProfiles();
    }
    return service.fetchProfiles();
  }

  Future<List<ServiceCard>> cards() async {
    if (service.useMockData) {
      return mock.getCards();
    }
    return service.fetchCards();
  }

  Future<List<DeviceInfo>> devices() async {
    if (service.useMockData) {
      return mock.getDevices();
    }
    return service.fetchDevices();
  }

  Future<List<BackupJob>> backups() async {
    if (service.useMockData) {
      return mock.getBackups();
    }
    return service.fetchBackups();
  }

  List<double> throughputSeries() {
    return mock.throughputSeries();
  }
}
