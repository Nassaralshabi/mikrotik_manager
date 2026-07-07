// ============================================================
//  SaveLocationSelector — واجهة اختيار مكان الحفظ عند إضافة كرت
//
//  تعرض خيارات الحفظ المتاحة كأزرار اختيار مع أيقونات
//  وتدعم تحديد Multiple locations
// ============================================================

import 'package:flutter/material.dart';
import '../../core/services/card_save_service.dart';

/// نوع الاختيار: واحد أو متعدد
enum SelectionMode { single, multi }

/// محدد وجهة الحفظ
class SaveLocationSelector extends StatefulWidget {
  /// الخيارات المتاحة
  final List<SaveLocation> availableLocations;

  /// الخيار الافتراضي
  final SaveLocation? defaultLocation;

  /// وضع الاختيار: واحد (single) أو متعدد (multi)
  final SelectionMode mode;

  /// عند تغيير الاختيار
  final ValueChanged<List<SaveLocation>>? onChanged;

  const SaveLocationSelector({
    super.key,
    this.availableLocations = const [
      SaveLocation.mikrotikDevice,
      SaveLocation.localDatabase,
      SaveLocation.pdfFile,
      SaveLocation.all,
    ],
    this.defaultLocation,
    this.mode = SelectionMode.single,
    this.onChanged,
  });

  @override
  State<SaveLocationSelector> createState() => _SaveLocationSelectorState();
}

class _SaveLocationSelectorState extends State<SaveLocationSelector> {
  Set<SaveLocation> _selected = {};

  @override
  void initState() {
    super.initState();
    if (widget.defaultLocation != null) {
      _selected = {widget.defaultLocation!};
    } else if (widget.availableLocations.contains(SaveLocation.mikrotikDevice)) {
      _selected = {SaveLocation.mikrotikDevice};
    } else if (widget.availableLocations.isNotEmpty) {
      _selected = {widget.availableLocations.first};
    }
  }

  List<SaveLocation> get selected => _selected.toList();

  void _toggle(SaveLocation location) {
    setState(() {
      if (widget.mode == SelectionMode.single) {
        _selected = {location};
      } else {
        if (_selected.contains(location)) {
          _selected.remove(location);
        } else {
          _selected.add(location);
        }
      }
    });
    widget.onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.save, size: 18, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'مكان الحفظ',
                style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...widget.availableLocations.map((location) => _buildLocationOption(location)),
      ],
    );
  }

  Widget _buildLocationOption(SaveLocation location) {
    final isSelected = _selected.contains(location);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _toggle(location),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                _iconForLocation(location),
                size: 20,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      location.description,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.mode == SelectionMode.multi)
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.white24,
                )
              else
                Radio<SaveLocation>(
                  value: location,
                  groupValue: _selected.firstOrNull,
                  onChanged: (v) {
                    if (v != null) _toggle(v);
                  },
                  fillColor: WidgetStateProperty.all(
                    isSelected ? Theme.of(context).primaryColor : Colors.white24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForLocation(SaveLocation location) {
    switch (location) {
      case SaveLocation.mikrotikDevice:
        return Icons.router;
      case SaveLocation.localDatabase:
        return Icons.storage;
      case SaveLocation.pdfFile:
        return Icons.picture_as_pdf;
      case SaveLocation.clipboard:
        return Icons.content_copy;
      case SaveLocation.all:
        return Icons.select_all;
    }
  }
}
