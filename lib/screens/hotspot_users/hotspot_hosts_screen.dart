import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../widgets/skeleton_loader.dart';
import '../../l10n/translations.dart';

enum HostFilter {
  all,
  authorized,
  unauthorized,
  bypassed,
}

class HotspotHostsScreen extends ConsumerStatefulWidget {
  const HotspotHostsScreen({super.key});

  @override
  ConsumerState<HotspotHostsScreen> createState() => _HotspotHostsScreenState();
}

class _HotspotHostsScreenState extends ConsumerState<HotspotHostsScreen> {
  HostFilter _selectedFilter = HostFilter.all;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HotspotHost> _filterHosts(List<HotspotHost> hosts) {
    var filtered = hosts;

    // Apply status filter
    switch (_selectedFilter) {
      case HostFilter.authorized:
        filtered = filtered.where((h) => h.authorized && !h.bypassed).toList();
        break;
      case HostFilter.unauthorized:
        filtered = filtered.where((h) => !h.authorized && !h.bypassed).toList();
        break;
      case HostFilter.bypassed:
        filtered = filtered.where((h) => h.bypassed).toList();
        break;
      case HostFilter.all:
        break;
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((h) =>
              h.displayName.toLowerCase().contains(query) ||
              (h.address?.toLowerCase().contains(query) ?? false) ||
              (h.macAddress?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final hostsAsync = ref.watch(hotspotHostsProvider);

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
          title: Text(AppStrings.of(context).hotspotHosts),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(hotspotHostsProvider.notifier).refresh();
          },
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(
                child: hostsAsync.when(
                  data: (hosts) {
                    final filteredHosts = _filterHosts(hosts);
                    if (filteredHosts.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildHostsList(filteredHosts);
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.appSurface,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by IP, MAC, or user...',
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
          SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HostFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : HostFilter.all;
                      });
                    },
                    selectedColor: context.appPrimary.withValues(alpha: 0.2),
                    checkmarkColor: context.appPrimary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? context.appPrimary
                          : context.appOnSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(HostFilter filter) {
    switch (filter) {
      case HostFilter.all:
        return 'All';
      case HostFilter.authorized:
        return 'Authorized';
      case HostFilter.unauthorized:
        return 'Unauthorized';
      case HostFilter.bypassed:
        return 'Bypassed';
    }
  }

  Widget _buildHostsList(List<HotspotHost> hosts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hosts.length,
      itemBuilder: (context, index) {
        return _buildHostCard(hosts[index]);
      },
    );
  }

  Widget _buildHostCard(HotspotHost host) {
    return InkWell(
      onTap: () => context.push('/main/hosts/${host.id}', extra: host),
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
                      color: _getStatusColor(host).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(host),
                      color: _getStatusColor(host),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          host.deviceName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: context.appOnSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (host.macAddress != null)
                          Text(
                            host.macAddress!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.7),
                                      fontFamily: 'monospace',
                                    ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(host),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: context.appOnSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
              if (host.uptime != null || host.idleTime != null) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (host.address != null)
                      _buildInfoChip(
                        Icons.computer_rounded,
                        'IP',
                        host.address!,
                      ),
                    if (host.uptime != null)
                      _buildInfoChip(
                        Icons.access_time,
                        'Uptime',
                        host.uptime!,
                      ),
                    if (host.idleTime != null)
                      _buildInfoChip(
                        Icons.timer_outlined,
                        'Idle',
                        host.idleTime!,
                      ),
                  ],
                ),
              ],
              if (host.comment != null) ...[
                SizedBox(height: 8),
                Text(
                  host.comment!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appOnSurface.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(HotspotHost host) {
    final text = host.statusText;
    final color = _getStatusColor(host);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: context.appOnSurface.withValues(alpha: 0.5)),
        SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(HotspotHost host) {
    if (host.bypassed) return const Color(0xFFF59E0B); // Amber
    if (host.authorized) return const Color(0xFF10B981); // Emerald
    return const Color(0xFF64748B); // Slate
  }

  IconData _getStatusIcon(HotspotHost host) {
    if (host.bypassed) return Icons.lock_open;
    if (host.authorized) return Icons.lock;
    return Icons.lock_outline;
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
            Icons.error_outline,
            color: context.appError,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading hosts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appOnSurface,
                ),
          ),
          SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appOnSurface.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lan_outlined,
            color: context.appOnSurface.withValues(alpha: 0.3),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No hosts found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appOnSurface,
                ),
          ),
          SizedBox(height: 8),
          Text(
            'Try changing filters or search terms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appOnSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
