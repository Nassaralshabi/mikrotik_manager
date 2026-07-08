class Voucher {
  final String username;
  final String password;
  final String profile;
  final String? validity;
  final String? dataLimit;
  final String? comment;
  final DateTime createdAt;
  final DateTime? firstUsedAt;
  final int? remainingSeconds;
  final DateTime? sessionStartedAt;
  final double? price;
  final bool disabled;

  Voucher({
    required this.username,
    required this.password,
    required this.profile,
    this.validity,
    this.dataLimit,
    this.comment,
    required this.createdAt,
    this.firstUsedAt,
    this.remainingSeconds,
    this.sessionStartedAt,
    this.price,
    this.disabled = false,
  });

  int? get totalSeconds => Voucher.validityToSeconds(validity);

  bool get isFirstUse => firstUsedAt == null;

  bool get isVoucher {
    if (comment == null) return false;
    final commentLower = comment!.toLowerCase();
    return commentLower.contains('mode:up') || commentLower.contains('mode:vc');
  }

  bool get isExpired {
    // A voucher is considered expired if it's disabled AND it's a voucher (has mode:vc/up in comment)
    // This matches the logic in HotspotUser
    if (!disabled) return false;
    return isVoucher;
  }

  bool get isDisabledOnly {
    // Manually disabled but NOT expired
    return disabled && !isVoucher;
  }

  bool get isActive => !disabled;

  bool get isInSession => sessionStartedAt != null && !isExpired;

  int get currentRemainingSeconds {
    if (firstUsedAt == null || totalSeconds == null) return totalSeconds ?? 0;
    final elapsed = DateTime.now().difference(firstUsedAt!).inSeconds;
    return (totalSeconds! - elapsed).clamp(0, totalSeconds!);
  }

  DateTime? get expiresAt {
    if (firstUsedAt == null || totalSeconds == null) return null;
    return firstUsedAt!.add(Duration(seconds: totalSeconds!));
  }

  String get remainingTimeDisplay {
    final secs = isFirstUse
        ? (remainingSeconds ?? totalSeconds ?? 0)
        : currentRemainingSeconds;
    if (secs <= 0) return 'Expired';
    if (secs >= 86400) {
      final d = secs ~/ 86400;
      final h = (secs % 86400) ~/ 3600;
      return '${d}d ${h}h';
    }
    if (secs >= 3600) {
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      return '${h}h ${m}m';
    }
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m ${s}s';
  }

  String get displayText {
    if (username == password) {
      return 'Voucher: $username';
    } else {
      return 'User: $username\nPass: $password';
    }
  }

  String get qrData {
    if (username == password) {
      return 'WIFI:S:$username;;';
    } else {
      return 'WIFI:S:$username;P:$password;;';
    }
  }

  static int? validityToSeconds(String? validity) {
    if (validity == null || validity.isEmpty || validity == 'unlimited') {
      return null;
    }
    final match = RegExp(r'^(\d+)\s*([a-z]+)$', caseSensitive: false)
        .firstMatch(validity);
    if (match == null) return null;
    final value = int.tryParse(match.group(1) ?? '');
    final unit = match.group(2)?.toLowerCase() ?? '';
    if (value == null) return null;
    switch (unit) {
      case 's':
      case 'sec':
        return value;
      case 'm':
      case 'min':
        return value * 60;
      case 'h':
      case 'hr':
        return value * 3600;
      case 'd':
      case 'day':
        return value * 86400;
      case 'w':
      case 'week':
        return value * 604800;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'profile': profile,
      'validity': validity,
      'dataLimit': dataLimit,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'firstUsedAt': firstUsedAt?.toIso8601String(),
      'remainingSeconds': remainingSeconds,
      'sessionStartedAt': sessionStartedAt?.toIso8601String(),
      'price': price,
    };
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      username: (json['username'] as String?) ?? '',
      password: (json['password'] as String?) ?? '',
      profile: (json['profile'] as String?) ?? 'default',
      validity: json['validity'] as String?,
      dataLimit: json['dataLimit'] as String?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      firstUsedAt: json['firstUsedAt'] != null
          ? DateTime.parse(json['firstUsedAt'] as String)
          : null,
      remainingSeconds: json['remainingSeconds'] as int?,
      sessionStartedAt: json['sessionStartedAt'] != null
          ? DateTime.parse(json['sessionStartedAt'] as String)
          : null,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }

  Voucher copyWith({
    String? username,
    String? password,
    String? profile,
    String? validity,
    String? dataLimit,
    String? comment,
    DateTime? createdAt,
    DateTime? firstUsedAt,
    int? remainingSeconds,
    DateTime? sessionStartedAt,
    double? price,
  }) {
    return Voucher(
      username: username ?? this.username,
      password: password ?? this.password,
      profile: profile ?? this.profile,
      validity: validity ?? this.validity,
      dataLimit: dataLimit ?? this.dataLimit,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      firstUsedAt: firstUsedAt ?? this.firstUsedAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      price: price ?? this.price,
    );
  }
}