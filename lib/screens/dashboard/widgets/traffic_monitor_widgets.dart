import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../services/models.dart';
import '../../../l10n/translations.dart';

class TrafficMonitorCard extends ConsumerStatefulWidget {
  const TrafficMonitorCard({super.key});

  @override
  ConsumerState<TrafficMonitorCard> createState() => _TrafficMonitorCardState();
}

class _TrafficMonitorCardState extends ConsumerState<TrafficMonitorCard> {
  Timer? _refreshTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        ref.read(interfaceTrafficProvider.notifier).silentRefresh();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trafficAsync = ref.watch(interfaceTrafficProvider);

    return trafficAsync.when(
      data: (interfaces) {
        if (interfaces.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayInterfaces =
            _isExpanded ? interfaces : interfaces.take(4).toList();

        return Card(
          color: context.appSurface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: interfaces.length > 4
                ? () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.appPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.swap_vert_rounded,
                            color: context.appPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(AppStrings.of(context).networkTraffic,
                          style: TextStyle(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.7),
                              fontSize: 14)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(AppStrings.of(context).live,
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (interfaces.length > 4) ...[
                        const SizedBox(width: 8),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: context.appOnSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...displayInterfaces
                      .map((iface) => _buildInterfaceRow(iface)),
                  if (interfaces.length > 4 && !_isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                          AppStrings.of(context)
                              .moreInterfaces
                              .replaceAll('%d', '${interfaces.length - 4}'),
                          style: TextStyle(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.5),
                              fontSize: 11)),
                    ),
                  if (_isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(AppStrings.of(context).tapToCollapse,
                          style: TextStyle(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.4),
                              fontSize: 10)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildInterfaceRow(InterfaceTraffic iface) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            iface.running ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: iface.running ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              iface.name,
              style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _buildTrafficIndicator('↓', iface.rxRateDisplay, Colors.green),
          const SizedBox(width: 8),
          _buildTrafficIndicator('↑', iface.txRateDisplay, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildTrafficIndicator(String symbol, String rate, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(symbol,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(rate,
            style: TextStyle(
                color: context.appOnSurface,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
