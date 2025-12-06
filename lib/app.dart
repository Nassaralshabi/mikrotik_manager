import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/backend_repository.dart';
import 'data/services/backend_service.dart';
import 'data/services/mock_data_source.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/session_controller.dart';
import 'features/shell/home_shell.dart';

class NUMApp extends StatelessWidget {
  const NUMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BackendRepository>(
          create: (_) => BackendRepository(
            service: BackendService(baseUrl: 'http://127.0.0.1', useMockData: true),
            mock: MockDataSource(),
          ),
        ),
        ChangeNotifierProvider<SessionController>(
          create: (context) => SessionController(context.read<BackendRepository>()),
        ),
      ],
      child: Consumer<SessionController>(
        builder: (context, session, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'NUM Router Manager',
            theme: AppTheme.lightTheme,
            home: session.status == SessionStatus.authenticated
                ? const HomeShell()
                : const LoginScreen(),
          );
        },
      ),
    );
  }
}
