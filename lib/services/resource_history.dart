import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';

/// Data point for tracking resource usage over time
class ResourceDataPoint {
  final DateTime timestamp;
  final double cpuLoad;
  final double memoryUsage;
  final double diskUsage;

  ResourceDataPoint({
    required this.timestamp,
    required this.cpuLoad,
    required this.memoryUsage,
    required this.diskUsage,
  });

  factory ResourceDataPoint.fromResources(SystemResources resources) {
    final memoryUsage = resources.totalMemory > 0
        ? ((resources.totalMemory - resources.freeMemory) / resources.totalMemory * 100)
        : 0.0;
    final diskUsage = resources.totalHddSpace > 0
        ? ((resources.totalHddSpace - resources.freeHddSpace) / resources.totalHddSpace * 100)
        : 0.0;

    return ResourceDataPoint(
      timestamp: DateTime.now(),
      cpuLoad: resources.cpuLoad.toDouble(),
      memoryUsage: memoryUsage,
      diskUsage: diskUsage,
    );
  }

  ResourceDataPoint copyWith({
    DateTime? timestamp,
    double? cpuLoad,
    double? memoryUsage,
    double? diskUsage,
  }) {
    return ResourceDataPoint(
      timestamp: timestamp ?? this.timestamp,
      cpuLoad: cpuLoad ?? this.cpuLoad,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      diskUsage: diskUsage ?? this.diskUsage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'cpuLoad': cpuLoad,
      'memoryUsage': memoryUsage,
      'diskUsage': diskUsage,
    };
  }

  factory ResourceDataPoint.fromJson(Map<String, dynamic> json) {
    return ResourceDataPoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      cpuLoad: (json['cpuLoad'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      diskUsage: (json['diskUsage'] as num).toDouble(),
    );
  }
}

/// Manages the history of resource usage data
class ResourceHistory {
  final List<ResourceDataPoint> _dataPoints = [];
  static const int _maxDataPoints = 60; // Keep last 60 data points (3 minutes at 3s intervals)

  List<ResourceDataPoint> get dataPoints => List.unmodifiable(_dataPoints);

  void addDataPoint(ResourceDataPoint dataPoint) {
    _dataPoints.add(dataPoint);
    if (_dataPoints.length > _maxDataPoints) {
      _dataPoints.removeAt(0);
    }
  }

  void addFromResources(SystemResources resources) {
    addDataPoint(ResourceDataPoint.fromResources(resources));
  }

  void clear() {
    _dataPoints.clear();
  }

  /// Get CPU data points for chart
  List<ResourceDataPoint> getCpuData() => _dataPoints;

  /// Get Memory data points for chart
  List<ResourceDataPoint> getMemoryData() => _dataPoints;

  /// Get Disk data points for chart
  List<ResourceDataPoint> getDiskData() => _dataPoints;

  /// Get the latest data point
  ResourceDataPoint? get latest => _dataPoints.isNotEmpty ? _dataPoints.last : null;

  /// Get the average CPU load over the history
  double get averageCpuLoad {
    if (_dataPoints.isEmpty) return 0.0;
    final sum = _dataPoints.fold<double>(0, (prev, point) => prev + point.cpuLoad);
    return sum / _dataPoints.length;
  }

  /// Get the average Memory usage over the history
  double get averageMemoryUsage {
    if (_dataPoints.isEmpty) return 0.0;
    final sum = _dataPoints.fold<double>(0, (prev, point) => prev + point.memoryUsage);
    return sum / _dataPoints.length;
  }

  /// Get the average Disk usage over the history
  double get averageDiskUsage {
    if (_dataPoints.isEmpty) return 0.0;
    final sum = _dataPoints.fold<double>(0, (prev, point) => prev + point.diskUsage);
    return sum / _dataPoints.length;
  }
}

/// Notifier for resource history state
class ResourceHistoryNotifier extends TimerNotifier {
  final ResourceHistory _history = ResourceHistory();

  ResourceHistory get history => _history;

  List<ResourceDataPoint> get cpuData => _history.getCpuData();
  List<ResourceDataPoint> get memoryData => _history.getMemoryData();
  List<ResourceDataPoint> get diskData => _history.getDiskData();

  ResourceDataPoint? get latest => _history.latest;

  double get averageCpuLoad => _history.averageCpuLoad;
  double get averageMemoryUsage => _history.averageMemoryUsage;
  double get averageDiskUsage => _history.averageDiskUsage;

  void addDataPoint(ResourceDataPoint dataPoint) {
    _history.addDataPoint(dataPoint);
    notifyListeners();
  }

  void addFromResources(SystemResources resources) {
    _history.addFromResources(resources);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }
}

/// Base timer notifier for auto-refresh functionality
class TimerNotifier extends ChangeNotifier {
  Timer? _timer;

  void startPeriodicRefresh(Duration interval, VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      callback();
    });
  }

  void stopPeriodicRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
