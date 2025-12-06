import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';

class UsersReportView extends StatefulWidget {
  const UsersReportView({
    super.key,
    required this.repository,
    required this.startDate,
    required this.endDate,
  });

  final BackendRepository repository;
  final DateTime startDate;
  final DateTime endDate;

  @override
  State<UsersReportView> createState() => _UsersReportViewState();
}

class _UsersReportViewState extends State<UsersReportView> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadUsersReport();
  }

  Future<Map<String, dynamic>> _loadUsersReport() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'totalUsers': 245,
      'activeUsers': 156,
      'inactiveUsers': 67,
      'bannedUsers': 22,
      'newUsersThisMonth': 34,
      'avgSessionTime': '2.5 ساعة',
      'totalDataUsage': '2.4 TB',
      'topUsers': [
        {
          'username': 'user001',
          'dataUsage': '45.2 GB',
          'sessionTime': '48 ساعة',
          'lastSeen': '2024-01-07',
        },
        {
          'username': 'user002',
          'dataUsage': '38.7 GB',
          'sessionTime': '42 ساعة',
          'lastSeen': '2024-01-07',
        },
        {
          'username': 'user003',
          'dataUsage': '33.1 GB',
          'sessionTime': '35 ساعة',
          'lastSeen': '2024-01-06',
        },
      ],
      'hourlyActivity': [
        {'hour': 0, 'users': 12},
        {'hour': 6, 'users': 34},
        {'hour': 12, 'users': 89},
        {'hour': 18, 'users': 156},
        {'hour': 24, 'users': 67},
      ],
      'weeklyStats': [
        {'day': 'الأحد', 'newUsers': 8, 'activeUsers': 89},
        {'day': 'الإثنين', 'newUsers': 12, 'activeUsers': 134},
        {'day': 'الثلاثاء', 'newUsers': 6, 'activeUsers': 156},
        {'day': 'الأربعاء', 'newUsers': 9, 'activeUsers': 145},
        {'day': 'الخميس', 'newUsers': 15, 'activeUsers': 167},
        {'day': 'الجمعة', 'newUsers': 18, 'activeUsers': 198},
        {'day': 'السبت', 'newUsers': 21, 'activeUsers': 201},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المستخدمين'),
        actions: [
          IconButton(
            onPressed: _exportReport,
            icon: const Icon(Icons.file_download),
            tooltip: 'تصدير التقرير',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingStateView();
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          
          final data = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ملخص المستخدمين
                _buildUsersSummary(data),
                const SizedBox(height: 24),
                
                // النشاط الأسبوعي
                _buildWeeklyActivityChart(data),
                const SizedBox(height: 24),
                
                // النشاط اليومي
                _buildDailyActivityChart(data),
                const SizedBox(height: 24),
                
                // أكثر المستخدمين نشاطاً
                _buildTopUsersTable(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsersSummary(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائيات المستخدمين (${DateFormat('yyyy/MM/dd').format(widget.startDate)} - ${DateFormat('yyyy/MM/dd').format(widget.endDate)})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.0,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _SummaryCard(
              title: 'إجمالي المستخدمين',
              value: '${data['totalUsers']}',
              icon: Icons.people,
              color: const Color(0xFF0066FF),
            ),
            _SummaryCard(
              title: 'المستخدمون النشطون',
              value: '${data['activeUsers']}',
              icon: Icons.people_alt,
              color: const Color(0xFF00B894),
            ),
            _SummaryCard(
              title: 'مستخدمون جدد',
              value: '${data['newUsersThisMonth']}',
              icon: Icons.person_add,
              color: const Color(0xFFFF8C42),
            ),
            _SummaryCard(
              title: 'المستخدمون المحظورون',
              value: '${data['bannedUsers']}',
              icon: Icons.block,
              color: const Color(0xFFE74C3C),
            ),
            _SummaryCard(
              title: 'متوسط وقت الجلسة',
              value: data['avgSessionTime'],
              icon: Icons.access_time,
              color: const Color(0xFF6C63FF),
            ),
            _SummaryCard(
              title: 'إجمالي استخدام البيانات',
              value: data['totalDataUsage'],
              icon: Icons.data_usage,
              color: const Color(0xFF9B59B6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyActivityChart(Map<String, dynamic> data) {
    final weeklyStats = data['weeklyStats'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'النشاط الأسبوعي',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < weeklyStats.length) {
                            return Text(weeklyStats[value.toInt()]['day']);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyStats.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['activeUsers'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF0066FF),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: weeklyStats.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['newUsers'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF00B894),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem('المستخدمون النشطون', const Color(0xFF0066FF)),
                const SizedBox(width: 24),
                _LegendItem('مستخدمون جدد', const Color(0xFF00B894)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyActivityChart(Map<String, dynamic> data) {
    final hourlyActivity = data['hourlyActivity'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'النشاط على مدار اليوم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < hourlyActivity.length) {
                            return Text('${hourlyActivity[value.toInt()]['hour']}');
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: hourlyActivity.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['users'].toDouble(),
                          color: const Color(0xFF0066FF),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUsersTable(Map<String, dynamic> data) {
    final topUsers = data['topUsers'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أكثر المستخدمين نشاطاً',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFF8F9FA)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('المستخدم', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('استخدام البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('وقت الجلسة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('آخر ظهور', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...topUsers.map((user) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(user['username']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(user['dataUsage']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(user['sessionTime']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(user['lastSeen']),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: تصدير تقرير المستخدمين')),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(this.title, this.color);

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}