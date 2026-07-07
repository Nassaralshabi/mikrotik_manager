// ============================================================
//  MQTT Riverpod Provider — بديل ChangeNotifierProvider القديم
//
//  المزايا:
//  - StreamProvider + autoDispose (ينظف نفسه عند عدم الحاجة)
//  - يمكن استخدام select() لعزل إعادة البناء
//  - type-safe
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mqtt_service.dart';

/// State لإدارة اتصال MQTT
class MqttConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? error;

  const MqttConnectionState({
    required this.isConnected,
    required this.isConnecting,
    this.error,
  });

  MqttConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    bool clearError = false,
  }) =>
      MqttConnectionState(
        isConnected: isConnected ?? this.isConnected,
        isConnecting: isConnecting ?? this.isConnecting,
        error: clearError ? null : (error ?? this.error),
      );

  static const initial = MqttConnectionState(
    isConnected: false,
    isConnecting: false,
  );
}

/// Provider للـ MqttService نفسه (ليس الـ stream)
final mqttServiceProvider = Provider<MqttService>((ref) {
  final mqtt = MqttService();
  ref.onDispose(() {
    mqtt.dispose();
  });
  return mqtt;
});

/// Provider لحالة الاتصال
final mqttConnectionProvider = StateNotifierProvider<MqttConnectionNotifier, MqttConnectionState>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  return MqttConnectionNotifier(mqtt);
});

class MqttConnectionNotifier extends StateNotifier<MqttConnectionState> {
  final MqttService _mqtt;

  MqttConnectionNotifier(this._mqtt) : super(MqttConnectionState.initial);

  void configure(String username, String password) {
    state = state.copyWith(isConnecting: true, clearError: true);
    try {
      _mqtt.configure(username, password);
      state = state.copyWith(isConnected: true, isConnecting: false);
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: e.toString(),
      );
    }
  }

  void disconnect() {
    _mqtt.dispose();
    state = MqttConnectionState.initial;
  }
}

/// StreamProvider لرسائل MQTT — هذا هو جوهر التحويل
/// يستخدم autoDispose لتنظيف الاشتراك عند إغلاق الشاشة
final mqttMessagesProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  final stream = mqtt.messages;

  ref.onDispose(() {
    // الـ Stream سيتوقف تلقائياً عند انتهاء الـ Provider
  });

  return stream;
});

/// Provider للإرسال — يستخدم ref.read (لا يُعيد بناء)
final mqttPublishProvider = Provider<Future<void> Function(Map<String, dynamic>)>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  return (message) async {
    mqtt.publish(message);
  };
});
