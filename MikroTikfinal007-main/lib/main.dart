import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mqtt_service.dart';
import 'app_theme.dart';
import 'login_screen.dart';
import 'snackbar_helpers.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MqttService(),
      child: const MyApp(),
    ),
  );
}

// مفتاح عالمي لـ ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'MikroTik Manager',
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
