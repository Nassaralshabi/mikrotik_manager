import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/cached_qr_image.dart';
import '../../theme/app_theme.dart';
import '../../services/models/voucher.dart';
import '../../services/log_service.dart';
import '../../services/cache_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/voucher_printer.dart';
import '../../providers/app_providers.dart';
import '../../utils/filter_utils.dart';
import '../../utils/performance_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/back_to_top_fab.dart';
import 'voucher_detail_screen.dart';
import '../../providers/bulk_voucher_provider.dart';
import '../../l10n/translations.dart';

class VouchersListScreen extends ConsumerStatefulWidget {
  const VouchersListScreen({super.key});

  @override
  ConsumerState<VouchersListScreen> createState() => _VouchersListScreenState();
}

class _VouchersListScreenState extends ConsumerState<VouchersListScreen> {
  String _searchQuery = '';
  VoucherFilter _filter = VoucherFilter.all;
  VoucherSort? _currentSort;
  bool _isSelectionMode = false;
  final Set<String> _selectedVoucherIds = {};
  final ScrollController _scrollController = ScrollController();
  final Debouncer _searchDebouncer =
      Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vouchersProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _applySort(VoucherSort sort) {
    setState(() {
      _currentSort = sort;
    });
    ref.read(vouchersProvider.notifier).sortVouchers(sort);
  }

  List<Widget> _buildNormalActions(AsyncValue<List<Voucher>> vouchersAsync) {
    return [
      IconButton(
        icon: Icon(Icons.refresh_rounded),
        onPressed: vouchersAsync.isLoading ? null : _refreshVouchers,
        tooltip: 'Refresh',
      ),
      IconButton(
        icon: Icon(Icons.print_rounded),
        onPressed: vouchersAsync.isLoading ? null : _printAllVouchers,
        tooltip: 'Print All',
      ),
      IconButton(
        icon: Icon(Icons.checklist_rounded),
        onPressed: _toggleSelectionMode,
        tooltip: 'Select multiple',
      ),
      PopupMenuButton<VoucherSort>(
        icon: Icon(Icons.more_vert_rounded),
        onSelected: _applySort,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: VoucherSort.newest,
            child: Row(
              children: [
                if (_currentSort == VoucherSort.newest)
                  Icon(Icons.check, size: 18, color: context.appPrimary),
                SizedBox(width: _currentSort == VoucherSort.newest ? 8 : 24),
                Text(AppStrings.of(context).newestFirst),
              ],
            ),
          ),
          PopupMenuItem(
            value: VoucherSort.oldest,
            child: Row(
              children: [
                if (_currentSort == VoucherSort.oldest)
                  Icon(Icons.check, size: 18, color: context.appPrimary),
                SizedBox(width: _currentSort == VoucherSort.oldest ? 8 : 24),
                Text(AppStrings.of(context).oldestFirst),
              ],
            ),
          ),
          PopupMenuItem(
            value: VoucherSort.az,
            child: Row(
              children: [
                if (_currentSort == VoucherSort.az)
                  Icon(Icons.check, size: 18, color: context.appPrimary),
                SizedBox(width: _currentSort == VoucherSort.az ? 8 : 24),
                Text(AppStrings.of(context).aToZ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: VoucherSort.az,
            child: Row(
              children: [
                Icon(Icons.library_books_rounded, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text('Bulk Actions', style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSelectionModeActions(
      AsyncValue<List<Voucher>> vouchersAsync) {
    return [
      if (vouchersAsync.valueOrNull != null)
        IconButton(
          icon: Icon(Icons.print_rounded),
          onPressed: vouchersAsync.isLoading ? null : _printAllVouchers,
          tooltip: 'Print All',
        ),
      if (_selectedVoucherIds.isNotEmpty)
        IconButton(
          icon: Icon(Icons.delete_rounded, color: Colors.red),
          onPressed: _confirmBulkDelete,
          tooltip: 'Delete selected',
        ),
      IconButton(
        icon: Icon(Icons.checklist_rounded),
        onPressed: _toggleSelectionMode,
        tooltip: 'Select multiple',
      ),
    ];
  }

  Future<void> _refreshVouchers() async {
    await ref.read(vouchersProvider.notifier).refresh();
  }

  Future<void> _printAllVouchers() async {
    final vouchersAsync = ref.read(vouchersProvider);
    final vouchers = vouchersAsync.valueOrNull ?? [];
    final filtered = _filterVouchers(vouchers);
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).noVouchersToPrint)),
      );
      return;
    }
    final template = ref.read(voucherTemplateProvider);
    final cache = CacheService();
    final settings = cache.getAppSettings();
    final companyName = settings?['companyName'] as String? ?? 'WiFi';
    final loginUrl = settings?['loginUrl'] as String? ?? 'http://wifi.local';
    final currency = settings?['currency'] as String? ?? 'USD';
    final currencySymbol = CurrencyData.currencies[currency]?.symbol ?? '\$';

    await VoucherPrinter.printBulkVouchers(
      context,
      filtered,
      template: template,
      companyName: companyName,
      loginUrl: loginUrl,
      currencySymbol: currencySymbol,
    );
  }

void _openBulkActions(List<Voucher> vouchers) {
    if (vouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No vouchers available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkActionsScreen(vouchers: vouchers),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedVoucherIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedVoucherIds.clear();
    });
  }

  void _toggleVoucherSelection(String voucherId) {
    setState(() {
      if (_selectedVoucherIds.contains(voucherId)) {
        _selectedVoucherIds.remove(voucherId);
        if (_selectedVoucherIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedVoucherIds.add(voucherId);
      }
    });
  }

  Future<void> _confirmBulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Delete ${_selectedVoucherIds.length} vouchers?',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'This action cannot be undone.',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bulkDeleteVouchers();
    }
  }

  Future<void> _bulkDeleteVouchers() async {
    int successCount = 0;
    int failCount = 0;
    final totalVouchers = _selectedVoucherIds.length;

    if (!mounted) return;

    late BuildContext dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return AlertDialog(
          backgroundColor: context.appSurface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'Deleting $totalVouchers vouchers...',
                style: TextStyle(color: context.appOnSurface),
              ),
            ],
          ),
        );
      },
    );

    for (final voucherId in _selectedVoucherIds) {
      try {
        await ref.read(vouchersProvider.notifier).deleteVoucher(voucherId);
        await LogService.logVoucherDeleted(voucherId, null);
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    // Exit selection mode first
    _exitSelectionMode();

    // Close progress dialog
    if (mounted) {
      Navigator.of(dialogContext).pop();
    }

    // Show snackbar after dialog is closed
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Deleted $successCount vouchers${failCount > 0 ? ' ($failCount failed)' : ''}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: failCount > 0 ? Colors.orange : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vouchersAsync = ref.watch(vouchersProvider);

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
          leading: _isSelectionMode
              ? IconButton(
                  icon: Icon(Icons.close_rounded),
                  onPressed: _exitSelectionMode,
                  tooltip: 'Exit selection',
                )
              : IconButton(
                  icon: Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/main'),
                  tooltip: 'Back',
                ),
          title: _isSelectionMode
              ? Text(AppStrings.of(context)
                  .selectedCount
                  .replaceFirst('%d', _selectedVoucherIds.length.toString()))
              : _buildTitleWithBadge(context, vouchersAsync),
          actions: _isSelectionMode
              ? _buildSelectionModeActions(vouchersAsync)
              : _buildNormalActions(vouchersAsync),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vouchersProvider);
            await ref.read(vouchersProvider.future);
          },
          child: Column(
            children: [
              // Search and Filter Bar
              _buildSearchAndFilterBar(),

              // Vouchers Grid
              Expanded(
                child: vouchersAsync.when(
                  data: (vouchers) {
                    final filteredVouchers = _filterVouchers(vouchers);
                    if (filteredVouchers.isEmpty) {
                      return vouchers.isEmpty
                          ? _buildEmptyState()
                          : _buildNoFilterResultsState();
                    }
                    return _buildVouchersGrid(filteredVouchers);
                  },
                  loading: () => SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      child: SkeletonLoaders.grid(
                        crossAxisCount: 2,
                        itemCount: 6,
                      ),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: context.appError),
                        SizedBox(height: 16),
                        Text(AppStrings.of(context).errorLoadingVouchers,
                            style: TextStyle(color: context.appOnBackground)),
                        SizedBox(height: 8),
                        Text(error.toString(),
                            style: TextStyle(
                                color: context.appOnBackground
                                    .withValues(alpha: 0.7))),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshVouchers,
                          child: Text(AppStrings.of(context).retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BackToTopFAB(scrollController: _scrollController),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'generate_voucher',
                    onPressed: () {
                      context.push('/main/users/generate');
                    },
                    backgroundColor: context.appPrimary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search vouchers...',
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _searchDebouncer.run(() {});
            },
          ),

          SizedBox(height: 12),

          // Filter Chips
          Row(
            children: VoucherFilter.values.map((filter) {
              final isSelected = _filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _filter = filter;
                    });
                  },
                  selectedColor: context.appPrimary.withValues(alpha: 0.2),
                  checkmarkColor: context.appPrimary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? context.appPrimary
                        : context.appOnSurface.withValues(alpha: 0.7),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? context.appPrimary
                        : context.appOnSurface.withValues(alpha: 0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVouchersGrid(List<Voucher> vouchers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive crossAxisCount and aspect ratio
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;
        final spacing = 12.0;
        final horizontalPadding = 16.0 * 2;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final availableWidth = screenWidth - horizontalPadding - totalSpacing;
        final itemWidth = availableWidth / crossAxisCount;
        // Height: QR area (itemWidth) + info section (approximately 100)
        final childAspectRatio = itemWidth / (itemWidth + 100);

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio.clamp(0.65, 0.85),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            final isSelected = _selectedVoucherIds.contains(voucher.username);

            return GestureDetector(
              onTap: _isSelectionMode
                  ? () => _toggleVoucherSelection(voucher.username)
                  : null,
              onLongPress:
                  _isSelectionMode ? null : () => _showDeleteDialog(voucher),
              child: Stack(
                children: [
                  _VoucherGridCard(
                    voucher: voucher,
                    isSelected: isSelected,
                    isSelectionMode: _isSelectionMode,
                  ),
                  if (_isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.appPrimary
                              : context.appSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? context.appPrimary
                                : context.appOnSurface.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteDialog(Voucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).deleteVoucherTitle,
            style: TextStyle(color: context.appOnSurface)),
        content: Text(
            AppStrings.of(context).deleteVoucherMessage(voucher.username),
            style:
                TextStyle(color: context.appOnSurface.withValues(alpha: 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.of(context).cancel,
                style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(vouchersProvider.notifier).deleteVoucher(voucher.username);
      await LogService.logVoucherDeleted(voucher.username, null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).voucherDeleted),
        ));
      }
    }
  }

  Widget _buildEmptyState() {
    return EmptyStates.noVouchers(() {
      context.push('/main/users/generate');
    });
  }

  Widget _buildNoFilterResultsState() {
    return EmptyStates.noSearchResults(_searchQuery);
  }

  List<Voucher> _filterVouchers(List<Voucher> vouchers) {
    // Apply search filter using FilterUtils
    var filtered = FilterUtils.filterBySearch<Voucher>(
      vouchers,
      _searchQuery,
      [(v) => v.username, (v) => v.password, (v) => v.profile],
    );

    // Apply status filter
    switch (_filter) {
      case VoucherFilter.active:
        filtered = filtered.where((v) => v.isActive).toList();
        break;
      case VoucherFilter.expired:
        filtered = filtered.where((v) => v.isExpired).toList();
        break;
      case VoucherFilter.all:
        break;
    }

    return filtered;
  }

  Widget _buildTitleWithBadge(
      BuildContext context, AsyncValue<List<Voucher>> vouchersAsync) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Vouchers',
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _buildCountBadge(context, vouchersAsync),
        ),
      ],
    );
  }

  Widget _buildCountBadge(
      BuildContext context, AsyncValue<List<Voucher>> vouchersAsync) {
    return vouchersAsync.when(
      data: (vouchers) {
        final active = vouchers.where((v) => v.isActive).length;
        final expired = vouchers.where((v) => v.isExpired).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.appPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$active active • $expired expired',
            style: TextStyle(
              color: context.appPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _VoucherGridCard extends StatelessWidget {
  final Voucher voucher;
  final bool isSelected;
  final bool isSelectionMode;

  const _VoucherGridCard({
    required this.voucher,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = voucher.isExpired;

    return InkWell(
      onTap: isSelectionMode
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoucherDetailScreen(voucher: voucher),
                ),
              );
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.appPrimary.withValues(alpha: 0.2),
                    context.appPrimary.withValues(alpha: 0.1),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isExpired
                      ? [
                          context.appCard.withValues(alpha: 0.5),
                          context.appCard,
                        ]
                      : [
                          context.appCard,
                          context.appCard.withValues(alpha: 0.8),
                        ],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? context.appPrimary
                : isExpired
                    ? context.appError.withValues(alpha: 0.3)
                    : context.appPrimary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code Section
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CachedQrImage(
                    data: voucher.qrData,
                    size: 100,
                    foregroundColor:
                        isExpired ? Colors.grey : context.appPrimary,
                  ),
                ),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    voucher.username,
                    style: TextStyle(
                      color: isExpired
                          ? context.appOnSurface.withValues(alpha: 0.5)
                          : context.appOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Password (if different)
                  if (voucher.username != voucher.password) ...[
                    SizedBox(height: 2),
                    Text(
                      voucher.password,
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: 8),

                  // Status Badge - disabled on MikroTik shows as Expired (voucher was disabled/expired)
                  Row(
                    children: [
                      StatusBadge(
                        status: voucher.isExpired
                            ? VoucherStatus.expired
                            : voucher.isDisabledOnly
                                ? VoucherStatus.disabled
                                : VoucherStatus.active,
                        showLabel: true,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                      ),
                      const Spacer(),
                      // Remaining time
                      if (voucher.remainingSeconds != null &&
                          voucher.remainingSeconds! > 0) ...[
                        Icon(Icons.timer_outlined,
                            size: 12, color: context.appPrimary),
                        const SizedBox(width: 2),
                        Text(
                          voucher.remainingTimeDisplay,
                          style: TextStyle(
                            color: context.appPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: context.appOnSurface.withValues(alpha: 0.3)),
                    ],
                  ),

                  SizedBox(height: 4),

                  // Profile
                  Text(
                    voucher.profile.toUpperCase(),
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum VoucherFilter {
  all('All'),
  active('Active'),
  expired('Expired');

  const VoucherFilter(this.label);
  final String label;
}

enum VoucherSort {
  newest,
  oldest,
  az,
}
