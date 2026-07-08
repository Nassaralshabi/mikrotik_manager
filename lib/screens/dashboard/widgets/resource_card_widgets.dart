import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models.dart';
import '../../../providers/app_providers.dart';

// Optimized resource card widget with RepaintBoundary
class ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double usagePercent;
  final String? subtitle;

  const ResourceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.usagePercent,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
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
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildValue(context),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                _buildSubtitle(context),
              ],
              const SizedBox(height: 12),
              _buildProgressBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: context.appPrimary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValue(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: context.appOnSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      subtitle!,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: context.appOnSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final isError = usagePercent > 0.8;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: usagePercent.clamp(0.0, 1.0),
        backgroundColor: context.appOnSurface.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          isError ? context.appError : context.appPrimary,
        ),
        minHeight: 6,
      ),
    );
  }
}

// Real-time CPU Load card that listens to resources updates
class CpuLoadCard extends StatelessWidget {
  final ValueNotifier<SystemResources?> resourcesNotifier;

  const CpuLoadCard({
    super.key,
    required this.resourcesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SystemResources?>(
      valueListenable: resourcesNotifier,
      builder: (context, resources, _) {
        final cpuLoad = resources?.cpuLoad ?? 0;
        return ResourceCard(
          icon: Icons.memory_rounded,
          title: 'CPU Load',
          value: '$cpuLoad%',
          usagePercent: cpuLoad / 100,
        );
      },
    );
  }
}

// Real-time Memory card that listens to resources updates
class MemoryCard extends StatelessWidget {
  final ValueNotifier<SystemResources?> resourcesNotifier;

  const MemoryCard({
    super.key,
    required this.resourcesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SystemResources?>(
      valueListenable: resourcesNotifier,
      builder: (context, resources, _) {
        final freeMemory = resources?.freeMemory ?? 0;
        final totalMemory = resources?.totalMemory ?? 0;
        final usedMemory = totalMemory - freeMemory;
        final memoryUsagePercent = totalMemory > 0
            ? ((totalMemory - freeMemory) / totalMemory).toDouble()
            : 0.0;

        return ResourceCard(
          icon: Icons.storage_rounded,
          title: 'Memory',
          value: '${(usedMemory / 1024 / 1024).toStringAsFixed(1)} MB',
          usagePercent: memoryUsagePercent,
          subtitle: '${(totalMemory / 1024 / 1024).toStringAsFixed(0)} MB Total',
        );
      },
    );
  }
}

// Real-time Disk card that listens to resources updates
class DiskCard extends StatelessWidget {
  final ValueNotifier<SystemResources?> resourcesNotifier;

  const DiskCard({
    super.key,
    required this.resourcesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SystemResources?>(
      valueListenable: resourcesNotifier,
      builder: (context, resources, _) {
        final freeHddSpace = resources?.freeHddSpace ?? 0;
        final totalHddSpace = resources?.totalHddSpace ?? 0;
        final usedHdd = totalHddSpace - freeHddSpace;
        final hddUsagePercent = totalHddSpace > 0
            ? ((totalHddSpace - freeHddSpace) / totalHddSpace).toDouble()
            : 0.0;

        return ResourceCard(
          icon: Icons.sd_storage_rounded,
          title: 'Disk',
          value: '${(usedHdd / 1024 / 1024).toStringAsFixed(1)} MB',
          usagePercent: hddUsagePercent,
          subtitle: '${(totalHddSpace / 1024 / 1024).toStringAsFixed(0)} MB Total',
        );
      },
    );
  }
}

// Daily Income card - shows today's revenue
class DailyIncomeCard extends ConsumerWidget {
  const DailyIncomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(incomeProvider).when(
      data: (incomeState) {
        return _IncomeCard(
          icon: Icons.attach_money_rounded,
          title: 'Today\'s Income',
          value: '\$${incomeState.summary.todayIncome.toStringAsFixed(2)}',
          subtitle: '${incomeState.summary.transactionsToday} transaction${incomeState.summary.transactionsToday != 1 ? 's' : ''}',
          color: Colors.green,
        );
      },
      loading: () => const _IncomeCard(
        icon: Icons.attach_money_rounded,
        title: 'Today\'s Income',
        value: '\$0.00',
        subtitle: 'Loading...',
        color: Colors.green,
      ),
      error: (_, __) => const _IncomeCard(
        icon: Icons.attach_money_rounded,
        title: 'Today\'s Income',
        value: '\$0.00',
        subtitle: 'Error loading',
        color: Colors.green,
      ),
    );
  }
}

// Monthly Income card - shows this month's revenue
class MonthlyIncomeCard extends ConsumerWidget {
  const MonthlyIncomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(incomeProvider).when(
      data: (incomeState) {
        return _IncomeCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'This Month',
          value: '\$${incomeState.summary.thisMonthIncome.toStringAsFixed(2)}',
          subtitle: '${incomeState.summary.transactionsThisMonth} transaction${incomeState.summary.transactionsThisMonth != 1 ? 's' : ''}',
          color: Colors.blue,
        );
      },
      loading: () => _IncomeCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'This Month',
        value: '\$0.00',
        subtitle: 'Loading...',
        color: Colors.blue,
      ),
      error: (_, __) => _IncomeCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'This Month',
        value: '\$0.00',
        subtitle: 'Error loading',
        color: Colors.blue,
      ),
    );
  }
}

// Custom Income Card widget without progress bar
class _IncomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _IncomeCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
