import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/resource_history.dart';
import '../../../l10n/translations.dart';
import '../../../widgets/skeleton_loader.dart';

class CombinedResourceChart extends StatefulWidget {
  final ResourceHistoryNotifier resourceHistory;

  const CombinedResourceChart({
    super.key,
    required this.resourceHistory,
  });

  @override
  State<CombinedResourceChart> createState() => _CombinedResourceChartState();
}

class _CombinedResourceChartState extends State<CombinedResourceChart>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _animationController;

  List<FlSpot> _cpuSpots = [];
  List<FlSpot> _memorySpots = [];
  List<FlSpot> _diskSpots = [];
  int _lastDataLength = 0;

  @override
  void initState() {
    super.initState();
    _generateSpots();
    _lastDataLength = widget.resourceHistory.cpuData.length;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    widget.resourceHistory.addListener(_onDataChanged);
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshChartData();
    });
  }

  void _refreshChartData() {
    final newLength = widget.resourceHistory.cpuData.length;
    if (newLength != _lastDataLength) {
      _lastDataLength = newLength;
      _generateSpots();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onDataChanged() {
    _generateSpots();
    _lastDataLength = widget.resourceHistory.cpuData.length;
    if (mounted) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(CombinedResourceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceHistory != widget.resourceHistory) {
      oldWidget.resourceHistory.removeListener(_onDataChanged);
      widget.resourceHistory.addListener(_onDataChanged);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    widget.resourceHistory.removeListener(_onDataChanged);
    super.dispose();
  }

  void _generateSpots() {
    final dataPoints = widget.resourceHistory.cpuData;
    const maxPoints = 60;

    final startIndex =
        dataPoints.length > maxPoints ? dataPoints.length - maxPoints : 0;

    _cpuSpots = [];
    _memorySpots = [];
    _diskSpots = [];

    DateTime? referenceTime;
    if (dataPoints.isNotEmpty && startIndex < dataPoints.length) {
      referenceTime = dataPoints[startIndex].timestamp;
    }

    for (int i = startIndex; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final x = referenceTime != null
          ? point.timestamp.difference(referenceTime).inSeconds.toDouble()
          : 0.0;
      _cpuSpots.add(FlSpot(x, point.cpuLoad));
      _memorySpots.add(FlSpot(x, point.memoryUsage));
      _diskSpots.add(FlSpot(x, point.diskUsage));
    }
  }

  Widget _buildChart() {
    if (_cpuSpots.isEmpty) {
      return _buildEmptyState();
    }

    final visiblePoints = _cpuSpots.length.clamp(10, 50).toDouble();
    final startX =
        (_cpuSpots.length - visiblePoints).clamp(0.0, double.infinity);
    final maxX = _cpuSpots.length.toDouble().clamp(1.0, 60.0);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: context.appOnSurface.withValues(alpha: 0.08),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 18,
                  interval: (maxX - startX) / 4,
                  getTitlesWidget: (value, meta) {
                    if (value < 0) return const SizedBox.shrink();
                    final seconds = value.toInt();
                    if (seconds < 60) {
                      return Text('${seconds}s',
                          style: TextStyle(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.5),
                              fontSize: 8));
                    }
                    final minutes = seconds ~/ 60;
                    return Text('${minutes}m',
                        style: TextStyle(
                            color: context.appOnSurface.withValues(alpha: 0.5),
                            fontSize: 8));
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: 25,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value > 100) {
                      return const SizedBox.shrink();
                    }
                    return Text('${value.toInt()}',
                        style: TextStyle(
                            color: context.appOnSurface.withValues(alpha: 0.5),
                            fontSize: 8));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: startX,
            maxX: maxX,
            minY: 0,
            maxY: 100,
            clipData: const FlClipData.all(),
            lineBarsData: [
              LineChartBarData(
                spots: _cpuSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: 0.15),
                      const Color(0xFF6366F1).withValues(alpha: 0.0)
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: _memorySpots,
                isCurved: true,
                curveSmoothness: 0.3,
                gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)]),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.15),
                      const Color(0xFF10B981).withValues(alpha: 0.0)
                    ],
                  ),
                ),
              ),
              LineChartBarData(
                spots: _diskSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      const Color(0xFFF59E0B).withValues(alpha: 0.0)
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: const LineTouchData(enabled: false),
          ),
        );
      },
    );
  }

Widget _buildEmptyState() {
    return SizedBox(
      height: 240,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerEffect(
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: Card(
                  color: context.appCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Collecting data...',
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.resourceHistory.latest;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        return Card(
          color: context.appSurface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 8 : 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.appPrimary.withValues(alpha: 0.15),
                            context.appPrimary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.analytics_rounded,
                          color: context.appPrimary,
                          size: isSmallScreen ? 20 : 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.of(context).systemResources,
                              style: TextStyle(
                                  color: context.appOnSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: isSmallScreen ? 12 : 14)),
                          const SizedBox(height: 4),
                          if (latest != null)
                            Wrap(
                              spacing: isSmallScreen ? 6 : 12,
                              children: [
                                _buildLegendItem('CPU', latest.cpuLoad,
                                    const Color(0xFF6366F1)),
                                _buildLegendItem('RAM', latest.memoryUsage,
                                    const Color(0xFF10B981)),
                                _buildLegendItem('Disk', latest.diskUsage,
                                    const Color(0xFFF59E0B)),
                              ],
                            )
                          else
                            Text(AppStrings.of(context).loading,
                                style: TextStyle(
                                    color: context.appOnSurface
                                        .withValues(alpha: 0.5),
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                    if (latest != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6 : 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: context.appPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync_rounded,
                                size: isSmallScreen ? 10 : 12,
                                color: context.appPrimary),
                            const SizedBox(width: 4),
                            Text(AppStrings.of(context).live,
                                style: TextStyle(
                                    color: context.appPrimary,
                                    fontSize: isSmallScreen ? 9 : 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: SizedBox(
                      height: isSmallScreen ? 160 : 200, child: _buildChart()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text('$label ${value.toStringAsFixed(0)}%',
            style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
                fontSize: 11)),
      ],
    );
  }
}
