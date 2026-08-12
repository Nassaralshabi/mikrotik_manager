import 'dart:convert';
import 'package:flutter/material.dart';
import 'snackbar_helpers.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mikrotik_connector.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  Map<String, dynamic> _stats = {
    'totalSessions': 0,
    'dataDownloaded': 0.0,
    'dataUploaded': 0.0,
    'cpuUsage': 0.0,
    'memoryUsage': 0.0,
    'uptime': '',
    'activeUsers': 0,
    'version': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchMikrotikStats();
  }

  Future<void> _fetchMikrotikStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    RouterOSClient? client;
    try {
      client = await MikrotikConnector.connect();

      // الإصلاح: استخدام القيمة المحفوظة عند تسجيل الدخول بدلاً من الافتراضي
      final prefs = await SharedPreferences.getInstance();
      final bool isVersion7OrNewer = prefs.getBool('is_version7_plus') ?? false;

      final resourceResponse = await client.talk(['/system/resource/print']);
      Map<String, dynamic> resourceData = {};
      if (resourceResponse.isNotEmpty) {
        resourceData = Map<String, dynamic>.from(resourceResponse[0]);
      }

      final interfaceResponse = await client.talk(['/interface/print', 'stats']);
      double totalDownload = 0.0;
      double totalUpload = 0.0;
      
      for (var iface in interfaceResponse) {
        final rxBytes = double.tryParse(iface['rx-byte']?.toString() ?? '0') ?? 0.0;
        final txBytes = double.tryParse(iface['tx-byte']?.toString() ?? '0') ?? 0.0;
        totalDownload += rxBytes;
        totalUpload += txBytes;
      }

      // الإصلاح: جلب بيانات المستخدمين النشطين مرة واحدة فقط
      List<Map<String, dynamic>> activeUsers = [];
      List<Map<String, dynamic>> sessions = [];
      try {
        final activeResponse = await client.talk(['/ip/hotspot/active/print']);
        activeUsers = activeResponse.map((e) => Map<String, dynamic>.from(e)).toList();
        // استخدام نفس البيانات للجلسات (لا حاجة لجلب مكرر)
        sessions = activeUsers;
      } catch (e) {
        // إذا فشل hotspot، جرب user-manager
        activeUsers = [];
        try {
          final sessionResponse = await client.talk(['/tool/user-manager/session/print']);
          sessions = sessionResponse.map((e) => Map<String, dynamic>.from(e)).toList();
        } catch (e) {
          sessions = [];
        }
      }

      final cpuLoad = resourceData['cpu-load']?.toString() ?? '0';
      final totalMemory = double.tryParse(resourceData['total-memory']?.toString() ?? '0') ?? 1.0;
      final freeMemory = double.tryParse(resourceData['free-memory']?.toString() ?? '0') ?? 0.0;
      final memoryUsagePercent = ((totalMemory - freeMemory) / totalMemory * 100);

      if (mounted) {
        setState(() {
          _stats = {
            'totalSessions': sessions.length,
            'dataDownloaded': totalDownload / (1024 * 1024),
            'dataUploaded': totalUpload / (1024 * 1024),
            'cpuUsage': double.tryParse(cpuLoad) ?? 0.0,
            'memoryUsage': memoryUsagePercent,
            'uptime': resourceData['uptime']?.toString() ?? 'غير متوفر',
            'activeUsers': activeUsers.length,
            'version': resourceData['version']?.toString() ?? 'غير معروف',
          };
          _isLoading = false;
        });
      }

      // تحديث إصدار RouterOS
      final versionStr = resourceData['version']?.toString() ?? '6';
      await prefs.setString('mikrotik_version', versionStr);
      try {
        final isV7 = int.parse(versionStr.split('.').first) >= 7;
        await prefs.setBool('is_version7_plus', isV7);
      } catch (e) {
        // تجاهل أخطاء تحليل الإصدار
      }

    } on MikrotikCredentialsMissingException catch (e) {
      setState(() {
        _errorMessage = 'خطأ في بيانات الدخول: ${e.message}';
        _isLoading = false;
      });
    } on MikrotikConnectionException catch (e) {
      setState(() {
        _errorMessage = 'خطأ في الاتصال: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب البيانات: ${e.toString()}';
        _isLoading = false;
      });
    } finally {
      client?.close();
    }
  }

  Future<void> _generatePdfReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss', 'ar');

      final prefs = await SharedPreferences.getInstance();
      String clientName = 'غير محدد';
      final isLinked = prefs.getBool('is_network_linked') ?? false;
      if (isLinked) {
        final dataString = prefs.getString('qahtani_linked_data');
        if (dataString != null) {
          try {
            final data = Map<String, dynamic>.from(
              jsonDecode(dataString)
            );
            clientName = data['client_info']?['name'] ?? 'غير محدد';
          } catch (e) {
            clientName = 'غير محدد';
          }
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'تقرير إحصائيات MikroTik',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                
                pw.Text('معلومات التقرير:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('التاريخ والوقت: ${dateFormat.format(now)}'),
                pw.Text('اسم العميل: $clientName'),
                pw.Text('إصدار MikroTik: ${_stats['version']}'),
                pw.SizedBox(height: 20),
                
                pw.Text('الإحصائيات الرئيسية:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                
                pw.Table.fromTextArray(
                  headers: ['المؤشر', 'القيمة'],
                  data: [
                    ['إجمالي الجلسات', '${_stats['totalSessions']}'],
                    ['البيانات المحملة', '${_stats['dataDownloaded'].toStringAsFixed(2)} MB'],
                    ['البيانات المرفوعة', '${_stats['dataUploaded'].toStringAsFixed(2)} MB'],
                    ['استخدام المعالج', '${_stats['cpuUsage'].toStringAsFixed(1)}%'],
                    ['استخدام الذاكرة', '${_stats['memoryUsage'].toStringAsFixed(1)}%'],
                    ['وقت التشغيل', _stats['uptime']],
                    ['المستخدمين النشطين', '${_stats['activeUsers']}'],
                  ],
                  cellAlignment: pw.Alignment.centerRight,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 30,
                ),
                
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'تم إنشاء هذا التقرير بواسطة MikroTik Manager',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      
      if (mounted) {
        Navigator.of(context).pop();
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'mikrotik_stats_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showErrorSnackBar(context, 'فشل إنشاء تقرير PDF.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        backgroundColor: Theme.of(context).cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchMikrotikStats,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: (_isLoading || _errorMessage.isNotEmpty) ? null : _generatePdfReport,
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل الإحصائيات...',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchMikrotikStats,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPieChart(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final download = _stats['dataDownloaded'] as double;
    final upload = _stats['dataUploaded'] as double;
    final total = download + upload;

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد بيانات استخدام متاحة',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'استخدام البيانات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: download,
                      title: '${(download / total * 100).toStringAsFixed(1)}%',
                      color: Colors.blue[400],
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: upload,
                      title: '${(upload / total * 100).toStringAsFixed(1)}%',
                      color: Colors.green[400],
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('التحميل', Colors.blue[400]!, download),
                _buildLegendItem('الرفع', Colors.green[400]!, upload),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
            Text(
              '${value.toStringAsFixed(2)} MB',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text(
              'الإحصائيات التفصيلية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'إجمالي الجلسات',
              '${_stats['totalSessions']}',
              Icons.group,
              Colors.purple[400]!,
            ),
            _buildStatCard(
              'المستخدمين النشطين',
              '${_stats['activeUsers']}',
              Icons.people,
              Colors.teal[400]!,
            ),
            _buildStatCard(
              'استخدام المعالج',
              '${_stats['cpuUsage'].toStringAsFixed(1)}%',
              Icons.memory,
              Colors.orange[400]!,
            ),
            _buildStatCard(
              'استخدام الذاكرة',
              '${_stats['memoryUsage'].toStringAsFixed(1)}%',
              Icons.storage,
              Colors.pink[400]!,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildUptimeCard(),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUptimeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[400]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.access_time, color: Colors.blue[400], size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وقت التشغيل',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatUptime(_stats['uptime']),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  String _formatUptime(String uptime) {
    if (uptime.isEmpty || uptime == 'غير متوفر') return uptime;
    
    return uptime
        .replaceAll('w', ' أسبوع ')
        .replaceAll('d', ' يوم ')
        .replaceAll('h', ' ساعة ')
        .replaceAll('m', ' دقيقة ')
        .replaceAll('s', ' ثانية');
  }
}
