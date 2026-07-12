import 'dart:math';
import 'package:flutter/material.dart';

class EncryptAnimation extends StatefulWidget {
  final String text;
  final bool isEncrypting;
  final Color textColor;
  final double fontSize;
  final VoidCallback? onComplete;

  const EncryptAnimation({
    super.key,
    required this.text,
    required this.isEncrypting,
    required this.textColor,
    this.fontSize = 16,
    this.onComplete,
  });

  @override
  State<EncryptAnimation> createState() => _EncryptAnimationState();
}

class _EncryptAnimationState extends State<EncryptAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  final List<_Particle> _particles = [];
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=!@#\$%^&*';
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _generateParticles();

    _controller.addListener(() {
      setState(() {
        _displayText = _scramble(widget.text, _controller.value, widget.isEncrypting);
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble() * 1.5,
        size: 2 + _random.nextDouble() * 4,
        opacity: 0.3 + _random.nextDouble() * 0.7,
      ));
    }
  }

  String _scramble(String text, double progress, bool encrypting) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final charProgress = (progress * text.length - i).clamp(0.0, 1.0);
      if (encrypting) {
        buffer.write(charProgress > 0 ? _chars[_random.nextInt(_chars.length)] : text[i]);
      } else {
        buffer.write(charProgress > 0 ? text[i] : _chars[_random.nextInt(_chars.length)]);
      }
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            color: widget.textColor,
          ),
          child: Text(
            _displayText,
            style: TextStyle(
              color: widget.textColor,
              fontSize: widget.fontSize,
              fontFamily: 'SpaceMono',
              letterSpacing: 1.5,
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x, y, speed, size, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = (p.x + progress * p.speed * 0.3) % 1.0 * size.width;
      final dy = (p.y + progress * p.speed * 0.2) % 1.0 * size.height;
      final paint = Paint()
        ..color = color.withOpacity(p.opacity * (1 - progress))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}