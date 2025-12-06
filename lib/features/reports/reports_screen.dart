import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/backend_repository.dart';
import '../../widgets/section_header.dart';
import 'sales_report_view.dart';
import 'cards_report_view.dart';
import 'users_report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final BackendRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'التقارير والإحصائيات'),
          const SizedBox(height: 16),
          
          // فترة التقرير
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'فترة التقرير',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('من تاريخ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(DateFormat('yyyy/MM/dd').format(_startDate)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectEndDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('إلى تاريخ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(DateFormat('yyyy/MM/dd').format(_endDate)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // أنواع التقارير
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _ReportCard(
                  title: 'تقرير المبيعات',
                  subtitle: 'تفاصيل المبيعات والأرباح',
                  icon: Icons.trending_up,
                  color: const Color(0xFF0066FF),
                  onTap: () => _showSalesReport(),
                ),
                _ReportCard(
                  title: 'تقرير البطاقات',
                  subtitle: 'إحصائيات البطاقات المباعة',
                  icon: Icons.credit_card,
                  color: const Color(0xFF00B894),
                  onTap: () => _showCardsReport(),
                ),
                _ReportCard(
                  title: 'تقرير المستخدمين',
                  subtitle: 'إحصائيات المستخدمين النشطين',
                  icon: Icons.people,
                  color: const Color(0xFFFF8C42),
                  onTap: () => _showUsersReport(),
                ),
                _ReportCard(
                  title: 'التقرير الشامل',
                  subtitle: 'تقرير كامل لجميع العمليات',
                  icon: Icons.description,
                  color: const Color(0xFF6C63FF),
                  onTap: () => _showFullReport(),
                ),
                _ReportCard(
                  title: 'تقرير المدفوعات',
                  subtitle: 'تفاصيل المدفوعات والعمولات',
                  icon: Icons.payment,
                  color: const Color(0xFFE74C3C),
                  onTap: () => _showPaymentReport(),
                ),
                _ReportCard(
                  title: 'تقرير التحميلات',
                  subtitle: 'إحصائيات استخدام البيانات',
                  icon: Icons.download,
                  color: const Color(0xFF9B59B6),
                  onTap: () => _showDownloadReport(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  void _showSalesReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalesReportView(
          repository: widget.repository,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  void _showCardsReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardsReportView(
          repository: widget.repository,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  void _showUsersReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsersReportView(
          repository: widget.repository,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  void _showFullReport() {
    // عرض التقرير الشامل كما في HTML
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التقرير الشامل'),
        content: const Text('قريباً: التقرير الشامل بتصميم HTML المطور'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showPaymentReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: تقرير المدفوعات')),
    );
  }

  void _showDownloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: تقرير التحميلات')),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}