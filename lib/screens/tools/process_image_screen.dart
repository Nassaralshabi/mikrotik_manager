// ============================================================
//  ProcessImageScreen — شاشة معالجة الصورة (OCR)
//
//  المزايا:
//   - التقاط صورة من الكاميرا
//   - اختيار صورة من المعرض
//   - استخراج النص عربي/إنجليزي
//   - عرض النص المتعرّف عليه
//   - نسخ النص أو استخدامه كاسم مستخدم/كلمة سر
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../services/ocr_service.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/translations.dart';

class ProcessImageScreen extends StatefulWidget {
  const ProcessImageScreen({super.key});

  @override
  State<ProcessImageScreen> createState() => _ProcessImageScreenState();
}

class _ProcessImageScreenState extends State<ProcessImageScreen> {
  final _ocr = OcrService();
  OcrResult? _result;
  bool _isProcessing = false;
  bool _preferArabic = false;
  String? _error;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    setState(() {
      _isProcessing = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _ocr.captureFromCamera(preferArabic: _preferArabic);
      if (result == null) {
        setState(() => _isProcessing = false);
        return;
      }
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } on OcrException catch (e) {
      setState(() {
        _error = e.message;
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isProcessing = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _ocr.pickFromGallery(preferArabic: _preferArabic);
      if (result == null) {
        setState(() => _isProcessing = false);
        return;
      }
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } on OcrException catch (e) {
      setState(() {
        _error = e.message;
        _isProcessing = false;
      });
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.copiedToClipboard)),
    );
  }

  void _copyLine(String line) {
    _copyText(line);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.processImageOcr),
      ),
      body: Column(
        children: [
          // Arabic toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SwitchListTile(
              value: _preferArabic,
              onChanged: (v) => setState(() => _preferArabic = v),
              title: const Text('تفضيل التعرّف على العربية'),
              secondary: const Icon(Icons.translate),
              dense: true,
            ),
          ),

          // Image preview
          if (_result?.imagePath != null)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_result!.imagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Error
          if (_error != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),

          // Processing
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري معالجة OCR...'),
                ],
              ),
            ),

          // Result
          if (_result != null && !_isProcessing)
            Expanded(
              child: _buildResult(s),
            ),

          // Empty state
          if (_result == null && !_isProcessing && _error == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.document_scanner,
                        size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'التقط صورة أو اختر من المعرض\nلاستخراج النص منها',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _captureFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(s.takePhoto),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _isProcessing ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(s.chooseFromGallery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(AppStrings s) {
    final text = _result!.text.trim();
    if (text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(s.noTextFoundInImage,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final lines = _result!.lines;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                s.recognizedText,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyText(text),
              tooltip: s.copyText,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Full text card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lines list
        if (lines.isNotEmpty) ...[
          Text('الأسطر (${lines.length})',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...lines.map((line) => Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  title: Text(line, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyLine(line),
                    tooltip: s.copy,
                  ),
                  onTap: () => _copyLine(line),
                ),
              )),
        ],

        // Credentials extraction
        const SizedBox(height: 16),
        _buildCredentialsCard(s),
      ],
    );
  }

  Widget _buildCredentialsCard(AppStrings s) {
    final creds = _ocr.extractCredentials(_result!.text);
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text('بيانات اعتماد مكتشفة',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700)),
              ],
            ),
            const SizedBox(height: 8),
            if (creds['username'] != null)
              _buildCredRow('اسم المستخدم', creds['username']!, s),
            if (creds['password'] != null)
              _buildCredRow('كلمة السر', creds['password']!, s),
            if (creds['username'] == null && creds['password'] == null)
              Text('لم يتم العثور على نمط واضح',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCredRow(String label, String value, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyText(value),
            tooltip: s.copy,
          ),
        ],
      ),
    );
  }
}
