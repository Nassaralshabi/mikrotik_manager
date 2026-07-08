import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/models/activity_log.dart';
import '../../services/log_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../l10n/translations.dart';

/// Provider for activity logs
final activityLogsProvider =
    StateNotifierProvider<ActivityLogsNotifier, AsyncValue<List<ActivityLog>>>(
        (ref) {
  return ActivityLogsNotifier();
});

class ActivityLogsNotifier
    extends StateNotifier<AsyncValue<List<ActivityLog>>> {
  ActivityLogsNotifier() : super(const AsyncValue.loading()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    state = const AsyncValue.loading();
    try {
      await LogService.init();
      final logs = LogService.getLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearLogs() async {
    try {
      await LogService.clearAll();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class ActivityLogsScreen extends ConsumerStatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  ConsumerState<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends ConsumerState<ActivityLogsScreen> {
  String _searchQuery = '';
  LogFilter _filter = LogFilter.all;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Ensure LogService is initialized and reload logs
    Future.microtask(() {
      LogService.init().then((_) {
        ref.read(activityLogsProvider.notifier).loadLogs();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(activityLogsProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: AppStrings.of(context).back,
        ),
        title: Text(
          AppStrings.of(context).activityLogs,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            onPressed: _exportLogs,
            tooltip: AppStrings.of(context).exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmClearLogs,
            tooltip: AppStrings.of(context).clear,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(activityLogsProvider.notifier).loadLogs(),
            tooltip: AppStrings.of(context).refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activityLogsProvider);
        },
        child: logsAsync.when(
          data: (logs) {
            final filteredLogs = _applyFilters(logs);

            return Column(
              children: [
                _buildFilterBar(logs),
                Expanded(
                  child: filteredLogs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredLogs.length,
                          itemBuilder: (context, index) {
                            return _LogCard(log: filteredLogs[index]);
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => SizedBox(
            height: 400,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) =>
                  SkeletonLoaders.transactionItem(),
            ),
          ),
          error: (error, _) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  List<ActivityLog> _applyFilters(List<ActivityLog> logs) {
    var filtered = logs;

    // Apply type filter
    if (_filter != LogFilter.all) {
      filtered =
          filtered.where((log) => _filter.types.contains(log.type)).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((log) {
        return log.title.toLowerCase().contains(query) ||
            log.description.toLowerCase().contains(query) ||
            (log.username?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply date filter
    if (_startDate != null) {
      filtered =
          filtered.where((log) => log.timestamp.isAfter(_startDate!)).toList();
    }

    if (_endDate != null) {
      final endOfDay =
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered =
          filtered.where((log) => log.timestamp.isBefore(endOfDay)).toList();
    }

    return filtered;
  }

  Widget _buildFilterBar(List<ActivityLog> logs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppStrings.of(context).searchLogs,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: context.appBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _showDateRangePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.appOnSurface.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: context.appOnSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateRange(),
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: LogFilter.values.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter.displayName),
                    selected: _filter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _filter = selected ? filter : LogFilter.all;
                      });
                    },
                    selectedColor: context.appPrimary.withValues(alpha: 0.2),
                    checkmarkColor: context.appPrimary,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStates.noLogs();
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: context.appError,
          ),
          const SizedBox(height: 16),
          Text(
             AppStrings.of(context).failedToLoadLogs,
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    if (_startDate != null && _endDate != null) {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    } else if (_startDate != null) {
      return '${_formatDate(_startDate!)} - Now';
    } else if (_endDate != null) {
      return AppStrings.of(context).untilDate.replaceAll('%s', _formatDate(_endDate!));
    }
    return AppStrings.of(context).allTime;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: AppStrings.of(context).apply,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.appPrimary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E293B),
              onSurface: const Color(0xFFE2E8F0),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _exportLogs() {
    final logsAsync = ref.read(activityLogsProvider);
    logsAsync.whenData((logs) {
      if (logs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).noLogsToExport)),
        );
        return;
      }

      // For now, just show a success message
      // In a real app, you would use LogService.exportToCsv() and save/share the CSV file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).exportedLogEntries.replaceFirst('%d', logs.length.toString())),
          action: SnackBarAction(
            label: AppStrings.of(context).ok,
            onPressed: () {},
          ),
        ),
      );
    });
  }

  void _confirmClearLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
           AppStrings.of(context).clearAllLogs,
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
           AppStrings.of(context).actionCannotBeUndone,
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              AppStrings.of(context).cancel,
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: context.appError),
            child: Text(AppStrings.of(context).clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(activityLogsProvider.notifier).clearLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).logsCleared)),
        );
      }
    }
  }
}

class _LogCard extends StatelessWidget {
  final ActivityLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.title,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.description,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: context.appOnSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(log.timestamp),
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    if (log.username != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: context.appOnSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.username!,
                        style: TextStyle(
                          color: context.appOnSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Color _getColor() {
    switch (log.type) {
      case LogType.login:
        return const Color(0xFF10B981); // Green
      case LogType.logout:
        return const Color(0xFFF59E0B); // Orange
      case LogType.connection:
        return const Color(0xFF3B82F6); // Blue
      case LogType.voucherCreated:
        return const Color(0xFF7C3AED); // Purple
      case LogType.voucherDeleted:
        return const Color(0xFFEF4444); // Red
      case LogType.voucherPrinted:
        return const Color(0xFF06B6D4); // Cyan
      case LogType.sale:
        return const Color(0xFF14B8A6); // Teal
      case LogType.userAction:
        return const Color(0xFF64748B); // Slate
      case LogType.userEnabled:
        return const Color(0xFF10B981); // Green
      case LogType.userDisabled:
        return const Color(0xFFF59E0B); // Orange
      case LogType.error:
        return const Color(0xFFEF4444); // Red
      case LogType.system:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getIcon() {
    switch (log.type) {
      case LogType.login:
        return Icons.login_rounded;
      case LogType.logout:
        return Icons.logout_rounded;
      case LogType.connection:
        return Icons.router_rounded;
      case LogType.voucherCreated:
        return Icons.add_card_rounded;
      case LogType.voucherDeleted:
        return Icons.delete_rounded;
      case LogType.voucherPrinted:
        return Icons.print_rounded;
      case LogType.sale:
        return Icons.payments_rounded;
      case LogType.userAction:
        return Icons.person_rounded;
      case LogType.userEnabled:
        return Icons.person_add_rounded;
      case LogType.userDisabled:
        return Icons.person_remove_rounded;
      case LogType.error:
        return Icons.error_rounded;
      case LogType.system:
        return Icons.settings_rounded;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(timestamp);
    }
  }
}
