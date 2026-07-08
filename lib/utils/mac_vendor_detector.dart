import 'package:flutter/material.dart';

/// MAC Address Vendor Detection Utility
/// Identifies device manufacturers from MAC address prefixes (OUI)
class MacVendorDetector {
  /// Common MAC address prefixes and their vendors
  static const Map<String, VendorInfo> _vendorMap = {
    // Apple
    '00:1B:63': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '00:1F:F3': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '00:23:DF': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '00:25:00': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '00:26:B0': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '28:CF:E9': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '3C:15:C2': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    '58:55:CA': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    'AC:87:A3': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    'F0:18:98': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),
    'F8:FF:C2': VendorInfo('Apple', 'devices/apple.png', Icons.phone_iphone),

    // Samsung
    '00:12:FB': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '00:15:B9': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '00:16:6F': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '00:17:C9': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '00:21:19': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '00:23:4E': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '00:26:18': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '3C:D9:2B': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '4C:54:99': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    '78:02:F8': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    'AC:5F:3E': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    'B4:9E:42': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),
    'CC:3A:61': VendorInfo('Samsung', 'devices/samsung.png', Icons.smartphone),

    // Xiaomi
    '34:CE:00': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    '38:8C:50': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    '64:09:80': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    '78:11:DC': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    'AC:23:3F': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    'CC:81:D4': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    'E8:AB:FA': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    'F0:B4:29': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),
    'F4:8B:32': VendorInfo('Xiaomi', 'devices/xiaomi.png', Icons.smartphone),

    // Oppo
    '00:E0:4C': VendorInfo('OPPO', 'devices/oppo.png', Icons.smartphone),
    '44:25:AD': VendorInfo('OPPO', 'devices/oppo.png', Icons.smartphone),
    '80:C0:EA': VendorInfo('OPPO', 'devices/oppo.png', Icons.smartphone),
    'AC:7D:F5': VendorInfo('OPPO', 'devices/oppo.png', Icons.smartphone),
    'F4:F1:73': VendorInfo('OPPO', 'devices/oppo.png', Icons.smartphone),

    // Vivo
    '00:08:CA': VendorInfo('Vivo', 'devices/vivo.png', Icons.smartphone),
    '34:AF:2D': VendorInfo('Vivo', 'devices/vivo.png', Icons.smartphone),
    '70:6E:88': VendorInfo('Vivo', 'devices/vivo.png', Icons.smartphone),
    'AC:FD:EC': VendorInfo('Vivo', 'devices/vivo.png', Icons.smartphone),
    'DC:FE:18': VendorInfo('Vivo', 'devices/vivo.png', Icons.smartphone),

    // Huawei
    '00:E0:FC': VendorInfo('Huawei', 'devices/huawei.png', Icons.smartphone),
    '08:18:1F': VendorInfo('Huawei', 'devices/huawei.png', Icons.smartphone),
    '80:26:89': VendorInfo('Huawei', 'devices/huawei.png', Icons.smartphone),
    '88:25:93': VendorInfo('Huawei', 'devices/huawei.png', Icons.smartphone),
    'F8:01:13': VendorInfo('Huawei', 'devices/huawei.png', Icons.smartphone),

    // Realme
    'AE:FD:22': VendorInfo('Realme', 'devices/realme.png', Icons.smartphone),
    'D2:19:F1': VendorInfo('Realme', 'devices/realme.png', Icons.smartphone),
    'E2:5A:76': VendorInfo('Realme', 'devices/realme.png', Icons.smartphone),

    // OnePlus
    '44:24:E8': VendorInfo('OnePlus', 'devices/oneplus.png', Icons.smartphone),
    '70:5A:14': VendorInfo('OnePlus', 'devices/oneplus.png', Icons.smartphone),

    // Google
    '1C:65:9D': VendorInfo('Google', 'devices/google.png', Icons.phone_android),
    '40:4E:36': VendorInfo('Google', 'devices/google.png', Icons.phone_android),
    '7C:96:82': VendorInfo('Google', 'devices/google.png', Icons.phone_android),
    'A4:BB:6D': VendorInfo('Google', 'devices/google.png', Icons.phone_android),
    'F4:F5:DB': VendorInfo('Google', 'devices/google.png', Icons.phone_android),

    // Asus
    '00:1A:A0': VendorInfo('ASUS', 'devices/asus.png', Icons.computer),
    '04:D4:C4': VendorInfo('ASUS', 'devices/asus.png', Icons.computer),
    '1C:B7:2C': VendorInfo('ASUS', 'devices/asus.png', Icons.computer),
    '38:2C:80': VendorInfo('ASUS', 'devices/asus.png', Icons.computer),
    'AC:22:0B': VendorInfo('ASUS', 'devices/asus.png', Icons.computer),

    // Dell
    '00:08:74': VendorInfo('Dell', 'devices/dell.png', Icons.laptop),
    '00:0E:EC': VendorInfo('Dell', 'devices/dell.png', Icons.laptop),
    '00:1B:21': VendorInfo('Dell', 'devices/dell.png', Icons.laptop),
    '00:1E:C9': VendorInfo('Dell', 'devices/dell.png', Icons.laptop),
    'D4:AE:52': VendorInfo('Dell', 'devices/dell.png', Icons.laptop),

    // HP
    '00:0E:7F': VendorInfo('HP', 'devices/hp.png', Icons.laptop),
    '00:15:60': VendorInfo('HP', 'devices/hp.png', Icons.laptop),
    '00:17:A4': VendorInfo('HP', 'devices/hp.png', Icons.laptop),
    '00:19:B9': VendorInfo('HP', 'devices/hp.png', Icons.laptop),
    '00:1F:29': VendorInfo('HP', 'devices/hp.png', Icons.laptop),
    '3C:A8:2A': VendorInfo('HP', 'devices/hp.png', Icons.laptop),

    // Lenovo
    '00:0C:76': VendorInfo('Lenovo', 'devices/lenovo.png', Icons.laptop),
    '00:1E:67': VendorInfo('Lenovo', 'devices/lenovo.png', Icons.laptop),
    '00:21:CC': VendorInfo('Lenovo', 'devices/lenovo.png', Icons.laptop),
    '00:E0:6C': VendorInfo('Lenovo', 'devices/lenovo.png', Icons.laptop),
    'F4:6D:03': VendorInfo('Lenovo', 'devices/lenovo.png', Icons.laptop),

    // Microsoft
    '00:15:5D': VendorInfo('Microsoft', 'devices/microsoft.png', Icons.computer),
    '00:1B:D6': VendorInfo('Microsoft', 'devices/microsoft.png', Icons.computer),
    'BC:D1:D3': VendorInfo('Microsoft', 'devices/microsoft.png', Icons.computer),

    // TP-Link
    '00:13:1A': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    '04:72:9F': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    '10:FE:ED': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    '34:96:72': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    '40:16:9E': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    '50:C7:BF': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    'AC:15:A2': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),
    'F4:EC:38': VendorInfo('TP-Link', 'devices/tplink.png', Icons.router),

    // Tenda
    '00:B0:52': VendorInfo('Tenda', 'devices/tenda.png', Icons.router),
    'C8:3A:35': VendorInfo('Tenda', 'devices/tenda.png', Icons.router),
    'E0:B9:A5': VendorInfo('Tenda', 'devices/tenda.png', Icons.router),

    // D-Link
    '00:05:5D': VendorInfo('D-Link', 'devices/dlink.png', Icons.router),
    '00:0E:58': VendorInfo('D-Link', 'devices/dlink.png', Icons.router),
    '00:1B:2E': VendorInfo('D-Link', 'devices/dlink.png', Icons.router),
    '14:CC:20': VendorInfo('D-Link', 'devices/dlink.png', Icons.router),

    // Netgear
    '00:09:5B': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    '00:0F:B5': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    '00:14:6C': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    '00:24:B2': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    '2C:30:33': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    '38:EA:2A': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    'A0:21:B7': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),
    'A4:17:31': VendorInfo('Netgear', 'devices/netgear.png', Icons.router),

    // Cisco
    '00:00:0C': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:01:42': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:05:5A': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:0B:BE': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:0D:BD': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:0E:B5': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:11:BC': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:15:C7': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:16:47': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:17:94': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:18:BA': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:19:06': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1B:D0': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1C:B0': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1D:24': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1E:13': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1E:14': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1E:A5': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1F:6C': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:1F:9E': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:22:91': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:23:AB': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:24:CB': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:26:72': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
    '00:27:0D': VendorInfo('Cisco', 'devices/cisco.png', Icons.router),
  };

  /// Get vendor information from MAC address
  static VendorInfo? getVendor(String? macAddress) {
    if (macAddress == null || macAddress.isEmpty) {
      return null;
    }

    // Normalize MAC address format
    final normalized = _normalizeMac(macAddress);
    if (normalized.isEmpty) {
      return null;
    }

    // Get first 3 octets (OUI - Organizationally Unique Identifier)
    final oui = normalized.substring(0, 8).toUpperCase();

    return _vendorMap[oui];
  }

  /// Get vendor name from MAC address
  static String? getVendorName(String? macAddress) {
    return getVendor(macAddress)?.name;
  }

  /// Get device type from MAC vendor
  static String getDeviceType(String? macAddress) {
    final vendor = getVendor(macAddress);
    if (vendor == null) {
      return 'Unknown Device';
    }

    // Determine device type based on vendor
    final name = vendor.name.toLowerCase();
    if (name.contains('link') || name.contains('netgear') ||
        name.contains('cisco') || name.contains('tenda') ||
        name.contains('d-link') || name.contains('asus')) {
      return 'Router/Access Point';
    } else if (name.contains('apple') || name.contains('samsung') ||
        name.contains('xiaomi') || name.contains('oppo') ||
        name.contains('vivo') || name.contains('huawei') ||
        name.contains('realme') || name.contains('oneplus') ||
        name.contains('google')) {
      return 'Mobile Device';
    } else if (name.contains('dell') || name.contains('hp') ||
        name.contains('lenovo') || name.contains('microsoft') ||
        name.contains('asus')) {
      return 'Laptop/Computer';
    }

    return 'Network Device';
  }

  /// Check if device is likely a mobile phone
  static bool isMobileDevice(String? macAddress) {
    final deviceType = getDeviceType(macAddress);
    return deviceType == 'Mobile Device';
  }

  /// Check if device is likely a router
  static bool isRouter(String? macAddress) {
    final deviceType = getDeviceType(macAddress);
    return deviceType == 'Router/Access Point';
  }

  /// Check if device is likely a computer
  static bool isComputer(String? macAddress) {
    final deviceType = getDeviceType(macAddress);
    return deviceType == 'Laptop/Computer';
  }

  /// Get icon for device based on MAC vendor
  static IconData getDeviceIcon(String? macAddress) {
    final vendor = getVendor(macAddress);
    if (vendor != null) {
      return vendor.icon;
    }

    // Default icon based on device type
    final deviceType = getDeviceType(macAddress);
    switch (deviceType) {
      case 'Router/Access Point':
        return Icons.router;
      case 'Mobile Device':
        return Icons.smartphone;
      case 'Laptop/Computer':
        return Icons.computer;
      default:
        return Icons.devices_other;
    }
  }

  /// Get color for device type
  static int getDeviceColorHex(String? macAddress) {
    if (isMobileDevice(macAddress)) {
      return 0xFF6C63FF; // Purple for mobile
    } else if (isRouter(macAddress)) {
      return 0xFFF59E0B; // Orange for routers
    } else if (isComputer(macAddress)) {
      return 0xFF10B981; // Green for computers
    }
    return 0xFF64748B; // Gray for unknown
  }

  /// Normalize MAC address to consistent format (XX:XX:XX:XX:XX:XX)
  static String _normalizeMac(String mac) {
    // Remove all non-hex characters
    final cleaned = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');

    // Must be 12 hex characters
    if (cleaned.length != 12) {
      return '';
    }

    // Format with colons
    return '${cleaned.substring(0, 2)}:${cleaned.substring(2, 4)}:${cleaned.substring(4, 6)}:${cleaned.substring(6, 8)}:${cleaned.substring(8, 10)}:${cleaned.substring(10, 12)}';
  }
}

/// Vendor information class
class VendorInfo {
  final String name;
  final String imagePath;
  final IconData icon;

  const VendorInfo(this.name, this.imagePath, this.icon);
}
