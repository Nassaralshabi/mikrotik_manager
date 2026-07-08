import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../widgets/skeleton_loader.dart';
import '../../l10n/translations.dart';

class DhcpLeasesScreen extends ConsumerStatefulWidget {
  const DhcpLeasesScreen({super.key});

  @override
  ConsumerState<DhcpLeasesScreen> createState() => _DhcpLeasesScreenState();
}

class _DhcpLeasesScreenState extends ConsumerState<DhcpLeasesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DhcpLease> _filterLeases(List<DhcpLease> leases) {
    var filtered = leases;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((l) =>
              l.displayName.toLowerCase().contains(query) ||
              (l.address?.toLowerCase().contains(query) ?? false) ||
              (l.macAddress?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final leasesAsync = ref.watch(dhcpLeasesProvider);

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
            onPressed: () => context.go('/main'),
            tooltip: 'Back',
          ),
          title: Text(AppStrings.of(context).dhcpLeases),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dhcpLeasesProvider.notifier).silentRefresh();
          },
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: leasesAsync.when(
                  data: (leases) {
                    final filteredLeases = _filterLeases(leases);
                    if (filteredLeases.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildLeasesList(filteredLeases);
                  },
                  loading: () => _buildLoadingState(),
                  error: (error, _) => _buildErrorState(error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.appSurface,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by IP, MAC, or device name...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: context.appBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildLeasesList(List<DhcpLease> leases) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leases.length,
      itemBuilder: (context, index) {
        return _buildLeaseCard(leases[index]);
      },
    );
  }

  Widget _buildLeaseCard(DhcpLease lease) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: context.appCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lease).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.devices_rounded,
                    color: _getStatusColor(lease),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lease.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: context.appOnSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (lease.macAddress != null)
                        Text(
                          lease.macAddress!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    context.appOnSurface.withValues(alpha: 0.7),
                                fontFamily: 'monospace',
                              ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(lease),
              ],
            ),
            if (lease.address != null) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.computer_rounded,
                    'IP',
                    lease.address!,
                  ),
                  if (lease.status != null)
                    _buildInfoChip(
                      Icons.info_outline_rounded,
                      'Status',
                      lease.statusDisplay,
                    ),
                  if (lease.isDynamic == false)
                    _buildInfoChip(
                      Icons.star_rounded,
                      'Type',
                      'Static',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DhcpLease lease) {
    switch (lease.status?.toLowerCase()) {
      case 'bound':
        return Colors.green;
      case 'waiting':
        return Colors.orange;
      case 'offered':
        return Colors.blue;
      case 'freed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(DhcpLease lease) {
    Color color;
    String text;

    switch (lease.status?.toLowerCase()) {
      case 'bound':
        color = Colors.green;
        text = 'Active';
        break;
      case 'waiting':
        color = Colors.orange;
        text = 'Waiting';
        break;
      case 'offered':
        color = Colors.blue;
        text = 'Offered';
        break;
      case 'freed':
        color = Colors.red;
        text = 'Freed';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: context.appOnSurface.withValues(alpha: 0.5),
        ),
        SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No DHCP Leases Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appOnSurface.withValues(alpha: 0.7),
                ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect devices to the network to see leases',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appOnSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => SkeletonLoaders.userListItem(),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load DHCP leases',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appOnSurface,
                ),
          ),
          SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appOnSurface.withValues(alpha: 0.5),
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(dhcpLeasesProvider.notifier).silentRefresh();
            },
            icon: Icon(Icons.refresh_rounded),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
