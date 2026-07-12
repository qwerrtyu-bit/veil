import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String contactId;
  final String contactName;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.isVideo = false,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _isMuted = false;
  bool _isSpeaker = true;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _seconds++);
      _startTimer();
    });
  }

  String get _timeString {
    final min = _seconds ~/ 60;
    final sec = _seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _endCall() => context.go('/chats');

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Stack(
              alignment: Alignment.center,
              children: [
                if (!_isMuted)
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _MicWavePainter(
                          amplitude: _waveController.value * 30,
                          color: const Color(0xFF10B981),
                        ),
                        size: const Size(120, 120),
                      );
                    },
                  ),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  child: Text(
                    widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(widget.contactName, style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(widget.isVideo ? 'Видеозвонок' : 'Аудиозвонок', style: const TextStyle(color: Color(0xFF71717A), fontSize: 14)),
            const SizedBox(height: 4),
            Text(_timeString, style: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontFamily: 'SpaceMono')),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(icon: _isMuted ? Icons.mic_off : Icons.mic, color: _isMuted ? Colors.red : const Color(0xFF27272A), label: _isMuted ? 'Выкл' : 'Микрофон', onTap: () => setState(() => _isMuted = !_isMuted)),
                  _buildCallButton(icon: Icons.call_end, color: Colors.red, label: 'Завершить', onTap: _endCall, isLarge: true),
                  _buildCallButton(icon: _isSpeaker ? Icons.volume_up : Icons.volume_off, color: _isSpeaker ? const Color(0xFF10B981) : const Color(0xFF27272A), label: _isSpeaker ? 'Динамик' : 'Тихо', onTap: () => setState(() => _isSpeaker = !_isSpeaker)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('⚠️ Звонки работают в десктопной версии. На вебе — демо.', style: TextStyle(color: Colors.orange, fontSize: 11), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({required IconData icon, required Color color, required String label, required VoidCallback onTap, bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(width: isLarge ? 68 : 52, height: isLarge ? 68 : 52, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: color == Colors.red ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20)] : null), child: Icon(icon, color: Colors.white, size: isLarge ? 30 : 24)),
        const SizedBox(height: 8), Text(label, style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
      ]),
    );
  }
}

class _MicWavePainter extends CustomPainter {
  final double amplitude;
  final Color color;
  _MicWavePainter({required this.amplitude, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, 40.0 + i * 15 + amplitude * (i + 1) * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MicWavePainter oldDelegate) => true;
}