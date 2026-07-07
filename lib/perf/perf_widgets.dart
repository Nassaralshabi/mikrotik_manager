// ============================================================
//  Performance Helpers — أدوات مشتركة لتحسين الأداء
//  يُستخدم في كل الشاشات
// ============================================================

import 'package:flutter/material.dart';
import 'dart:io';
import 'device_capability.dart';

/// صورة مُخبّاة في الذاكرة بدقة مناسبة لحجم العرض
/// تمنع تحميل صور 4K في مساحة صغيرة (توفير RAM كبير)
class CachedImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const CachedImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    // cacheWidth يحسب البكسلات المطلوبة فقط
    // على شاشة 2x density وعرض 200px، نحتاج 400px فقط بدل 4K
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final targetWidth = width != null ? (width! * dpr).round() : null;
    final targetHeight = height != null ? (height! * dpr).round() : null;

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: targetWidth,
      cacheHeight: targetHeight,
      // filterQuality منخفض يُسرّع الرسم على الأجهزة الضعيفة
      filterQuality: DeviceCapability.instance.isLowEnd
          ? FilterQuality.low
          : FilterQuality.medium,
      gaplessPlayback: true,  // لا يومض عند التحميل
    );
  }
}

/// بطاقة مُحسّنة — RepaintBoundary + const حيثما أمكن
class PerfCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const PerfCard({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin ?? const EdgeInsets.all(8),
      child: child,
    );
    // RepaintBoundary يمنع إعادة رسم البطاقة عند تحديث الـ parent
    return RepaintBoundary(child: onTap != null ? InkWell(onTap: onTap, child: card) : card);
  }
}

/// مؤشر تحميل مُحسّن للأجهزة الضعيفة
/// - حجم أصغر (strokWidth 2 بدل 4)
/// - لون ثابت بدون animation
class PerfLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;

  const PerfLoadingIndicator({
    super.key,
    this.message,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6b3fa0)),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// قائمة محسّنة — تستخدم itemExtent + cacheExtent ديناميكي
class PerfListView<T> extends StatelessWidget {
  final List<T> items;
  final double itemExtent;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? emptyWidget;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;

  const PerfListView({
    super.key,
    required this.items,
    required this.itemExtent,
    required this.itemBuilder,
    this.emptyWidget,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const Center(child: Text('لا توجد بيانات'));
    }
    return RepaintBoundary(
      child: ListView.builder(
        itemCount: items.length,
        itemExtent: itemExtent,  // مهم: يُسرّع scroll بشكل كبير
        padding: padding,
        controller: controller,
        shrinkWrap: shrinkWrap,
        cacheExtent: DeviceCapability.instance.listViewCacheExtent,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, i) => itemBuilder(context, items[i], i),
      ),
    );
  }
}

/// يلتف حول widget يُعاد بناؤه كثيراً — يمنع إعادة بناء الأطفال
class PerfBoundary extends StatelessWidget {
  final Widget child;
  const PerfBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}

/// صورة من ملف مع cacheWidth — لاستبدال Image.file في كل الشاشات
/// يحل مشكلة تحميل صور كبيرة على الأجهزة الضعيفة
class CachedFileImage extends StatelessWidget {
  final File? file;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const CachedFileImage({
    super.key,
    this.file,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final targetWidth = width != null ? (width! * dpr).round() : null;

    return Image.file(
      file!,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: targetWidth,
      filterQuality: DeviceCapability.instance.isLowEnd
          ? FilterQuality.low
          : FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}
