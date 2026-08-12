// ملف: pdf_generator.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pdf_templates_screen.dart'; // تأكد من وجود هذا الملف واستيراد PdfTemplate

/// دالة توليد الـ PDF في الخلفية (Isolate)
Future<Uint8List> _generatePdfInBackground(Map<String, dynamic> data) async {
  // استلام البيانات
  final cardUsernames = data['cardUsernames'] as List<String>;
  final imageBytes = data['imageBytes'] as Uint8List; // نمرر الصورة كـ Uint8List
  final textXRatio = data['textXRatio'] as double;
  final textYRatio = data['textYRatio'] as double;
  final cardsPerPage = data['cardsPerPage'] as int;
  final imageWidth = data['imageWidth'] as double;
  final imageHeight = data['imageHeight'] as double;
  final markerWidthRatio = data['markerWidthRatio'] as double;
  final markerHeightRatio = data['markerHeightRatio'] as double;
  final printDate = data['printDate'] as String;   // تاريخ الطباعة (يظهر في البطاقة)
  final category = data['category'] as String;     // فئة الكارت (يظهر في البطاقة واسم الملف)

  final doc = pw.Document();
  final imageProvider = pw.MemoryImage(imageBytes);

  int step = cardsPerPage;
  for (var i = 0; i < cardUsernames.length; i += step) {
    final pageCards = cardUsernames.sublist(
        i, i + step > cardUsernames.length ? cardUsernames.length : i + step);

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final List<pw.Widget> gridChildren = [];

          for (var user in pageCards) {
            gridChildren.add(
              pw.LayoutBuilder(builder: (ctx, constraints) {
                final cellWidth = constraints!.maxWidth;
                final cellHeight = constraints.maxHeight;

                // حساب موقع النص بناءً على نسب القالب
                final boxWidth = markerWidthRatio * cellWidth;
                final boxHeight = markerHeightRatio * cellHeight;
                final boxLeft = (textXRatio * cellWidth) - (boxWidth / 2);
                final boxTop = (textYRatio * cellHeight) - (boxHeight / 2);

                return pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.5),
                  ),
                  child: pw.Stack(
                    fit: pw.StackFit.expand,
                    children: [
                      // صورة الخلفية
                      pw.Image(imageProvider, fit: pw.BoxFit.fill),
                      
                      // اسم المستخدم + الفئة + التاريخ
                      pw.Positioned(
                        left: boxLeft,
                        top: boxTop,
                        child: pw.Container(
                          width: boxWidth,
                          height: boxHeight,
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                user,
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'فئة: $category',
                                style: const pw.TextStyle(
                                  color: PdfColors.grey,
                                  fontSize: 8,
                                ),
                              ),
                              pw.Text(
                                'تاريخ: $printDate',
                                style: const pw.TextStyle(
                                  color: PdfColors.grey,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          }

          // ملء الفراغات المتبقية في الشبكة
          int remainingSlots = cardsPerPage - pageCards.length;
          for (var j = 0; j < remainingSlots; j++) {
            gridChildren.add(pw.SizedBox.shrink());
          }

          return pw.GridView(
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            crossAxisCount: 3,
            childAspectRatio: imageWidth / imageHeight,
            children: gridChildren,
          );
        },
      ),
    );
  }

  return doc.save();
}

/// فئة مسؤولة عن توليد ومشاركة الـ PDF
class PdfGenerator {
  /// توليد ومشاركة ملف PDF يحتوي على بطاقات Wi-Fi
  /// 
  /// - [cardUsernames]: قائمة بأسماء المستخدمين
  /// - [template]: قالب البطاقة (يحتوي على مسار الصورة والنسب)
  /// - [category]: فئة الكارت (مثلاً "500" أو "300")، تظهر في اسم الملف وداخل البطاقة
  static Future<void> sharePdf(
    BuildContext context, {
    required List<String> cardUsernames,
    required PdfTemplate template,
    String category = 'general', // قيمة افتراضية
  }) async {
    // إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // قراءة الصورة في الواجهة الرئيسية (لضمان التوافق مع Web)
      final imageBytes = await File(template.imagePath).readAsBytes();

      // تحضير التاريخ
      final now = DateTime.now();
      final dateForFilename =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final dateForCard =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // تجهيز البيانات التي سترسل إلى Isolate
      final Map<String, dynamic> generationData = {
        'cardUsernames': cardUsernames,
        'imageBytes': imageBytes,
        'textXRatio': template.textXRatio,
        'textYRatio': template.textYRatio,
        'cardsPerPage': template.cardsPerPage,
        'imageWidth': template.imageWidth,
        'imageHeight': template.imageHeight,
        'markerWidthRatio': template.markerWidthRatio,
        'markerHeightRatio': template.markerHeightRatio,
        'printDate': dateForCard,
        'category': category,
      };

      // توليد الـ PDF في الخلفية
      final pdfBytes = await compute(_generatePdfInBackground, generationData);

      // إغلاق مؤشر التحميل
      if (context.mounted) Navigator.of(context).pop();

      // اسم الملف: wifi-cards_فئة_تاريخ.pdf
      final filename = 'wifi-cards_${category}_$dateForFilename.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    } catch (e) {
      // إغلاق مؤشر التحميل وإظهار رسالة خطأ
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل إنشاء ملف PDF. الرجاء التأكد من وجود القالب وصلاحية الصورة.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // يمكنك أيضاً طباعة الخطأ للتشخيص
      debugPrint('Error generating PDF: $e');
    }
  }
}
