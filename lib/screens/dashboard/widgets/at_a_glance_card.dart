import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../utils/currency_formatter.dart';

/// A compact "Quick Info" summary card showing key metrics
class AtAGlanceCard extends ConsumerWidget {
  const AtAGlanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(hotspotUsersProvider);
    final incomeAsync = ref.watch(incomeProvider);
    
    final cache = ref.read(cacheServiceProvider);
    final settings = cache.getAppSettings();
    final currencyCode = settings?['currency'] as String? ?? 'USD';

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.go('/main/users'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dashboard_rounded,
                    color: context.appPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Info',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: context.appOnSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      usersAsync,
                      incomeAsync,
                      currencyCode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context,
    AsyncValue usersAsync,
    AsyncValue incomeAsync,
    String currencyCode,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // Online users
            Expanded(
              child: _buildMetric(
                context,
                icon: Icons.wifi_rounded,
                color: Colors.green,
                label: 'Online',
                value: usersAsync.when(
                  data: (paginatedUsers) => '${paginatedUsers.activeUsernames.length}',
                  loading: () => '-',
                  error: (_, __) => '-',
                ),
              ),
            ),
            // Total users
            Expanded(
              child: _buildMetric(
                context,
                icon: Icons.people_rounded,
                color: context.appPrimary,
                label: 'Total',
                value: usersAsync.when(
                  data: (paginatedUsers) => '${paginatedUsers.totalCount}',
                  loading: () => '-',
                  error: (_, __) => '-',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Today's revenue
            Expanded(
              child: _buildMetric(
                context,
                icon: Icons.today_rounded,
                color: Colors.amber,
                label: 'Today',
                value: incomeAsync.when(
                  data: (income) => _formatCurrency(income.summary.todayIncome, currencyCode),
                  loading: () => '-',
                  error: (_, __) => '-',
                ),
              ),
            ),
            // This Month revenue
            Expanded(
              child: _buildMetric(
                context,
                icon: Icons.calendar_month_rounded,
                color: Colors.orange,
                label: 'Month',
                value: incomeAsync.when(
                  data: (income) =>
                      _formatCurrency(income.summary.thisMonthIncome, currencyCode),
                  loading: () => '-',
                  error: (_, __) => '-',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatCurrency(double amount, String currencyCode) {
    final currencyInfo = CurrencyData.fromCode(currencyCode);
    return CurrencyFormatter.formatCompact(amount, currencyInfo);
  }
}
