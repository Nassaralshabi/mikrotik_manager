import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../l10n/translations.dart';

class HotspotHostDetailsScreen extends ConsumerWidget {
  final HotspotHost host;

  const HotspotHostDetailsScreen({
    super.key,
    required this.host,
  });

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatPackets(int? packets) {
    if (packets == null) return 'N/A';
    if (packets >= 1000000) return '${(packets / 1000000).toStringAsFixed(1)}M';
    if (packets >= 1000) return '${(packets / 1000).toStringAsFixed(1)}K';
    return packets.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/main/hosts'),
          ),
          title: Text(AppStrings.of(context).hostDetails),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: () async {
                // Trigger refresh of hotspot hosts data
                await ref.read(hotspotHostsProvider.notifier).refresh();
                // Navigate back to show refreshed data
                if (context.mounted) {
                  context.go('/main/hosts');
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              SizedBox(height: 16),
              _buildStatusCard(context),
              SizedBox(height: 16),
              _buildConnectionDetailsCard(context),
              SizedBox(height: 16),
              if (host.bytesIn != null || host.bytesOut != null) ...[
                _buildTrafficCard(context),
                SizedBox(height: 16),
              ],
              _buildActionsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      color: context.appCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host.deviceName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (host.macAddress != null) ...[
                    SizedBox(height: 4),
                    Text(
                      host.macAddress!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.7),
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Card(
      color: context.appCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatusBadge(),
                SizedBox(width: 12),
                if (host.user != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: context.appPrimary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          host.user!,
                          style: TextStyle(
                            color: context.appPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDetailsCard(BuildContext context) {
    return Card(
      color: context.appCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Details',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            _buildDetailTile(
                context, Icons.router_rounded, 'Server', host.server ?? 'N/A'),
            if (host.macAddress != null)
              _buildDetailTile(context, Icons.badge_rounded, 'MAC Address',
                  host.macAddress!),
            if (host.address != null)
              _buildDetailTile(
                  context, Icons.computer_rounded, 'IP Address', host.address!),
            if (host.uptime != null)
              _buildDetailTile(
                  context, Icons.access_time_rounded, 'Uptime', host.uptime!),
            if (host.idleTime != null)
              _buildDetailTile(
                  context, Icons.timer_outlined, 'Idle Time', host.idleTime!),
            if (host.comment != null)
              _buildDetailTile(
                  context, Icons.comment_rounded, 'Comment', host.comment!),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficCard(BuildContext context) {
    final totalBytes = (host.bytesIn ?? 0) + (host.bytesOut ?? 0);
    final totalPackets = (host.packetsIn ?? 0) + (host.packetsOut ?? 0);

    return Card(
      color: context.appCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traffic Statistics',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTrafficTile(
                    Icons.download_rounded,
                    'Download',
                    _formatBytes(host.bytesIn),
                    '${_formatPackets(host.packetsIn)} pkts',
                    context.appSecondary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTrafficTile(
                    Icons.upload_rounded,
                    'Upload',
                    _formatBytes(host.bytesOut),
                    '${_formatPackets(host.packetsOut)} pkts',
                    context.appPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Data',
                        style: TextStyle(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatBytes(totalBytes),
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Packets',
                        style: TextStyle(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatPackets(totalPackets),
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      color: context.appCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: context.appPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 16),
            _buildActionButton(
              Icons.logout_rounded,
              'Remove Host',
              Colors.red,
              () {
                _showRemoveDialog(context);
              },
            ),
            SizedBox(height: 12),
            _buildActionButton(
              Icons.block_rounded,
              'Block MAC Address',
              Colors.orange,
              () {
                _showBlockDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: context.appOnSurface.withValues(alpha: 0.5)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficTile(
    IconData icon,
    String label,
    String value,
    String subtext,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              color: color.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final text = host.statusText;
    final color = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (host.bypassed) return const Color(0xFFF59E0B); // Amber
    if (host.authorized) return const Color(0xFF10B981); // Emerald
    return const Color(0xFF64748B); // Slate
  }

  IconData _getStatusIcon() {
    if (host.bypassed) return Icons.lock_open;
    if (host.authorized) return Icons.lock;
    return Icons.lock_outline;
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).removeHost),
        content: Text(AppStrings.of(context)
            .removeHostConfirmation
            .replaceAll('%s', host.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(AppStrings.of(context).hostRemovedSuccessfully)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.of(context).remove),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).blockMacAddress),
        content: Text(AppStrings.of(context)
            .blockMacConfirmation
            .replaceAll('%s', host.macAddress ?? 'N/A')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppStrings.of(context).macAddressBlocked)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(AppStrings.of(context).block),
          ),
        ],
      ),
    );
  }
}
