// ============================================================
//  PdfTemplateService — إدارة قوالب PDF للكروت
//
//  المزايا:
//   - حفظ/تحميل القوالب في Hive
//   - 3 أنواع: Full Size, Compact, Minimal
//   - تخصيص الألوان، الخط، QR، الشعار، السعر، الصلاحية
//   - توليد PDF من القالب + بيانات الكرت
// ============================================================

import 'dart:io';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ============================================================
//  نموذج القالب
// ============================================================

class PdfTemplate {
  final String id;
  String name;
  TemplateType type;
  int copiesPerPage;
  PdfColor backgroundColor;
  PdfColor textColor;
  PdfColor accentColor;
  bool showQrCode;
  bool showLogo;
  bool showPrice;
  bool showValidity;
  bool showProfile;
  String? logoPath;
  double qrSize;
  double padding;
  String fontFamily;

  PdfTemplate({
    required this.id,
    required this.name,
    this.type = TemplateType.full,
    this.copiesPerPage = 3,
    PdfColor? backgroundColor,
    PdfColor? textColor,
    PdfColor? accentColor,
    this.showQrCode = true,
    this.showLogo = false,
    this.showPrice = true,
    this.showValidity = true,
    this.showProfile = true,
    this.logoPath,
    this.qrSize = 80,
    this.padding = 16,
    this.fontFamily = 'Helvetica',
  })  : backgroundColor = backgroundColor ?? PdfColors.white,
        textColor = textColor ?? PdfColors.black,
        accentColor = accentColor ?? PdfColors.blue800;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.index,
        'copiesPerPage': copiesPerPage,
        'backgroundColor': backgroundColor.toString(),
        'textColor': textColor.toString(),
        'accentColor': accentColor.toString(),
        'showQrCode': showQrCode,
        'showLogo': showLogo,
        'showPrice': showPrice,
        'showValidity': showValidity,
        'showProfile': showProfile,
        'logoPath': logoPath,
        'qrSize': qrSize,
        'padding': padding,
        'fontFamily': fontFamily,
      };

  factory PdfTemplate.fromMap(Map<dynamic, dynamic> map) => PdfTemplate(
        id: map['id'] as String,
        name: map['name'] as String,
        type: TemplateType.values[map['type'] as int? ?? 0],
        copiesPerPage: map['copiesPerPage'] as int? ?? 3,
        showQrCode: map['showQrCode'] as bool? ?? true,
        showLogo: map['showLogo'] as bool? ?? false,
        showPrice: map['showPrice'] as bool? ?? true,
        showValidity: map['showValidity'] as bool? ?? true,
        showProfile: map['showProfile'] as bool? ?? true,
        logoPath: map['logoPath'] as String?,
        qrSize: (map['qrSize'] as num?)?.toDouble() ?? 80,
        padding: (map['padding'] as num?)?.toDouble() ?? 16,
        fontFamily: map['fontFamily'] as String? ?? 'Helvetica',
      );

  PdfTemplate copy() => PdfTemplate(
        id: id,
        name: name,
        type: type,
        copiesPerPage: copiesPerPage,
        backgroundColor: backgroundColor,
        textColor: textColor,
        accentColor: accentColor,
        showQrCode: showQrCode,
        showLogo: showLogo,
        showPrice: showPrice,
        showValidity: showValidity,
        showProfile: showProfile,
        logoPath: logoPath,
        qrSize: qrSize,
        padding: padding,
        fontFamily: fontFamily,
      );
}

enum TemplateType { full, compact, minimal }

// ============================================================
//  Service
// ============================================================

class PdfTemplateService {
  static const _boxName = 'pdf_templates';
  Box? _box;

  static final PdfTemplateService _instance = PdfTemplateService._();
  factory PdfTemplateService() => _instance;
  PdfTemplateService._();

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  // ─── CRUD ───

  Future<List<PdfTemplate>> getAllTemplates() async {
    final box = await _getBox();
    final templates = <PdfTemplate>[];
    for (final key in box.keys) {
      final map = box.get(key) as Map?;
      if (map != null) {
        templates.add(PdfTemplate.fromMap(map));
      }
    }
    templates.sort((a, b) => a.name.compareTo(b.name));
    return templates;
  }

  Future<void> saveTemplate(PdfTemplate template) async {
    final box = await _getBox();
    await box.put(template.id, template.toMap());
  }

  Future<void> deleteTemplate(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> setDefault(String id) async {
    final box = await _getBox();
    await box.put('default_template_id', id);
  }

  Future<String?> getDefaultId() async {
    final box = await _getBox();
    return box.get('default_template_id') as String?;
  }

  Future<PdfTemplate?> getDefaultTemplate() async {
    final id = await getDefaultId();
    if (id == null) return null;
    final box = await _getBox();
    final map = box.get(id) as Map?;
    if (map == null) return null;
    return PdfTemplate.fromMap(map);
  }

  // ─── Seed defaults ───

  Future<void> seedDefaults() async {
    final templates = await getAllTemplates();
    if (templates.isNotEmpty) return;

    final defaults = [
      PdfTemplate(
        id: 'full_default',
        name: 'قالب كامل',
        type: TemplateType.full,
        copiesPerPage: 3,
      ),
      PdfTemplate(
        id: 'compact_default',
        name: 'قالب مضغوط',
        type: TemplateType.compact,
        copiesPerPage: 6,
      ),
      PdfTemplate(
        id: 'minimal_default',
        name: 'قالب مختصر',
        type: TemplateType.minimal,
        copiesPerPage: 10,
        showPrice: false,
        showProfile: false,
      ),
    ];

    for (final t in defaults) {
      await saveTemplate(t);
    }
    await setDefault('full_default');
  }

  // ─── Generate PDF ───

  Future<Uint8List> generatePdf({
    required PdfTemplate template,
    required List<Map<String, String>> vouchers,
    String? profileName,
    String? validity,
    String? price,
  }) async {
    final pdf = pw.Document();

    // Build voucher widgets based on template type
    final voucherWidgets = <pw.Widget>[];
    for (final v in vouchers) {
      voucherWidgets.add(_buildVoucherCard(
        template: template,
        username: v['username'] ?? '',
        password: v['password'] ?? '',
        profileName: profileName,
        validity: validity,
        price: price,
      ));
    }

    // Determine grid layout
    int crossAxisCount;
    double cellHeight;
    switch (template.type) {
      case TemplateType.full:
        crossAxisCount = 2;
        cellHeight = 200;
        break;
      case TemplateType.compact:
        crossAxisCount = 3;
        cellHeight = 130;
        break;
      case TemplateType.minimal:
        crossAxisCount = 4;
        cellHeight = 90;
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(template.padding),
        build: (context) {
          // Chunk vouchers into pages
          final pages = <pw.Widget>[];
          for (var i = 0; i < voucherWidgets.length; i += crossAxisCount * 4) {
            final chunk = voucherWidgets.sublist(
              i,
              (i + crossAxisCount * 4).clamp(0, voucherWidgets.length),
            );
            pages.add(
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chunk
                    .map((w) => pw.SizedBox(
                          width: (PdfPageFormat.a4.width -
                                  template.padding * 2 -
                                  8 * (crossAxisCount - 1)) /
                              crossAxisCount,
                          height: cellHeight,
                          child: w,
                        ))
                    .toList(),
              ),
            );
            if (i + crossAxisCount * 4 < voucherWidgets.length) {
              pages.add(pw.SizedBox(height: 16));
            }
          }
          return pages;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildVoucherCard({
    required PdfTemplate template,
    required String username,
    required String password,
    String? profileName,
    String? validity,
    String? price,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: template.backgroundColor,
        border: pw.Border.all(color: template.accentColor, width: 1.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      padding: pw.EdgeInsets.all(template.type == TemplateType.minimal ? 6 : 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          if (template.showLogo || template.type == TemplateType.full)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Hotspot Voucher',
                  style: pw.TextStyle(
                    color: template.accentColor,
                    fontSize: template.type == TemplateType.minimal ? 7 : 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (template.showQrCode)
                  pw.Container(
                    width: template.qrSize * 0.4,
                    height: template.qrSize * 0.4,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: template.textColor, width: 0.5),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'QR',
                        style: pw.TextStyle(
                          fontSize: 6,
                          color: template.textColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          pw.SizedBox(height: 4),
          // Username
          pw.Text(
            username,
            style: pw.TextStyle(
              color: template.textColor,
              fontSize: template.type == TemplateType.minimal ? 10 : 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          // Password
          if (password.isNotEmpty && password != username) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Pass: $password',
              style: pw.TextStyle(
                color: template.textColor,
                fontSize: template.type == TemplateType.minimal ? 7 : 9,
              ),
            ),
          ],
          // Profile
          if (template.showProfile && profileName != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              profileName,
              style: pw.TextStyle(
                color: template.accentColor,
                fontSize: template.type == TemplateType.minimal ? 6 : 8,
              ),
            ),
          ],
          // Validity + Price
          if (template.showValidity || template.showPrice) ...[
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (template.showValidity && validity != null)
                  pw.Text(
                    validity,
                    style: pw.TextStyle(
                      color: template.textColor,
                      fontSize: template.type == TemplateType.minimal ? 6 : 8,
                    ),
                  ),
                if (template.showPrice && price != null)
                  pw.Text(
                    price,
                    style: pw.TextStyle(
                      color: template.accentColor,
                      fontSize: template.type == TemplateType.minimal ? 8 : 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Save PDF to file ───

  Future<String> savePdfToFile(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
