import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/filter_utils.dart';
import '../../utils/show_feedback.dart';
import '../../l10n/translations.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportToCSV(WidgetRef ref) async {
    final incomeAsync = ref.read(incomeProvider);
    final income = incomeAsync.valueOrNull;

    if (income == null || income.transactions.isEmpty) {
      FeedbackUtils.showInfo(
          context, AppStrings.of(context).noTransactionsToExport);
      return;
    }

    try {
      // Generate CSV content
      final buffer = StringBuffer();
      buffer.writeln('Username,Profile,Price,Date,Time,Comment');

      for (final transaction in income.transactions) {
        final date = DateFormat('yyyy-MM-dd').format(transaction.timestamp);
        final time = DateFormat('HH:mm:ss').format(transaction.timestamp);
        final comment = transaction.comment?.replaceAll(',', ';') ?? '';
        buffer.writeln(
            '${transaction.username},${transaction.profile.toUpperCase()},${transaction.price},$date,$time,$comment');
      }

      // Save to file
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/sales_report_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      // Share the file
      if (!mounted) return;
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sales Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
      );
      
      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Report exported successfully!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          AppStrings.of(context).failedToExport.replaceAll('%s', e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/main'),
            tooltip: 'Back',
          ),
          title: Text(
            'Revenue',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.calendar_today_rounded),
              initialValue: incomeAsync.valueOrNull?.filter ?? '30days',
              onSelected: (filter) {
                ref.read(incomeProvider.notifier).setFilter(filter);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: '7days',
                    child: Text('Last 7 Days')),
                const PopupMenuItem(
                    value: '30days',
                    child: Text('Last 30 Days')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.file_download_rounded),
              onPressed: () => _exportToCSV(ref),
              tooltip: 'Export CSV',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(incomeProvider.notifier).refresh(),
            ),
          ],
        ),
        body: Column(
          children: [
            const _SummaryCards(),
            Container(
              color: context.appSurface,
              child: TabBar(
                controller: _tabController,
                labelColor: context.appPrimary,
                unselectedLabelColor:
                    context.appOnSurface.withValues(alpha: 0.6),
                indicatorColor: context.appPrimary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Charts'),
                  Tab(icon: Icon(Icons.pie_chart_rounded), text: 'By Profile'),
                  Tab(
                      icon: Icon(Icons.receipt_long_rounded),
                      text: 'Transactions'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ChartsTab(),
                  _ByProfileTab(),
                  _TransactionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends ConsumerWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        final summary = income.summary;
        final filterLabel = income.filter == '7days' ? 'Last 7 Days' : 'Last 30 Days';

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Today',
                      value: formatCurrency(ref, summary.todayIncome),
                      icon: Icons.today_rounded,
                      color: context.appPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'This Month',
                      value: formatCurrency(ref, summary.thisMonthIncome),
                      icon: Icons.calendar_month_rounded,
                      color: context.appSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Transactions Today',
                      value: summary.transactionsToday.toString(),
                      icon: Icons.receipt_long_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: filterLabel,
                      value: formatCurrency(ref, income.chartPoints.fold(0.0, (sum, p) => sum + p.amount)),
                      icon: Icons.analytics_rounded,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCards(context),
      error: (_, __) => _buildErrorCards(context),
    );
  }

  Widget _buildLoadingCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      child: const Row(
        children: [
          Expanded(child: _CardPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _CardPlaceholder()),
        ],
      ),
    );
  }

  Widget _buildErrorCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      child: const Row(
        children: [
          Expanded(child: _CardPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _CardPlaceholder()),
        ],
      ),
    );
  }


}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
    );
  }
}

class _ChartsTab extends ConsumerWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Revenue Trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      income.filter == '7days' ? '7 Days' : '30 Days',
                      style: TextStyle(
                        color: context.appPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RevenueChart(points: income.chartPoints),
              const SizedBox(height: 24),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...income.transactions.take(5).map((t) => _TransactionCard(transaction: t)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, __) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: context.appError,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load revenue data',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends ConsumerWidget {
  final List<SalesChartPoint> points;

  const _RevenueChart({required this.points});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (points.isEmpty || points.every((p) => p.amount == 0)) {
      return _buildEmptyChart(context);
    }

    final maxAmount = points.fold(0.0, (max, p) => p.amount > max ? p.amount : max);
    final interval = maxAmount > 0 ? (maxAmount / 4).ceilToDouble() : 1000.0;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 8),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval > 0 ? interval : 1.0,
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.appOnSurface.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: points.length > 10 ? 5 : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                  
                  if (points.length > 10 && idx % 5 != 0 && idx != points.length - 1) {
                    return const SizedBox.shrink();
                  }

                  final date = points[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i].amount)),
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: LinearGradient(
                colors: [context.appPrimary, context.appSecondary],
              ),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: points.length < 15,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: context.appCard,
                  strokeWidth: 2,
                  strokeColor: context.appPrimary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.appPrimary.withValues(alpha: 0.2),
                    context.appPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => context.appSurface,
              getTooltipItems: (spots) => spots.map((s) {
                final date = points[s.x.toInt()].date;
                return LineTooltipItem(
                  '${DateFormat('MMM dd').format(date)}\n',
                  TextStyle(color: context.appOnSurface, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: formatCurrency(ref, s.y),
                      style: TextStyle(color: context.appPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: context.appOnSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No revenue data yet',
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ByProfileTab extends ConsumerWidget {
  const _ByProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        if (income.transactions.isEmpty) {
          return _buildEmptyState(context);
        }

        final groupedByProfile = _groupByProfile(income.transactions);
        final sortedProfiles = groupedByProfile.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue by Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...sortedProfiles.map((entry) {
                return _ProfileRevenueCard(
                  profileName: entry.key,
                  revenue: entry.value,
                  transactionCount: income.transactions
                      .where((t) => t.profile == entry.key)
                      .length,
                  rank:
                      sortedProfiles.indexWhere((e) => e.key == entry.key) + 1,
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          Center(child: Text(AppStrings.of(context).connectionError)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No revenue data yet',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _groupByProfile(List<SalesTransaction> transactions) {
    final grouped = <String, double>{};
    for (final transaction in transactions) {
      grouped[transaction.profile] =
          (grouped[transaction.profile] ?? 0) + transaction.price;
    }
    return grouped;
  }
}

class _ProfileRevenueCard extends ConsumerWidget {
  final String profileName;
  final double revenue;
  final int transactionCount;
  final int rank;

  const _ProfileRevenueCard({
    required this.profileName,
    required this.revenue,
    required this.transactionCount,
    required this.rank,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankColor = _getRankColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appCard,
            context.appCard.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName.toUpperCase(),
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$transactionCount transactions',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(ref, revenue),
            style: TextStyle(
              color: context.appPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}

class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab();

  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  String _searchQuery = '';
  String? _selectedProfile;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        final allTransactions = income.transactions;
        var transactions = FilterUtils.filterBySearch<SalesTransaction>(
          allTransactions,
          _searchQuery,
          [(t) => t.username, (t) => t.profile],
        );

        transactions = FilterUtils.filterByField<SalesTransaction>(
          transactions,
          _selectedProfile,
          (t) => t.profile,
        );

        transactions = FilterUtils.filterByDateRange<SalesTransaction>(
          transactions,
          _startDate,
          _endDate,
          (t) => t.timestamp,
        );

        transactions = FilterUtils.sortByDate<SalesTransaction>(
            transactions, (t) => t.timestamp);

        final profiles = FilterUtils.getUniqueValues<SalesTransaction>(
          allTransactions,
          (t) => t.profile,
        );

        return Column(
          children: [
            _FilterBar(
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              selectedProfile: _selectedProfile,
              profiles: profiles,
              onProfileChanged: (profile) {
                setState(() {
                  _selectedProfile = profile;
                });
              },
              startDate: _startDate,
              endDate: _endDate,
              onDateRangeChanged: (start, end) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                });
              },
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return _TransactionCard(
                          transaction: transactions[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          Center(child: Text(AppStrings.of(context).connectionError)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? selectedProfile;
  final List<String> profiles;
  final ValueChanged<String?> onProfileChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;

  const _FilterBar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedProfile,
    required this.profiles,
    required this.onProfileChanged,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => onSearchChanged(''),
                          )
                        : null,
                    filled: true,
                    fillColor: context.appBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showDateRangePicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.appOnSurface.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: context.appOnSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateRange(),
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (profiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text(AppStrings.of(context).allProfiles),
                    selected: selectedProfile == null,
                    onSelected: (selected) {
                      onProfileChanged(selected ? null : '');
                    },
                  ),
                  ...profiles.map((profile) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(profile.toUpperCase()),
                        selected: selectedProfile == profile,
                        onSelected: (selected) {
                          onProfileChanged(selected ? profile : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange() {
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    } else if (startDate != null) {
      return '${_formatDate(startDate!)} - Now';
    } else if (endDate != null) {
      return 'Until ${_formatDate(endDate!)}';
    }
    return 'All Time';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Color(0xFFE2E8F0),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }
}

class _TransactionCard extends ConsumerWidget {
  final SalesTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.username,
                      style: TextStyle(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.profile.toUpperCase(),
                      style: TextStyle(
                        color: context.appPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatCurrency(ref, transaction.price),
                style: TextStyle(
                  color: context.appSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: context.appOnSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimestamp(transaction.timestamp),
                style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              if (transaction.comment != null) ...[
                Icon(
                  Icons.comment_rounded,
                  size: 16,
                  color: context.appOnSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transaction.comment!,
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }



  String _formatTimestamp(DateTime timestamp) {
    return FilterUtils.formatRelativeTime(timestamp);
  }
}

String formatCurrency(WidgetRef ref, double value) {
  final cache = ref.read(cacheServiceProvider);
  final settings = cache.getAppSettings();
  final currencyCode = settings?['currency'] as String? ?? 'USD';
  final currencyInfo = CurrencyData.fromCode(currencyCode);
  return CurrencyFormatter.format(value, currencyInfo);
}
