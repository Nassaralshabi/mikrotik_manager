import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/cache_service.dart';
import '../../services/models.dart';
import '../../services/template_service.dart';
import '../../services/onboarding_service.dart';
import '../../l10n/translations.dart';
import '../../l10n/locale_provider.dart';
import '../../utils/currency_formatter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _companyController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  void _initFromCache() {
    if (_initialized) return;
    _initialized = true;
    final cache = CacheService();
    final settings = cache.getAppSettings();
    if (settings != null && settings['companyName'] != null) {
      _companyController.text = settings['companyName'];
    }
  }

  @override
  Widget build(BuildContext context) {
    _initFromCache();
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/main'),
        ),
        title: Text(
          AppStrings.of(context).settings,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, AppStrings.of(context).appearance),
          const SizedBox(height: 8),
          _buildThemeCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppStrings.of(context).general),
          const SizedBox(height: 8),
          _buildGeneralCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppStrings.of(context).voucherTemplates),
          const SizedBox(height: 8),
          _buildTemplateCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppStrings.of(context).logs),
          const SizedBox(height: 8),
          _buildLogsCard(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppStrings.of(context).connections),
          const SizedBox(height: 8),
          _buildSavedRoutersCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppStrings.of(context).account),
          const SizedBox(height: 8),
          _buildLogoutCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, AppStrings.of(context).about),
          const SizedBox(height: 8),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.appOnBackground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            ref,
            icon: Icons.auto_awesome_rounded,
            title: AppStrings.of(context).purpleTheme,
            subtitle: AppStrings.of(context).defaultVibrantPurple,
            color: const Color(0xFF7C3AED),
            mode: AppThemeMode.purple,
            currentMode: currentTheme,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.wb_sunny_rounded,
            title: AppStrings.of(context).lightTheme,
            subtitle: AppStrings.of(context).cleanModernLook,
            color: const Color(0xFFF8FAFC),
            mode: AppThemeMode.light,
            currentMode: currentTheme,
            iconColor: const Color(0xFF7C3AED),
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.waves_rounded,
            title: AppStrings.of(context).blueTheme,
            subtitle: AppStrings.of(context).oceanBlueVibes,
            color: const Color(0xFF2563EB),
            mode: AppThemeMode.blue,
            currentMode: currentTheme,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.eco_rounded,
            title: AppStrings.of(context).greenTheme,
            subtitle: AppStrings.of(context).natureInspiredGreen,
            color: const Color(0xFF10B981),
            mode: AppThemeMode.green,
            currentMode: currentTheme,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.favorite_rounded,
            title: AppStrings.of(context).pinkTheme,
            subtitle: AppStrings.of(context).romanticPinkVibes,
            color: const Color(0xFFEC4899),
            mode: AppThemeMode.pink,
            currentMode: currentTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required AppThemeMode mode,
    required AppThemeMode currentMode,
    Color? iconColor,
  }) {
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: iconColor ?? color,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: iconColor ?? color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: iconColor ?? color,
                size: 24,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralCard(BuildContext context, WidgetRef ref) {
    final cache = CacheService();
    final settings = cache.getAppSettings();
    final currentLocale = ref.watch(localeProvider);
    final selectedCountry = settings?['country'] as String?;
    final selectedCurrency = settings?['currency'] as String?;

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Language
            _buildSettingsTile(
              context,
              icon: Icons.language_rounded,
              title: AppStrings.of(context).language,
              subtitle: LocaleService.localeNames[currentLocale.languageCode] ??
                  'English',
              trailing:
                  '${LocaleService.localeFlags[currentLocale.languageCode] ?? ''} ',
              onTap: () => _showLanguageDialog(context, ref),
            ),
            Divider(color: context.appOnSurface.withValues(alpha: 0.08)),
            // Country
            _buildSettingsTile(
              context,
              icon: Icons.public_rounded,
              title: AppStrings.of(context).country,
              subtitle: selectedCountry ?? AppStrings.of(context).notSet,
              onTap: () => _showCountryDialog(context, ref, cache),
            ),
            Divider(color: context.appOnSurface.withValues(alpha: 0.08)),
            // Currency
            _buildSettingsTile(
              context,
              icon: Icons.attach_money_rounded,
              title: AppStrings.of(context).currency,
              subtitle: selectedCurrency ?? AppStrings.of(context).notSet,
              onTap: () => _showCurrencyDialog(context, ref, cache),
            ),
            Divider(color: context.appOnSurface.withValues(alpha: 0.08)),
            // Business Name
            _buildSettingsTile(
              context,
              icon: Icons.business_rounded,
              title: AppStrings.of(context).businessName,
              subtitle:
                  (settings?['companyName'] as String?)?.isNotEmpty == true
                      ? settings!['companyName']
                      : AppStrings.of(context).notSet,
              onTap: () => _showCompanyDialog(context, ref, cache),
            ),
            Divider(color: context.appOnSurface.withValues(alpha: 0.08)),
            // Login URL
            _buildSettingsTile(
              context,
              icon: Icons.link_rounded,
              title: 'Login URL',
              subtitle: (settings?['loginUrl'] as String?)?.isNotEmpty == true
                  ? settings!['loginUrl']
                  : 'http://wifi.local',
              onTap: () => _showLoginUrlDialog(context, ref, cache),
            ),
            Divider(color: context.appOnSurface.withValues(alpha: 0.08)),
            // Reset Onboarding
            _buildSettingsTile(
              context,
              icon: Icons.refresh_rounded,
              title: 'Reset Onboarding',
              subtitle: 'Show welcome screens again',
              onTap: () => _showResetOnboardingDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetOnboardingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Onboarding?'),
        content: Text(
            'You will see the welcome screens next time you open the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await OnboardingService.clearAll();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: context.appPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.appOnSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appOnSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing, style: const TextStyle(fontSize: 16)),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appOnSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).language,
            style: TextStyle(color: context.appOnSurface)),
        children: LocaleService.localeNames.entries.map((e) {
          return SimpleDialogOption(
            onPressed: () {
              ref.read(localeProvider.notifier).setLocale(Locale(e.key));
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Text(LocaleService.localeFlags[e.key] ?? '',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(e.value, style: TextStyle(color: context.appOnSurface)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCountryDialog(
      BuildContext context, WidgetRef ref, CacheService cache) {
    final countries = [
      'Indonesia',
      'Malaysia',
      'Philippines',
      'Thailand',
      'Vietnam',
      'Singapore',
      'Cambodia',
      'Myanmar',
      'Laos',
      'Bangladesh',
      'India',
      'Pakistan',
      'Nigeria',
      'Kenya',
      'Tanzania',
      'South Africa',
      'Brazil',
      'Other',
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).country,
            style: TextStyle(color: context.appOnSurface)),
        children: countries.map((c) {
          return SimpleDialogOption(
            onPressed: () async {
              final current = cache.getAppSettings() ?? {};
              await cache.saveAppSettings(
                country: c,
                currency: current['currency'] ?? 'USD',
                companyName: current['companyName'] ?? '',
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) setState(() {});
            },
            child: Text(c, style: TextStyle(color: context.appOnSurface)),
          );
        }).toList(),
      ),
    );
  }

  void _showCurrencyDialog(
      BuildContext context, WidgetRef ref, CacheService cache) {
    final currencies = CurrencyData.allCurrencies;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: context.appSurface,
        title: Text(AppStrings.of(context).currency,
            style: TextStyle(color: context.appOnSurface)),
        children: currencies.map((e) {
          return SimpleDialogOption(
            onPressed: () async {
              // Update cache
              final current = cache.getAppSettings() ?? {};
              await cache.saveAppSettings(
                country: current['country'] ?? '',
                currency: e.code,
                companyName: current['companyName'] ?? '',
              );

              // Update currency provider
              ref.read(currencyProvider.notifier).setCurrency(e.code);

              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) setState(() {});
            },
            child: Row(
              children: [
                Text(e.symbol,
                    style: TextStyle(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${e.code} - ${e.name}',
                      style: TextStyle(color: context.appOnSurface)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCompanyDialog(
      BuildContext context, WidgetRef ref, CacheService cache) {
    final controller = TextEditingController(
      text: cache.getAppSettings()?['companyName'] ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => _CompanyNameDialog(
        controller: controller,
        onSave: () async {
          final current = cache.getAppSettings() ?? {};
          await cache.saveAppSettings(
            country: current['country'] ?? '',
            currency: current['currency'] ?? 'USD',
            companyName: controller.text.trim(),
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) setState(() {});
        },
      ),
    );
  }

  void _showLoginUrlDialog(
      BuildContext context, WidgetRef ref, CacheService cache) {
    final controller = TextEditingController(
      text: cache.getAppSettings()?['loginUrl'] ?? 'http://wifi.local',
    );
    showDialog(
      context: context,
      builder: (ctx) => _LoginUrlDialog(
        controller: controller,
        onSave: () async {
          final current = cache.getAppSettings() ?? {};
          await cache.saveAppSettings(
            country: current['country'] ?? '',
            currency: current['currency'] ?? 'USD',
            companyName: current['companyName'] ?? '',
            loginUrl: controller.text.trim(),
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) setState(() {});
        },
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WidgetRef ref) {
    final currentTemplate = ref.watch(voucherTemplateProvider);

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTemplateOption(
            context,
            ref,
            icon: Icons.description_rounded,
            title: 'Full Size',
            subtitle: 'Complete voucher with all details and cut lines',
            color: const Color(0xFF7C3AED),
            template: VoucherTemplate.full,
            currentTemplate: currentTemplate,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildTemplateOption(
            context,
            ref,
            icon: Icons.notes_rounded,
            title: 'Compact',
            subtitle: 'Smaller voucher with essential info',
            color: const Color(0xFF06B6D4),
            template: VoucherTemplate.compact,
            currentTemplate: currentTemplate,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildTemplateOption(
            context,
            ref,
            icon: Icons.receipt_rounded,
            title: 'Minimal',
            subtitle: 'Simple design with QR and credentials only',
            color: const Color(0xFF10B981),
            template: VoucherTemplate.minimal,
            currentTemplate: currentTemplate,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildTemplateOption(
            context,
            ref,
            icon: Icons.style_rounded,
            title: 'Classic',
            subtitle: 'Traditional layout with price on side',
            color: const Color(0xFFF59E0B),
            template: VoucherTemplate.classic,
            currentTemplate: currentTemplate,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildTemplateOption(
            context,
            ref,
            icon: Icons.auto_awesome_rounded,
            title: 'Modern',
            subtitle: 'Colorful design with price badge',
            color: const Color(0xFFEC4899),
            template: VoucherTemplate.modern,
            currentTemplate: currentTemplate,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildTemplateOption(
            context,
            ref,
            icon: Icons.view_agenda_rounded,
            title: 'Compact Alt',
            subtitle: 'Compact list style voucher',
            color: const Color(0xFF6366F1),
            template: VoucherTemplate.compactAlt,
            currentTemplate: currentTemplate,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          InkWell(
            onTap: () => context.push('/main/settings/voucher-template'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Template',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.appOnSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Customize voucher text, fields and colors',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appOnSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoucherTemplate template,
    required VoucherTemplate currentTemplate,
  }) {
    final isSelected = template == currentTemplate;

    return InkWell(
      onTap: () =>
          ref.read(voucherTemplateProvider.notifier).setTemplate(template),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: color,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 24,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard(BuildContext context) {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/main/logs'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF6366F1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.of(context).activityLogs,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.of(context).viewUserActions,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedRoutersCard(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(savedConnectionsProvider);

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    color: context.appPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.of(context).savedRouters,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: context.appOnSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      connectionsAsync.when(
                        data: (connections) {
                          return Text(
                            '${connections.length} ${AppStrings.of(context).saved.toLowerCase()}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          );
                        },
                        loading: () => Text(
                          AppStrings.of(context).loading,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    context.appOnSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: context.appPrimary,
                  onPressed: () => _showAddRouterDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            connectionsAsync.when(
              data: (connections) {
                if (connections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        AppStrings.of(context).noSavedRouters,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: connections.map((conn) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildConnectionTile(context, ref, conn),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(
      BuildContext context, WidgetRef ref, RouterConnection connection) {
    return InkWell(
      onTap: () => _showEditRouterDialog(context, ref, connection),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.router_rounded,
              color: context.appPrimary.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connection.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: context.appOnSurface.withValues(alpha: 0.6),
              iconSize: 20,
              onPressed: () => _showEditRouterDialog(context, ref, connection),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: context.appError,
              iconSize: 20,
              onPressed: () => _showDeleteDialog(context, ref, connection),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, RouterConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          AppStrings.of(context).deleteConnectionTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
              ),
        ),
        content: Text(
          AppStrings.of(context).removeConnection(connection.name),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface.withValues(alpha: 0.8),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.of(context).cancel,
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(savedConnectionsProvider.notifier)
                  .deleteConnection(connection.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '${AppStrings.of(context).deletedSuccess} "${connection.name}"')),
              );
            },
            child: Text(
              AppStrings.of(context).delete,
              style: TextStyle(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLogoutDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.of(context).logout,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.of(context).disconnectFromRouter,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          AppStrings.of(context).logoutTitle,
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          AppStrings.of(context).confirmLogout,
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: Text(AppStrings.of(context).logout,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAboutDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.of(context).about,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.of(context).version} 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appPrimary,
                      context.appSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.router_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // App Name
              Text(
                'ΩMMON',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),

              // Tagline
              Text(
                AppStrings.of(context).onboardingSubtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),

              // Version
              Text(
                '${AppStrings.of(context).version} 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                AppStrings.of(context).appDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),

              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      context.appOnSurface.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Developers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.code_rounded,
                    color: context.appPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.of(context).developedBy,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Developer Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildDeveloperCard(
                      context,
                      name: 'Favian Hugo',
                      icon: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDeveloperCard(
                      context,
                      name: 'Syarif Abdurrahman',
                      icon: Icons.person_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close Button
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(AppStrings.of(context).close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(
    BuildContext context, {
    required String name,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: context.appBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: context.appPrimary,
            size: 28,
          ),
          const SizedBox(height: 8),
          // Use FittedBox to prevent text overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add a new router connection
  void _showAddRouterDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final hostController = TextEditingController();
    final portController = TextEditingController(text: '8728');
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _RouterConnectionDialog(
        title: AppStrings.of(context).addRouter,
        nameController: nameController,
        hostController: hostController,
        portController: portController,
        usernameController: usernameController,
        onSave: () {
          if (nameController.text.trim().isEmpty ||
              hostController.text.trim().isEmpty ||
              usernameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.of(context).fillAllFields)),
            );
            return;
          }

          ref.read(savedConnectionsProvider.notifier).addConnection(
                name: nameController.text.trim(),
                host: hostController.text.trim(),
                port: portController.text.trim(),
                username: usernameController.text.trim(),
              );

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${AppStrings.of(context).addedSuccess} "${nameController.text.trim()}"')),
          );
        },
      ),
    );
  }

  /// Show dialog to edit an existing router connection
  void _showEditRouterDialog(
      BuildContext context, WidgetRef ref, RouterConnection connection) {
    final nameController = TextEditingController(text: connection.name);
    final hostController = TextEditingController(text: connection.host);
    final portController = TextEditingController(text: connection.port);
    final usernameController = TextEditingController(text: connection.username);

    showDialog(
      context: context,
      builder: (context) => _RouterConnectionDialog(
        title: AppStrings.of(context).editRouterTitle,
        nameController: nameController,
        hostController: hostController,
        portController: portController,
        usernameController: usernameController,
        onSave: () {
          if (nameController.text.trim().isEmpty ||
              hostController.text.trim().isEmpty ||
              usernameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.of(context).fillAllFields)),
            );
            return;
          }

          final updatedConnection = RouterConnection(
            id: connection.id,
            name: nameController.text.trim(),
            host: hostController.text.trim(),
            port: portController.text.trim(),
            username: usernameController.text.trim(),
            createdAt: connection.createdAt,
          );

          ref
              .read(savedConnectionsProvider.notifier)
              .updateConnection(updatedConnection);

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${AppStrings.of(context).updatedSuccess} "${nameController.text.trim()}"')),
          );
        },
      ),
    );
  }
}

/// Dialog widget for adding/editing router connections
class _RouterConnectionDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final VoidCallback onSave;

  const _RouterConnectionDialog({
    required this.title,
    required this.nameController,
    required this.hostController,
    required this.portController,
    required this.usernameController,
    required this.onSave,
  });

  @override
  State<_RouterConnectionDialog> createState() =>
      _RouterConnectionDialogState();
}

class _RouterConnectionDialogState extends State<_RouterConnectionDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    widget.nameController.dispose();
    widget.hostController.dispose();
    widget.portController.dispose();
    widget.usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.appPrimary.withValues(alpha: 0.2),
                            context.appSecondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.router_rounded,
                        color: context.appPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: context.appOnSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.of(context).enterRouterDetails,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(context).connectionNameLabel,
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: AppStrings.of(context).connectionNameHint,
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.bookmark_rounded, color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a connection name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Host Field
                TextFormField(
                  controller: widget.hostController,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(context).hostLabel,
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: AppStrings.of(context).hostHint,
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.computer_rounded, color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a host or IP address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Port Field
                TextFormField(
                  controller: widget.portController,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(context).portLabel,
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: AppStrings.of(context).portHint,
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.settings_ethernet_rounded,
                        color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a port number';
                    }
                    final port = int.tryParse(value.trim());
                    if (port == null || port < 1 || port > 65535) {
                      return 'Please enter a valid port (1-65535)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username Field
                TextFormField(
                  controller: widget.usernameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.of(context).usernameLabel,
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: AppStrings.of(context).usernameHint,
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.person_rounded, color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Note about password
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: context.appPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.of(context).passwordNoteLong,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.appOnSurface,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              context.appOnSurface.withValues(alpha: 0.7),
                          side: BorderSide(
                            color: context.appOnSurface.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppStrings.of(context).cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(AppStrings.of(context).save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyNameDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _CompanyNameDialog({
    required this.controller,
    required this.onSave,
  });

  @override
  State<_CompanyNameDialog> createState() => _CompanyNameDialogState();
}

class _CompanyNameDialogState extends State<_CompanyNameDialog> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Text(AppStrings.of(context).businessName,
          style: TextStyle(color: context.appOnSurface)),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppStrings.of(context).businessNameHint,
          filled: true,
          fillColor: context.appBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        style: TextStyle(color: context.appOnSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: widget.onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(AppStrings.of(context).save),
        ),
      ],
    );
  }
}

class _LoginUrlDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _LoginUrlDialog({
    required this.controller,
    required this.onSave,
  });

  @override
  State<_LoginUrlDialog> createState() => _LoginUrlDialogState();
}

class _LoginUrlDialogState extends State<_LoginUrlDialog> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appSurface,
      title: Text('Login URL', style: TextStyle(color: context.appOnSurface)),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'http://wifi.local',
          helperText: 'Hotspot server DNS name (e.g., http://wifi.local)',
          filled: true,
          fillColor: context.appBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        style: TextStyle(color: context.appOnSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: widget.onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.appPrimary,
            foregroundColor: Colors.white,
          ),
          child: Text(AppStrings.of(context).save),
        ),
      ],
    );
  }
}
