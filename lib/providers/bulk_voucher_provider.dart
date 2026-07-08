import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../services/models/voucher.dart';
import '../../services/cache_service.dart';
import '../../providers/app_providers.dart';

class BulkVoucherState {
  final Set<String> selectedUsernames;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const BulkVoucherState({
    this.selectedUsernames = const {},
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  BulkVoucherState copyWith({
    Set<String>? selectedUsernames,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return BulkVoucherState(
      selectedUsernames: selectedUsernames ?? this.selectedUsernames,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  int get count => selectedUsernames.length;
  bool get hasSelection => selectedUsernames.isNotEmpty;
}

class BulkVoucherNotifier extends StateNotifier<BulkVoucherState> {
  final Ref _ref;

  BulkVoucherNotifier(this._ref) : super(const BulkVoucherState());

  void toggleSelection(String username) {
    final current = Set<String>.from(state.selectedUsernames);
    if (current.contains(username)) {
      current.remove(username);
    } else {
      current.add(username);
    }
    state = state.copyWith(selectedUsernames: current);
  }

  void selectAll(List<Voucher> vouchers) {
    final allUsernames = vouchers.map((v) => v.username).toSet();
    state = state.copyWith(selectedUsernames: allUsernames);
  }

  void clearSelection() {
    state = state.copyWith(selectedUsernames: {});
  }

  Future<void> extendValidity(String additionalTime) async {
    if (!state.hasSelection) return;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final service = _ref.read(routerOSServiceProvider);
      final client = service.client;

      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not connected to RouterOS',
        );
        return;
      }

      // Get all hotspot users
      final users = await client.getHotspotUsers();

      int successCount = 0;
      for (final username in state.selectedUsernames) {
        // Find user by username
        final user = users.firstWhere(
          (u) => u['name'] == username,
          orElse: () => <String, dynamic>{},
        );

        if (user.isEmpty) continue;

        final userId = user['.id'] as String?;
        if (userId == null || userId.isEmpty) continue;

        // Get current limit-uptime
        final currentLimit = user['limit-uptime'] ?? '';
        final newLimit = _addTime(currentLimit, additionalTime);

        // Update user with new validity
        await client.updateUser(userId, {'limit-uptime': newLimit});

        successCount++;
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Extended $successCount users by $additionalTime',
      );

      // Clear selection after successful operation
      state = state.copyWith(selectedUsernames: {});

      // Refresh users list
      _ref.invalidate(hotspotUsersProvider);
      _ref.invalidate(vouchersProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to extend validity: $e',
      );
    }
  }

  String _addTime(String current, String additional) {
    if (current.isEmpty) return additional;
    if (current == 'unlimited') return additional;

    // Parse both durations and add
    final currentSeconds = _parseDuration(current);
    final additionalSeconds = _parseDuration(additional);
    final totalSeconds = currentSeconds + additionalSeconds;

    return _formatDuration(totalSeconds);
  }

  int _parseDuration(String duration) {
    if (duration.isEmpty || duration == 'unlimited') return 0;

    int total = 0;
    final match = RegExp(r'(\d+)(\w)').allMatches(duration.toLowerCase());
    for (final m in match) {
      final value = int.parse(m.group(1)!);
      final unit = m.group(2)!;
      switch (unit) {
        case 's':
          total += value;
          break;
        case 'm':
          total += value * 60;
          break;
        case 'h':
          total += value * 3600;
          break;
        case 'd':
          total += value * 86400;
          break;
      }
    }
    return total;
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) return '${days}d${hours}h';
    if (hours > 0) return '${hours}h${minutes}m';
    return '${minutes}m';
  }

  Future<String?> exportToPdf(List<Voucher> vouchers) async {
    if (vouchers.isEmpty) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final cache = CacheService();
      final settings = cache.getAppSettings();
      final companyName = settings?['companyName'] as String? ?? 'My WiFi';

      final pdf = pw.Document();

      // Filter vouchers to export
      final vouchersToExport = state.hasSelection
          ? vouchers.where((v) => state.selectedUsernames.contains(v.username)).toList()
          : vouchers;

      if (vouchersToExport.isEmpty) {
        state = state.copyWith(isLoading: false, error: 'No vouchers to export');
        return null;
      }

      // Create A4 PDF with voucher grid
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Voucher List - ${vouchersToExport.length} vouchers',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfCell('Username', isHeader: true),
                      _pdfCell('Password', isHeader: true),
                      _pdfCell('Profile', isHeader: true),
                      _pdfCell('Validity', isHeader: true),
                      _pdfCell('Status', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...vouchersToExport.map((v) => pw.TableRow(
                        children: [
                          _pdfCell(v.username),
                          _pdfCell(v.password),
                          _pdfCell(v.profile),
                          _pdfCell(v.validity ?? '-'),
                          _pdfCell(v.remainingSeconds != null &&
                                  v.remainingSeconds! > 0
                              ? 'Active'
                              : 'Inactive'),
                        ],
                      )),
                ],
              ),
            ];
          },
        ),
      );

      // Save to file
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/vouchers_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Exported ${vouchersToExport.length} vouchers to PDF',
      );

      return file.path;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to export PDF: $e',
      );
      return null;
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  Future<void> deleteSelected() async {
    if (!state.hasSelection) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = _ref.read(routerOSServiceProvider);
      final client = service.client;

      if (client == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not connected to RouterOS',
        );
        return;
      }

      // Get all hotspot users to find IDs
      final users = await client.getHotspotUsers();

      int successCount = 0;
      for (final username in state.selectedUsernames) {
        final user = users.firstWhere(
          (u) => u['name'] == username,
          orElse: () => <String, dynamic>{},
        );

        if (user.isEmpty) continue;

        final userId = user['.id'] as String?;
        if (userId == null || userId.isEmpty) continue;

        await client.deleteUser(userId);
        successCount++;

        // Also delete from local vouchers
        try {
          await _ref.read(vouchersProvider.notifier).expireVoucher(username);
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Deleted $successCount vouchers',
        selectedUsernames: {},
      );

      // Refresh
      _ref.invalidate(hotspotUsersProvider);
      _ref.invalidate(vouchersProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete: $e',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final bulkVoucherProvider =
    StateNotifierProvider<BulkVoucherNotifier, BulkVoucherState>((ref) {
  return BulkVoucherNotifier(ref);
});

// BulkActionsScreen - Main screen for bulk voucher operations
class BulkActionsScreen extends ConsumerStatefulWidget {
  final List<Voucher> vouchers;
  final String? profileFilter;

  const BulkActionsScreen({
    super.key,
    required this.vouchers,
    this.profileFilter,
  });

  @override
  ConsumerState<BulkActionsScreen> createState() => _BulkActionsScreenState();
}

class _BulkActionsScreenState extends ConsumerState<BulkActionsScreen> {
  String _selectedExtension = '1h';

  @override
  void initState() {
    super.initState();
    // Clear any previous selection
    Future.microtask(() {
      ref.read(bulkVoucherProvider.notifier).clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bulkState = ref.watch(bulkVoucherProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        title: const Text('Bulk Actions'),
        actions: [
          if (bulkState.hasSelection)
            TextButton(
              onPressed: () {
                ref.read(bulkVoucherProvider.notifier).clearSelection();
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection info
            _buildInfoCard(bulkState),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Action buttons row
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  icon: Icons.select_all_rounded,
                  label: 'Select All',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    ref.read(bulkVoucherProvider.notifier).selectAll(widget.vouchers);
                  },
                ),
                _buildActionButton(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Export PDF',
                  color: const Color(0xFFEF4444),
                  onTap: _exportPdf,
                ),
                _buildActionButton(
                  icon: Icons.delete_sweep_rounded,
                  label: 'Delete Selected',
                  color: const Color(0xFFF59E0B),
                  onTap: bulkState.hasSelection ? _confirmDelete : null,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Extend Validity Section
            Text(
              'Extend Validity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassmorphismDecoration(
                surfaceColor: context.appSurface,
                onSurfaceColor: context.appOnSurface,
                borderRadius: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add time to selected users:',
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '15m',
                      '30m',
                      '1h',
                      '2h',
                      '4h',
                      '8h',
                      '1d',
                      '3d',
                      '7d',
                    ].map((time) => ChoiceChip(
                          label: Text(time),
                          selected: _selectedExtension == time,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedExtension = time);
                            }
                          },
                        )).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: bulkState.hasSelection && !bulkState.isLoading
                          ? () => _extendValidity(_selectedExtension)
                          : null,
                      icon: bulkState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.timer_rounded),
                      label: Text(
                        bulkState.hasSelection
                            ? 'Extend ${bulkState.count} users by $_selectedExtension'
                            : 'Select users first',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Voucher List
            Text(
              'Vouchers (${widget.vouchers.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            ...widget.vouchers.map((voucher) => _buildVoucherTile(voucher)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BulkVoucherState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.hasSelection
            ? context.appPrimary.withValues(alpha: 0.1)
            : context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.hasSelection
              ? context.appPrimary.withValues(alpha: 0.3)
              : context.appOnSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.hasSelection ? Icons.check_circle : Icons.info_outline,
            color: state.hasSelection
                ? context.appPrimary
                : context.appOnSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.hasSelection
                  ? '${state.count} vouchers selected'
                  : 'Tap vouchers to select',
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: state.hasSelection ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (state.hasSelection)
            Text(
              '${state.count}',
              style: TextStyle(
                color: context.appPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.15)
              : context.appOnSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null
                ? color.withValues(alpha: 0.3)
                : context.appOnSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onTap != null
                  ? color
                  : context.appOnSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: onTap != null
                    ? color
                    : context.appOnSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherTile(Voucher voucher) {
    final bulkState = ref.watch(bulkVoucherProvider);
    final isSelected = bulkState.selectedUsernames.contains(voucher.username);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? context.appPrimary.withValues(alpha: 0.1)
            : context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? context.appPrimary
              : context.appOnSurface.withValues(alpha: 0.1),
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          ref.read(bulkVoucherProvider.notifier).toggleSelection(voucher.username);
        },
        title: Text(
          voucher.username,
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              voucher.password,
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.6),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                voucher.profile,
                style: TextStyle(
                  color: context.appPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        secondary: Icon(
          voucher.remainingSeconds != null && voucher.remainingSeconds! > 0
              ? Icons.check_circle
              : Icons.circle_outlined,
          color: voucher.remainingSeconds != null && voucher.remainingSeconds! > 0
              ? context.appSuccess
              : context.appOnSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Future<void> _extendValidity(String time) async {
    await ref.read(bulkVoucherProvider.notifier).extendValidity(time);
    final state = ref.read(bulkVoucherProvider);

    if (mounted) {
      if (state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: context.appSuccess,
          ),
        );
      } else if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: context.appError,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    final path = await ref.read(bulkVoucherProvider.notifier).exportToPdf(widget.vouchers);
    final state = ref.read(bulkVoucherProvider);

    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'PDF exported'),
          backgroundColor: context.appSuccess,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () => Share.shareXFiles([XFile(path)]),
          ),
        ),
      );
    } else if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: context.appError,
        ),
      );
    }
  }

  void _confirmDelete() {
    final bulkState = ref.read(bulkVoucherProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vouchers'),
        content: Text(
          'Are you sure you want to delete ${bulkState.count} vouchers? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(bulkVoucherProvider.notifier).deleteSelected();
              final state = ref.read(bulkVoucherProvider);

              if (mounted) {
                if (state.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: context.appSuccess,
                    ),
                  );
                  Navigator.pop(context); // Go back after delete
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.appError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}