import 'dart:async';
import 'dart:io';
import 'package:dart_ping/dart_ping.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'network_map_screen.dart';
import 'rogue_dhcp_detector_screen.dart';

enum DiagnosticStatus { pending, running, success, warning, error }

enum SeverityLevel { info, low, medium, high }

class NetworkRecommendation {
  final String title;
  final String description;
  final SeverityLevel severity;
  final IconData icon;
  final List<String> steps;
  bool expanded;

  NetworkRecommendation({
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
    required this.steps,
    this.expanded = false,
  });
}

class _NetworkDiagnostic {
  final String id;
  final String title;
  final String description;
  DiagnosticStatus status;
  String message;
  double? latencyMs;
  double? downloadSpeedMbps;
  double? uploadSpeedMbps;

  _NetworkDiagnostic({
    required this.id,
    required this.title,
    required this.description,
    this.status = DiagnosticStatus.pending,
    this.message = 'لم يتم الفحص بعد',
    this.latencyMs,
    this.downloadSpeedMbps,
    this.uploadSpeedMbps,
  });
}

class NetworkDoctorScreen extends StatefulWidget {
  const NetworkDoctorScreen({super.key});

  @override
  State<NetworkDoctorScreen> createState() => _NetworkDoctorScreenState();
}

class _NetworkDoctorScreenState extends State<NetworkDoctorScreen> {
  late final Dio _dio;
  bool _isRunningAll = false;
  String? _gatewayIp;
  final List<_NetworkDiagnostic> _tests = [
    _NetworkDiagnostic(
      id: 'gateway',
      title: 'اتصال الراوتر',
      description: 'التحقق من الوصول إلى البوابة الافتراضية',
    ),
    _NetworkDiagnostic(
      id: 'internet',
      title: 'اتصال الإنترنت الخارجي',
      description: 'التحقق من الوصول إلى الإنترنت',
    ),
    _NetworkDiagnostic(
      id: 'dns',
      title: 'فحص DNS',
      description: 'التحقق من القدرة على حل أسماء النطاقات',
    ),
    _NetworkDiagnostic(
      id: 'latency',
      title: 'زمن الاستجابة',
      description: 'قياس متوسط تأخير الشبكة',
    ),
    _NetworkDiagnostic(
      id: 'speed_test',
      title: 'اختبار سرعة الإنترنت',
      description: 'قياس سرعة التحميل والرفع الفعلية',
    ),
  ];

  final List<NetworkRecommendation> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    _resolveGateway();
  }

  Future<void> _resolveGateway() async {
    try {
      final gw = await NetworkInfo().getWifiGatewayIP();
      if (mounted) setState(() => _gatewayIp = gw);
    } catch (_) {}
  }

  Future<void> _runAll() async {
    if (mounted) setState(() => _isRunningAll = true);
    for (final t in _tests) {
      if (t.id == 'speed_test') {
        final proceed = await _confirmSpeedTest();
        if (proceed != true) {
          continue;
        }
      }
      await _executeTest(t);
    }
    _generateRecommendations();
    if (mounted) setState(() => _isRunningAll = false);
  }

  Future<void> _executeTest(_NetworkDiagnostic test) async {
    _updateTest(test.id, DiagnosticStatus.running, 'جاري الفحص...');
    try {
      switch (test.id) {
        case 'gateway':
          await _checkGateway(test);
          break;
        case 'internet':
          await _checkInternet(test);
          break;
        case 'dns':
          await _checkDns(test);
          break;
        case 'latency':
          await _checkLatency(test);
          break;
        case 'speed_test':
          await _checkSpeedTest(test);
          break;
        default:
          _updateTest(test.id, DiagnosticStatus.error, 'فحص غير معروف');
      }
    } catch (e) {
      _updateTest(test.id, DiagnosticStatus.error, 'فشل الفحص: ${e.toString()}');
    } finally {
      _generateRecommendations();
    }
  }

  void _updateTest(String id, DiagnosticStatus status, String message) {
    if (!mounted) return;
    setState(() {
      final index = _tests.indexWhere((test) => test.id == id);
      if (index != -1) {
        _tests[index].status = status;
        _tests[index].message = message;
      }
    });
  }

  void _updateTestWithSpeed(String id, DiagnosticStatus status, String message,
      {double? downloadSpeed, double? uploadSpeed}) {
    if (!mounted) return;
    setState(() {
      final index = _tests.indexWhere((test) => test.id == id);
      if (index != -1) {
        _tests[index].status = status;
        _tests[index].message = message;
        _tests[index].downloadSpeedMbps = downloadSpeed;
        _tests[index].uploadSpeedMbps = uploadSpeed;
      }
    });
  }

  Future<void> _checkGateway(_NetworkDiagnostic test) async {
    final gw = _gatewayIp;
    if (gw == null || gw.isEmpty) {
      throw Exception('تعذر تحديد بوابة الشبكة');
    }
    final p = Ping(gw, count: 2, timeout: 2);
    double success = 0;
    await for (final r in p.stream) {
      if (r.response != null) success += 1;
    }
    if (success >= 1) {
      _updateTest(test.id, DiagnosticStatus.success, 'تم الوصول إلى البوابة $gw');
    } else {
      _updateTest(test.id, DiagnosticStatus.error, 'تعذر الوصول إلى البوابة $gw');
    }
  }

  Future<void> _checkInternet(_NetworkDiagnostic test) async {
    try {
      final r = await _dio.get('https://www.google.com/generate_204');
      if (r.statusCode == 204 || r.statusCode == 200) {
        _updateTest(test.id, DiagnosticStatus.success, 'الاتصال بالإنترنت يعمل');
      } else {
        _updateTest(test.id, DiagnosticStatus.warning, 'استجابة غير متوقعة من الإنترنت');
      }
    } on DioException catch (e) {
      _updateTest(test.id, DiagnosticStatus.error, 'لا يوجد اتصال بالإنترنت: ${e.message}');
    }
  }

  Future<void> _checkDns(_NetworkDiagnostic test) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        _updateTest(test.id, DiagnosticStatus.success, 'خادم DNS يعمل');
      } else {
        _updateTest(test.id, DiagnosticStatus.warning, 'لا يمكن حل أسماء النطاقات');
      }
    } catch (e) {
      _updateTest(test.id, DiagnosticStatus.error, 'فشل فحص DNS: ${e.toString()}');
    }
  }

  Future<void> _checkLatency(_NetworkDiagnostic test) async {
    final p = Ping('1.1.1.1', count: 4, timeout: 2);
    final samples = <double>[];
    await for (final r in p.stream) {
      final ms = r.response?.time?.inMilliseconds;
      if (ms != null) samples.add(ms.toDouble());
    }
    if (samples.isEmpty) {
      _updateTest(test.id, DiagnosticStatus.error, 'تعذر قياس زمن الاستجابة');
      return;
    }
    final avg = samples.reduce((a, b) => a + b) / samples.length;
    final status = avg > 150
        ? DiagnosticStatus.warning
        : DiagnosticStatus.success;
    final msg = 'المتوسط: ${avg.toStringAsFixed(0)} مللي ثانية';
    if (!mounted) return;
    setState(() {
      test.latencyMs = avg;
    });
    _updateTest(test.id, status, msg);
  }

  Future<void> _checkSpeedTest(_NetworkDiagnostic test) async {
    const downloadTestUrl = 'https://speed.cloudflare.com/__down?bytes=25000000';
    const uploadTestUrl = 'https://speed.cloudflare.com/__up';
    
    // إنشاء Dio instance منفصل مع timeout أطول لاختبار السرعة
    final speedTestDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    
    try {
      final downloadStopwatch = Stopwatch()..start();
      final downloadResponse = await speedTestDio.get(
        downloadTestUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      downloadStopwatch.stop();

      final downloadBytes = (downloadResponse.data as List<int>).length;
      final downloadTimeSeconds = downloadStopwatch.elapsedMilliseconds / 1000;
      final downloadSpeedMbps = (downloadBytes * 8 / downloadTimeSeconds) / 1000000;

      final uploadData = List<int>.filled(5000000, 0);
      final uploadStopwatch = Stopwatch()..start();
      await speedTestDio.post(
        uploadTestUrl,
        data: uploadData,
        options: Options(
          headers: {'Content-Type': 'application/octet-stream'},
        ),
      );
      uploadStopwatch.stop();

      final uploadBytes = uploadData.length;
      final uploadTimeSeconds = uploadStopwatch.elapsedMilliseconds / 1000;
      final uploadSpeedMbps = (uploadBytes * 8 / uploadTimeSeconds) / 1000000;

      final message = 'التحميل: ${downloadSpeedMbps.toStringAsFixed(2)} Mbps\nالرفع: ${uploadSpeedMbps.toStringAsFixed(2)} Mbps';
      final status = downloadSpeedMbps < 1.0 ? DiagnosticStatus.warning : DiagnosticStatus.success;

      _updateTestWithSpeed(test.id, status, message, downloadSpeed: downloadSpeedMbps, uploadSpeed: uploadSpeedMbps);
    } catch (e) {
      throw Exception('فشل اختبار السرعة: ${e.toString()}');
    } finally {
      speedTestDio.close();
    }
  }

  void _generateRecommendations() {
    _recommendations.clear();
    final gateway = _tests.firstWhere((t) => t.id == 'gateway');
    final internet = _tests.firstWhere((t) => t.id == 'internet');
    final dns = _tests.firstWhere((t) => t.id == 'dns');
    final latency = _tests.firstWhere((t) => t.id == 'latency');
    final speedTest = _tests.firstWhere((t) => t.id == 'speed_test');

    if (gateway.status == DiagnosticStatus.error) {
      _recommendations.add(NetworkRecommendation(
        title: 'تعذر الوصول إلى الراوتر',
        description: 'لا يمكن الاتصال بالبوابة الافتراضية${_gatewayIp != null ? ' ($_gatewayIp)' : ''}.',
        severity: SeverityLevel.high,
        icon: Icons.router,
        steps: [
          'تحقق من اتصالك بشبكة Wi‑Fi',
          'تأكد من عنوان IP للبوابة',
          'أعد تشغيل الراوتر',
          'تحقق من الكابلات والتوصيلات',
        ],
      ));
    }

    if (internet.status == DiagnosticStatus.error) {
      _recommendations.add(NetworkRecommendation(
        title: 'لا يوجد اتصال بالإنترنت',
        description: 'تعذر الوصول إلى الإنترنت من الشبكة الحالية.',
        severity: SeverityLevel.high,
        icon: Icons.public_off,
        steps: [
          'تحقق من حالة الاشتراك لدى مزود الخدمة',
          'أعد تشغيل المودم والراوتر',
          'تحقق من وجود انقطاع عام في المنطقة',
        ],
      ));
    }

    if (dns.status == DiagnosticStatus.error || dns.status == DiagnosticStatus.warning) {
      _recommendations.add(NetworkRecommendation(
        title: 'مشكلة في DNS',
        description: 'قد لا تعمل خدمة حل أسماء النطاقات بالشكل الصحيح.',
        severity: SeverityLevel.medium,
        icon: Icons.dns,
        steps: [
          'جرّب استخدام خوادم DNS عامة مثل 1.1.1.1 أو 8.8.8.8',
          'تحقق من إعدادات DNS على الراوتر',
        ],
      ));
    }

    if (latency.latencyMs != null) {
      if (latency.latencyMs! > 200) {
        _recommendations.add(NetworkRecommendation(
          title: 'زمن استجابة مرتفع',
          description: 'المتوسط ${latency.latencyMs!.toStringAsFixed(0)} مللي ثانية أعلى من المتوقع.',
          severity: SeverityLevel.medium,
          icon: Icons.punch_clock,
          steps: [
            'تحقق من الأجهزة التي قد تستهلك النطاق بشكل كبير',
            'جرّب إعادة تشغيل الراوتر',
            'اختبر الكابل أو شبكة الـ Wi‑Fi',
          ],
        ));
      } else if (latency.latencyMs! <= 50) {
        _recommendations.add(NetworkRecommendation(
          title: 'زمن استجابة ممتاز',
          description: 'المتوسط ${latency.latencyMs!.toStringAsFixed(0)} مللي ثانية مناسب للألعاب والبث.',
          severity: SeverityLevel.info,
          icon: Icons.speed,
          steps: [
            'لا توجد إجراءات مطلوبة',
          ],
        ));
      }
    }

    if (speedTest.id == 'speed_test' && speedTest.downloadSpeedMbps != null) {
      if (speedTest.downloadSpeedMbps! < 1.0) {
        _recommendations.add(
          NetworkRecommendation(
            title: 'سرعة إنترنت بطيئة جداً',
            description: 'سرعة التحميل ${speedTest.downloadSpeedMbps!.toStringAsFixed(2)} Mbps أقل من المتوقع بكثير.',
            severity: SeverityLevel.high,
            icon: Icons.slow_motion_video,
            steps: [
              'تحقق من عدد الأجهزة المتصلة بالشبكة',
              'أعد تشغيل الراوتر والمودم',
              'افحص إذا كان هناك تطبيقات تستهلك النطاق الترددي',
              'اتصل بمزود الخدمة للتحقق من سرعة الباقة',
              'تأكد من عدم وجود مشاكل في الكابلات',
            ],
          ),
        );
      } else if (speedTest.downloadSpeedMbps! >= 10.0) {
        _recommendations.add(
          NetworkRecommendation(
            title: 'سرعة إنترنت ممتازة',
            description: 'سرعة التحميل ${speedTest.downloadSpeedMbps!.toStringAsFixed(2)} Mbps جيدة للتصفح والبث.',
            severity: SeverityLevel.info,
            icon: Icons.speed,
            steps: [
              'يمكنك الاستمتاع ببث الفيديو بجودة عالية',
              'سرعة مناسبة للألعاب عبر الإنترنت',
              'التحميلات ستكون سريعة',
            ],
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<bool?> _confirmSpeedTest() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحذير اختبار السرعة'),
        content: const Text('سيتم استهلاك حوالي 30 ميجا من البيانات لإجراء الاختبار. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('متابعة')),
        ],
      ),
    );
  }

  int get _countSuccess => _tests.where((t) => t.status == DiagnosticStatus.success).length;
  int get _countWarning => _tests.where((t) => t.status == DiagnosticStatus.warning).length;
  int get _countError => _tests.where((t) => t.status == DiagnosticStatus.error).length;
  int get _countPending => _tests.where((t) => t.status == DiagnosticStatus.pending).length;

  Color _statusColor(DiagnosticStatus s) {
    switch (s) {
      case DiagnosticStatus.success:
        return Colors.green;
      case DiagnosticStatus.warning:
        return Colors.orange;
      case DiagnosticStatus.error:
        return Colors.redAccent;
      case DiagnosticStatus.running:
        return Theme.of(context).primaryColor;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    }
  }

  String _statusLabel(DiagnosticStatus s) {
    switch (s) {
      case DiagnosticStatus.success:
        return 'ناجح';
      case DiagnosticStatus.warning:
        return 'تحذير';
      case DiagnosticStatus.error:
        return 'فشل';
      case DiagnosticStatus.running:
        return 'جاري...';
      case DiagnosticStatus.pending:
        return 'بالانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('طبيب الشبكة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isRunningAll ? null : _runAll,
            icon: const Icon(Icons.play_circle_fill),
            tooltip: 'تشغيل جميع الفحوصات',
            color: theme.primaryColor,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildTestsSection(),
            const SizedBox(height: 16),
            _buildRecommendationsSection(),
            const SizedBox(height: 16),
            _buildAdvancedTools(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.6), primary.withOpacity(0.3)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الفحوصات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تشخيص شامل لحالة الشبكة',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningAll ? null : _runAll,
              icon: _isRunningAll
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isRunningAll ? 'جاري التشغيل...' : 'تشغيل جميع الفحوصات',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildChip('ناجحة', _countSuccess.toString(), Colors.greenAccent, Icons.check_circle)),
        const SizedBox(width: 10),
        Expanded(child: _buildChip('تحذير', _countWarning.toString(), Colors.orange, Icons.warning)),
        const SizedBox(width: 10),
        Expanded(child: _buildChip('فشل', _countError.toString(), Colors.redAccent, Icons.error)),
      ],
    );
  }

  Widget _buildChip(String title, String value, Color color, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'الفحوصات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        ..._tests.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTestCard(t),
        )).toList(),
      ],
    );
  }

  Widget _buildTestCard(_NetworkDiagnostic t) {
    final theme = Theme.of(context);
    final color = _statusColor(t.status);
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.network_check, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  _statusLabel(t.status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (t.id == 'latency' && t.latencyMs != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'المتوسط: ${t.latencyMs!.toStringAsFixed(0)} مللي ثانية',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (t.id == 'speed_test' && (t.downloadSpeedMbps != null || t.uploadSpeedMbps != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.speed, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'التحميل: ${t.downloadSpeedMbps?.toStringAsFixed(2) ?? '-'} Mbps • الرفع: ${t.uploadSpeedMbps?.toStringAsFixed(2) ?? '-'} Mbps',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: Text(
              t.message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: t.status == DiagnosticStatus.running
                      ? null
                      : () async {
                          if (t.id == 'speed_test') {
                            final proceed = await _confirmSpeedTest();
                            if (proceed != true) return;
                          }
                          await _executeTest(t);
                        },
                  icon: t.status == DiagnosticStatus.running
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow, size: 20),
                  label: const Text('تشغيل'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (t.id == 'speed_test') ...[
                const SizedBox(width: 10),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                      SizedBox(width: 6),
                      Text(
                        '~30MB',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'التوصيات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        if (_recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                SizedBox(width: 12),
                Text(
                  'لا توجد توصيات - الشبكة في حالة جيدة!',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
        ..._recommendations.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecommendationCard(r),
        )).toList(),
      ],
    );
  }

  Widget _buildRecommendationCard(NetworkRecommendation r) {
    final theme = Theme.of(context);
    Color sevColor;
    String severityLabel;
    
    switch (r.severity) {
      case SeverityLevel.high:
        sevColor = Colors.redAccent;
        severityLabel = 'عاجل';
        break;
      case SeverityLevel.medium:
        sevColor = Colors.orange;
        severityLabel = 'متوسط';
        break;
      case SeverityLevel.low:
        sevColor = Colors.amber;
        severityLabel = 'منخفض';
        break;
      case SeverityLevel.info:
        sevColor = Colors.blueAccent;
        severityLabel = 'معلومة';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: sevColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(r.icon, color: sevColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            r.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: sevColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            severityLabel,
                            style: TextStyle(
                              color: sevColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => r.expanded = !r.expanded);
                },
                icon: Icon(
                  r.expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          if (r.expanded) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            const Text(
              'خطوات الحل:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...r.steps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sevColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$index',
                        style: TextStyle(
                          color: sevColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedTools() {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'أدوات متقدمة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NetworkMapScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primary.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.hub_outlined, size: 32, color: primary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'خريطة الشبكة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RogueDhcpDetectorScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.security, size: 32, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'كاشف DHCP الدخيل',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
