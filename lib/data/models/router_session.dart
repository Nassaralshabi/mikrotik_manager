class RouterSession {
  const RouterSession({
    required this.username,
    required this.ipAddress,
    required this.uptime,
    required this.downloadMbps,
    required this.uploadMbps,
    this.sessionId,
    this.profileName,
    this.customerName,
    this.callerStation,
    this.nasPort,
    this.downloadBytes,
    this.uploadBytes,
    this.isActive,
  });

  final String username;
  final String ipAddress;
  final Duration uptime;
  final double downloadMbps;
  final double uploadMbps;
  final String? sessionId;
  final String? profileName;
  final String? customerName;
  final String? callerStation;
  final String? nasPort;
  final int? downloadBytes;
  final int? uploadBytes;
  final bool? isActive;

  /// تحويل من JSON عادي
  factory RouterSession.fromJson(Map<String, dynamic> json) {
    return RouterSession(
      username: json['username'] as String? ?? '',
      ipAddress: json['ip'] as String? ?? '',
      uptime: Duration(seconds: json['uptime_seconds'] as int? ?? 0),
      downloadMbps: (json['download_mbps'] as num?)?.toDouble() ?? 0.0,
      uploadMbps: (json['upload_mbps'] as num?)?.toDouble() ?? 0.0,
      sessionId: json['session_id'] as String?,
      profileName: json['profile'] as String?,
      customerName: json['customer'] as String?,
      callerStation: json['caller_station'] as String?,
      nasPort: json['nas_port'] as String?,
      downloadBytes: json['download_bytes'] as int?,
      uploadBytes: json['upload_bytes'] as int?,
      isActive: json['is_active'] as bool?,
    );
  }

  /// تحويل من MikroTik RouterOS v6
  factory RouterSession.fromMikroTikV6(Map<String, dynamic> json) {
    return RouterSession(
      username: json['user'] as String? ?? json['username'] as String? ?? '',
      ipAddress: json['caller-id'] as String? ?? json['nas-ip'] as String? ?? '',
      uptime: _parseMikroTikDuration(json['uptime'] as String? ?? '0'),
      downloadMbps: _parseMikroTikBytes(json['download-used'] as String? ?? '0') / 1000000,
      uploadMbps: _parseMikroTikBytes(json['upload-used'] as String? ?? '0') / 1000000,
      sessionId: json['.id'] as String?,
      profileName: json['actual-profile'] as String?,
      customerName: json['customer'] as String?,
      callerStation: json['caller-station-id'] as String?,
      nasPort: json['nas-port'] as String?,
      downloadBytes: _parseMikroTikBytes(json['download-used'] as String? ?? '0').toInt(),
      uploadBytes: _parseMikroTikBytes(json['upload-used'] as String? ?? '0').toInt(),
      isActive: (json['active-sessions'] as String? ?? '0') != '0',
    );
  }

  /// تحويل من MikroTik RouterOS v7+
  factory RouterSession.fromMikroTikV7(Map<String, dynamic> json) {
    return RouterSession(
      username: json['username'] as String? ?? '',
      ipAddress: json['caller-id'] as String? ?? '',
      uptime: _parseMikroTikDuration(json['uptime'] as String? ?? '0'),
      downloadMbps: (json['download-rate'] as num?)?.toDouble() ?? 0.0,
      uploadMbps: (json['upload-rate'] as num?)?.toDouble() ?? 0.0,
      sessionId: json['.id'] as String?,
      profileName: json['profile'] as String?,
      customerName: json['customer'] as String?,
      downloadBytes: (json['download-bytes'] as num?)?.toInt(),
      uploadBytes: (json['upload-bytes'] as num?)?.toInt(),
      isActive: json['active'] as bool? ?? false,
    );
  }

  /// تحويل مدة من تنسيق MikroTik
  static Duration _parseMikroTikDuration(String duration) {
    try {
      // تنسيق MikroTik: \"1d2h3m4s\" أو ثواني مباشرة
      if (duration.contains('d') || duration.contains('h') || duration.contains('m') || duration.contains('s')) {
        int totalSeconds = 0;
        
        // أيام
        final daysMatch = RegExp(r'(\\d+)d').firstMatch(duration);
        if (daysMatch != null) {
          totalSeconds += int.parse(daysMatch.group(1)!) * 86400;
        }
        
        // ساعات
        final hoursMatch = RegExp(r'(\\d+)h').firstMatch(duration);
        if (hoursMatch != null) {
          totalSeconds += int.parse(hoursMatch.group(1)!) * 3600;
        }
        
        // دقائق
        final minutesMatch = RegExp(r'(\\d+)m').firstMatch(duration);
        if (minutesMatch != null) {
          totalSeconds += int.parse(minutesMatch.group(1)!) * 60;
        }
        
        // ثواني
        final secondsMatch = RegExp(r'(\\d+)s').firstMatch(duration);
        if (secondsMatch != null) {
          totalSeconds += int.parse(secondsMatch.group(1)!);
        }
        
        return Duration(seconds: totalSeconds);
      } else {
        // رقم مباشر بالثواني
        return Duration(seconds: int.tryParse(duration) ?? 0);
      }
    } catch (e) {
      return Duration.zero;
    }
  }

  /// تحويل حجم البيانات من تنسيق MikroTik
  static double _parseMikroTikBytes(String bytes) {
    try {
      if (bytes.isEmpty || bytes == '0') return 0.0;
      
      // إزالة الأحرف غير الرقمية من النهاية
      final cleanBytes = bytes.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleanBytes) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'ip': ipAddress,
      'uptime_seconds': uptime.inSeconds,
      'download_mbps': downloadMbps,
      'upload_mbps': uploadMbps,
      'session_id': sessionId,
      'profile': profileName,
      'customer': customerName,
      'caller_station': callerStation,
      'nas_port': nasPort,
      'download_bytes': downloadBytes,
      'upload_bytes': uploadBytes,
      'is_active': isActive,
    };
  }

  /// تنسيق المدة للعرض
  String get formattedUptime {
    final hours = uptime.inHours;
    final minutes = uptime.inMinutes.remainder(60);
    final seconds = uptime.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}س ${minutes}د';
    } else if (minutes > 0) {
      return '${minutes}د ${seconds}ث';
    } else {
      return '${seconds}ث';
    }
  }

  /// تنسيق استخدام البيانات
  String get formattedDataUsage {
    if (downloadBytes != null && uploadBytes != null) {
      final totalMB = (downloadBytes! + uploadBytes!) / 1024 / 1024;
      if (totalMB > 1024) {
        return '${(totalMB / 1024).toStringAsFixed(2)} GB';
      } else {
        return '${totalMB.toStringAsFixed(2)} MB';
      }
    }
    return 'غير متاح';
  }

  /// معدل النقل الإجمالي
  double get totalThroughputMbps => downloadMbps + uploadMbps;
}"