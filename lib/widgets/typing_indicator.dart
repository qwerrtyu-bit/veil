import 'dart:math';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool isTyping;
  final String? username;
  final Color color;

  const TypingIndicator({
    super.key,
    required this.isTyping,
    this.username,
    this.color = const Color(0xFF6C5CE7),
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _generateParticles();
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speedX: (-0.5 + _random.nextDouble()) * 0.5,
        speedY: (-0.5 + _random.nextDouble()) * 0.5,
        opacity: 0.3 + _random.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTyping) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final time = _controller.value * 2 * 3.14;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0.08),
                widget.color.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.color.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Аватар или имя
              if (widget.username != null) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: widget.color.withOpacity(0.15),
                  child: Text(
                    widget.username![0].toUpperCase(),
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Частицы
              CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  time: time,
                  color: widget.color,
                ),
                child: const SizedBox(
                  width: 40,
                  height: 20,
                ),
              ),
              const SizedBox(width: 8),
              // Точки
              Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final value = ((time / 2 + delay) % (2 * 3.14)) / (2 * 3.14);
                  final scale = 0.5 + 0.5 * (1 + sin(value * 2 * 3.14)) / 2;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Transform.scale(
                      scale: 0.6 + scale * 0.8,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.3 + scale * 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 4),
              Text(
                widget.username != null
                    ? 'печатает...'
                    : 'Печатает...',
                style: TextStyle(
                  color: widget.color.withOpacity(0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speedX;
  final double speedY;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.time,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = (p.x + time * p.speedX * 0.1) % 1.0 * size.width;
      final dy = (p.y + time * p.speedY * 0.1) % 1.0 * size.height;

      final paint = Paint()
        ..color = color.withOpacity(p.opacity * (0.5 + 0.5 * (1 + sin(time + p.x * 10)) / 2))
        ..style = PaintingStyle.fill;

      final radius = p.size * (1 + 0.3 * sin(time * 1.2 + p.y * 5));

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}