import '../models/backup_job.dart';
import '../models/device_info.dart';
import '../models/router_session.dart';
import '../models/service_card.dart';
import '../models/user_profile.dart';
import '../services/backend_service.dart';
import '../services/mock_data_source.dart';
import '../services/router_service.dart';
import 'data_mode.dart';

class BackendRepository {
  BackendRepository({
    required this.service,
    required this.mock,
    required this.router,
  });

  final BackendService service;
  final MockDataSource mock;
  final RouterService router;
  DataMode mode = DataMode.router;

  void setMode(DataMode value) {
    mode = value;
    service.toggleMock(value == DataMode.mock);
  }

  void setBaseUrl(String value) {
    service.updateBaseUrl(value);
  }

  Future<bool> login({
    required String username,
    required String password,
    required String ip,
    required int port,
    bool useSSL = false,
    bool forceV6Api = true,
  }) async {
    switch (mode) {
      case DataMode.router:
        return await router.login(
          host: ip,
          username: username,
          password: password,
          port: port,
          useSSL: useSSL,
          forceV6Api: forceV6Api,
        );
      case DataMode.backend:
        return service.login(username: username, password: password, ip: ip, port: port);
      case DataMode.mock:
        await Future.delayed(const Duration(milliseconds: 400));
        return true;
    }
  }

  Future<void> disconnect() async {
    await router.disconnect();
  }

  Future<List<RouterSession>> activeSessions() {
    switch (mode) {
      case DataMode.router:
        return router.fetchActiveSessions();
      case DataMode.backend:
        return service.fetchActiveSessions();
      case DataMode.mock:
        return Future.value(mock.getActiveSessions());
    }
  }

  Future<List<UserProfile>> profiles() {
    switch (mode) {
      case DataMode.router:
        return router.fetchProfiles();
      case DataMode.backend:
        return service.fetchProfiles();
      case DataMode.mock:
        return Future.value(mock.getProfiles());
    }
  }

  Future<List<ServiceCard>> cards() {
    switch (mode) {
      case DataMode.router:
        return router.fetchCards();
      case DataMode.backend:
        return service.fetchCards();
      case DataMode.mock:
        return Future.value(mock.getCards());
    }
  }

  Future<List<DeviceInfo>> devices() {
    switch (mode) {
      case DataMode.router:
        return router.fetchDevices();
      case DataMode.backend:
        return service.fetchDevices();
      case DataMode.mock:
        return Future.value(mock.getDevices());
    }
  }

  Future<List<BackupJob>> backups() {
    switch (mode) {
      case DataMode.router:
        return router.fetchBackups();
      case DataMode.backend:
        return service.fetchBackups();
      case DataMode.mock:
        return Future.value(mock.getBackups());
    }
  }

  List<double> throughputSeries() {
    switch (mode) {
      case DataMode.router:
        final data = router.throughputSeries();
        return data.isEmpty ? mock.throughputSeries() : data;
      default:
        return mock.throughputSeries();
    }
  }
}
