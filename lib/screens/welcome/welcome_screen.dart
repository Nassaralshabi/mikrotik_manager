import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/network_scanner.dart';
import '../../services/onboarding_service.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../widgets/scanning_dialog.dart';
import '../../theme/app_theme.dart';
import '../../l10n/translations.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingService.showWhatsNewIfNeeded(context);
    });
  }

  Future<void> _navigateAfterLogin() async {
    final setupDone = await OnboardingService.isSetupCompleted();
    if (mounted) {
      if (setupDone) {
        context.go('/main/dashboard');
      } else {
        context.go('/setup');
      }
    }
  }

  Future<void> _scanNetwork() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ScanningDialog(),
    );
    try {
      final results = await NetworkScanner.scanForRouters();
      if (!mounted) return;
      Navigator.of(context).pop();
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).noRoutersFound)),
        );
        return;
      }
      _showRouterListDialog(results);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppStrings.of(context).scanFailed.replaceAll('%s', '$e'))),
        );
      }
    }
  }

  void _showRouterListDialog(List<NetworkScannerResult> results) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Row(
          children: [
            Icon(Icons.wifi_tethering_rounded, size: 22,
                color: context.appPrimary),
            const SizedBox(width: 8),
            Text(
              AppStrings.of(context).foundRouters.replaceAll(
                  '%d', results.length.toString()),
              style: TextStyle(
                  color: context.appOnSurface, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (_, i) {
              final r = results[i];
              return ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.router_rounded,
                      color: context.appPrimary, size: 22),
                ),
                title: Text(r.ip,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Port ${r.port}${r.isRestApi ? ' (REST)' : ' (API)'}'),
                trailing: Icon(Icons.add_rounded,
                    color: context.appPrimary),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleScannedRouter(r);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.of(context).close,
                style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }

  void _handleScannedRouter(NetworkScannerResult r) {
    context.push('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appPrimary,
      body: SafeArea(
        child: Column(
          children: [
              // Fixed header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.router_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "\u03A9MMON",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.of(context).onboardingSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable bottom section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: _buildSavedConnectionsSection(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: _buildQuickConnectSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickConnectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.appSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add_rounded,
                color: context.appSuccess,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.of(context).connectNewRouter,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.appOnSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: context.appPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login_rounded, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.of(context).enterDetails,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _scanNetwork,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                  color: context.appSuccess.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_find_rounded,
                    size: 18, color: context.appSuccess),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.of(context).findRouter,
                      style: TextStyle(
                          color: context.appSuccess,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, _) {
            final service = ref.watch(routerOSServiceProvider);
            if (!service.isConnected) {
              return const SizedBox.shrink();
            }
            return Center(
              child: TextButton(
                onPressed: () => context.go('/main/dashboard'),
                child: Text(
                  AppStrings.of(context).enterApp,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSavedConnectionsSection() {
    final connectionsAsync = ref.watch(savedConnectionsProvider);

    return connectionsAsync.when(
      data: (connections) {
        if (connections.isEmpty) {
          return _buildEmptyConnections();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flash_on_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppStrings.of(context).myRouters,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appOnSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${connections.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.appOnSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connections.length,
              itemBuilder: (context, index) {
                return _buildConnectionTile(connections[index]);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyConnections(),
    );
  }

  Widget _buildEmptyConnections() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.appCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.appOnSurface.withValues(alpha: 0.08),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_tethering_off_rounded,
              size: 48,
              color: context.appOnSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.of(context).noRoutersSaved,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.appOnSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.of(context).tapToConnectFirstRouter,
              style: TextStyle(
                fontSize: 12,
                color: context.appOnSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(RouterConnection connection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showQuickLoginDialog(connection),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.appPrimary,
                              context.appPrimary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            connection.name.isNotEmpty
                                ? connection.name[0].toUpperCase()
                                : 'R',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                connection.name,
                                style: TextStyle(
                                  color: context.appOnSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.dns_rounded,
                                    size: 12,
                                    color: context.appOnSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${connection.host}:${connection.port}',
                                    style: TextStyle(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.person_rounded,
                                    size: 12,
                                    color: context.appOnSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    connection.username,
                                    style: TextStyle(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.appPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          size: 20,
                          color: context.appPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _confirmDeleteConnection(connection),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Container(
                width: 48,
                height: 72,
                decoration: BoxDecoration(
                  color: context.appError.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: context.appError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConnection(RouterConnection connection) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          AppStrings.of(context).deleteConnectionTitle,
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          AppStrings.of(context).removeConnection(connection.name),
          style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.of(context).cancel,
                style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(savedConnectionsProvider.notifier)
                  .deleteConnection(connection.id);
              Navigator.pop(dialogContext);
            },
            child: Text(
              AppStrings.of(context).delete,
              style: TextStyle(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickLoginDialog(RouterConnection connection) {
    showDialog(
      context: context,
      builder: (dialogContext) => _QuickLoginDialog(
        connection: connection,
        onConnect: (password) => _handleQuickLogin(connection, password),
      ),
    );
  }

  Future<void> _handleQuickLogin(
      RouterConnection connection, String password) async {
    try {
      await ref.read(authStateProvider.notifier).login(
            host: connection.host,
            port: connection.port,
            username: connection.username,
            password: password,
            rememberMe: false,
            useRest: false,
          );
      if (mounted) {
        _navigateAfterLogin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppStrings.of(context).connectionFailed}: $e'),
            backgroundColor: context.appError,
          ),
        );
      }
    }
  }
}

class _QuickLoginDialog extends StatefulWidget {
  final RouterConnection connection;
  final Function(String password) onConnect;

  const _QuickLoginDialog({
    required this.connection,
    required this.onConnect,
  });

  @override
  State<_QuickLoginDialog> createState() => _QuickLoginDialogState();
}

class _QuickLoginDialogState extends State<_QuickLoginDialog> {
  late final TextEditingController _passwordController;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Text(
        '${AppStrings.of(context).connect} ${widget.connection.name}',
        style: TextStyle(
          color: context.appOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoRow(Icons.dns_rounded,
              '${widget.connection.host}:${widget.connection.port}'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person_rounded, widget.connection.username),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppStrings.of(context).password,
              prefixIcon: const Icon(Icons.lock_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.appPrimary),
              ),
            ),
            autofocus: true,
            onSubmitted: _isConnecting
                ? null
                : (value) {
                    setState(() => _isConnecting = true);
                    Navigator.pop(context);
                    widget.onConnect(value);
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isConnecting
              ? null
              : () => Navigator.pop(context),
          child: Text(AppStrings.of(context).cancel,
              style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.6))),
        ),
        ElevatedButton(
          onPressed: _isConnecting
              ? null
              : () {
                  setState(() => _isConnecting = true);
                  Navigator.pop(context);
                  widget.onConnect(_passwordController.text);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appPrimary,
            foregroundColor: Colors.white,
          ),
          child: _isConnecting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppStrings.of(context).connect),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16,
            color: context.appOnSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.6),
                fontSize: 14)),
      ],
    );
  }
}
