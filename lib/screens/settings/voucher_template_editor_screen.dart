import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/template_service.dart';

final customVoucherTemplateProvider = StateNotifierProvider<CustomTemplateNotifier, CustomVoucherTemplate>((ref) {
  return CustomTemplateNotifier();
});

class CustomTemplateNotifier extends StateNotifier<CustomVoucherTemplate> {
  CustomTemplateNotifier() : super(const CustomVoucherTemplate()) {
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final template = await TemplateService.loadCustomTemplate();
      if (template != null) {
        state = template;
      }
    } catch (e) {
      // Use default
    }
  }

  Future<void> setTemplate(CustomVoucherTemplate template) async {
    state = template;
    await TemplateService.saveCustomTemplate(template);
  }

  void updateCompanyName(String value) {
    state = state.copyWith(companyName: value);
  }

  void updateHeaderText(String value) {
    state = state.copyWith(headerText: value);
  }

  void toggleShowUsername() {
    state = state.copyWith(showUsername: !state.showUsername);
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void toggleShowValidity() {
    state = state.copyWith(showValidity: !state.showValidity);
  }

  void toggleShowProfile() {
    state = state.copyWith(showProfile: !state.showProfile);
  }

  void toggleShowPrice() {
    state = state.copyWith(showPrice: !state.showPrice);
  }

  void toggleShowQrCode() {
    state = state.copyWith(showQrCode: !state.showQrCode);
  }

  void toggleShowCutLines() {
    state = state.copyWith(showCutLines: !state.showCutLines);
  }

  void updatePrimaryColor(String value) {
    state = state.copyWith(primaryColor: value);
  }

  void updateBackgroundColor(String value) {
    state = state.copyWith(backgroundColor: value);
  }
}

class VoucherTemplateEditorScreen extends ConsumerStatefulWidget {
  const VoucherTemplateEditorScreen({super.key});

  @override
  ConsumerState<VoucherTemplateEditorScreen> createState() => _VoucherTemplateEditorScreenState();
}

class _VoucherTemplateEditorScreenState extends ConsumerState<VoucherTemplateEditorScreen> {
  late TextEditingController _companyNameController;
  late TextEditingController _headerTextController;

  final List<Map<String, String>> _colorOptions = [
    {'name': 'Purple', 'value': '#7C3AED'},
    {'name': 'Blue', 'value': '#3B82F6'},
    {'name': 'Green', 'value': '#10B981'},
    {'name': 'Orange', 'value': '#F59E0B'},
    {'name': 'Red', 'value': '#EF4444'},
    {'name': 'Pink', 'value': '#EC4899'},
    {'name': 'Cyan', 'value': '#06B6D4'},
    {'name': 'Indigo', 'value': '#6366F1'},
  ];

  final List<Map<String, String>> _bgColorOptions = [
    {'name': 'Dark', 'value': '#1E293B'},
    {'name': 'Black', 'value': '#0F172A'},
    {'name': 'White', 'value': '#FFFFFF'},
    {'name': 'Gray', 'value': '#64748B'},
    {'name': 'Slate', 'value': '#334155'},
    {'name': 'Navy', 'value': '#1E3A5F'},
  ];

  @override
  void initState() {
    super.initState();
    final template = ref.read(customVoucherTemplateProvider);
    _companyNameController = TextEditingController(text: template.companyName);
    _headerTextController = TextEditingController(text: template.headerText);
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _headerTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final template = ref.watch(customVoucherTemplateProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Voucher Template Editor',
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveTemplate,
            icon: Icon(Icons.save_rounded, color: context.appPrimary, size: 20),
            label: Text(
              'Save',
              style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewCard(template),
            const SizedBox(height: 24),
            _buildSectionTitle('Branding'),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Company Name',
              controller: _companyNameController,
              hint: 'Your Business Name',
              onChanged: (value) {
                ref.read(customVoucherTemplateProvider.notifier).updateCompanyName(value);
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Header Text',
              controller: _headerTextController,
              hint: 'WiFi Voucher',
              onChanged: (value) {
                ref.read(customVoucherTemplateProvider.notifier).updateHeaderText(value);
              },
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Fields to Display'),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.person_rounded,
              title: 'Username',
              subtitle: 'Show hotspot username',
              value: template.showUsername,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowUsername(),
            ),
            _buildToggleCard(
              icon: Icons.lock_rounded,
              title: 'Password',
              subtitle: 'Show hotspot password',
              value: template.showPassword,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowPassword(),
            ),
            _buildToggleCard(
              icon: Icons.schedule_rounded,
              title: 'Validity',
              subtitle: 'Show validity period',
              value: template.showValidity,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowValidity(),
            ),
            _buildToggleCard(
              icon: Icons.card_membership_rounded,
              title: 'Profile',
              subtitle: 'Show user profile',
              value: template.showProfile,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowProfile(),
            ),
            _buildToggleCard(
              icon: Icons.payments_rounded,
              title: 'Price',
              subtitle: 'Show voucher price',
              value: template.showPrice,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowPrice(),
            ),
            _buildToggleCard(
              icon: Icons.qr_code_rounded,
              title: 'QR Code',
              subtitle: 'Show WiFi QR code',
              value: template.showQrCode,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowQrCode(),
            ),
            _buildToggleCard(
              icon: Icons.cut_rounded,
              title: 'Cut Lines',
              subtitle: 'Show cut lines for printing',
              value: template.showCutLines,
              onChanged: (_) => ref.read(customVoucherTemplateProvider.notifier).toggleShowCutLines(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Colors'),
            const SizedBox(height: 12),
            _buildColorPicker(
              title: 'Primary Color',
              selectedValue: template.primaryColor,
              options: _colorOptions,
              onChanged: (value) => ref.read(customVoucherTemplateProvider.notifier).updatePrimaryColor(value),
            ),
            const SizedBox(height: 12),
            _buildColorPicker(
              title: 'Background Color',
              selectedValue: template.backgroundColor,
              options: _bgColorOptions,
              onChanged: (value) => ref.read(customVoucherTemplateProvider.notifier).updateBackgroundColor(value),
            ),
            const SizedBox(height: 32),
            _buildResetButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: context.appOnSurface,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPreviewCard(CustomVoucherTemplate template) {
    Color primaryColor;
    try {
      primaryColor = Color(int.parse(template.primaryColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      primaryColor = context.appPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.2),
            primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Live Preview',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        template.companyName,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (template.showQrCode)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(Icons.qr_code, color: Colors.grey.shade600, size: 50),
                        ),
                    ],
                  ),
                ),
                if (template.showUsername || template.showPassword) ...[
                  const Divider(height: 16),
                  if (template.showUsername)
                    _buildPreviewRow(Icons.person_rounded, 'User', 'demo123'),
                  if (template.showPassword)
                    _buildPreviewRow(Icons.lock_rounded, 'Pass', 'password'),
                  if (template.showValidity)
                    _buildPreviewRow(Icons.schedule_rounded, 'Valid', '24 hours'),
                  if (template.showProfile)
                    _buildPreviewRow(Icons.card_membership_rounded, 'Profile', 'default'),
                ],
                if (template.showCutLines) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.content_cut, size: 14, color: Colors.grey.shade400),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: context.appCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.appPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: context.appPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.appPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker({
    required String title,
    required String selectedValue,
    required List<Map<String, String>> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.appOnSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option['value'];
            Color color;
            try {
              color = Color(int.parse(option['value']!.replaceFirst('#', '0xFF')));
            } catch (e) {
              color = Colors.grey;
            }

            return GestureDetector(
              onTap: () => onChanged(option['value']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: context.appOnSurface, width: 2)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  option['name']!,
                  style: TextStyle(
                    color: selectedValue == '#FFFFFF' || selectedValue == '#F59E0B'
                        ? Colors.black
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _resetToDefault,
        icon: const Icon(Icons.restore_rounded),
        label: const Text('Reset to Default'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.appOnSurface,
          side: BorderSide(color: context.appOnSurface.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _saveTemplate() async {
    final template = ref.read(customVoucherTemplateProvider);
    await ref.read(customVoucherTemplateProvider.notifier).setTemplate(template);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Template saved successfully'),
          backgroundColor: context.appSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Reset Template?',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'This will reset all customization to default values.',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(customVoucherTemplateProvider.notifier).setTemplate(const CustomVoucherTemplate());
              _companyNameController.text = 'Hotspot WiFi';
              _headerTextController.text = 'WiFi Voucher';
            },
            style: TextButton.styleFrom(foregroundColor: context.appError),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}