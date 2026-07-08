import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/models.dart';
import '../theme/app_theme.dart';

final currentConnectionProvider = StateProvider<RouterConnection?>((ref) => null);

class RouterSwitcher extends ConsumerStatefulWidget {
  const RouterSwitcher({super.key});

  @override
  ConsumerState<RouterSwitcher> createState() => _RouterSwitcherState();
}

class _RouterSwitcherState extends ConsumerState<RouterSwitcher> {
  @override
  void initState() {
    super.initState();
    _loadCurrentConnection();
  }

  Future<void> _loadCurrentConnection() async {
    final connections = await ref.read(routerOSServiceProvider).loadSavedConnections();
    final currentId = ref.read(routerOSServiceProvider).currentConnectionId;
    
    if (currentId != null && connections.isNotEmpty) {
      final current = connections.firstWhere(
        (c) => c['id'] == currentId,
        orElse: () => connections.first,
      );
      ref.read(currentConnectionProvider.notifier).state = RouterConnection.fromJson(current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedConnectionsAsync = ref.watch(savedConnectionsProvider);
    final currentConnection = ref.watch(currentConnectionProvider);
    final service = ref.watch(routerOSServiceProvider);

    return savedConnectionsAsync.when(
      data: (connections) {
        if (connections.isEmpty) {
          return const SizedBox.shrink();
        }

        return PopupMenuButton<RouterConnection>(
          tooltip: 'Switch Router',
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: context.appSurface,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.appPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.router_rounded,
                      size: 16,
                      color: context.appPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentConnection?.name ?? 'Router',
                      style: TextStyle(
                        color: context.appPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: context.appPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          onSelected: (connection) => _switchToConnection(connection),
          itemBuilder: (context) => [
            PopupMenuItem<RouterConnection>(
              enabled: false,
              height: 40,
              child: Text(
                'Switch Router',
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const PopupMenuDivider(),
            ...connections.map((connection) {
              final isSelected = currentConnection?.id == connection.id;
              final isConnected = service.currentConnectionId == connection.id && service.isConnected;

              return PopupMenuItem<RouterConnection>(
                value: connection,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? Colors.green
                            : context.appOnSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connection.name,
                            style: TextStyle(
                              color: isSelected
                                  ? context.appPrimary
                                  : context.appOnSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          Text(
                            '${connection.host}:${connection.port}',
                            style: TextStyle(
                              color: context.appOnSurface.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 18,
                        color: context.appPrimary,
                      ),
                  ],
                ),
              );
            }),
            const PopupMenuDivider(),
            PopupMenuItem<RouterConnection>(
              enabled: false,
              height: 36,
              child: Row(
                children: [
                  Icon(
                    Icons.settings_rounded,
                    size: 16,
                    color: context.appOnSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Manage Connections',
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _showManageConnectionsDialog(context);
                });
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _switchToConnection(RouterConnection connection) async {
    if (connection.id == ref.read(routerOSServiceProvider).currentConnectionId) {
      return;
    }

    try {
      final service = ref.read(routerOSServiceProvider);
      final connections = await service.getConnectionsWithPasswords();
      final connData = connections.firstWhere(
        (c) => c['id'] == connection.id,
        orElse: () => throw Exception('Connection not found'),
      );

      await service.switchConnection(connData);
      ref.read(currentConnectionProvider.notifier).state = connection;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${connection.name}'),
            backgroundColor: context.appSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch: $e'),
            backgroundColor: context.appError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showManageConnectionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ManageConnectionsDialog(),
    );
  }
}

class _ManageConnectionsDialog extends ConsumerWidget {
  const _ManageConnectionsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedConnectionsAsync = ref.watch(savedConnectionsProvider);

    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Row(
        children: [
          Icon(Icons.router_rounded, color: context.appPrimary),
          const SizedBox(width: 12),
          Text(
            'Router Connections',
            style: TextStyle(color: context.appOnSurface),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: savedConnectionsAsync.when(
          data: (connections) {
            if (connections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.router_outlined,
                      size: 48,
                      color: context.appOnSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved connections',
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: connections.length,
              itemBuilder: (context, index) {
                final connection = connections[index];
                final isActive = ref.read(routerOSServiceProvider).currentConnectionId == connection.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? context.appPrimary.withValues(alpha: 0.1)
                        : context.appCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? context.appPrimary.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.router_rounded,
                        color: context.appPrimary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      connection.name,
                      style: TextStyle(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${connection.host}:${connection.port}',
                          style: TextStyle(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        if (isActive)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (connection.useRest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'REST',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: context.appError,
                            size: 20,
                          ),
                          onPressed: () => _deleteConnection(context, ref, connection.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: $e',
              style: TextStyle(color: context.appError),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Close',
            style: TextStyle(color: context.appOnSurface),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteConnection(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Delete Connection?',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'This will remove the saved connection. You can add it again later.',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.appError),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(savedConnectionsProvider.notifier).deleteConnection(id);
    }
  }
}