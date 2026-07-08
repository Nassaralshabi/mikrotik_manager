import 'dart:async';
import 'models.dart';

/// History data for rate calculation
class _InterfaceRateData {
  final int txBytes;
  final int rxBytes;
  final DateTime timestamp;

  _InterfaceRateData({
    required this.txBytes,
    required this.rxBytes,
    required this.timestamp,
  });
}

/// Traffic rate calculator - computes real-time rates from cumulative byte counts
class TrafficRateService {
  final Map<String, _InterfaceRateData> _rateData = {};
  Timer? _updateTimer;
  static const _updateInterval = Duration(seconds: 3);

  /// Calculate rates from current traffic data
  List<InterfaceTraffic> calculateRates(List<InterfaceTraffic> currentData) {
    final now = DateTime.now();

    return currentData.map((interface) {
      final key = interface.name;

      // Get previous data if available
      final previous = _rateData[key];

      int? txRate;
      int? rxRate;

      if (previous != null &&
          interface.txBytes != null &&
          interface.rxBytes != null) {
        // Calculate time difference in seconds
        final timeDiff =
            now.difference(previous.timestamp).inSeconds.toDouble();

        if (timeDiff > 0) {
          // Calculate bytes per second
          final txDiff = (interface.txBytes! - previous.txBytes)
              .clamp(0, double.infinity)
              .toInt();
          final rxDiff = (interface.rxBytes! - previous.rxBytes)
              .clamp(0, double.infinity)
              .toInt();

          txRate = (txDiff / timeDiff).round();
          rxRate = (rxDiff / timeDiff).round();
        }
      }

      // Store current data for next calculation
      _rateData[key] = _InterfaceRateData(
        txBytes: interface.txBytes ?? 0,
        rxBytes: interface.rxBytes ?? 0,
        timestamp: now,
      );

      // Return updated interface with calculated rates
      return InterfaceTraffic(
        name: interface.name,
        type: interface.type,
        txBytes: interface.txBytes,
        rxBytes: interface.rxBytes,
        txBytesPerSecond: txRate,
        rxBytesPerSecond: rxRate,
        mtu: interface.mtu,
        running: interface.running,
        enabled: interface.enabled,
      );
    }).toList();
  }

  /// Start periodic updates (optional, for auto-refresh)
  void startPeriodicUpdate(Function() onUpdate) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (_) {
      onUpdate();
    });
  }

  /// Stop periodic updates
  void stopPeriodicUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Clear stored history
  void clearHistory() {
    _rateData.clear();
  }

  /// Remove history for specific interface
  void removeInterface(String interfaceName) {
    _rateData.remove(interfaceName);
  }
}
