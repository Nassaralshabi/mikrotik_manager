import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models/voucher.dart';
import '../../../widgets/cached_qr_image.dart';
import '../../../l10n/translations.dart';

/// Print preview dialog showing vouchers before printing
class PrintPreviewDialog extends StatefulWidget {
  final List<Voucher> vouchers;
  final String? templateName;
  final Function(List<Voucher> vouchers) onPrint;

  const PrintPreviewDialog({
    super.key,
    required this.vouchers,
    this.templateName,
    required this.onPrint,
  });

  @override
  State<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<PrintPreviewDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _vouchersPerPage = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _totalPages => (widget.vouchers.length / _vouchersPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Preview content
            Expanded(
              child: _buildPreviewContent(context),
            ),

            // Page indicator and actions
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.print_rounded,
            color: context.appPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Print Preview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${widget.vouchers.length} vouchers • $_totalPages page(s)',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            color: context.appOnSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: _totalPages,
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * _vouchersPerPage;
          final endIndex =
              (startIndex + _vouchersPerPage).clamp(0, widget.vouchers.length);
          final pageVouchers = widget.vouchers.sublist(startIndex, endIndex);

          return _buildPrintPage(context, pageVouchers, pageIndex + 1);
        },
      ),
    );
  }

  Widget _buildPrintPage(
      BuildContext context, List<Voucher> vouchers, int pageNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WiFi Voucher',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                Text(
                  'Page $pageNumber/$_totalPages',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Vouchers grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                return _buildVoucherPrintCard(context, vouchers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherPrintCard(BuildContext context, Voucher voucher) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // QR Code
          Expanded(
            flex: 3,
            child: Center(
              child: CachedQrImage(
                data: voucher.qrData,
                size: 80,
              ),
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    voucher.username,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (voucher.username != voucher.password)
                    Text(
                      voucher.password,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    voucher.profile.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Page indicator
          ...List.generate(_totalPages, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentPage
                    ? context.appPrimary
                    : context.appPrimary.withValues(alpha: 0.2),
              ),
            );
          }),
          const Spacer(),

          // Template info
          if (widget.templateName != null) ...[
            Icon(
              Icons.description_rounded,
              size: 16,
              color: context.appOnSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              widget.templateName!,
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Print button
          ElevatedButton.icon(
            onPressed: () {
              widget.onPrint(widget.vouchers);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text(AppStrings.of(context).printAll),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick print settings dialog
class PrintSettingsDialog extends StatefulWidget {
  final int voucherCount;
  final Function(int copies, String template) onConfirm;

  const PrintSettingsDialog({
    super.key,
    required this.voucherCount,
    required this.onConfirm,
  });

  @override
  State<PrintSettingsDialog> createState() => _PrintSettingsDialogState();
}

class _PrintSettingsDialogState extends State<PrintSettingsDialog> {
  int _copies = 1;
  String _selectedTemplate = 'Standard';

  final List<String> _templates = [
    'Standard',
    'Compact',
    'Large QR',
    'With Instructions',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Text(
        'Print Settings',
        style: TextStyle(color: context.appOnSurface),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total vouchers: ${widget.voucherCount}',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),

          // Copies
          Text(
            'Copies per voucher:',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _copies > 1 ? () => setState(() => _copies--) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '$_copies',
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _copies++),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Template
          Text(
            'Template:',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selectedTemplate,
            onChanged: (value) {
              setState(() {
                _selectedTemplate = value!;
              });
            },
            child: Column(
              children: _templates.map((template) {
                return RadioListTile<String>(
                  title: Text(
                    template,
                    style: TextStyle(color: context.appOnSurface),
                  ),
                  value: template,
                  activeColor: context.appPrimary,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style:
                TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_copies, _selectedTemplate);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(AppStrings.of(context).previewAndPrint),
        ),
      ],
    );
  }
}
