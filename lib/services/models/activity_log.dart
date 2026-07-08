/// Activity log types
enum LogType {
  login, // User login
  logout, // User logout
  connection, // Router connection
  voucherCreated, // Voucher created
  voucherDeleted, // Voucher deleted
  voucherPrinted, // Voucher printed
  sale, // Sale made
  userAction, // General user action
  userEnabled, // User enabled
  userDisabled, // User disabled
  error, // Error occurred
  system, // System event
}

/// Activity log entry model
class ActivityLog {
  final String id;
  final LogType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? username;
  final String? routerHost;
  final Map<String, dynamic>? metadata;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.username,
    this.routerHost,
    this.metadata,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] ?? json['.id'] ?? '',
      type: LogType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LogType.userAction,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.tryParse(json['timestamp']) ?? DateTime.now())
          : DateTime.now(),
      username: json['username'],
      routerHost: json['routerHost'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (username != null) 'username': username,
      if (routerHost != null) 'routerHost': routerHost,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Get icon for log type
  static String getIcon(LogType type) {
    switch (type) {
      case LogType.login:
        return 'login';
      case LogType.logout:
        return 'logout';
      case LogType.connection:
        return 'router';
      case LogType.voucherCreated:
        return 'add_card';
      case LogType.voucherDeleted:
        return 'delete';
      case LogType.voucherPrinted:
        return 'print';
      case LogType.sale:
        return 'payments';
      case LogType.userAction:
        return 'person';
      case LogType.userEnabled:
        return 'person_add';
      case LogType.userDisabled:
        return 'person_remove';
      case LogType.error:
        return 'error';
      case LogType.system:
        return 'settings';
    }
  }

  /// Get color name for log type
  static String getColorName(LogType type) {
    switch (type) {
      case LogType.login:
        return 'green';
      case LogType.logout:
        return 'orange';
      case LogType.connection:
        return 'blue';
      case LogType.voucherCreated:
        return 'purple';
      case LogType.voucherDeleted:
        return 'red';
      case LogType.voucherPrinted:
        return 'cyan';
      case LogType.sale:
        return 'emerald';
      case LogType.userAction:
        return 'slate';
      case LogType.userEnabled:
        return 'green';
      case LogType.userDisabled:
        return 'orange';
      case LogType.error:
        return 'red';
      case LogType.system:
        return 'gray';
    }
  }

  ActivityLog copyWith({
    String? id,
    LogType? type,
    String? title,
    String? description,
    DateTime? timestamp,
    String? username,
    String? routerHost,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      username: username ?? this.username,
      routerHost: routerHost ?? this.routerHost,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Log filter options
enum LogFilter {
  all,
  login,
  logout,
  voucher,
  sale,
  error,
  system,
}

extension LogFilterExtension on LogFilter {
  String get displayName {
    switch (this) {
      case LogFilter.all:
        return 'All';
      case LogFilter.login:
        return 'Login';
      case LogFilter.logout:
        return 'Logout';
      case LogFilter.voucher:
        return 'Voucher';
      case LogFilter.sale:
        return 'Sale';
      case LogFilter.error:
        return 'Error';
      case LogFilter.system:
        return 'System';
    }
  }

  List<LogType> get types {
    switch (this) {
      case LogFilter.all:
        return LogType.values;
      case LogFilter.login:
        return [LogType.login];
      case LogFilter.logout:
        return [LogType.logout];
      case LogFilter.voucher:
        return [
          LogType.voucherCreated,
          LogType.voucherDeleted,
          LogType.voucherPrinted
        ];
      case LogFilter.sale:
        return [LogType.sale];
      case LogFilter.error:
        return [LogType.error];
      case LogFilter.system:
        return [LogType.system];
    }
  }
}
