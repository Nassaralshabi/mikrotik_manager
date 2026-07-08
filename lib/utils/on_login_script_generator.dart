class OnLoginScriptGenerator {
  static String generate(String validity, {double? price}) {
    final parsed = _parseValidity(validity);
    if (parsed == null) return '';

    final days = parsed['days'] ?? 0;
    final hours = parsed['hours'] ?? 0;
    final minutes = parsed['minutes'] ?? 0;

    String interval = '';
    if ((parsed['days'] ?? 0) > 0) interval += '${parsed['days']}d';
    if ((parsed['hours'] ?? 0) > 0) interval += '${parsed['hours']}h';
    if ((parsed['minutes'] ?? 0) > 0) interval += '${parsed['minutes']}m';
    if (interval.isEmpty) interval = '1m';

    final priceTag = price != null ? '-${price.toInt()}' : '';

    return ':local date [/system clock get date]; '
        ':if ([/ip hotspot user get [find name="\$user"] comment] != "aktif$priceTag-\$date") do={'
        '/ip hotspot user set [find name="\$user"] comment="aktif$priceTag-\$date"; '
        '/system scheduler add name="\$user" interval=$interval on-event="/ip hotspot user disable [find name=\\"\$user\\"]; /ip hotspot active remove [find user=\\"\$user\\"]; /system scheduler remove [find name=\\"\$user\\"]"'
        '}';
  }

  static bool isValidSessionTimeout(String? sessionTimeout) {
    if (sessionTimeout == null || sessionTimeout.isEmpty) return false;
    return _parseValidity(sessionTimeout) != null;
  }

  static Map<String, int>? _parseValidity(String v) {
    v = v.toLowerCase().trim();
    if (v.isEmpty || v == 'unlimited') return null;

    int d = 0, h = 0, m = 0, s = 0;

    final fullMatch = RegExp(r'^(\d+)d\s+(\d+):(\d+):(\d+)$').firstMatch(v);
    if (fullMatch != null) {
      d = int.tryParse(fullMatch.group(1) ?? '0') ?? 0;
      h = int.tryParse(fullMatch.group(2) ?? '0') ?? 0;
      m = int.tryParse(fullMatch.group(3) ?? '0') ?? 0;
      s = int.tryParse(fullMatch.group(4) ?? '0') ?? 0;
      return {'days': d, 'hours': h, 'minutes': m, 'seconds': s};
    }

    for (final match in RegExp(r'(\d+)([smhd])').allMatches(v)) {
      final val = int.tryParse(match.group(1) ?? '') ?? 0;
      final unit = match.group(2);
      if (unit == 's')
        s += val;
      else if (unit == 'm')
        m += val;
      else if (unit == 'h')
        h += val;
      else if (unit == 'd') d += val;
    }

    if (d == 0 && h == 0 && m == 0 && s == 0) return null;
    return {'days': d, 'hours': h, 'minutes': m, 'seconds': s};
  }
}
