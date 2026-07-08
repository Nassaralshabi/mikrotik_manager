import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/models.dart';
import '../../utils/mac_vendor_detector.dart';
import '../../l10n/translations.dart';

class HotspotHostDetailScreen extends StatelessWidget {
  final HotspotHost host;

  const HotspotHostDetailScreen({
    super.key,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    final vendor = MacVendorDetector.getVendor(host.macAddress);
    final deviceType = MacVendorDetector.getDeviceType(host.macAddress);
    final deviceIcon = MacVendorDetector.getDeviceIcon(host.macAddress);
    final vendorName = vendor?.name ?? 'Unknown Vendor';
    final deviceColor =
        Color(MacVendorDetector.getDeviceColorHex(host.macAddress));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(AppStrings.of(context).deviceDetails),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // Refresh data
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header Card
              _buildDeviceHeaderCard(
                  context, deviceIcon, vendorName, deviceType, deviceColor),
              SizedBox(height: 16),

              // Connection Status Card
              _buildConnectionStatusCard(context),
              SizedBox(height: 16),

              // Network Information Card
              _buildNetworkInfoCard(context, deviceType, deviceColor),
              SizedBox(height: 16),

              // Data Usage Card
              if (host.bytesIn != null || host.bytesOut != null)
                _buildDataUsageCard(context),
              SizedBox(height: 16),

              // Vendor Information Card
              _buildVendorInfoCard(context, vendor, deviceColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceHeaderCard(
    BuildContext context,
    IconData deviceIcon,
    String vendorName,
    String deviceType,
    Color deviceColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deviceColor.withValues(alpha: 0.2),
            deviceColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deviceColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Device Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: deviceColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              deviceIcon,
              size: 48,
              color: deviceColor,
            ),
          ),
          SizedBox(height: 16),

          // Device Name
          Text(
            host.deviceName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),

          // Vendor Name
          Text(
            vendorName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: deviceColor,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),

          // Device Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: deviceColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: deviceColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              deviceType,
              style: TextStyle(
                color: deviceColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard(BuildContext context) {
    final statusColor = host.bypassed
        ? Color(0xFFF59E0B)
        : host.authorized
            ? Color(0xFF10B981)
            : Color(0xFF64748B);

    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: statusColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Connection Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Status Badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        host.bypassed
                            ? Icons.lock_open
                            : host.authorized
                                ? Icons.lock
                                : Icons.lock_outline,
                        size: 16,
                        color: statusColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        host.statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    host.statusDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ),
              ],
            ),

            // User Info
            if (host.user != null) ...[
              SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.person,
                'Logged in as',
                host.user!,
              ),
            ],

            // Uptime
            if (host.uptime != null)
              _buildInfoRow(
                context,
                Icons.access_time,
                'Connected for',
                host.uptime!,
              ),

            // Idle Time
            if (host.idleTime != null)
              _buildInfoRow(
                context,
                Icons.timer_outlined,
                'Idle for',
                host.idleTime!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfoCard(
    BuildContext context,
    String deviceType,
    Color deviceColor,
  ) {
    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: context.appPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Network Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // IP Address
            if (host.address != null)
              _buildInfoRow(
                context,
                Icons.computer,
                'IP Address',
                host.address!,
              ),

            // MAC Address
            if (host.macAddress != null)
              _buildInfoRow(
                context,
                Icons.fingerprint,
                'MAC Address',
                host.macAddress!,
                isCode: true,
              ),

            // Server
            if (host.server != null)
              _buildInfoRow(
                context,
                Icons.router,
                'Hotspot Server',
                host.server!,
              ),

            // Hostname from DHCP
            if (host.hostname != null && host.hostname != host.deviceName)
              _buildInfoRow(
                context,
                Icons.dns,
                'DHCP Hostname',
                host.hostname!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataUsageCard(BuildContext context) {
    final bytesIn = host.bytesIn ?? 0;
    final bytesOut = host.bytesOut ?? 0;
    final totalBytes = bytesIn + bytesOut;

    final downloadMB = bytesIn / (1024 * 1024);
    final uploadMB = bytesOut / (1024 * 1024);
    final totalMB = totalBytes / (1024 * 1024);

    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_usage, color: context.appPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Data Usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Spacer(),
                Text(
                  '${totalMB.toStringAsFixed(2)} MB',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.appPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Download
            _buildDataRow(
              context,
              Icons.arrow_downward,
              'Download',
              '${downloadMB.toStringAsFixed(2)} MB',
              Colors.green,
              bytesIn / totalBytes,
            ),

            SizedBox(height: 12),

            // Upload
            _buildDataRow(
              context,
              Icons.arrow_upward,
              'Upload',
              '${uploadMB.toStringAsFixed(2)} MB',
              Colors.blue,
              bytesOut / totalBytes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfoCard(
    BuildContext context,
    VendorInfo? vendor,
    Color deviceColor,
  ) {
    return Card(
      elevation: 0,
      color: context.appCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: deviceColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Device Manufacturer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (vendor != null) ...[
              _buildInfoRow(
                context,
                Icons.business_center,
                'Vendor',
                vendor.name,
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.devices_other,
                'Device Category',
                MacVendorDetector.isMobileDevice(host.macAddress)
                    ? 'Mobile Device'
                    : MacVendorDetector.isRouter(host.macAddress)
                        ? 'Network Infrastructure'
                        : 'Computer/Peripheral',
              ),
            ] else ...[
              _buildInfoRow(
                context,
                Icons.help_outline,
                'Vendor',
                'Unknown',
              ),
              SizedBox(height: 8),
              Text(
                'MAC vendor not found in database. This device may use a less common network adapter.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isCode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: context.appOnSurface.withValues(alpha: 0.5)),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: context.appOnSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    double percentage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// Extension on HotspotHost for display helpers
extension HotspotHostExtension on HotspotHost {
  String get statusText {
    if (bypassed) return 'Bypassed';
    if (authorized) return 'Authorized';
    return 'Unauthorized';
  }

  String get statusDescription {
    if (bypassed) {
      return 'This device can access the network without login (bypassed)';
    }
    if (authorized) {
      return 'This device is authenticated and connected';
    }
    return 'This device needs to login to access the network';
  }
}
