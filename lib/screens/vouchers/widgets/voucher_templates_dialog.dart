import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/translations.dart';

/// Predefined voucher template for quick generation
class VoucherTemplate {
  final String name;
  final String validity;
  final String description;
  final IconData icon;
  final Color color;
  final int? timeLimit; // in seconds, null for no limit
  final int? dataLimit; // in bytes, null for no limit

  const VoucherTemplate({
    required this.name,
    required this.validity,
    required this.description,
    required this.icon,
    required this.color,
    this.timeLimit,
    this.dataLimit,
  });
}

/// Predefined templates
const List<VoucherTemplate> voucherTemplates = [
  VoucherTemplate(
    name: '1 Hour',
    validity: '1 hour',
    description: 'Quick access pass',
    icon: Icons.access_time_rounded,
    color: Color(0xFF6366F1), // Indigo
    timeLimit: 3600,
  ),
  VoucherTemplate(
    name: '3 Hours',
    validity: '3 hours',
    description: 'Standard session',
    icon: Icons.schedule_rounded,
    color: Color(0xFF8B5CF6), // Purple
    timeLimit: 10800,
  ),
  VoucherTemplate(
    name: '1 Day',
    validity: '24 hours',
    description: 'Full day access',
    icon: Icons.calendar_today_rounded,
    color: Color(0xFF06B6D4), // Cyan
    timeLimit: 86400,
  ),
  VoucherTemplate(
    name: '1 Week',
    validity: '7 days',
    description: 'Weekly pass',
    icon: Icons.date_range_rounded,
    color: Color(0xFF10B981), // Emerald
    timeLimit: 604800,
  ),
  VoucherTemplate(
    name: '1 Month',
    validity: '30 days',
    description: 'Monthly subscription',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFFF59E0B), // Amber
    timeLimit: 2592000,
  ),
  VoucherTemplate(
    name: 'Unlimited',
    validity: 'No limit',
    description: 'Full access pass',
    icon: Icons.all_inclusive_rounded,
    color: Color(0xFFEC4899), // Pink
    timeLimit: null,
  ),
];

/// Dialog for selecting a voucher template
class VoucherTemplatesDialog extends StatelessWidget {
  final Function(VoucherTemplate template) onTemplateSelected;

  const VoucherTemplatesDialog({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    color: context.appPrimary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Generate',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: context.appOnSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Select a template to generate vouchers',
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
            ),

            // Templates grid
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: voucherTemplates.length,
                  itemBuilder: (context, index) {
                    return _buildTemplateCard(
                      context,
                      voucherTemplates[index],
                    );
                  },
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to custom generation
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(AppStrings.of(context).customSettings),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.appPrimary,
                    side: BorderSide(color: context.appPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, VoucherTemplate template) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTemplateSelected(template);
      },
      child: Container(
        decoration: BoxDecoration(
          color: template.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: template.color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: template.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                template.icon,
                color: template.color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              template.name,
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.validity,
              style: TextStyle(
                color: template.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.description,
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.5),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick generate settings from template
class TemplateGenerateSettings {
  final String templateName;
  final int quantity;
  final String prefix;
  final String profile;

  const TemplateGenerateSettings({
    required this.templateName,
    required this.quantity,
    required this.prefix,
    required this.profile,
  });
}

/// Dialog to configure generation from a template
class TemplateGenerateDialog extends StatefulWidget {
  final VoucherTemplate template;
  final List<String> profiles;
  final Function(TemplateGenerateSettings settings) onGenerate;

  const TemplateGenerateDialog({
    super.key,
    required this.template,
    required this.profiles,
    required this.onGenerate,
  });

  @override
  State<TemplateGenerateDialog> createState() => _TemplateGenerateDialogState();
}

class _TemplateGenerateDialogState extends State<TemplateGenerateDialog> {
  late int _quantity;
  late String _prefix;
  late String _selectedProfile;

  @override
  void initState() {
    super.initState();
    _quantity = 10;
    _prefix = 'wifi';
    _selectedProfile =
        widget.profiles.isNotEmpty ? widget.profiles.first : 'default';
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;

    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: template.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(template.icon, color: template.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${template.name} Vouchers',
                  style: TextStyle(color: context.appOnSurface),
                ),
                Text(
                  template.validity,
                  style: TextStyle(
                    color: template.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity
          _buildLabel('Quantity'),
          Row(
            children: [
              IconButton(
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Expanded(
                child: Slider(
                  value: _quantity.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '$_quantity',
                  onChanged: (value) {
                    setState(() {
                      _quantity = value.toInt();
                    });
                  },
                  activeColor: template.color,
                ),
              ),
              IconButton(
                onPressed:
                    _quantity < 100 ? () => setState(() => _quantity++) : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_quantity',
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Username prefix
          _buildLabel('Username Prefix'),
          TextField(
            decoration: InputDecoration(
              hintText: 'e.g., wifi, guest, user',
              filled: true,
              fillColor: context.appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => _prefix = value,
            controller: TextEditingController(text: _prefix)
              ..selection = TextSelection.collapsed(offset: _prefix.length),
          ),
          const SizedBox(height: 16),

          // Profile
          _buildLabel('Profile'),
          DropdownButtonFormField<String>(
            initialValue: _selectedProfile,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.appBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: context.appSurface,
            items: widget.profiles.map((profile) {
              return DropdownMenuItem(
                value: profile,
                child: Text(
                  profile.toUpperCase(),
                  style: TextStyle(color: context.appOnSurface),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProfile = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.of(context).cancel,
            style:
                TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            widget.onGenerate(TemplateGenerateSettings(
              templateName: template.name,
              quantity: _quantity,
              prefix: _prefix,
              profile: _selectedProfile,
            ));
            Navigator.pop(context);
          },
          icon: Icon(Icons.bolt_rounded, size: 18),
          label: Text(AppStrings.of(context).generate),
          style: ElevatedButton.styleFrom(
            backgroundColor: template.color,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.appOnSurface.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
