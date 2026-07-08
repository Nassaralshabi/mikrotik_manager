// ============================================================
//  MQTT Riverpod Provider — بديل ChangeNotifierProvider القديم
//
//  استخدام:
//    final mqtt = context.read(mqttServiceProvider);
//    mqtt.configure(username, password);
//    mqtt.publish(message);
//
//  للـ Stream:
//    final messages = context.watch(mqttMessagesProvider);
//    messages.whenData((msg) => ...);
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../mqtt_service.dart';
import 'package:flutter/material.dart';

/// مزوّد لمفتاح ScaffoldMessenger (يُضبط من main.dart)
final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>((ref) {
  throw UnimplementedError('يجب تعيين scaffoldMessengerKeyProvider في main.dart');
});

/// Provider للـ MqttService نفسه
/// يبقى حياً طوال عمر التطبيق (ليس autoDispose)
final mqttServiceProvider = Provider<MqttService>((ref) {
  // نحاول الحصول على scaffoldMessengerKey (قد لا يكون متاحاً)
  GlobalKey<ScaffoldMessengerState>? key;
  try {
    key = ref.read(scaffoldMessengerKeyProvider);
  } catch (_) {
    key = null;
  }
  final mqtt = MqttService(scaffoldMessengerKey: key);
  ref.onDispose(() {
    mqtt.dispose();
  });
  return mqtt;
});

/// StreamProvider لرسائل MQTT
final mqttMessagesProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  return mqtt.messages;
});

/// Provider للإرسال
final mqttPublishProvider = Provider<void Function(Map<String, dynamic>)>((ref) {
  final mqtt = ref.watch(mqttServiceProvider);
  return (message) => mqtt.publish(message);
});
