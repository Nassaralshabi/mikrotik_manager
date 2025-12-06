import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/router_session.dart';
import '../../data/models/service_card.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/backend_repository.dart';
import '../../data/repositories/data_mode.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});

  final BackendRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  late Future<_DashboardPayload> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
  }

  Future<_DashboardPayload> _loadDashboardData() async {
    final results = await Future.wait([
      widget.repository.activeSessions(),
      widget.repository.profiles(),
      widget.repository.cards(),
    ]);
    return _DashboardPayload(
      sessions: results[0] as List<RouterSession>,
      profiles: results[1] as List<UserProfile>,
      cards: results[2] as List<ServiceCard>,
    );
  }

  Future<void> _handleRefresh() async {
    final newFuture = _loadDashboardData();
    setState(() {
      _dashboardFuture = newFuture;
    });
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<_DashboardPayload>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingStateView();
        }
        if (snapshot.hasError) {
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        final payload = snapshot.data!;
        final sessions = payload.sessions;
        final profiles = payload.profiles;
        final cards = payload.cards;
        final activeUsers = profiles.where((p) => !p.isSuspended).length;
        final suspendedUsers = profiles.length - activeUsers;
        final availableCards = cards.where((c) => c.status.contains('متاحة')).length;
        final avgDownload = sessions.isEmpty
            ? 0
            : sessions.map((s) => s.downloadMbps).reduce((a, b) => a + b) / sessions.length;
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryGrid(
                  items: [
                    SummaryCard(
                      title: 'المشتركين النشطين',
                      value: activeUsers.toString(),
                      subtitle: 'الموقوف: $suspendedUsers',
                      icon: Icons.people_alt,
                      color: const Color(0xFF0066FF),
                    ),
                    SummaryCard(
                      title: 'الجلسات المباشرة',
                      value: sessions.length.toString(),
                      subtitle: 'متوسط التنزيل ${avgDownload.toStringAsFixed(1)} Mbps',
                      icon: Icons.wifi_tethering,
                      color: const Color(0xFF00B894),
                    ),
                    SummaryCard(
                      title: 'البطاقات المتاحة',
                      value: availableCards.toString(),
                      subtitle: 'مجموع الخطط ${cards.length}',
                      icon: Icons.credit_card,
                      color: const Color(0xFFFF8C42),
                    ),
                    SummaryCard(
                      title: 'نسخ احتياطي اليوم',
                      value: '3 مهام',
                      subtitle: _connectionSubtitle,
                      icon: Icons.backup_table,
                      color: const Color(0xFF6C63FF),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'مراقبة معدل النقل'),
                SizedBox(
                  height: 260,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _ThroughputChart(points: widget.repository.throughputSeries()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: 'أحدث الجلسات النشطة'),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(session.username.characters.first.toUpperCase())),
                        title: Text(session.username),
                        subtitle: Text('IP ${session.ipAddress} · مدة ${_formatDuration(session.uptime)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${session.downloadMbps.toStringAsFixed(1)} Mbps'),
                            Text('رفع ${session.uploadMbps.toStringAsFixed(1)}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _connectionSubtitle {
    switch (widget.repository.mode) {
      case DataMode.router:
        return 'متصل بالراوتر مباشرة';
      case DataMode.backend:
        return 'عبر خادم PHP';
      case DataMode.mock:
        return 'وضع محاكاة';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '$hoursس $minutesد';
  }

  @override
  bool get wantKeepAlive => true;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxis = 1;
        if (width >= 1100) {
          crossAxis = 4;
        } else if (width >= 880) {
          crossAxis = 3;
        } else if (width >= 600) {
          crossAxis = 2;
        }
        final itemWidth = width / crossAxis - 12;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items.map((item) => SizedBox(width: crossAxis == 1 ? width : itemWidth, child: item)).toList(),
        );
      },
    );
  }
}

class _DashboardPayload {
  const _DashboardPayload({
    required this.sessions,
    required this.profiles,
    required this.cards,
  });

  final List<RouterSession> sessions;
  final List<UserProfile> profiles;
  final List<ServiceCard> cards;
}

class _ThroughputChart extends StatelessWidget {
  const _ThroughputChart({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) => Text('س${value.toInt()}'),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i])
            ],
            isCurved: true,
            barWidth: 4,
            gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [scheme.primary.withOpacity(.3), scheme.primary.withOpacity(.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
