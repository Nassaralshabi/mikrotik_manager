import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CachedQrImage extends StatelessWidget {
  final String data;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final int version;

  const CachedQrImage({
    super.key,
    required this.data,
    this.size = 100,
    this.foregroundColor,
    this.backgroundColor,
    this.version = QrVersions.auto,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: QrImageView(
        key: ValueKey('qr_$data'),
        data: data,
        version: version,
        size: size,
        gapless: false,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor ?? Colors.black,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor ?? Colors.black,
        ),
        backgroundColor: backgroundColor ?? Colors.white,
      ),
    );
  }
}
