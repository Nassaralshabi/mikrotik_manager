import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';

class CardsReportView extends StatefulWidget {
  const CardsReportView({
    super.key,
    required this.repository,
    required this.startDate,
    required this.endDate,
  });

  final BackendRepository repository;
  final DateTime startDate;
  final DateTime endDate;

  @override
  State<CardsReportView> createState() => _CardsReportViewState();
}

class _CardsReportViewState extends State<CardsReportView> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadCardsReport();
  }

  Future<Map<String, dynamic>> _loadCardsReport() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'totalCards': 342,
      'activeCards': 156,
      'expiredCards': 98,
      'blockedCards': 24,
      'availableCards': 64,
      'cardsByType': [
        {'type': 'باقة يومية', 'count': 45, 'price': 10.0},
        {'type': 'باقة أسبوعية', 'count': 32, 'price': 50.0},
        {'type': 'باقة شهرية', 'count': 67, 'price': 150.0},
        {'type': 'باقة سنوية', 'count': 12, 'price': 1200.0},
      ],
      'monthlyStats': [
        {'month': 'يناير', 'sold': 45, 'created': 60},
        {'month': 'فبراير', 'sold': 38, 'created': 50},
        {'month': 'مارس', 'sold': 62, 'created': 70},
        {'month': 'أبريل', 'sold': 53, 'created': 65},
        {'month': 'مايو', 'sold': 47, 'created': 55},
        {'month': 'يونيو', 'sold': 71, 'created': 80},
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير البطاقات'),
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
                // ملخص البطاقات
                _buildCardsSummary(data),
                const SizedBox(height: 24),
                
                // رسم دائري لحالات البطاقات
                _buildCardsStatusChart(data),
                const SizedBox(height: 24),
                
                // إحصائيات شهرية
                _buildMonthlyChart(data),
                const SizedBox(height: 24),
                
                // البطاقات حسب النوع
                _buildCardsByTypeTable(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardsSummary(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائيات البطاقات (${DateFormat('yyyy/MM/dd').format(widget.startDate)} - ${DateFormat('yyyy/MM/dd').format(widget.endDate)})',
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
              title: 'إجمالي البطاقات',
              value: '${data['totalCards']}',
              icon: Icons.credit_card,
              color: const Color(0xFF0066FF),
            ),
            _SummaryCard(
              title: 'البطاقات النشطة',
              value: '${data['activeCards']}',
              icon: Icons.check_circle,
              color: const Color(0xFF00B894),
            ),
            _SummaryCard(
              title: 'البطاقات المنتهية',
              value: '${data['expiredCards']}',
              icon: Icons.access_time,
              color: const Color(0xFFFF8C42),
            ),
            _SummaryCard(
              title: 'البطاقات المحظورة',
              value: '${data['blockedCards']}',
              icon: Icons.block,
              color: const Color(0xFFE74C3C),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsStatusChart(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع البطاقات حسب الحالة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: data['activeCards'].toDouble(),
                            title: 'نشطة',
                            color: const Color(0xFF00B894),
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: data['expiredCards'].toDouble(),
                            title: 'منتهية',
                            color: const Color(0xFFFF8C42),
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: data['blockedCards'].toDouble(),
                            title: 'محظورة',
                            color: const Color(0xFFE74C3C),
                            radius: 60,
                          ),
                          PieChartSectionData(
                            value: data['availableCards'].toDouble(),
                            title: 'متاحة',
                            color: const Color(0xFF6C63FF),
                            radius: 60,
                          ),
                        ],
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendItem('نشطة', const Color(0xFF00B894), data['activeCards']),
                        _LegendItem('منتهية', const Color(0xFFFF8C42), data['expiredCards']),
                        _LegendItem('محظورة', const Color(0xFFE74C3C), data['blockedCards']),
                        _LegendItem('متاحة', const Color(0xFF6C63FF), data['availableCards']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(Map<String, dynamic> data) {
    final monthlyStats = data['monthlyStats'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات شهرية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < monthlyStats.length) {
                            return Text(monthlyStats[value.toInt()]['month']);
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
                  barGroups: monthlyStats.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['created'].toDouble(),
                          color: const Color(0xFF0066FF),
                          width: 12,
                        ),
                        BarChartRodData(
                          toY: entry.value['sold'].toDouble(),
                          color: const Color(0xFF00B894),
                          width: 12,
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

  Widget _buildCardsByTypeTable(Map<String, dynamic> data) {
    final cardsByType = data['cardsByType'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'البطاقات حسب النوع',
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
                      child: Text('نوع البطاقة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('العدد', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...cardsByType.map((card) {
                  final total = card['count'] * card['price'];
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(card['type']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${card['count']}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${card['price'].toStringAsFixed(2)} ر.س'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${total.toStringAsFixed(2)} ر.س'),
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
      const SnackBar(content: Text('قريباً: تصدير تقرير البطاقات')),
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
  const _LegendItem(this.title, this.color, this.value);

  final String title;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
          Expanded(
            child: Text('$title ($value)', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}