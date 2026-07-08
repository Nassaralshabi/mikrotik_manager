import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/resource_history.dart';

/// Alert severity level
enum AlertLevel {
  warning,
  critical,
}

/// A system alert
class SystemAlert {
  final String message;
  final AlertLevel level;
  final IconData icon;

  const SystemAlert({
    required this.message,
    required this.level,
    required this.icon,
  });
}

/// A card that shows system alerts when resources are under stress
class SystemAlertsCard extends StatelessWidget {
  final ResourceHistoryNotifier resourceHistory;

  const SystemAlertsCard({
    super.key,
    required this.resourceHistory,
  });

  List<SystemAlert> _generateAlerts() {
    final latest = resourceHistory.latest;
    if (latest == null) return [];

    final alerts = <SystemAlert>[];

    // CPU alerts
    if (latest.cpuLoad >= 90) {
      alerts.add(const SystemAlert(
        message: 'CPU usage critical (>90%)',
        level: AlertLevel.critical,
        icon: Icons.speed_rounded,
      ));
    } else if (latest.cpuLoad >= 75) {
      alerts.add(const SystemAlert(
        message: 'CPU usage high (>75%)',
        level: AlertLevel.warning,
        icon: Icons.speed_rounded,
      ));
    }

    // Memory alerts
    if (latest.memoryUsage >= 95) {
      alerts.add(const SystemAlert(
        message: 'Memory usage critical (>95%)',
        level: AlertLevel.critical,
        icon: Icons.memory_rounded,
      ));
    } else if (latest.memoryUsage >= 85) {
      alerts.add(const SystemAlert(
        message: 'Memory usage high (>85%)',
        level: AlertLevel.warning,
        icon: Icons.memory_rounded,
      ));
    }

    // Disk alerts
    if (latest.diskUsage >= 95) {
      alerts.add(const SystemAlert(
        message: 'Disk usage critical (>95%)',
        level: AlertLevel.critical,
        icon: Icons.storage_rounded,
      ));
    } else if (latest.diskUsage >= 85) {
      alerts.add(const SystemAlert(
        message: 'Disk usage high (>85%)',
        level: AlertLevel.warning,
        icon: Icons.storage_rounded,
      ));
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _generateAlerts();

    if (alerts.isEmpty) return const SizedBox.shrink();

    // Only show the most severe alert
    final hasCritical = alerts.any((a) => a.level == AlertLevel.critical);
    final primaryAlert = hasCritical
        ? alerts.firstWhere((a) => a.level == AlertLevel.critical)
        : alerts.first;

    final isCritical = primaryAlert.level == AlertLevel.critical;
    final color = isCritical
        ? const Color(0xFFF43F5E) // Rose
        : const Color(0xFFF59E0B); // Amber

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Could show more details or navigate to logs
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    primaryAlert.icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isCritical ? 'CRITICAL' : 'WARNING',
                              style: TextStyle(
                                color: isCritical ? Colors.white : Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'System Alert',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        primaryAlert.message,
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
