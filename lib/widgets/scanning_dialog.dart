import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScanningDialog extends StatefulWidget {
  final String title;
  final String subtitle;

  const ScanningDialog({
    super.key,
    this.title = 'Scanning Network',
    this.subtitle = 'Searching for MikroTik routers...',
  });

  @override
  State<ScanningDialog> createState() => _ScanningDialogState();
}

class _ScanningDialogState extends State<ScanningDialog>
    with TickerProviderStateMixin {
  late AnimationController _rotationCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF7B61FF);

    return AlertDialog(
      backgroundColor: Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: Listenable.merge([_rotationCtrl, _pulseCtrl]),
            builder: (context, _) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Transform.rotate(
                        angle: _rotationCtrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(80, 80),
                          painter: _RadarPainter(
                            color: primary,
                            progress: _rotationCtrl.value,
                          ),
                        ),
                      ),
                      // Middle ring
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                      ),
                      // Center icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_find_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: primary.withValues(alpha: 0.1),
                color: primary,
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Color color;
  final double progress;

  _RadarPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Radar sweep
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: progress * 2 * math.pi - math.pi / 2,
        endAngle: progress * 2 * math.pi + 0.3,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius - 2, ringPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}
