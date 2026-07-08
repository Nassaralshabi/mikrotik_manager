import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/models.dart';
import '../../services/routeros_service.dart';
import '../../l10n/translations.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/show_feedback.dart';
import 'edit_hotspot_user_screen.dart';

class HotspotUserDetailsScreen extends StatefulWidget {
  final HotspotUser user;

  const HotspotUserDetailsScreen({super.key, required this.user});

  @override
  State<HotspotUserDetailsScreen> createState() =>
      _HotspotUserDetailsScreenState();
}

class _HotspotUserDetailsScreenState extends State<HotspotUserDetailsScreen> {
  late HotspotUser _user;
  final _routerOSService = RouterOSService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = _routerOSService.client;
      if (client != null) {
        // In a real implementation, we would fetch fresh data here
        // For now, just show we tried
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context)
                  .failedToRefresh
                  .replaceAll('%s', e.toString())),
              backgroundColor: context.appError,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'User Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: _isLoading ? null : _refreshUserData,
            ),
            IconButton(
              icon: Icon(Icons.edit_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditHotspotUserScreen(user: _user.toMap()),
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserHeader(),
                    SizedBox(height: 16),
                    _buildStatusCard(),
                    SizedBox(height: 16),
                    _buildInfoSection(),
                    SizedBox(height: 16),
                    _buildStatsSection(),
                    SizedBox(height: 16),
                    _buildActionsSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appPrimary,
                    context.appPrimary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ID: ${_user.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.7),
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _user.active
          ? context.appPrimary.withValues(alpha: 0.1)
          : context.appOnSurface.withValues(alpha: 0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _user.active
              ? context.appPrimary.withValues(alpha: 0.5)
              : context.appOnSurface.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              _user.active ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: _user.active
                  ? context.appPrimary
                  : context.appOnSurface.withValues(alpha: 0.5),
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.7),
                        ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _user.active ? 'Active' : 'Inactive',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _user.active
                              ? context.appPrimary
                              : context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            if (_user.active && _user.uptime != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _user.uptime!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 12),
        Card(
          color: context.appSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                Icons.badge_rounded,
                'Username',
                _user.name,
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
              _buildInfoTile(
                Icons.card_membership_rounded,
                'Profile',
                _user.profile,
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
              _buildInfoTile(
                Icons.fingerprint_rounded,
                'User ID',
                _user.id,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usage Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 12),
        Card(
          color: context.appSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildStatTile(
                Icons.upload_rounded,
                'Bytes Out',
                _formatBytes(_user.bytesOut),
                Colors.green,
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
              _buildStatTile(
                Icons.download_rounded,
                'Bytes In',
                _formatBytes(_user.bytesIn),
                Colors.blue,
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
                indent: 16,
                endIndent: 16,
              ),
              _buildStatTile(
                Icons.data_usage_rounded,
                'Total Data Used',
                _user.dataUsed,
                context.appPrimary,
              ),
              if (_user.limitBytesIn != null ||
                  _user.limitBytesOut != null) ...[
                Divider(
                  height: 1,
                  color: context.appOnSurface.withValues(alpha: 0.1),
                  indent: 16,
                  endIndent: 16,
                ),
                _buildStatTile(
                  Icons.rule_rounded,
                  'Data Limit',
                  'Set',
                  Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 12),
        Card(
          color: context.appSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: context.appPrimary,
                ),
                title: Text(AppStrings.of(context).editUserTitle),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditHotspotUserScreen(user: _user.toMap()),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              ListTile(
                leading: Icon(
                  Icons.wifi_rounded,
                  color: context.appPrimary,
                ),
                title: Text(_user.active
                    ? 'Remove User from Hotspot'
                    : 'Add User to Hotspot'),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${_user.active ? "Remove" : "Add"} functionality coming soon')),
                  );
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: context.appError,
                ),
                title: Text(AppStrings.of(context).deleteUser),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  _confirmDeleteUser();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: context.appPrimary,
        size: 20,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
      ),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildStatTile(
      IconData icon, String label, String value, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: color,
        size: 20,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
      ),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'N/A';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  void _confirmDeleteUser() async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      itemName: _user.name,
      itemType: 'user',
    );
    if (confirmed) {
      _deleteUser();
    }
  }

  Future<void> _deleteUser() async {
    try {
      final client = _routerOSService.client;
      if (client != null) {
        await client.removeHotspotUser(_user.id);
        if (mounted) {
          FeedbackUtils.showSuccess(
            context,
            AppStrings.of(context).userDeletedMsg(_user.name),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          AppStrings.of(context)
              .failedToDeleteUser
              .replaceAll('%s', e.toString()),
        );
      }
    }
  }
}
