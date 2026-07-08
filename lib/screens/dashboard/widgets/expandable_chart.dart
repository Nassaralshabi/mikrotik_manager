import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/resource_history.dart';
import '../../../l10n/translations.dart';

/// Time range options for the chart
enum ChartTimeRange {
  oneMinute(60, '1 min'),
  fiveMinutes(300, '5 min'),
  fifteenMinutes(900, '15 min');

  final int seconds;
  final String label;

  const ChartTimeRange(this.seconds, this.label);
}

/// A chart that can be tapped to expand full-screen with time range picker
class ExpandableResourceChart extends StatefulWidget {
  final ResourceHistoryNotifier resourceHistory;

  const ExpandableResourceChart({
    super.key,
    required this.resourceHistory,
  });

  @override
  State<ExpandableResourceChart> createState() =>
      _ExpandableResourceChartState();
}

class _ExpandableResourceChartState extends State<ExpandableResourceChart> {
  // ignore: prefer_final_fields
  ChartTimeRange _selectedRange = ChartTimeRange.fiveMinutes;

  List<FlSpot> _cpuSpots = [];
  List<FlSpot> _memorySpots = [];
  List<FlSpot> _diskSpots = [];

  @override
  void initState() {
    super.initState();
    _generateSpots();
    widget.resourceHistory.addListener(_onDataChanged);
  }

  @override
  void didUpdateWidget(ExpandableResourceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceHistory != widget.resourceHistory) {
      oldWidget.resourceHistory.removeListener(_onDataChanged);
      widget.resourceHistory.addListener(_onDataChanged);
    }
  }

  @override
  void dispose() {
    widget.resourceHistory.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _generateSpots();
    if (mounted) setState(() {});
  }

  void _generateSpots() {
    final dataPoints = widget.resourceHistory.cpuData;
    final maxSeconds = _selectedRange.seconds;

    if (dataPoints.isEmpty) {
      _cpuSpots = [];
      _memorySpots = [];
      _diskSpots = [];
      return;
    }

    final now = dataPoints.last.timestamp;
    final cutoff = now.subtract(Duration(seconds: maxSeconds));

    _cpuSpots = [];
    _memorySpots = [];
    _diskSpots = [];

    for (final point in dataPoints) {
      if (point.timestamp.isBefore(cutoff)) continue;
      final x = point.timestamp.difference(cutoff).inSeconds.toDouble();
      _cpuSpots.add(FlSpot(x, point.cpuLoad));
      _memorySpots.add(FlSpot(x, point.memoryUsage));
      _diskSpots.add(FlSpot(x, point.diskUsage));
    }
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenChart(
          resourceHistory: widget.resourceHistory,
          initialRange: _selectedRange,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Card(
        color: context.appSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
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
                        color: context.appPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Resources',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: context.appOnSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            _buildLegendItem('CPU', const Color(0xFF6366F1)),
                            const SizedBox(width: 12),
                            _buildLegendItem('RAM', const Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            _buildLegendItem('Disk', const Color(0xFFF59E0B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_full_rounded,
                            size: 12, color: context.appPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Expand',
                          style: TextStyle(
                            color: context.appPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 180,
                child: _buildChart(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    if (_cpuSpots.isEmpty) {
      return Center(
        child: Text(
          'Collecting data...',
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      );
    }

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
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > 100) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        clipData: const FlClipData.all(),
        lineBarsData: [
          _buildLineData(_cpuSpots, const Color(0xFF6366F1)),
          _buildLineData(_memorySpots, const Color(0xFF10B981)),
          _buildLineData(_diskSpots, const Color(0xFFF59E0B)),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                String label;
                Color color;
                if (spot.barIndex == 0) {
                  label = 'CPU';
                  color = const Color(0xFF6366F1);
                } else if (spot.barIndex == 1) {
                  label = 'RAM';
                  color = const Color(0xFF10B981);
                } else {
                  label = 'Disk';
                  color = const Color(0xFFF59E0B);
                }
                return LineTooltipItem(
                  '$label: ${spot.y.toStringAsFixed(0)}%',
                  TextStyle(color: color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

/// Full-screen chart view with time range picker
class _FullScreenChart extends StatefulWidget {
  final ResourceHistoryNotifier resourceHistory;
  final ChartTimeRange initialRange;

  const _FullScreenChart({
    required this.resourceHistory,
    required this.initialRange,
  });

  @override
  State<_FullScreenChart> createState() => _FullScreenChartState();
}

class _FullScreenChartState extends State<_FullScreenChart> {
  late ChartTimeRange _selectedRange;

  List<FlSpot> _cpuSpots = [];
  List<FlSpot> _memorySpots = [];
  List<FlSpot> _diskSpots = [];

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
    _generateSpots();
    widget.resourceHistory.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.resourceHistory.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _generateSpots();
    if (mounted) setState(() {});
  }

  void _generateSpots() {
    final dataPoints = widget.resourceHistory.cpuData;
    final maxSeconds = _selectedRange.seconds;

    if (dataPoints.isEmpty) {
      _cpuSpots = [];
      _memorySpots = [];
      _diskSpots = [];
      return;
    }

    final now = dataPoints.last.timestamp;
    final cutoff = now.subtract(Duration(seconds: maxSeconds));

    _cpuSpots = [];
    _memorySpots = [];
    _diskSpots = [];

    for (final point in dataPoints) {
      if (point.timestamp.isBefore(cutoff)) continue;
      final x = point.timestamp.difference(cutoff).inSeconds.toDouble();
      _cpuSpots.add(FlSpot(x, point.cpuLoad));
      _memorySpots.add(FlSpot(x, point.memoryUsage));
      _diskSpots.add(FlSpot(x, point.diskUsage));
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.resourceHistory.latest;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        title: Text(AppStrings.of(context).systemResources),
        actions: [
          if (latest != null) ...[
            _buildLiveIndicator(context),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          // Time range selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: context.appSurface,
            child: Row(
              children: [
                Text(
                  'Time Range:',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<ChartTimeRange>(
                    segments: ChartTimeRange.values.map((range) {
                      return ButtonSegment(
                        value: range,
                        label: Text(range.label),
                      );
                    }).toList(),
                    selected: {_selectedRange},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _selectedRange = selected.first;
                        _generateSpots();
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return context.appPrimary.withValues(alpha: 0.2);
                        }
                        return context.appBackground;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return context.appPrimary;
                        }
                        return context.appOnSurface.withValues(alpha: 0.7);
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                    'CPU', latest?.cpuLoad ?? 0, const Color(0xFF6366F1)),
                const SizedBox(width: 24),
                _buildLegendItem(
                    'RAM', latest?.memoryUsage ?? 0, const Color(0xFF10B981)),
                const SizedBox(width: 24),
                _buildLegendItem(
                    'Disk', latest?.diskUsage ?? 0, const Color(0xFFF59E0B)),
              ],
            ),
          ),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFullScreenChart(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${value.toStringAsFixed(0)}%',
          style: TextStyle(
            color: context.appOnSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenChart() {
    if (_cpuSpots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Collecting data...',
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: context.appOnSurface.withValues(alpha: 0.1),
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
              reservedSize: 24,
              interval: _selectedRange.seconds / 4,
              getTitlesWidget: (value, meta) {
                final seconds = value.toInt();
                if (seconds < 60) {
                  return Text(
                    '${seconds}s',
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  );
                }
                final minutes = seconds ~/ 60;
                return Text(
                  '${minutes}m',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 25,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > 100) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        clipData: const FlClipData.all(),
        lineBarsData: [
          _buildLineData(_cpuSpots, const Color(0xFF6366F1)),
          _buildLineData(_memorySpots, const Color(0xFF10B981)),
          _buildLineData(_diskSpots, const Color(0xFFF59E0B)),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                String label;
                Color color;
                if (spot.barIndex == 0) {
                  label = 'CPU';
                  color = const Color(0xFF6366F1);
                } else if (spot.barIndex == 1) {
                  label = 'RAM';
                  color = const Color(0xFF10B981);
                } else {
                  label = 'Disk';
                  color = const Color(0xFFF59E0B);
                }
                return LineTooltipItem(
                  '$label: ${spot.y.toStringAsFixed(0)}%',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
