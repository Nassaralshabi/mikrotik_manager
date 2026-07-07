// ============================================================
//  SecureCredentials — تخزين آمن لبيانات اعتماد MikroTik و MQTT
//
//  يستخدم flutter_secure_storage (مشفّر) بدل SharedPreferences (نص عادي)
//  مع fallback آمن
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// إدارة آمنة لبيانات الاعتماد
/// جميع البيانات تُخزّن مشفّرة في Keychain (iOS) / EncryptedSharedPreferences (Android)
class SecureCredentials {
  SecureCredentials._();
  static final SecureCredentials instance = SecureCredentials._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // مفاتيح التخزين
  static const _keyIp = 'mikrotik_ip';
  static const _keyUser = 'mikrotik_user';
  static const _keyPass = 'mikrotik_pass';
  static const _keyPort = 'mikrotik_port';
  static const _keySshPort = 'mikrotik_ssh_port';
  static const _keyMqttUser = 'mqtt_user';
  static const _keyMqttPass = 'mqtt_pass';
  static const _keyRememberMe = 'remember_me';

  // ============================================================
  //  MikroTik Credentials
  // ============================================================

  Future<MikrotikCreds> loadMikrotikCreds() async {
    try {
      final ip = await _storage.read(key: _keyIp) ?? '';
      final user = await _storage.read(key: _keyUser) ?? '';
      final pass = await _storage.read(key: _keyPass) ?? '';
      final portStr = await _storage.read(key: _keyPort) ?? '8728';
      final sshPortStr = await _storage.read(key: _keySshPort) ?? '22';
      return MikrotikCreds(
        ip: ip,
        user: user,
        pass: pass,
        port: int.tryParse(portStr) ?? 8728,
        sshPort: int.tryParse(sshPortStr) ?? 22,
      );
    } catch (e) {
      return MikrotikCreds.empty;
    }
  }

  Future<void> saveMikrotikCreds(MikrotikCreds creds) async {
    await Future.wait([
      _storage.write(key: _keyIp, value: creds.ip),
      _storage.write(key: _keyUser, value: creds.user),
      _storage.write(key: _keyPass, value: creds.pass),
      _storage.write(key: _keyPort, value: creds.port.toString()),
      _storage.write(key: _keySshPort, value: creds.sshPort.toString()),
    ]);
  }

  Future<void> clearMikrotikCreds() async {
    await Future.wait([
      _storage.delete(key: _keyIp),
      _storage.delete(key: _keyUser),
      _storage.delete(key: _keyPass),
      _storage.delete(key: _keyPort),
      _storage.delete(key: _keySshPort),
    ]);
  }

  // ============================================================
  //  MQTT Credentials
  // ============================================================

  Future<MqttCreds> loadMqttCreds() async {
    try {
      final user = await _storage.read(key: _keyMqttUser) ?? '';
      final pass = await _storage.read(key: _keyMqttPass) ?? '';
      return MqttCreds(user: user, pass: pass);
    } catch (e) {
      return MqttCreds.empty;
    }
  }

  Future<void> saveMqttCreds(MqttCreds creds) async {
    await Future.wait([
      _storage.write(key: _keyMqttUser, value: creds.user),
      _storage.write(key: _keyMqttPass, value: creds.pass),
    ]);
  }

  Future<void> clearMqttCreds() async {
    await Future.wait([
      _storage.delete(key: _keyMqttUser),
      _storage.delete(key: _keyMqttPass),
    ]);
  }

  // ============================================================
  //  Remember Me
  // ============================================================

  Future<bool> getRememberMe() async {
    final val = await _storage.read(key: _keyRememberMe);
    return val == 'true';
  }

  Future<void> setRememberMe(bool value) async {
    await _storage.write(key: _keyRememberMe, value: value.toString());
  }

  /// مسح كل البيانات
  Future<void> clearAll() async {
    await Future.wait([
      clearMikrotikCreds(),
      clearMqttCreds(),
      _storage.delete(key: _keyRememberMe),
    ]);
  }
}

// ============================================================
//  Data Classes
// ============================================================

class MikrotikCreds {
  final String ip;
  final String user;
  final String pass;
  final int port;
  final int sshPort;

  const MikrotikCreds({
    required this.ip,
    required this.user,
    required this.pass,
    required this.port,
    required this.sshPort,
  });

  static const empty = MikrotikCreds(ip: '', user: '', pass: '', port: 8728, sshPort: 22);
}

class MqttCreds {
  final String user;
  final String pass;

  const MqttCreds({required this.user, required this.pass});
  static const empty = MqttCreds(user: '', pass: '');
}
