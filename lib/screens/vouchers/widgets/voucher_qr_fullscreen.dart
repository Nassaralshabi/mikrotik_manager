import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models/voucher.dart';
import '../../../widgets/cached_qr_image.dart';
import '../../../l10n/translations.dart';

/// Fullscreen QR code viewer for easy scanning
class VoucherQrFullscreen extends StatefulWidget {
  final Voucher voucher;
  final bool showShareButton;

  const VoucherQrFullscreen({
    super.key,
    required this.voucher,
    this.showShareButton = true,
  });

  @override
  State<VoucherQrFullscreen> createState() => _VoucherQrFullscreenState();
}

class _VoucherQrFullscreenState extends State<VoucherQrFullscreen> {
  double _qrSize = 280;

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          voucher.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copyCredentials(context),
            tooltip: 'Copy credentials',
          ),
          if (widget.showShareButton)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _shareVoucher(context),
              tooltip: 'Share voucher',
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR Code
              GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    _qrSize =
                        (_qrSize * details.horizontalScale).clamp(150.0, 400.0);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: CachedQrImage(
                    data: voucher.qrData,
                    size: _qrSize,
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Voucher info
              Text(
                voucher.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (voucher.username != voucher.password)
                Text(
                  'Password: ${voucher.password}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: voucher.isExpired
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: voucher.isExpired ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  voucher.isExpired ? 'EXPIRED' : 'ACTIVE',
                  style: TextStyle(
                    color: voucher.isExpired ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Profile info
              Text(
                'Profile: ${voucher.profile.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 32),

              // Zoom hint
              Text(
                'Pinch to zoom',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyCredentials(BuildContext context) {
    final text =
        'Username: ${widget.voucher.username}\nPassword: ${widget.voucher.password}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).credentialsCopied),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareVoucher(BuildContext context) {
    final voucher = widget.voucher;
    final text = '''🎫 WiFi Voucher

Username: ${voucher.username}
Password: ${voucher.password}
Profile: ${voucher.profile.toUpperCase()}

${voucher.isExpired ? '⚠️ This voucher has expired' : '✅ This voucher is active'}

---
Generated by ΩMMON''';

    // Use share_plus if available, or just copy to clipboard
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.of(context).voucherDetailsCopied),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
}

/// Voucher info card shown below fullscreen QR
class VoucherInfoSheet extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback? onShare;
  final VoidCallback? onCopy;
  final VoidCallback? onPrint;

  const VoucherInfoSheet({
    super.key,
    required this.voucher,
    this.onShare,
    this.onCopy,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appOnSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            voucher.username,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: voucher.isExpired
                  ? context.appError.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              voucher.isExpired ? 'Expired' : 'Active',
              style: TextStyle(
                color: voucher.isExpired ? context.appError : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info rows
          _buildInfoRow(context, 'Username', voucher.username),
          if (voucher.username != voucher.password)
            _buildInfoRow(context, 'Password', voucher.password),
          _buildInfoRow(context, 'Profile', voucher.profile.toUpperCase()),
          if (voucher.validity != null)
            _buildInfoRow(context, 'Validity', voucher.validity!),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              if (onCopy != null)
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    color: context.appPrimary,
                    onTap: onCopy!,
                  ),
                ),
              if (onCopy != null && onShare != null) const SizedBox(width: 12),
              if (onShare != null)
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: Colors.green,
                    onTap: onShare!,
                  ),
                ),
              if (onShare != null && onPrint != null) const SizedBox(width: 12),
              if (onPrint != null)
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.print_rounded,
                    label: 'Print',
                    color: Colors.blue,
                    onTap: onPrint!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
