import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/models/voucher.dart';
import '../../services/cache_service.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/voucher_printer.dart';
import '../../providers/app_providers.dart';
import '../../widgets/cached_qr_image.dart';
import '../../l10n/translations.dart';

class VoucherPreviewScreen extends ConsumerStatefulWidget {
  final List<Voucher> vouchers;
  final String profileName;
  final String? companyName;

  const VoucherPreviewScreen({
    super.key,
    required this.vouchers,
    required this.profileName,
    this.companyName,
  });

  @override
  ConsumerState<VoucherPreviewScreen> createState() =>
      _VoucherPreviewScreenState();
}

class _VoucherPreviewScreenState extends ConsumerState<VoucherPreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

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
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Generated Vouchers (${widget.vouchers.length})',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.select_all_rounded),
              onPressed: _selectAllVouchers,
              tooltip: 'Select All',
            ),
            IconButton(
              icon: Icon(Icons.share_rounded),
              onPressed: _isSharing ? null : _shareAllVouchers,
              tooltip: 'Share All',
            ),
            IconButton(
              icon: Icon(Icons.print_rounded),
              onPressed: _isSharing ? null : _printAllVouchers,
              tooltip: 'Print Vouchers',
            ),
          ],
        ),
        body: Column(
          children: [
            // Summary Card
            _buildSummaryCard(),

            // Vouchers List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.vouchers.length,
                itemBuilder: (context, index) {
                  return _VoucherCard(
                    voucher: widget.vouchers[index],
                    onCopy: () => _copyVoucher(widget.vouchers[index]),
                    onShare: () => _shareSingleVoucher(widget.vouchers[index]),
                    companyName: widget.companyName,
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isSharing ? null : _captureAndShareScreenshot,
          backgroundColor: context.appPrimary,
          foregroundColor: Colors.white,
          child: _isSharing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.print_rounded),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final activeCount = widget.vouchers.where((v) => v.isActive).length;
    final expiredCount = widget.vouchers.length - activeCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appPrimary.withValues(alpha: 0.1),
            context.appSecondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                label: 'Total',
                value: '${widget.vouchers.length}',
                icon: Icons.confirmation_number_rounded,
                color: context.appPrimary,
              ),
              _SummaryItem(
                label: 'Active',
                value: '$activeCount',
                icon: Icons.check_circle_rounded,
                color: Colors.green,
              ),
              _SummaryItem(
                label: 'Expired',
                value: '$expiredCount',
                icon: Icons.cancel_rounded,
                color: Colors.red,
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: context.appOnSurface.withValues(alpha: 0.1)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_rounded,
                  color: context.appOnSurface.withValues(alpha: 0.6), size: 16),
              SizedBox(width: 8),
              Text(
                'Profile: ${widget.profileName.toUpperCase()}',
                style: TextStyle(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectAllVouchers() {
    // Copy all vouchers to clipboard
    final buffer = StringBuffer();
    buffer.writeln('=== Generated Vouchers ===');
    buffer.writeln('Profile: ${widget.profileName}');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('Total: ${widget.vouchers.length}');
    buffer.writeln('');

    for (int i = 0; i < widget.vouchers.length; i++) {
      final voucher = widget.vouchers[i];
      buffer.writeln('${i + 1}. ${voucher.username} / ${voucher.password}');
      if (voucher.comment != null && voucher.comment!.isNotEmpty) {
        buffer.writeln('   Comment: ${voucher.comment}');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context)
              .vouchersCopied
              .replaceAll('%d', '${widget.vouchers.length}')),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: context.appPrimary,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _copyVoucher(Voucher voucher) {
    final text = 'User: ${voucher.username}\nPassword: ${voucher.password}';
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).voucherCopied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareSingleVoucher(Voucher voucher) async {
    final text =
        'WiFi Voucher\nUser: ${voucher.username}\nPassword: ${voucher.password}';
    try {
      await Share.share(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.of(context)
                  .failedToShare
                  .replaceAll('%s', e.toString()))),
        );
      }
    }
  }

  Future<void> _shareAllVouchers() async {
    final buffer = StringBuffer();
    buffer.writeln('=== WiFi Vouchers ===');
    buffer.writeln('Generated: ${DateTime.now()}');

    for (int i = 0; i < widget.vouchers.length; i++) {
      final voucher = widget.vouchers[i];
      buffer.writeln('\n${i + 1}. ${voucher.username} / ${voucher.password}');
    }

    try {
      await Share.share(buffer.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.of(context)
                  .failedToShare
                  .replaceAll('%s', e.toString()))),
        );
      }
    }
  }

  Future<void> _printAllVouchers() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final cache = CacheService();
      final settings = cache.getAppSettings();
      final companyName = settings?['companyName'] as String? ?? 'WiFi';
      final loginUrl = settings?['loginUrl'] as String? ?? 'http://wifi.local';
      final currency = settings?['currency'] as String? ?? 'USD';
      final currencySymbol = CurrencyData.currencies[currency]?.symbol ?? '\$';

      final template = ref.read(voucherTemplateProvider);
      await VoucherPrinter.printBulkVouchers(
        context,
        widget.vouchers,
        template: template,
        companyName: companyName,
        loginUrl: loginUrl,
        currencySymbol: currencySymbol,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.of(context)
                  .failedToPrint
                  .replaceAll('%s', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _captureAndShareScreenshot() async {
    setState(() {
      _isSharing = true;
    });

    try {
      // Capture the voucher list as an image
      final image = await _screenshotController.captureFromWidget(
        Material(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number_rounded,
                          color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Generated Vouchers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(AppStrings.of(context)
                        .totalVouchers
                        .replaceAll('%d', '${widget.vouchers.length}')),
                    Text(AppStrings.of(context)
                        .profileLabel
                        .replaceAll('%s', widget.profileName)),
                  ],
                ),
                SizedBox(height: 16),

                // Vouchers Grid
                ...List.generate(
                  (widget.vouchers.length + 1) ~/ 2,
                  (rowIndex) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // First voucher in row
                        if (rowIndex * 2 < widget.vouchers.length)
                          Expanded(
                            child: _buildPrintableVoucher(
                              widget.vouchers[rowIndex * 2],
                            ),
                          ),
                        if (rowIndex * 2 < widget.vouchers.length &&
                            rowIndex * 2 + 1 < widget.vouchers.length)
                          SizedBox(width: 12),
                        // Second voucher in row
                        if (rowIndex * 2 + 1 < widget.vouchers.length)
                          Expanded(
                            child: _buildPrintableVoucher(
                              widget.vouchers[rowIndex * 2 + 1],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        pixelRatio: 2.0,
        delay: Duration(milliseconds: 100),
      );

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/vouchers_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(image);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Generated ${widget.vouchers.length} vouchers',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppStrings.of(context)
                  .failedToCreateScreenshot
                  .replaceAll('%s', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Widget _buildPrintableVoucher(Voucher voucher) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CachedQrImage(
            data: voucher.qrData,
            size: 80,
          ),
          SizedBox(height: 8),
          Text(
            voucher.username,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (voucher.username != voucher.password)
            Text(
              voucher.password,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final String? companyName;

  const _VoucherCard({
    required this.voucher,
    required this.onCopy,
    required this.onShare,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = voucher.isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
          color: isExpired
              ? context.appError.withValues(alpha: 0.3)
              : context.appPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Company Name (if set)
          if (companyName != null && companyName!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Text(
                companyName!,
                style: TextStyle(
                  color: context.appPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // QR Code Section (always visible)
          InkWell(
            onTap: () => _showFullScreenQR(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isExpired
                    ? context.appError.withValues(alpha: 0.05)
                    : context.appPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Large QR Code
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedQrImage(
                      data: voucher.qrData,
                      size: 80,
                      foregroundColor:
                          isExpired ? Colors.grey : context.appPrimary,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Voucher Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.username,
                          style: TextStyle(
                            color: isExpired
                                ? context.appOnSurface.withValues(alpha: 0.5)
                                : context.appOnSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (voucher.username != voucher.password)
                          Text(
                            voucher.password,
                            style: TextStyle(
                              color: isExpired
                                  ? context.appOnSurface.withValues(alpha: 0.5)
                                  : context.appOnSurface.withValues(alpha: 0.7),
                              fontSize: 16,
                            ),
                          ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              isExpired
                                  ? Icons.cancel_rounded
                                  : Icons.check_circle_rounded,
                              size: 16,
                              color:
                                  isExpired ? context.appError : Colors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              isExpired ? 'Expired' : 'Active',
                              style: TextStyle(
                                color:
                                    isExpired ? context.appError : Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.fullscreen_rounded,
                                size: 16,
                                color: context.appOnSurface
                                    .withValues(alpha: 0.5)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 20),
                        onPressed: onCopy,
                        tooltip: 'Copy',
                        color: context.appPrimary,
                      ),
                      IconButton(
                        icon: Icon(Icons.share_rounded, size: 20),
                        onPressed: onShare,
                        tooltip: 'Share',
                        color: context.appSecondary,
                      ),
                      IconButton(
                        icon: Icon(Icons.expand_rounded, size: 20),
                        onPressed: () => _showFullScreenQR(context),
                        tooltip: 'Full Screen QR',
                        color: context.appOnSurface.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Details
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              initiallyExpanded: false,
              title: Text(
                'View Details',
                style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.expand_more_rounded,
                color: context.appOnSurface.withValues(alpha: 0.5),
              ),
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        icon: Icons.pie_chart_rounded,
                        label: 'Profile',
                        value: voucher.profile.toUpperCase(),
                      ),
                      if (voucher.validity != null)
                        _DetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Validity',
                          value: voucher.validity!,
                        ),
                      if (voucher.dataLimit != null)
                        _DetailRow(
                          icon: Icons.data_usage_rounded,
                          label: 'Data Limit',
                          value: voucher.dataLimit!,
                        ),
                      if (voucher.comment != null &&
                          voucher.comment!.isNotEmpty)
                        _DetailRow(
                          icon: Icons.comment_rounded,
                          label: 'Comment',
                          value: voucher.comment!,
                        ),
                      if (voucher.expiresAt != null)
                        _DetailRow(
                          icon: Icons.event_rounded,
                          label: 'Expires',
                          value:
                              '${voucher.expiresAt!.day}/${voucher.expiresAt!.month}/${voucher.expiresAt!.year}',
                        ),
                      if (voucher.remainingSeconds != null)
                        _DetailRow(
                          icon: Icons.timer_outlined,
                          label: 'Remaining',
                          value: voucher.remainingTimeDisplay,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenQR(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenQRView(voucher: voucher),
      ),
    );
  }
}

class _FullScreenQRView extends StatelessWidget {
  final Voucher voucher;

  const _FullScreenQRView({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final isExpired = voucher.isExpired;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: context.appPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppStrings.of(context).scanVoucher),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_rounded),
            onPressed: () {
              final text =
                  'User: ${voucher.username}\nPassword: ${voucher.password}';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.of(context).copiedToClipboard),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CachedQrImage(
                data: voucher.qrData,
                size: MediaQuery.of(context).size.width * 0.7,
                foregroundColor: isExpired ? Colors.grey : context.appPrimary,
              ),
            ),
            SizedBox(height: 32),

            // Username
            Text(
              voucher.username,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),

            // Password (if different)
            if (voucher.username != voucher.password) ...[
              SizedBox(height: 8),
              Text(
                voucher.password,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                ),
              ),
            ],

            SizedBox(height: 16),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isExpired ? Colors.red : Colors.green,
                  width: 1,
                ),
              ),
              child: Text(
                isExpired ? 'EXPIRED' : 'ACTIVE',
                style: TextStyle(
                  color: isExpired ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),

            SizedBox(height: 32),

            // Profile info
            Text(
              'Profile: ${voucher.profile.toUpperCase()}',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),

            if (voucher.validity != null)
              Text(
                'Valid for: ${voucher.validity}',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: context.appOnSurface.withValues(alpha: 0.5),
          ),
          SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.appOnSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
