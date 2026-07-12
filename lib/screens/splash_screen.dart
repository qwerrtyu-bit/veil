import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

final secureStorage = FlutterSecureStorage();

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  final List<_GlowLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _generateLines();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(seconds: 2), _checkAuth);
  }

  void _generateLines() {
    for (int i = 0; i < 15; i++) {
      _lines.add(_GlowLine(
        startX: _random.nextDouble(),
        startY: _random.nextDouble(),
        speed: 0.2 + _random.nextDouble() * 0.8,
        length: 50 + _random.nextDouble() * 150,
        angle: _random.nextDouble() * pi * 2,
        opacity: 0.1 + _random.nextDouble() * 0.3,
      ));
    }
  }

  Future<void> _checkAuth() async {
    final hasIdentity = await secureStorage.read(key: 'has_identity');
    if (!mounted) return;
    if (hasIdentity == 'true') {
      context.go('/lock');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF0A0A0F)),
        child: Stack(
          children: [
            // Анимированные линии
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LinePainter(
                    lines: _lines,
                    time: _controller.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            // Логотип и текст
            Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Логотип
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4ADE80).withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0A0A0F), size: 42),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      VeilConstants.appName,
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE0E0E0),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      VeilConstants.tagline,
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF888899),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Версия внизу
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8)),
                ),
                child: Text(
                  'v${VeilConstants.version}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF444455), fontSize: 12, fontFamily: 'SpaceMono'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowLine {
  final double startX, startY, speed, length, angle, opacity;
  _GlowLine({
    required this.startX,
    required this.startY,
    required this.speed,
    required this.length,
    required this.angle,
    required this.opacity,
  });
}

class _LinePainter extends CustomPainter {
  final List<_GlowLine> lines;
  final double time;

  _LinePainter({required this.lines, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final progress = (time * line.speed) % 1.0;
      final x = (line.startX + progress * cos(line.angle)) * size.width;
      final y = (line.startY + progress * sin(line.angle)) * size.height;
      final endX = x + cos(line.angle) * line.length;
      final endY = y + sin(line.angle) * line.length;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF4ADE80).withOpacity(line.opacity),
            const Color(0xFF4ADE80).withOpacity(0),
          ],
        ).createShader(Rect.fromPoints(Offset(x, y), Offset(endX, endY)))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x, y), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => true;
}