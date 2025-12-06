import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/backend_repository.dart';
import '../../widgets/loading_state_view.dart';

class SalesReportView extends StatefulWidget {
  const SalesReportView({
    super.key,
    required this.repository,
    required this.startDate,
    required this.endDate,
  });

  final BackendRepository repository;
  final DateTime startDate;
  final DateTime endDate;

  @override
  State<SalesReportView> createState() => _SalesReportViewState();
}

class _SalesReportViewState extends State<SalesReportView> {
  late Future<Map<String, dynamic>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = _loadSalesReport();
  }

  Future<Map<String, dynamic>> _loadSalesReport() async {
    // محاكاة جلب بيانات تقرير المبيعات
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'totalSales': 25750.0,
      'totalCards': 156,
      'totalProfit': 7725.0,
      'commissionRate': 15.0,
      'salesData': [
        {'date': '2024-01-01', 'amount': 2500.0, 'cards': 15},
        {'date': '2024-01-02', 'amount': 3200.0, 'cards': 18},
        {'date': '2024-01-03', 'amount': 1800.0, 'cards': 12},
        {'date': '2024-01-04', 'amount': 4100.0, 'cards': 22},
        {'date': '2024-01-05', 'amount': 2900.0, 'cards': 17},
        {'date': '2024-01-06', 'amount': 3350.0, 'cards': 19},
        {'date': '2024-01-07', 'amount': 7900.0, 'cards': 53},
      ],
      'shopData': [
        {
          'shopName': 'متجر الواحة',
          'supervisor': 'أحمد محمد',
          'cardCount': 45,
          'commission': 12.5,
          'beforeCommission': 6750.0,
          'afterCommission': 5906.25,
        },
        {
          'shopName': 'متجر النور',
          'supervisor': 'فاطمة علي',
          'cardCount': 38,
          'commission': 15.0,
          'beforeCommission': 5700.0,
          'afterCommission': 4845.0,
        },
        {
          'shopName': 'متجر السلام',
          'supervisor': 'محمد أحمد',
          'cardCount': 73,
          'commission': 10.0,
          'beforeCommission': 13300.0,
          'afterCommission': 11970.0,
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير المبيعات'),
        actions: [
          IconButton(
            onPressed: _exportReport,
            icon: const Icon(Icons.file_download),
            tooltip: 'تصدير التقرير',
          ),
          IconButton(
            onPressed: _printReport,
            icon: const Icon(Icons.print),
            tooltip: 'طباعة',
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
                // ملخص التقرير
                _buildSummaryCards(data),
                const SizedBox(height: 24),
                
                // رسم بياني للمبيعات
                _buildSalesChart(data),
                const SizedBox(height: 24),
                
                // تفاصيل المتاجر
                _buildShopsTable(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملخص المبيعات (${DateFormat('yyyy/MM/dd').format(widget.startDate)} - ${DateFormat('yyyy/MM/dd').format(widget.endDate)})',
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
              title: 'إجمالي المبيعات',
              value: '${data['totalSales'].toStringAsFixed(2)} ر.س',
              icon: Icons.trending_up,
              color: const Color(0xFF0066FF),
            ),
            _SummaryCard(
              title: 'عدد البطاقات',
              value: '${data['totalCards']} بطاقة',
              icon: Icons.credit_card,
              color: const Color(0xFF00B894),
            ),
            _SummaryCard(
              title: 'صافي الربح',
              value: '${data['totalProfit'].toStringAsFixed(2)} ر.س',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFFFF8C42),
            ),
            _SummaryCard(
              title: 'نسبة العمولة',
              value: '${data['commissionRate']}%',
              icon: Icons.percent,
              color: const Color(0xFF6C63FF),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalesChart(Map<String, dynamic> data) {
    final salesData = data['salesData'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رسم بياني للمبيعات اليومية',
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
                          if (value.toInt() < salesData.length) {
                            return Text('${value.toInt() + 1}');
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
                      spots: salesData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['amount']);
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF0066FF),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsTable(Map<String, dynamic> data) {
    final shopData = data['shopData'] as List<Map<String, dynamic>>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل المتاجر',
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
                      child: Text('نقطة البيع', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('المشرف', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('البطاقات', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('المبيعات', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...shopData.map((shop) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(shop['shopName']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(shop['supervisor']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${shop['cardCount']}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${shop['afterCommission'].toStringAsFixed(2)} ر.س'),
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
      const SnackBar(content: Text('قريباً: تصدير التقرير')),
    );
  }

  void _printReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: طباعة التقرير')),
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