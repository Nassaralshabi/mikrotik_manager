class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.password,
    required this.profileName,
    required this.customerName,
    required this.isActive,
    required this.isSuspended,
    this.createdAt,
    this.lastSeen,
    required this.downloadUsed,
    required this.uploadUsed,
    required this.activeSessions,
    required this.totalSessions,
    this.callerStation,
    this.nasPort,
    this.profileType,
    this.validity,
    this.pricePerSession,
  });

  final String id;
  final String username;
  final String password;
  final String profileName;
  final String customerName;
  final bool isActive;
  final bool isSuspended;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final double downloadUsed;
  final double uploadUsed;
  final int activeSessions;
  final int totalSessions;
  final String? callerStation;
  final String? nasPort;
  final String? profileType;
  final String? validity;
  final double? pricePerSession;

  // Getters للتوافق مع الكود القديم
  String get name => customerName.isNotEmpty ? customerName : username;
  String get plan => profileName;
  double get balance => pricePerSession ?? 0.0;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
      profileName: json['profile'] as String? ?? json['plan'] as String? ?? '',
      customerName: json['customer'] as String? ?? json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isSuspended: json['is_suspended'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastSeen: json['last_seen'] != null
          ? DateTime.tryParse(json['last_seen'] as String)
          : null,
      downloadUsed: (json['download_used'] as num?)?.toDouble() ?? 0.0,
      uploadUsed: (json['upload_used'] as num?)?.toDouble() ?? 0.0,
      activeSessions: json['active_sessions'] as int? ?? 0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      callerStation: json['caller_station'] as String?,
      nasPort: json['nas_port'] as String?,
      profileType: json['profile_type'] as String?,
      validity: json['validity'] as String?,
      pricePerSession: (json['price_per_session'] as num?)?.toDouble() ?? 
                      (json['balance'] as num?)?.toDouble(),
    );
  }

  factory UserProfile.fromMikroTikV6(Map<String, dynamic> json) {
    return UserProfile(
      id: json['.id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      profileName: json['actual-profile'] as String? ?? json['profile'] as String? ?? '',
      customerName: json['customer'] as String? ?? '',
      isActive: json['disabled'] != 'yes',
      isSuspended: json['disabled'] == 'yes',
      createdAt: _parseMikroTikDate(json['reg-time'] as String?),
      lastSeen: _parseMikroTikDate(json['last-seen'] as String?),
      downloadUsed: _parseMikroTikBytes(json['download-used'] as String? ?? '0'),
      uploadUsed: _parseMikroTikBytes(json['upload-used'] as String? ?? '0'),
      activeSessions: int.tryParse(json['active-sessions'] as String? ?? '0') ?? 0,
      totalSessions: int.tryParse(json['sessions'] as String? ?? '0') ?? 0,
      callerStation: json['caller-station-id'] as String?,
      nasPort: json['nas-port'] as String?,
      profileType: json['profile-type'] as String?,
      validity: json['validity'] as String?,
      pricePerSession: double.tryParse(json['price'] as String? ?? '0'),
    );
  }

  static DateTime? _parseMikroTikDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      if (dateStr.contains('/')) {
        final months = {
          'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
          'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
          'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12'
        };
        
        final parts = dateStr.split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts.length > 1 ? parts[1] : '00:00:00';
          
          final dateComponents = datePart.split('/');
          if (dateComponents.length == 3) {
            final monthStr = dateComponents[0].toLowerCase();
            final day = dateComponents[1];
            final year = dateComponents[2];
            
            if (months.containsKey(monthStr)) {
              final month = months[monthStr]!;
              final isoDate = '$year-$month-$day $timePart';
              return DateTime.tryParse(isoDate);
            }
          }
        }
      }
      
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  static double _parseMikroTikBytes(String bytes) {
    try {
      if (bytes.isEmpty || bytes == '0') return 0.0;
      final cleanBytes = bytes.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanBytes) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'profile': profileName,
      'customer': customerName,
      'is_active': isActive,
      'is_suspended': isSuspended,
      'created_at': createdAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'download_used': downloadUsed,
      'upload_used': uploadUsed,
      'active_sessions': activeSessions,
      'total_sessions': totalSessions,
      'caller_station': callerStation,
      'nas_port': nasPort,
      'profile_type': profileType,
      'validity': validity,
      'price_per_session': pricePerSession,
    };
  }

  String get formattedDataUsage {
    final totalMB = (downloadUsed + uploadUsed) / 1024 / 1024;
    if (totalMB > 1024) {
      return '${(totalMB / 1024).toStringAsFixed(2)} GB';
    } else {
      return '${totalMB.toStringAsFixed(2)} MB';
    }
  }

  String get statusDisplay {
    if (isSuspended) return 'موقوف';
    if (!isActive) return 'غير نشط';
    if (activeSessions > 0) return 'متصل الآن';
    return 'نشط';
  }

  String get statusColor {
    if (isSuspended) return 'red';
    if (!isActive) return 'orange';
    if (activeSessions > 0) return 'green';
    return 'blue';
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? password,
    String? profileName,
    String? customerName,
    bool? isActive,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? lastSeen,
    double? downloadUsed,
    double? uploadUsed,
    int? activeSessions,
    int? totalSessions,
    String? callerStation,
    String? nasPort,
    String? profileType,
    String? validity,
    double? pricePerSession,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      profileName: profileName ?? this.profileName,
      customerName: customerName ?? this.customerName,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      downloadUsed: downloadUsed ?? this.downloadUsed,
      uploadUsed: uploadUsed ?? this.uploadUsed,
      activeSessions: activeSessions ?? this.activeSessions,
      totalSessions: totalSessions ?? this.totalSessions,
      callerStation: callerStation ?? this.callerStation,
      nasPort: nasPort ?? this.nasPort,
      profileType: profileType ?? this.profileType,
      validity: validity ?? this.validity,
      pricePerSession: pricePerSession ?? this.pricePerSession,
    );
  }
}
