import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/backend_repository.dart';
import '../auth/session_controller.dart';
import '../backup/backup_screen.dart';
import '../cards/cards_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../devices/devices_screen.dart';
import '../reports/reports_screen.dart';
import '../users/users_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final repository = context.read<BackendRepository>();
    final screens = [
      DashboardScreen(repository: repository),
      UsersScreen(repository: repository),
      CardsScreen(repository: repository),
      DevicesScreen(repository: repository),
      ReportsScreen(repository: repository),
      BackupScreen(repository: repository),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('NUM Operations · ${session.connectionLabel}'),
        actions: [
          IconButton(
            onPressed: () => context.read<SessionController>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: IndexedStack(
          key: ValueKey(_index),
          index: _index,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_customize_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'المشتركين'),
          NavigationDestination(icon: Icon(Icons.credit_card), label: 'البطاقات'),
          NavigationDestination(icon: Icon(Icons.router_outlined), label: 'الأجهزة'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'التقارير'),
          NavigationDestination(icon: Icon(Icons.backup_outlined), label: 'النسخ'),
        ],
      ),
    );
  }
}
