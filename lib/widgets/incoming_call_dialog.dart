import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart'; // <-- ДОБАВИТЬ
import '../services/webrtc_service.dart';
import '../screens/call_screen.dart'; // <-- ДОБАВИТЬ

class IncomingCallDialog extends ConsumerStatefulWidget {
  final String callerId;
  final String callerName;
  final String roomId;
  final String sdp;

  const IncomingCallDialog({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.roomId,
    required this.sdp,
  });

  @override
  ConsumerState<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends ConsumerState<IncomingCallDialog> {
  final _webRTC = WebRTCService();
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    try {
      await _webRTC.initRenderers();
      await _webRTC.initLocalStream();
    } catch (e) {
      print('❌ Ошибка инициализации стримов: $e');
    }
  }

  Future<void> _acceptCall() async {
    setState(() => _isAccepted = true);

    try {
      // Принимаем звонок
      await _webRTC.acceptCall(widget.roomId);
      
      // Устанавливаем удалённое описание (offer от звонящего)
      final description = RTCSessionDescription(widget.sdp, 'offer');
      await _webRTC.setRemoteDescription(description); // <-- ИСПРАВЛЕНО
      
      // Создаём и отправляем answer
      await _webRTC.createAnswer();

      // Закрываем диалог и переходим в экран звонка
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              contactId: widget.callerId,
              contactName: widget.callerName,
              isVideo: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка принятия звонка: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _rejectCall() {
    _webRTC.hangUp();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Анимация звонка
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Container(
                          width: 40 + value * 80,
                          height: 40 + value * 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6C5CE7).withOpacity(0.3 - value * 0.25),
                              width: 2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const Icon(
                    Icons.phone_in_talk,
                    color: Color(0xFF6C5CE7),
                    size: 40,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Входящий звонок',
              style: const TextStyle(
                color: Color(0xFFF4F4F5),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Color(0xFFF4F4F5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.callerId.substring(0, 8)}...',
              style: TextStyle(
                color: const Color(0xFF888899),
                fontSize: 13,
                fontFamily: 'SpaceMono',
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Кнопка "Отклонить"
                GestureDetector(
                  onTap: _rejectCall,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                // Кнопка "Принять"
                GestureDetector(
                  onTap: _isAccepted ? null : _acceptCall,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _isAccepted ? Colors.grey : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: _isAccepted
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 32,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}