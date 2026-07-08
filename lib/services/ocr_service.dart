// ============================================================
//  OcrService — خدمة التعرّف على النص من الصور
//
//  يستخدم Google ML Kit Text Recognition لاستخراج النصوص
//  من الصور الملتقطة بالكاميرا أو المختارة من المعرض.
//
//  المزايا:
//   - التقاط صورة من الكاميرا
//   - اختيار صورة من المعرض
//   - استخراج نص عربي وإنجليزي
//   - نسخ النص للاستخدام كاسم مستخدم/كلمة سر
// ============================================================

import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrResult {
  final String text;
  final List<TextBlock> blocks;
  final String? imagePath;

  OcrResult({
    required this.text,
    required this.blocks,
    this.imagePath,
  });

  List<String> get lines => blocks
      .expand((b) => b.lines)
      .map((l) => l.text)
      .where((t) => t.trim().isNotEmpty)
      .toList();

  List<String> get words => text
      .split(RegExp(r'[\s\n\r]+'))
      .where((w) => w.trim().isNotEmpty)
      .toList();
}

class OcrService {
  static final OcrService _instance = OcrService._();
  factory OcrService() => _instance;
  OcrService._();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  // ─── Capture from camera ───

  Future<OcrResult?> captureFromCamera({bool preferArabic = false}) async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xfile == null) return null;
      return _processImage(File(xfile.path), preferArabic: preferArabic);
    } catch (e) {
      throw OcrException('فشل التقاط الصورة: $e');
    }
  }

  // ─── Pick from gallery ───

  Future<OcrResult?> pickFromGallery({bool preferArabic = false}) async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xfile == null) return null;
      return _processImage(File(xfile.path), preferArabic: preferArabic);
    } catch (e) {
      throw OcrException('فشل اختيار الصورة: $e');
    }
  }

  // ─── Process image ───

  Future<OcrResult> _processImage(File image, {bool preferArabic = false}) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final result = await _textRecognizer.processImage(inputImage);

      return OcrResult(
        text: result.text,
        blocks: result.blocks,
        imagePath: image.path,
      );
    } catch (e) {
      throw OcrException('فشل معالجة الصورة: $e');
    }
  }

  // ─── Process from file path ───

  Future<OcrResult> processFile(String path, {bool preferArabic = false}) async {
    return _processImage(File(path), preferArabic: preferArabic);
  }

  // ─── Extract credentials from text ───

  /// يحاول استخراج اسم المستخدم وكلمة السر من النص
  /// يبحث عن أنماط مثل "user: xxx" أو "pass: yyy"
  Map<String, String?> extractCredentials(String text) {
    final result = <String, String?>{
      'username': null,
      'password': null,
    };

    final lines = text.split('\n');
    for (final line in lines) {
      final lower = line.toLowerCase().trim();

      // Pattern: user: xxx / username: xxx / user = xxx
      final userMatch = RegExp(
        r'(?:user(?:name)?|name)\s*[:=]\s*(.+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (userMatch != null && result['username'] == null) {
        result['username'] = userMatch.group(1)!.trim();
      }

      // Pattern: pass: xxx / password: xxx / pass = xxx
      final passMatch = RegExp(
        r'(?:pass(?:word)?|pwd)\s*[:=]\s*(.+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (passMatch != null && result['password'] == null) {
        result['password'] = passMatch.group(1)!.trim();
      }
    }

    // If no pattern found, try first two non-empty lines
    if (result['username'] == null && lines.isNotEmpty) {
      for (final line in lines) {
        final t = line.trim();
        if (t.isNotEmpty && !t.contains(':') && !t.contains('=')) {
          result['username'] = t;
          break;
        }
      }
    }

    return result;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class OcrException implements Exception {
  final String message;
  OcrException(this.message);
  @override
  String toString() => message;
}
