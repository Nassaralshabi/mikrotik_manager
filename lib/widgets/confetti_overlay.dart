import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final int particleCount;
  final Duration duration;
  final List<Color> colors;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.isPlaying = false,
    this.particleCount = 50,
    this.duration = const Duration(seconds: 3),
    this.colors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ],
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiParticle>? _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.isPlaying) {
      _startConfetti();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    final size = MediaQuery.of(context).size;
    _particles = List.generate(widget.particleCount, (index) {
      return _ConfettiParticle(
        x: _random.nextDouble() * size.width,
        y: -20 - _random.nextDouble() * 100,
        color: widget.colors[_random.nextInt(widget.colors.length)],
        size: 8 + _random.nextDouble() * 8,
        speedY: 2 + _random.nextDouble() * 4,
        speedX: -1 + _random.nextDouble() * 2,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: -0.1 + _random.nextDouble() * 0.2,
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isPlaying && _particles != null)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ConfettiPainter(
                  particles: _particles!,
                  progress: _controller.value,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double speedY;
  final double speedX;
  double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final currentY = particle.y + particle.speedY * progress * 200;
      final currentX = particle.x + particle.speedX * progress * 50;
      final currentRotation =
          particle.rotation + particle.rotationSpeed * progress * 10;

      if (currentY > size.height + 20) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: 1 - progress * 0.5)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiCelebration extends StatelessWidget {
  final String message;
  final Widget child;
  final bool celebrate;
  final int milestoneCount;
  final List<Color> colors;

  const ConfettiCelebration({
    super.key,
    required this.message,
    required this.child,
    required this.celebrate,
    this.milestoneCount = 100,
    this.colors = const [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (celebrate)
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiOverlay(
                isPlaying: celebrate,
                colors: colors,
                child: const SizedBox.expand(),
              ),
            ),
          ),
      ],
    );
  }
}
