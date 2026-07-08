import 'package:flutter/foundation.dart';

// Export activity log model
export 'models/activity_log.dart';

class InterfaceTraffic {
  final String name;
  final String type; // ether, bridge, wireless, etc.
  final int? txBytes; // Total transmitted bytes
  final int? rxBytes; // Total received bytes
  final int? txBytesPerSecond; // Current tx rate
  final int? rxBytesPerSecond; // Current rx rate
  final String? mtu;
  final bool running;
  final bool? enabled;

  InterfaceTraffic({
    required this.name,
    required this.type,
    this.txBytes,
    this.rxBytes,
    this.txBytesPerSecond,
    this.rxBytesPerSecond,
    this.mtu,
    required this.running,
    this.enabled,
  });

  factory InterfaceTraffic.fromJson(Map<String, dynamic> json) {
    return InterfaceTraffic(
      name: json['name'] ?? 'unknown',
      type: json['type'] ?? 'unknown',
      txBytes: json['tx-byte'] != null
          ? int.tryParse(json['tx-byte'].toString())
          : null,
      rxBytes: json['rx-byte'] != null
          ? int.tryParse(json['rx-byte'].toString())
          : null,
      txBytesPerSecond: json['tx-byte-per-second'] != null
          ? int.tryParse(json['tx-byte-per-second'].toString())
          : null,
      rxBytesPerSecond: json['rx-byte-per-second'] != null
          ? int.tryParse(json['rx-byte-per-second'].toString())
          : null,
      mtu: json['mtu']?.toString(),
      running: json['running'] == 'true' || json['running'] == true,
      enabled: json['disabled'] == 'false' || json['disabled'] == false,
    );
  }

  // Formatted getters
  String get txDisplay => _formatBytes(txBytes ?? 0);
  String get rxDisplay => _formatBytes(rxBytes ?? 0);
  String get txRateDisplay => _formatBytesPerSecond(txBytesPerSecond ?? 0);
  String get rxRateDisplay => _formatBytesPerSecond(rxBytesPerSecond ?? 0);

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB';
  }

  String _formatBytesPerSecond(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSecond < 1024 * 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB/s';
  }

  double get txPercent {
    if (txBytes == null || rxBytes == null) return 0;
    final total = txBytes! + rxBytes!;
    if (total == 0) return 0;
    return txBytes! / total;
  }

  double get rxPercent {
    if (txBytes == null || rxBytes == null) return 0;
    final total = txBytes! + rxBytes!;
    if (total == 0) return 0;
    return rxBytes! / total;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'tx-byte': txBytes?.toString(),
      'rx-byte': rxBytes?.toString(),
      'tx-byte-per-second': txBytesPerSecond?.toString(),
      'rx-byte-per-second': rxBytesPerSecond?.toString(),
      'mtu': mtu,
      'running': running,
      'disabled': enabled == false,
    };
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? rateLimitUpload; // in kbps (e.g., "512k" or "unlimited")
  final String? rateLimitDownload; // in kbps
  final String? validity; // time duration (e.g., "1h", "1d", "unlimited")
  final String? sessionTimeout; // session-timeout (e.g., "30m", "1h")
  final double? price; // selling price
  final int? sharedUsers; // number of shared users (0 = unlimited)
  final bool? autologout; // auto logout when limit reached
  final DateTime? expiresAt; // expire date/time
  final bool lockDevice; // 0 = all devices allowed, 1 = locked to one device
  final String? onLoginScript; // MikroTik on-login script for auto-expiry

  UserProfile({
    required this.id,
    required this.name,
    this.rateLimitUpload,
    this.rateLimitDownload,
    this.validity,
    this.sessionTimeout,
    this.price,
    this.sharedUsers,
    this.autologout,
    this.expiresAt,
    this.lockDevice = false,
    this.onLoginScript,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    debugPrint('[UserProfile] Parsing JSON: $json');
    double? price = json['price'] != null ? double.tryParse(json['price'].toString()) : null;
    String? validity = json['validity']?.toString();
    
    // Fallback: Aggressively parse price and validity from comment
    if (json['comment'] != null && json['comment'].toString().isNotEmpty) {
      final comment = json['comment'].toString();
      debugPrint('[UserProfile] Parsing comment: $comment');
      
      // Strategy 1: Mikhmon slash format "validity/price" (e.g., "1d/5000")
      if (comment.contains('/')) {
        final slashParts = comment.split('/');
        if (slashParts.length >= 2) {
          final vPart = slashParts[0].trim();
          final pPartWithMore = slashParts[1].trim();
          if (validity == null || validity == 'unlimited' || validity.isEmpty) {
            validity = vPart;
          }
          
          if (price == null || price == 0) {
            // Extract only the numbers from the beginning of the second part
            final pOnly = pPartWithMore.split(RegExp(r'[^0-9]'))[0];
            if (pOnly.isNotEmpty) {
              price = double.tryParse(pOnly);
            }
          }
        }
      }
      
      // Strategy 2: If price still 0, look for any part that is purely a large number
      if (price == null || price == 0) {
        final allParts = comment.split(RegExp(r'[;/\s]'));
        for (var part in allParts) {
          final p = part.trim();
          if (RegExp(r'^\d{3,7}$').hasMatch(p)) { // Looking for 3-7 digit numbers (prices)
            price = double.tryParse(p);
            break;
          }
        }
      }
    }
    // Strategy 4: Fallback to on-login script parsing (for old ROS versions without profile comments, or Mikhmon scripts)
    if (price == null || price == 0 || validity == null || validity == 'unlimited' || validity.isEmpty) {
      final onLogin = json['on-login']?.toString() ?? '';
      if (onLogin.isNotEmpty) {
        // Look for price
        if (price == null || price == 0) {
          // Check for explicit local price first
          final explicitPriceMatch = RegExp(r'(?:price|amount)\s*[:=]\s*"?(\d+)"?|local\s+price\s+"?(\d+)"?').firstMatch(onLogin);
          if (explicitPriceMatch != null) {
            final pStr = explicitPriceMatch.group(1) ?? explicitPriceMatch.group(2);
            if (pStr != null) price = double.tryParse(pStr);
          } else {
            // Check for Mikhmon's aktif-PRICE-$date pattern
            final aktifMatch = RegExp(r'aktif-(\d+)-\$date').firstMatch(onLogin);
            if (aktifMatch != null) {
              final pStr = aktifMatch.group(1);
              if (pStr != null) price = double.tryParse(pStr);
            }
          }
        }
        
        // Look for validity
        if (validity == null || validity == 'unlimited' || validity.isEmpty) {
          // Check for explicit local validity first
          final explicitValMatch = RegExp(r'(?:validity)\s*[:=]\s*"?([a-zA-Z0-9]+)"?|local\s+validity\s+"?([a-zA-Z0-9]+)"?').firstMatch(onLogin);
          if (explicitValMatch != null) {
            validity = explicitValMatch.group(1) ?? explicitValMatch.group(2);
          } else {
            // Check for Mikhmon's interval=... pattern
            final intervalMatch = RegExp(r'interval=([0-9a-zA-Z]+)').firstMatch(onLogin);
            if (intervalMatch != null) {
              validity = intervalMatch.group(1);
            }
          }
        }
      }
    }
    debugPrint('[UserProfile] Result: validity=$validity, price=$price');

    // Parse rate limit (MikroTik format: "upload/download" or "limit")
    String? upload;
    String? download;
    final rateLimit = json['rate-limit']?.toString();
    if (rateLimit != null && rateLimit.contains('/')) {
      final parts = rateLimit.split('/');
      upload = parts[0];
      download = parts[1];
    } else if (rateLimit != null) {
      download = rateLimit;
    }

    return UserProfile(
      id: json['.id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'default',
      rateLimitUpload: upload ?? json['rate-limit-upload'],
      rateLimitDownload: download ?? json['rate-limit-download'],
      validity: validity,
      sessionTimeout: json['session-timeout'],
      price: price,
      sharedUsers: json['shared-users'] != null
          ? int.tryParse(json['shared-users'].toString())
          : null,
      autologout: json['autologout'] == 'true' || json['autologout'] == true,
      expiresAt: json['expires-at'] != null
          ? DateTime.tryParse(json['expires-at'])
          : null,
      lockDevice: json['lock-device'] == 'true' || json['lock-device'] == true,
      onLoginScript: json['on-login'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '.id': id,
      'name': name,
      'rate-limit-upload': rateLimitUpload,
      'rate-limit-download': rateLimitDownload,
      'validity': validity,
      'session-timeout': sessionTimeout,
      'price': price?.toString(),
      'shared-users': sharedUsers?.toString(),
      'autologout': autologout?.toString() ?? 'false',
      'expires-at': expiresAt?.toIso8601String(),
      'lock-device': lockDevice.toString(),
      'on-login': onLoginScript,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rate-limit-upload': rateLimitUpload,
      'rate-limit-download': rateLimitDownload,
      'validity': validity,
      'session-timeout': sessionTimeout,
      'price': price?.toString(),
      'shared-users': sharedUsers?.toString(),
      'autologout': autologout?.toString() ?? 'false',
      'lock-device': lockDevice.toString(),
      'on-login': onLoginScript,
    };
  }

  // Display getters
  String get rateLimitDisplay {
    if (rateLimitUpload == null && rateLimitDownload == null) {
      return 'Unlimited';
    }
    final upload = rateLimitUpload ?? 'unlimited';
    final download = rateLimitDownload ?? 'unlimited';
    return '$upload/$download';
  }

  String get validityDisplay {
    if (validity == null || validity == 'unlimited' || validity == '0') {
      return 'Unlimited';
    }
    return validity!;
  }

  String get sessionTimeoutDisplay {
    if (sessionTimeout == null ||
        sessionTimeout == '0' ||
        sessionTimeout == 'unlimited') {
      return 'None';
    }
    return sessionTimeout!;
  }

  String get priceDisplay {
    if (price == null || price == 0) {
      return 'Free';
    }
    return '\$${price!.toStringAsFixed(2)}';
  }

  String get sharedUsersDisplay {
    if (sharedUsers == null || sharedUsers == 0) {
      return 'Unlimited';
    }
    return '$sharedUsers user${sharedUsers! > 1 ? 's' : ''}';
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? rateLimitUpload,
    String? rateLimitDownload,
    String? validity,
    String? sessionTimeout,
    double? price,
    int? sharedUsers,
    bool? autologout,
    DateTime? expiresAt,
    bool? lockDevice,
    String? onLoginScript,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      rateLimitUpload: rateLimitUpload ?? this.rateLimitUpload,
      rateLimitDownload: rateLimitDownload ?? this.rateLimitDownload,
      validity: validity ?? this.validity,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      price: price ?? this.price,
      sharedUsers: sharedUsers ?? this.sharedUsers,
      autologout: autologout ?? this.autologout,
      expiresAt: expiresAt ?? this.expiresAt,
      lockDevice: lockDevice ?? this.lockDevice,
      onLoginScript: onLoginScript ?? this.onLoginScript,
    );
  }
}

class SystemResources {
  final String platform;
  final String boardName;
  final String version;
  final int cpuFrequency;
  final int cpuLoad;
  final int freeMemory;
  final int totalMemory;
  final int freeHddSpace;
  final int totalHddSpace;
  final int uptimeSeconds;

  SystemResources({
    required this.platform,
    required this.boardName,
    required this.version,
    required this.cpuFrequency,
    required this.cpuLoad,
    required this.freeMemory,
    required this.totalMemory,
    required this.freeHddSpace,
    required this.totalHddSpace,
    required this.uptimeSeconds,
  });

  factory SystemResources.fromJson(Map<String, dynamic> json) {
    return SystemResources(
      platform: _safeString(json['platform'] ?? json['platform-text']),
      boardName: _safeString(json['board-name'] ?? json['board-name-text']),
      version: _safeString(json['version'] ?? json['version-text']),
      cpuFrequency: _parseSizeToInt(
          json['cpu-frequency'] ?? json['cpu-frequency-text'] ?? '0'),
      cpuLoad: int.tryParse(
              json['cpu-load']?.toString().replaceAll('%', '') ?? '0') ??
          0,
      freeMemory: _parseSizeToInt(
          json['free-memory'] ?? json['free-memory-text'] ?? '0'),
      totalMemory: _parseSizeToInt(
          json['total-memory'] ?? json['total-memory-text'] ?? '0'),
      freeHddSpace: _parseSizeToInt(
          json['free-hdd-space'] ?? json['free-hdd-space-text'] ?? '0'),
      totalHddSpace: _parseSizeToInt(
          json['total-hdd-space'] ?? json['total-hdd-space-text'] ?? '0'),
      uptimeSeconds: _parseUptime(json['uptime'] ?? json['uptime-text'] ?? '0'),
    );
  }

  /// Safely extract a string value, defaulting to 'Unknown' if null or empty
  static String _safeString(dynamic value) {
    if (value == null) return 'Unknown';
    final str = value.toString().trim();
    return str.isEmpty ? 'Unknown' : str;
  }

  static int _parseSizeToInt(String value) {
    if (value.isEmpty) return 0;

    // Try parsing as integer first
    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;

    // Parse format like "1048576KiB" or "1GiB" or "512MiB"
    final regex =
        RegExp(r'(\d+(?:\.\d+)?)\s*([KMGT]?i?B?)', caseSensitive: false);
    final match = regex.firstMatch(value);

    if (match != null) {
      final number = double.tryParse(match.group(1)!) ?? 0;
      final unit = (match.group(2) ?? '').toUpperCase();

      switch (unit) {
        case 'KI':
        case 'KIB':
          return (number * 1024).toInt();
        case 'K':
          return (number * 1000).toInt();
        case 'MI':
        case 'MIB':
          return (number * 1024 * 1024).toInt();
        case 'M':
          return (number * 1000 * 1000).toInt();
        case 'GI':
        case 'GIB':
          return (number * 1024 * 1024 * 1024).toInt();
        case 'G':
          return (number * 1000 * 1000 * 1000).toInt();
        case 'TI':
        case 'TIB':
          return (number * 1024 * 1024 * 1024 * 1024).toInt();
        case 'T':
          return (number * 1000 * 1000 * 1000 * 1000).toInt();
        default:
          return number.toInt();
      }
    }

    // Remove any non-numeric characters and try parsing
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return (double.tryParse(cleaned) ?? 0).toInt();
  }

  static int _parseUptime(String uptime) {
    if (uptime.isEmpty) return 0;

    // Try parsing as integer first (in case it's already in seconds)
    final asInt = int.tryParse(uptime);
    if (asInt != null) return asInt;

    // Parse format like "2d 3h 45m 30s" or "3h 45m" or "45m"
    int seconds = 0;
    final regex = RegExp(r'(\d+)([dhms])');
    final matches = regex.allMatches(uptime);

    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2);

      switch (unit) {
        case 'd':
          seconds += value * 86400;
          break;
        case 'h':
          seconds += value * 3600;
          break;
        case 'm':
          seconds += value * 60;
          break;
        case 's':
          seconds += value;
          break;
      }
    }

    return seconds;
  }

  double get memoryUsagePercent =>
      totalMemory > 0 ? ((totalMemory - freeMemory) / totalMemory * 100) : 0;

  double get hddUsagePercent => totalHddSpace > 0
      ? ((totalHddSpace - freeHddSpace) / totalHddSpace * 100)
      : 0;
}

class HotspotUser {
  final String id;
  final String name;
  final String profile;
  final bool active;
  final bool disabled;
  final String? uptime;
  final int? bytesIn;
  final int? bytesOut;
  final int? limitBytesIn;
  final int? limitBytesOut;
  final String? limitUptime;
  final String? comment;

  HotspotUser({
    required this.id,
    required this.name,
    required this.profile,
    required this.active,
    this.disabled = false,
    this.uptime,
    this.bytesIn,
    this.bytesOut,
    this.limitBytesIn,
    this.limitBytesOut,
    this.limitUptime,
    this.comment,
  });

  factory HotspotUser.fromJson(Map<String, dynamic> json,
      {Set<String>? activeUsernames}) {
    // Active only if username exists in the hotspot/active list
    final name = json['name'] ?? '';
    final isActive = activeUsernames != null
        ? activeUsernames.contains(name)
        : json['active'] == 'true';

    return HotspotUser(
      id: json['.id'] ?? '',
      name: name,
      profile: json['profile'] ?? 'default',
      active: isActive,
      disabled: json['disabled'] == 'true' || json['disabled'] == true,
      uptime: json['uptime'],
      bytesIn: int.tryParse(json['bytes-in'] ?? '0'),
      bytesOut: int.tryParse(json['bytes-out'] ?? '0'),
      limitBytesIn: int.tryParse(json['limit-bytes-in'] ?? '0'),
      limitBytesOut: int.tryParse(json['limit-bytes-out'] ?? '0'),
      limitUptime: json['limit-uptime'],
      comment: json['comment'],
    );
  }

  /// Check if this user was created via voucher generation
  /// Vouchers have comments like "mode:up" or "mode:vc"
  bool get isVoucher {
    if (comment == null) return false;
    final commentLower = comment!.toLowerCase();
    return commentLower.contains('mode:up') || commentLower.contains('mode:vc');
  }

  String get dataUsed {
    final bytes = (bytesIn ?? 0) + (bytesOut ?? 0);
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String get simpleUptime {
    if (uptime == null || uptime == '0s' || uptime == '00:00:00') return '-';
    // Simplify: 1d 2h 3m -> 1d2h, 1h 2m -> 1h2m
    return uptime!.replaceAll(' ', '').replaceAll('s', '');
  }

  /// Parse expiry date from comment field (format: "MM/DD/YY HH:MM:SS")
  DateTime? get expiresAt {
    if (comment == null) return null;
    try {
      final commentStr = comment!.toString();

      // 1. Try standard MM/DD/YY HH:MM:SS format
      final match1 =
          RegExp(r'(\d{2})/(\d{2})/(\d{2,4})\s+(\d{2}):(\d{2}):(\d{2})')
              .firstMatch(commentStr);
      if (match1 != null) {
        final month = int.parse(match1.group(1)!);
        final day = int.parse(match1.group(2)!);
        var year = int.parse(match1.group(3)!);
        if (year < 100) year += 2000;
        final hour = int.parse(match1.group(4)!);
        final minute = int.parse(match1.group(5)!);
        final second = int.parse(match1.group(6)!);
        return DateTime(year, month, day, hour, minute, second);
      }

      // 2. Try MikroTik format mmm/dd/yyyy HH:MM:SS (e.g. apr/14/2026 21:00:00)
      final match2 = RegExp(
              r'([a-z]{3})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
              caseSensitive: false)
          .firstMatch(commentStr);
      if (match2 != null) {
        final months = [
          'jan',
          'feb',
          'mar',
          'apr',
          'may',
          'jun',
          'jul',
          'aug',
          'sep',
          'oct',
          'nov',
          'dec'
        ];
        final monthStr = match2.group(1)!.toLowerCase();
        final month = months.indexOf(monthStr) + 1;
        if (month > 0) {
          final day = int.parse(match2.group(2)!);
          final year = int.parse(match2.group(3)!);
          final hour = int.parse(match2.group(4)!);
          final minute = int.parse(match2.group(5)!);
          final second = int.parse(match2.group(6)!);
          return DateTime(year, month, day, hour, minute, second);
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Parse MikroTik time string to seconds (e.g., "1h5m30s" -> 4530)
  int _parseTimeToSeconds(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 0;
    try {
      int totalSeconds = 0;
      final match = RegExp(r'(\d+)(\w)').allMatches(timeStr.toLowerCase());
      for (final m in match) {
        final value = int.parse(m.group(1)!);
        final unit = m.group(2)!;
        switch (unit) {
          case 's':
            totalSeconds += value;
            break;
          case 'm':
            totalSeconds += value * 60;
            break;
          case 'h':
            totalSeconds += value * 3600;
            break;
          case 'd':
            totalSeconds += value * 86400;
            break;
          case 'w':
            totalSeconds += value * 604800;
            break;
        }
      }
      return totalSeconds;
    } catch (e) {
      return 0;
    }
  }

  /// Check if this voucher/user is expired
  /// Expired if:
  /// 1) disabled AND comment contains 'aktif' (User's specific rule)
  /// 2) past expiry date from comment
  /// 3) uptime reached limit-uptime
  bool get isExpired {
    // 1. User's specific rule: if disabled and comment is 'aktif', it's expired
    if (disabled &&
        comment != null &&
        comment!.toLowerCase().contains('aktif')) {
      return true;
    }

    // 2. Check expiry date in comment
    final expiry = expiresAt;
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      return true;
    }

    // 3. Check if uptime has reached limit-uptime
    if (limitUptime != null && uptime != null) {
      final limitSeconds = _parseTimeToSeconds(limitUptime);
      final uptimeSeconds = _parseTimeToSeconds(uptime);
      // If limit is set and uptime has reached or exceeded it, user is expired
      if (limitSeconds > 0 && uptimeSeconds >= limitSeconds) {
        return true;
      }
    }
    return false;
  }

  /// Check if the user is manually disabled (and not expired)
  bool get isDisabledOnly => disabled && !isExpired;

  Map<String, dynamic> toMap() {
    return {
      '.id': id,
      'name': name,
      'profile': profile,
      'active': active.toString(),
      'disabled': disabled.toString(),
      'uptime': uptime ?? '0',
      'bytes-in': (bytesIn ?? 0).toString(),
      'bytes-out': (bytesOut ?? 0).toString(),
      'limit-bytes-in': (limitBytesIn ?? 0).toString(),
      'limit-bytes-out': (limitBytesOut ?? 0).toString(),
      'comment': comment,
    };
  }
}

class InterfaceStats {
  final String name;
  final String type;
  final bool running;
  final int? mtu;
  final int? txByte;
  final int? rxByte;

  InterfaceStats({
    required this.name,
    required this.type,
    required this.running,
    this.mtu,
    this.txByte,
    this.rxByte,
  });

  factory InterfaceStats.fromJson(Map<String, dynamic> json) {
    return InterfaceStats(
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 'Unknown',
      running: json['running'] == 'true',
      mtu: int.tryParse(json['mtu'] ?? '0'),
      txByte: int.tryParse(json['tx-byte'] ?? '0'),
      rxByte: int.tryParse(json['rx-byte'] ?? '0'),
    );
  }

  String get txData => '${(txByte ?? 0) / 1024 / 1024} MB';
  String get rxData => '${(rxByte ?? 0) / 1024 / 1024} MB';
}

class HotspotActiveUser {
  final String id;
  final String username;
  final String address;
  final String macAddress;
  final String loginTime;
  final String uptime;
  final int bytesIn;
  final int bytesOut;
  final String? server;
  final String profile;

  HotspotActiveUser({
    required this.id,
    required this.username,
    required this.address,
    required this.macAddress,
    required this.loginTime,
    required this.uptime,
    required this.bytesIn,
    required this.bytesOut,
    this.server,
    required this.profile,
  });

  factory HotspotActiveUser.fromJson(Map<String, dynamic> json) {
    return HotspotActiveUser(
      id: json['.id'] ?? '',
      username: json['user'] ?? '',
      address: json['address'] ?? '',
      macAddress: json['mac-address'] ?? '',
      loginTime: json['login-time'] ?? '0',
      uptime: json['uptime'] ?? '0',
      bytesIn: int.tryParse(json['bytes-in'] ?? '0') ?? 0,
      bytesOut: int.tryParse(json['bytes-out'] ?? '0') ?? 0,
      server: json['server'],
      profile: json['profile'] ?? 'default',
    );
  }

  String get dataUsed => _formatBytes(bytesIn + bytesOut);

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

// Sales transaction model for income tracking
class SalesTransaction {
  final String id;
  final String username;
  final String profile;
  final double price;
  final DateTime timestamp;
  final String? comment;

  SalesTransaction({
    required this.id,
    required this.username,
    required this.profile,
    required this.price,
    required this.timestamp,
    this.comment,
  });

  factory SalesTransaction.fromJson(Map<String, dynamic> json) {
    return SalesTransaction(
      id: json['id'] ?? json['.id'] ?? '',
      username: json['username'] ?? json['name'] ?? '',
      profile: json['profile'] ?? 'default',
      price: (json['price'] != null)
          ? (double.tryParse(json['price'].toString()) ?? 0.0)
          : (json['amount'] != null
              ? double.tryParse(json['amount'].toString()) ?? 0.0
              : 0.0),
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.tryParse(json['timestamp']) ?? DateTime.now())
          : DateTime.now(),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile': profile,
      'price': price,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (comment != null) 'comment': comment,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  // Format date as "MMM dd, yyyy"
  String get formattedDate {
    return '${_monthName(timestamp.month)} ${timestamp.day}, ${timestamp.year}';
  }

  // Format time as "HH:mm"
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  SalesTransaction copyWith({
    String? id,
    String? username,
    String? profile,
    double? price,
    DateTime? timestamp,
    String? comment,
  }) {
    return SalesTransaction(
      id: id ?? this.id,
      username: username ?? this.username,
      profile: profile ?? this.profile,
      price: price ?? this.price,
      timestamp: timestamp ?? this.timestamp,
      comment: comment ?? this.comment,
    );
  }
}

// Income summary model
class IncomeSummary {
  final double todayIncome;
  final double thisMonthIncome;
  final int transactionsToday;
  final int transactionsThisMonth;

  const IncomeSummary({
    required this.todayIncome,
    required this.thisMonthIncome,
    required this.transactionsToday,
    required this.transactionsThisMonth,
  });

  IncomeSummary copyWith({
    double? todayIncome,
    double? thisMonthIncome,
    int? transactionsToday,
    int? transactionsThisMonth,
  }) {
    return IncomeSummary(
      todayIncome: todayIncome ?? this.todayIncome,
      thisMonthIncome: thisMonthIncome ?? this.thisMonthIncome,
      transactionsToday: transactionsToday ?? this.transactionsToday,
      transactionsThisMonth:
          transactionsThisMonth ?? this.transactionsThisMonth,
    );
  }
}

// Saved Router Connection model
class RouterConnection {
  final String id;
  final String name;
  final String host;
  final String port;
  final String username;
  final bool useRest; // Whether to use ROS7 REST API (true) or Legacy API (false)
  final DateTime createdAt;

  RouterConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.useRest = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RouterConnection.fromJson(Map<String, dynamic> json) {
    return RouterConnection(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      host: (json['host'] as String?) ?? '',
      port: (json['port'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      useRest: json['useRest'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'useRest': useRest,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayName => name;
  String get address => '$host:$port';

  RouterConnection copyWith({
    String? id,
    String? name,
    String? host,
    String? port,
    String? username,
    bool? useRest,
    DateTime? createdAt,
  }) {
    return RouterConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      useRest: useRest ?? this.useRest,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Hotspot Host Model - Represents a DHCP host/lease in RouterOS hotspot
class HotspotHost {
  final String id;
  final String? macAddress;
  final String? address; // IP address
  final String? toAddress; // Target IP (for static entries)
  final String? server; // Hotspot server name
  final String? user; // Associated username (if logged in)
  final String? hostname; // Device hostname from DHCP
  final String? uptime; // Connection duration
  final String? idleTime; // Time since last activity
  final bool authorized; // Authorization status
  final bool bypassed; // Bypassed status (can access without login)
  final String? comment; // Comment/description
  final int? bytesIn; // Bytes received by host
  final int? bytesOut; // Bytes sent by host
  final int? packetsIn; // Packets received
  final int? packetsOut; // Packets sent

  HotspotHost({
    required this.id,
    this.macAddress,
    this.address,
    this.toAddress,
    this.server,
    this.user,
    this.hostname,
    this.uptime,
    this.idleTime,
    required this.authorized,
    required this.bypassed,
    this.comment,
    this.bytesIn,
    this.bytesOut,
    this.packetsIn,
    this.packetsOut,
  });

  factory HotspotHost.fromJson(Map<String, dynamic> json) {
    return HotspotHost(
      id: json['.id'] as String? ?? json['id'] as String? ?? '',
      macAddress: json['mac-address'] as String?,
      address: json['address'] as String?,
      toAddress: json['to-address'] as String?,
      server: json['server'] as String?,
      user: json['user'] as String?,
      hostname: json['host-name'] as String? ?? json['hostname'] as String?,
      uptime: json['uptime'] as String?,
      idleTime: json['idle-time'] as String?,
      authorized: json['authorized'] == 'true' || json['authorized'] == true,
      bypassed: json['bypassed'] == 'true' || json['bypassed'] == true,
      comment: json['comment'] as String?,
      bytesIn: _parseInt(json['bytes-in']),
      bytesOut: _parseInt(json['bytes-out']),
      packetsIn: _parseInt(json['packets-in']),
      packetsOut: _parseInt(json['packets-out']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '.id': id,
      'mac-address': macAddress,
      'address': address,
      'to-address': toAddress,
      'server': server,
      'user': user,
      'host-name': hostname,
      'uptime': uptime,
      'idle-time': idleTime,
      'authorized': authorized.toString(),
      'bypassed': bypassed.toString(),
      'comment': comment,
      'bytes-in': bytesIn,
      'bytes-out': bytesOut,
      'packets-in': packetsIn,
      'packets-out': packetsOut,
    };
  }

  /// Display name for the host (username or hostname)
  String get displayName {
    if (user != null && user!.isNotEmpty) return user!;
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (macAddress != null && macAddress!.isNotEmpty) return macAddress!;
    if (address != null && address!.isNotEmpty) return address!;
    return 'Unknown';
  }

  /// Device name for display (hostname or MAC)
  String get deviceName {
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (user != null && user!.isNotEmpty) return user!;
    return 'Unknown Device';
  }

  /// Status badge text
  String get statusText {
    if (bypassed) return 'Bypassed';
    if (authorized) return 'Authorized';
    return 'Unauthorized';
  }

  /// Check if host is active (has IP and is authorized or bypassed)
  bool get isActive =>
      address != null && address!.isNotEmpty && (authorized || bypassed);

  HotspotHost copyWith({
    String? id,
    String? macAddress,
    String? address,
    String? toAddress,
    String? server,
    String? user,
    String? hostname,
    String? uptime,
    String? idleTime,
    bool? authorized,
    bool? bypassed,
    String? comment,
    int? bytesIn,
    int? bytesOut,
    int? packetsIn,
    int? packetsOut,
  }) {
    return HotspotHost(
      id: id ?? this.id,
      macAddress: macAddress ?? this.macAddress,
      address: address ?? this.address,
      toAddress: toAddress ?? this.toAddress,
      server: server ?? this.server,
      user: user ?? this.user,
      hostname: hostname ?? this.hostname,
      uptime: uptime ?? this.uptime,
      idleTime: idleTime ?? this.idleTime,
      authorized: authorized ?? this.authorized,
      bypassed: bypassed ?? this.bypassed,
      comment: comment ?? this.comment,
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      packetsIn: packetsIn ?? this.packetsIn,
      packetsOut: packetsOut ?? this.packetsOut,
    );
  }

  @override
  String toString() {
    return 'HotspotHost(id: $id, macAddress: $macAddress, address: $address, user: $user, authorized: $authorized, bypassed: $bypassed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotspotHost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// DHCP Lease Model - Contains device hostname info
class DhcpLease {
  final String id;
  final String? address; // IP address
  final String? macAddress;
  final String? hostname; // Device name (e.g., OPPO, Samsung)
  final String? status; // bound, freed, waiting
  final String? server; // DHCP server
  final bool isDynamic; // Dynamic vs static lease
  final String? comment;
  final String? expiresAt;
  final int? bytesIn;
  final int? bytesOut;

  DhcpLease({
    required this.id,
    this.address,
    this.macAddress,
    this.hostname,
    this.status,
    this.server,
    required this.isDynamic,
    this.comment,
    this.expiresAt,
    this.bytesIn,
    this.bytesOut,
  });

  factory DhcpLease.fromJson(Map<String, dynamic> json) {
    return DhcpLease(
      id: json['.id'] ?? json['id'] ?? '',
      address: json['address'] as String?,
      macAddress: json['mac-address'] as String?,
      hostname: json['host-name'] as String? ?? json['hostname'] as String?,
      status: json['status'] as String?,
      server: json['server'] as String?,
      isDynamic: json['dynamic'] == 'true' || json['dynamic'] == true,
      comment: json['comment'] as String?,
      expiresAt:
          json['expires-after'] as String? ?? json['expires-at'] as String?,
      bytesIn: _parseInt(json['bytes-in']),
      bytesOut: _parseInt(json['bytes-out']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String get displayName {
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (macAddress != null && macAddress!.isNotEmpty) return macAddress!;
    if (address != null && address!.isNotEmpty) return address!;
    return 'Unknown Device';
  }

  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'bound':
        return 'Active';
      case 'waiting':
        return 'Waiting';
      case 'offered':
        return 'Offered';
      case 'freed':
        return 'Freed';
      default:
        return status ?? 'Unknown';
    }
  }
}
