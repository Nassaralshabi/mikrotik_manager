import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/command_center_provider.dart';
import '../../theme/app_theme.dart';

class CommandCenterMinimalScreen extends ConsumerWidget {
  const CommandCenterMinimalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commandCenterProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        title: Text(
          'Command Center',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: state.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.appPrimary,
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: context.appOnSurface),
            onPressed: state.isLoading
                ? null
                : () => ref.read(commandCenterProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(context, state),
          Expanded(
            child: _buildBody(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, CommandCenterState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassmorphismDecoration(
        surfaceColor: context.appSurface,
        onSurfaceColor: context.appOnSurface,
        borderRadius: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, Icons.router_rounded, 'Routers',
              '${state.onlineRouters}/${state.totalRouters}', context.appPrimary),
          _buildStatItem(
              context,
              Icons.people_rounded,
              'Online',
              '${state.totalOnlineUsers}',
              const Color(0xFF10B981)),
          _buildStatItem(
              context,
              Icons.memory_rounded,
              'Avg CPU',
              state.isLoading
                  ? '...'
                  : '${state.avgCpuLoad.round()}%',
              state.avgCpuLoad > 80
                  ? const Color(0xFFEF4444)
                  : state.avgCpuLoad > 50
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, CommandCenterState state) {
    if (state.isLoading && state.routers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.appPrimary),
            const SizedBox(height: 16),
            Text(
              'Loading router stats...',
              style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    if (state.routers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.router_rounded,
                size: 64, color: context.appOnSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'No routers configured',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a router in Settings to see stats here',
              style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.4), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(commandCenterProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.routers.length,
        itemBuilder: (context, index) {
          final router = state.routers[index];
          return _buildRouterCard(context, router);
        },
      ),
    );
  }

  Widget _buildRouterCard(BuildContext context, RouterStats router) {
    final cpuColor = router.cpuLoad == null
        ? context.appOnSurface.withValues(alpha: 0.4)
        : router.cpuLoad! > 80
            ? const Color(0xFFEF4444)
            : router.cpuLoad! > 50
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassmorphismDecoration(
        surfaceColor: context.appSurface,
        onSurfaceColor: context.appOnSurface,
        borderRadius: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: router.isConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        router.routerName,
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        router.address,
                        style: TextStyle(
                          color: context.appOnSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  router.isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: router.isConnected
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (router.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${router.errorMessage}',
                style: TextStyle(
                  color: context.appError.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChip(
                    context,
                    Icons.memory_rounded,
                    'CPU',
                    router.cpuLoad != null ? '${router.cpuLoad}%' : 'N/A',
                    cpuColor),
                _buildChip(
                    context,
                    Icons.upload_rounded,
                    'TX',
                    router.trafficTxMbps != null
                        ? '${router.trafficTxMbps} Mbps'
                        : 'N/A',
                    const Color(0xFF8B5CF6)),
                _buildChip(
                    context,
                    Icons.download_rounded,
                    'RX',
                    router.trafficRxMbps != null
                        ? '${router.trafficRxMbps} Mbps'
                        : 'N/A',
                    const Color(0xFF06B6D4)),
                _buildChip(
                    context,
                    Icons.people_rounded,
                    'Online',
                    router.onlineUsers?.toString() ?? 'N/A',
                    const Color(0xFF10B981)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}