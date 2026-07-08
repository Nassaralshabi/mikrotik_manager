/// Utility class for parsing validity periods and calculating expiry dates
/// Compatible with Mikhmon's on-login script format
class ValidityParser {
  /// Parse validity string (e.g., "5m", "1h", "1d", "1w", "1mo")
  /// and return the expiry DateTime, or null if invalid/unlimited
  static DateTime? parseValidity(String? validity) {
    if (validity == null || validity.isEmpty || validity == 'unlimited') {
      return null;
    }

    // Clean the input - lowercase and trim
    final input = validity.toLowerCase().trim();

    // Match pattern: number followed by unit
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-z]+)$').firstMatch(input);
    if (match == null) {
      return null;
    }

    final value = double.tryParse(match.group(1) ?? '');
    final unit = match.group(2) ?? '';

    if (value == null) {
      return null;
    }

    final now = DateTime.now();

    switch (unit) {
      case 's':
      case 'sec':
      case 'secs':
      case 'second':
      case 'seconds':
        return now.add(Duration(seconds: value.toInt()));
      case 'm':
      case 'min':
      case 'mins':
      case 'minute':
      case 'minutes':
        return now.add(Duration(minutes: value.toInt()));
      case 'h':
      case 'hr':
      case 'hrs':
      case 'hour':
      case 'hours':
        return now.add(Duration(hours: value.toInt()));
      case 'd':
      case 'day':
      case 'days':
        return now.add(Duration(days: value.toInt()));
      case 'w':
      case 'week':
      case 'weeks':
        return now.add(Duration(days: (value * 7).toInt()));
      case 'mo':
      case 'month':
      case 'months':
        // Add months (handle year rollover)
        return _addMonths(now, value.toInt());
      default:
        return null;
    }
  }

  /// Add months to a date, handling year rollover
  static DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;

    // Handle year rollover
    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }

    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
    var day = date.day;
    final maxDay = DateTime(year, month + 1, 0).day;
    if (day > maxDay) {
      day = maxDay;
    }

    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }

  /// Format expiry date in Mikhmon-compatible format
  /// Format: "MM/DD/YY HH:MM:SS" (e.g., "01/15/26 14:30:00")
  static String formatExpiryDate(DateTime expiry) {
    // Format: MM/DD/YY
    final month = expiry.month.toString().padLeft(2, '0');
    final day = expiry.day.toString().padLeft(2, '0');
    final year = expiry.year.toString().substring(2); // Last 2 digits

    // Format: HH:MM:SS
    final hour = expiry.hour.toString().padLeft(2, '0');
    final minute = expiry.minute.toString().padLeft(2, '0');
    final second = expiry.second.toString().padLeft(2, '0');

    return '$month/$day/$year $hour:$minute:$second';
  }

  /// Build comment with expiry for Mikhmon compatibility
  /// Format: "mode:vc;1d/5000;MM/DD/YY HH:MM:SS;..."
  static String buildCommentWithExpiry({
    required String mode, // 'vc' or 'up'
    required String validity,
    double? price,
    String? comment,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.month}.${now.day}.${now.year.toString().substring(2)}';
    
    // Ensure validity is not empty string for the price part
    final effectiveValidity = (validity == null || validity.isEmpty) ? "unlimited" : validity;
    
    final pricePart = price != null && price > 0 
        ? '$effectiveValidity/${price.toInt()}' 
        : effectiveValidity;

    final expiry = parseValidity(validity);
    if (expiry == null) {
      // No expiry, build basic comment
      return 'mode:$mode;$pricePart;$dateStr;${comment ?? ""}';
    }

    // Build comment with expiry
    final expiryStr = formatExpiryDate(expiry);
    return 'mode:$mode;$pricePart;$expiryStr;${comment ?? ""}';
  }

  /// Get validity in MikroTik format for API
  /// Returns formatted string like "5m", "1h", "1d", etc.
  static String? formatValidityForMikroTik(String? validity) {
    if (validity == null || validity.isEmpty || validity == 'unlimited') {
      return null;
    }

    final input = validity.toLowerCase().trim();

    // Ensure proper format - MikroTik uses: s, m, h, d, w, M, y
    // Note: 'ms' means milliseconds, which would be too short
    if (input.endsWith('ms')) {
      // Convert ms to seconds (minimum MikroTik unit is seconds)
      final match = RegExp(r'^(\d+(?:\.\d+)?)\s*ms$').firstMatch(input);
      if (match != null) {
        final value = double.tryParse(match.group(1) ?? '');
        if (value != null) {
          final seconds = (value / 1000).ceil();
          if (seconds > 0) {
            return '${seconds}s';
          }
        }
      }
      return null; // ms is too small, ignore
    }

    // Validate the format
    final parsed = parseValidity(validity);
    if (parsed == null) {
      return null;
    }

    // Return in MikroTik format
    // For months, MikroTik uses 'M' (capital), but 'mo' is more readable
    // We'll use the format MikroTik understands
    if (input.endsWith('mo') || input.endsWith('month') || input.endsWith('months')) {
      final match = RegExp(r'^(\d+(?:\.\d+)?)\s*mo').firstMatch(input);
      if (match != null) {
        return '${match.group(1)}M';
      }
    }

    return input;
  }

  /// Check if validity string is valid
  static bool isValidValidity(String? validity) {
    if (validity == null || validity.isEmpty || validity == 'unlimited') {
      return true; // unlimited is valid
    }
    return parseValidity(validity) != null;
  }

  /// Get human readable description of validity
  static String getValidityDescription(String? validity) {
    if (validity == null || validity.isEmpty || validity == 'unlimited') {
      return 'Unlimited';
    }

    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-z]+)$', caseSensitive: false)
        .firstMatch(validity);
    if (match == null) {
      return validity;
    }

    final value = match.group(1);
    final unit = match.group(2)?.toLowerCase() ?? '';

    switch (unit) {
      case 's':
      case 'sec':
      case 'secs':
      case 'second':
      case 'seconds':
        return '$value second${value == '1' ? '' : 's'}';
      case 'm':
      case 'min':
      case 'mins':
      case 'minute':
      case 'minutes':
        return '$value minute${value == '1' ? '' : 's'}';
      case 'h':
      case 'hr':
      case 'hrs':
      case 'hour':
      case 'hours':
        return '$value hour${value == '1' ? '' : 's'}';
      case 'd':
      case 'day':
      case 'days':
        return '$value day${value == '1' ? '' : 's'}';
      case 'w':
      case 'week':
      case 'weeks':
        return '$value week${value == '1' ? '' : 's'}';
      case 'mo':
      case 'month':
      case 'months':
        return '$value month${value == '1' ? '' : 's'}';
      default:
        return validity;
    }
  }
}
