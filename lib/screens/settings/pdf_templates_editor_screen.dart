// ============================================================
//  PdfTemplatesEditorScreen — محرّر قوالب PDF للكروت
//
//  المزايا:
//   - عرض كل القوالب في قائمة
//   - إضافة/تعديل/حذف قالب
//   - تخصيص: الألوان، QR، الشعار، السعر، الصلاحية
//   - معاينة القالب
//   - تعيين قالب افتراضي
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import '../../services/pdf_template_service.dart';
import '../../l10n/app_strings.dart';
import '../../l10n/translations.dart';

class PdfTemplatesEditorScreen extends ConsumerStatefulWidget {
  const PdfTemplatesEditorScreen({super.key});

  @override
  ConsumerState<PdfTemplatesEditorScreen> createState() =>
      _PdfTemplatesEditorScreenState();
}

class _PdfTemplatesEditorScreenState
    extends ConsumerState<PdfTemplatesEditorScreen> {
  final _service = PdfTemplateService();
  List<PdfTemplate> _templates = [];
  String? _defaultId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    await _service.seedDefaults();
    _templates = await _service.getAllTemplates();
    _defaultId = await _service.getDefaultId();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.pdfTemplatesEditor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTemplates,
            tooltip: s.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _buildEmpty(s)
              : _buildList(s),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, s),
        icon: const Icon(Icons.add),
        label: Text(s.addTemplate),
      ),
    );
  }

  Widget _buildEmpty(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(s.noTemplatesFound,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showEditor(context, s),
            icon: const Icon(Icons.add),
            label: Text(s.addTemplate),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppStrings s) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _templates.length,
      itemBuilder: (context, i) {
        final t = _templates[i];
        final isDefault = t.id == _defaultId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDefault ? Colors.green : Colors.blue,
              child: Icon(
                _typeIcon(t.type),
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Text(t.name),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'افتراضي',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '${_typeLabel(t.type, s)} • ${t.copiesPerPage} كروت/صفحة',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'edit':
                    _showEditor(context, s, template: t);
                    break;
                  case 'default':
                    await _service.setDefault(t.id);
                    _loadTemplates();
                    break;
                  case 'delete':
                    _confirmDelete(s, t);
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(s.edit)),
                if (!isDefault)
                  PopupMenuItem(
                      value: 'default', child: Text(s.setAsDefault)),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(s.delete, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
            onTap: () => _showPreview(context, s, t),
          ),
        );
      },
    );
  }

  IconData _typeIcon(TemplateType type) {
    switch (type) {
      case TemplateType.full:
        return Icons.fullscreen;
      case TemplateType.compact:
        return Icons.compress;
      case TemplateType.minimal:
        return Icons.minimize;
    }
  }

  String _typeLabel(TemplateType type, AppStrings s) {
    switch (type) {
      case TemplateType.full:
        return s.fullSize;
      case TemplateType.compact:
        return s.compact;
      case TemplateType.minimal:
        return s.minimal;
    }
  }

  void _showEditor(BuildContext context, AppStrings s, {PdfTemplate? template}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TemplateEditorPage(
          template: template?.copy() ??
              PdfTemplate(
                id: 'tpl_${DateTime.now().millisecondsSinceEpoch}',
                name: '',
              ),
          onSave: () async {
            await _loadTemplates();
          },
        ),
      ),
    );
  }

  void _showPreview(
      BuildContext context, AppStrings s, PdfTemplate template) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${s.preview}: ${template.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: _TemplatePreview(template: template),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AppStrings s, PdfTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteTemplate),
        content: Text('${s.deleteTemplate}? "${t.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteTemplate(t.id);
      _loadTemplates();
    }
  }
}

// ============================================================
//  Template Editor Page
// ============================================================

class _TemplateEditorPage extends StatefulWidget {
  final PdfTemplate template;
  final VoidCallback onSave;

  const _TemplateEditorPage({required this.template, required this.onSave});

  @override
  State<_TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends State<_TemplateEditorPage> {
  late PdfTemplate _t;
  final _service = PdfTemplateService();

  @override
  void initState() {
    super.initState();
    _t = widget.template;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(_t.name.isEmpty ? s.addTemplate : s.editTemplate),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: s.saveTemplate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name
          TextField(
            decoration: InputDecoration(
              labelText: s.templateName,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.label),
            ),
            controller: TextEditingController(text: _t.name),
            onChanged: (v) => _t.name = v,
          ),
          const SizedBox(height: 16),

          // Type
          Text(s.templateType, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<TemplateType>(
            segments: [
              ButtonSegment(value: TemplateType.full, label: Text(s.fullSize), icon: const Icon(Icons.fullscreen)),
              ButtonSegment(value: TemplateType.compact, label: Text(s.compact), icon: const Icon(Icons.compress)),
              ButtonSegment(value: TemplateType.minimal, label: Text(s.minimal), icon: const Icon(Icons.minimize)),
            ],
            selected: {_t.type},
            onSelectionChanged: (v) => setState(() => _t.type = v.first),
          ),
          const SizedBox(height: 16),

          // Copies per page
          Row(
            children: [
              const Text('كروت لكل صفحة'),
              Expanded(
                child: Slider(
                  value: _t.copiesPerPage.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: _t.copiesPerPage.toString(),
                  onChanged: (v) => setState(() => _t.copiesPerPage = v.round()),
                ),
              ),
              Text('${_t.copiesPerPage}'),
            ],
          ),
          const SizedBox(height: 16),

          // Toggles
          _ToggleTile(
            title: s.showQrCode,
            icon: Icons.qr_code,
            value: _t.showQrCode,
            onChanged: (v) => setState(() => _t.showQrCode = v),
          ),
          _ToggleTile(
            title: s.showLogo,
            icon: Icons.image,
            value: _t.showLogo,
            onChanged: (v) => setState(() => _t.showLogo = v),
          ),
          _ToggleTile(
            title: s.showPrice,
            icon: Icons.attach_money,
            value: _t.showPrice,
            onChanged: (v) => setState(() => _t.showPrice = v),
          ),
          _ToggleTile(
            title: s.showValidity,
            icon: Icons.access_time,
            value: _t.showValidity,
            onChanged: (v) => setState(() => _t.showValidity = v),
          ),
          _ToggleTile(
            title: s.showProfile,
            icon: Icons.assignment,
            value: _t.showProfile,
            onChanged: (v) => setState(() => _t.showProfile = v),
          ),
          const SizedBox(height: 16),

          // Colors
          Text('الألوان', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _ColorPickerTile(
            title: s.backgroundColor,
            color: _colorFromPdf(_t.backgroundColor),
            onPick: () => _pickColor(s.backgroundColor, _t.backgroundColor,
                (c) => setState(() => _t.backgroundColor = c)),
          ),
          _ColorPickerTile(
            title: s.textColor,
            color: _colorFromPdf(_t.textColor),
            onPick: () => _pickColor(s.textColor, _t.textColor,
                (c) => setState(() => _t.textColor = c)),
          ),
          _ColorPickerTile(
            title: 'لون مميّز',
            color: _colorFromPdf(_t.accentColor),
            onPick: () => _pickColor('لون مميّز', _t.accentColor,
                (c) => setState(() => _t.accentColor = c)),
          ),
          const SizedBox(height: 16),

          // QR Size
          if (_t.showQrCode)
            Row(
              children: [
                const Text('حجم QR'),
                Expanded(
                  child: Slider(
                    value: _t.qrSize,
                    min: 40,
                    max: 150,
                    divisions: 11,
                    label: _t.qrSize.round().toString(),
                    onChanged: (v) => setState(() => _t.qrSize = v),
                  ),
                ),
                Text('${_t.qrSize.round()}'),
              ],
            ),

          // Padding
          Row(
            children: [
              const Text('الهامش'),
              Expanded(
                child: Slider(
                  value: _t.padding,
                  min: 4,
                  max: 40,
                  divisions: 9,
                  label: _t.padding.round().toString(),
                  onChanged: (v) => setState(() => _t.padding = v),
                ),
              ),
              Text('${_t.padding.round()}'),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFromPdf(PdfColor c) => Color.fromARGB(
        (c.alpha * 255).round(),
        (c.red * 255).round(),
        (c.green * 255).round(),
        (c.blue * 255).round(),
      );

  void _pickColor(
      String title, PdfColor current, Function(PdfColor) onPicked) async {
    final colors = [
      PdfColors.white, PdfColors.black, PdfColors.red, PdfColors.blue,
      PdfColors.green, PdfColors.purple, PdfColors.orange, PdfColors.teal,
      PdfColors.pink, PdfColors.indigo, PdfColors.amber, PdfColors.cyan,
    ];
    final color = await showDialog<PdfColor>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((c) {
            return GestureDetector(
              onTap: () => Navigator.pop(ctx, c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colorFromPdf(c),
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.s.cancel),
          ),
        ],
      ),
    );
    if (color != null) onPicked(color);
  }

  Future<void> _save() async {
    if (_t.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.pleaseSelectProfile)),
      );
      return;
    }
    await _service.saveTemplate(_t);
    widget.onSave();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.templateSaved)),
      );
      Navigator.pop(context);
    }
  }
}

// ============================================================
//  Helper widgets
// ============================================================

class _ToggleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ColorPickerTile extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onPick;

  const _ColorPickerTile({
    required this.title,
    required this.color,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      trailing: const Icon(Icons.edit),
      onTap: onPick,
    );
  }
}

// ============================================================
//  Template Preview
// ============================================================

class _TemplatePreview extends StatelessWidget {
  final PdfTemplate template;

  const _TemplatePreview({required this.template});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _colorFromPdf(template.backgroundColor),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _colorFromPdf(template.accentColor), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hotspot Voucher',
                      style: TextStyle(
                        color: _colorFromPdf(template.accentColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    if (template.showQrCode)
                      Container(
                        width: 30,
                        height: 30,
                        color: _colorFromPdf(template.textColor),
                        child: const Center(
                          child: Text('QR',
                              style: TextStyle(fontSize: 8, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'user${1000 + i}',
                  style: TextStyle(
                    color: _colorFromPdf(template.textColor),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (template.showProfile)
                  Text('default',
                      style: TextStyle(
                          color: _colorFromPdf(template.accentColor),
                          fontSize: 10)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (template.showValidity)
                      Text('1d',
                          style: TextStyle(
                              color: _colorFromPdf(template.textColor),
                              fontSize: 10)),
                    if (template.showPrice)
                      Text('5 SAR',
                          style: TextStyle(
                              color: _colorFromPdf(template.accentColor),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _colorFromPdf(PdfColor c) => Color.fromARGB(
        (c.alpha * 255).round(),
        (c.red * 255).round(),
        (c.green * 255).round(),
        (c.blue * 255).round(),
      );
}
