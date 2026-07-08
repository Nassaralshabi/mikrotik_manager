import 'package:hive_flutter/hive_flutter.dart';
import 'models/activity_log.dart';

/// Service for managing activity logs with Hive persistence
class LogService {
  static const String _boxName = 'activity_logs';
  static Box<Map>? _box;

  /// Initialize the log service
  static Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// Get the box instance
  static Box<Map> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('LogService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Add a new log entry
  static Future<void> addLog({
    required LogType type,
    required String title,
    required String description,
    String? username,
    String? routerHost,
    Map<String, dynamic>? metadata,
  }) async {
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      username: username,
      routerHost: routerHost,
      metadata: metadata,
    );

    await box.add(log.toJson());
  }

  /// Get all logs
  static List<ActivityLog> getLogs() {
    final logs = <ActivityLog>[];
    for (var i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      if (data != null) {
        logs.add(ActivityLog.fromJson(Map<String, dynamic>.from(data as Map)));
      }
    }
    // Sort by timestamp (newest first)
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// Get logs filtered by type
  static List<ActivityLog> getLogsByType(List<LogType> types) {
    return getLogs().where((log) => types.contains(log.type)).toList();
  }

  /// Get logs filtered by date range
  static List<ActivityLog> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return getLogs().where((log) {
      return log.timestamp.isAfter(startDate) &&
          log.timestamp.isBefore(endOfDay);
    }).toList();
  }

  /// Search logs by query
  static List<ActivityLog> searchLogs(String query) {
    if (query.isEmpty) return getLogs();

    final lowerQuery = query.toLowerCase();
    return getLogs().where((log) {
      return log.title.toLowerCase().contains(lowerQuery) ||
          log.description.toLowerCase().contains(lowerQuery) ||
          (log.username?.toLowerCase().contains(lowerQuery) ?? false) ||
          (log.routerHost?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get recent logs (last N entries)
  static List<ActivityLog> getRecentLogs(int count) {
    final allLogs = getLogs();
    return allLogs.take(count).toList();
  }

  /// Get log count
  static int getLogCount() {
    return box.length;
  }

  /// Clear all logs
  static Future<void> clearAll() async {
    await box.clear();
  }

  /// Clear logs older than specified days
  static Future<void> clearOlderThan(int days) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final logs = getLogs();

    for (var i = logs.length - 1; i >= 0; i--) {
      if (logs[i].timestamp.isBefore(cutoffDate)) {
        // Find and delete from box
        for (var j = 0; j < box.length; j++) {
          final data = box.getAt(j);
          if (data != null) {
            final log = ActivityLog.fromJson(Map<String, dynamic>.from(data as Map));
            if (log.id == logs[i].id) {
              await box.deleteAt(j);
              break;
            }
          }
        }
      }
    }
  }

  /// Export logs as CSV string
  static String exportToCsv() {
    final logs = getLogs();
    final buffer = StringBuffer();
    buffer.writeln('ID,Type,Title,Description,Timestamp,Username,Router Host');

    for (final log in logs) {
      final timestamp = log.timestamp.toIso8601String();
      buffer.writeln(
          '${log.id},${log.type.name},"${log.title}","${log.description}",$timestamp,${log.username ?? ''},${log.routerHost ?? ''}');
    }

    return buffer.toString();
  }

  // Convenience methods for common log types

  /// Log user login
  static Future<void> logLogin(String username, String routerHost) async {
    await addLog(
      type: LogType.login,
      title: 'User Login',
      description: '$username logged in to $routerHost',
      username: username,
      routerHost: routerHost,
    );
  }

  /// Log user logout
  static Future<void> logLogout(String username) async {
    await addLog(
      type: LogType.logout,
      title: 'User Logout',
      description: '$username logged out',
      username: username,
    );
  }

  /// Log user enabled
  static Future<void> logUserEnabled(String username) async {
    await addLog(
      type: LogType.userEnabled,
      title: 'User Enabled',
      description: '$username has been enabled',
      username: username,
    );
  }

  /// Log user disabled
  static Future<void> logUserDisabled(String username) async {
    await addLog(
      type: LogType.userDisabled,
      title: 'User Disabled',
      description: '$username has been disabled',
      username: username,
    );
  }

  /// Log router connection
  static Future<void> logConnection(String routerHost, bool success) async {
    await addLog(
      type: LogType.connection,
      title: success ? 'Router Connected' : 'Connection Failed',
      description: success
          ? 'Successfully connected to $routerHost'
          : 'Failed to connect to $routerHost',
      routerHost: routerHost,
    );
  }

  /// Log voucher creation
  static Future<void> logVoucherCreated(
    String profile,
    int quantity,
    String? username,
  ) async {
    await addLog(
      type: LogType.voucherCreated,
      title: 'Vouchers Created',
      description: 'Created $quantity voucher(s) for profile $profile',
      username: username,
      metadata: {'profile': profile, 'quantity': quantity},
    );
  }

  /// Log voucher deletion
  static Future<void> logVoucherDeleted(
    String voucherId,
    String? username,
  ) async {
    await addLog(
      type: LogType.voucherDeleted,
      title: 'Voucher Deleted',
      description: 'Deleted voucher $voucherId',
      username: username,
      metadata: {'voucherId': voucherId},
    );
  }

  /// Log voucher print
  static Future<void> logVoucherPrinted(
    int quantity,
    String? username,
  ) async {
    await addLog(
      type: LogType.voucherPrinted,
      title: 'Vouchers Printed',
      description: 'Printed $quantity voucher(s)',
      username: username,
      metadata: {'quantity': quantity},
    );
  }

  /// Log sale
  static Future<void> logSale(
    String profile,
    double amount,
    String? username,
  ) async {
    await addLog(
      type: LogType.sale,
      title: 'Sale Completed',
      description: 'Sold $profile voucher for Rp ${amount.toStringAsFixed(0)}',
      username: username,
      metadata: {'profile': profile, 'amount': amount},
    );
  }

  /// Log error
  static Future<void> logError(String title, String description) async {
    await addLog(
      type: LogType.error,
      title: title,
      description: description,
    );
  }

  /// Log system event
  static Future<void> logSystem(String title, String description) async {
    await addLog(
      type: LogType.system,
      title: title,
      description: description,
    );
  }
}
