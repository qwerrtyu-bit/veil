import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../data/websocket_service.dart';
import '../providers/websocket_provider.dart';
import '../widgets/incoming_call_dialog.dart';
import '../services/ringtone_generator.dart';

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

class _CallScreenState extends ConsumerState<CallScreen> {
  late WebRTCService _webRTC;
  late WebSocketService _webSocket;
  bool _isMuted = false;
  bool _isSpeaker = true;
  int _seconds = 0;
  bool _isCallActive = false;
  bool _isInitialized = false;
  String? _roomId;

  @override
  void initState() {
    super.initState();

    _webSocket = ref.read(webSocketProvider);
    _webRTC = WebRTCService();

    _webSocket.onIncomingCall((data) {
      _showIncomingCallDialog(data);
    });

    _initCall();
  }

  Future<void> _initCall() async {
    try {
      // НЕ СОЗДАЁМ НОВЫЙ WEBSOCKET, ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩИЙ
      if (!_webSocket.isConnected) {
        print('❌ WebSocket не подключён, звонок невозможен');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Нет подключения к серверу'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✅ WebSocket уже подключён, начинаем звонок');

      if (widget.isVideo) {
        await _webRTC.initRenderers();
      }

      await _webRTC.initLocalStream();

      RingtoneGenerator.playDialtone();

      _roomId = 'call_${widget.contactId}_${DateTime.now().millisecondsSinceEpoch}';
      _webRTC.initSignalChannel(_webSocket, _roomId!);
      await _webRTC.startCall(_roomId!);

      setState(() {
        _isCallActive = true;
        _isInitialized = true;
      });

      _startTimer();
    } catch (e) {
      print('❌ Ошибка звонка: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось начать звонок: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showIncomingCallDialog(Map<String, dynamic> data) {
    final callerId = data['from'] as String? ?? 'unknown';
    final callerName = data['callerName'] as String? ?? 'Контакт';
    final roomId = data['roomId'] as String? ?? '';
    final sdp = data['sdp'] as String? ?? '';

    if (roomId.isEmpty || sdp.isEmpty) return;

    RingtoneGenerator.playRingtone();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        callerId: callerId,
        callerName: callerName,
        roomId: roomId,
        sdp: sdp,
      ),
    );
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isCallActive) return;
      setState(() => _seconds++);
      _startTimer();
    });
  }

  String get _timeString {
    final min = _seconds ~/ 60;
    final sec = _seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    _webRTC.hangUp();
    setState(() {
      _isCallActive = false;
      _isInitialized = false;
    });
    context.go('/chats');
  }

  @override
  void dispose() {
    _webRTC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0F),
                    const Color(0xFF1A1A2E).withOpacity(0.8),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),

            if (_isInitialized && widget.isVideo)
              Positioned.fill(
                child: Stack(
                  children: [
                    if (_webRTC.remoteRenderer != null)
                      Container(
                        color: Colors.black,
                        child: RTCVideoView(
                          _webRTC.remoteRenderer!,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    if (_webRTC.localRenderer != null)
                      Positioned(
                        top: 40,
                        right: 20,
                        child: Container(
                          width: 120,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: RTCVideoView(
                              _webRTC.localRenderer!,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                      child: Text(
                        widget.contactName.isNotEmpty
                            ? widget.contactName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF6C5CE7),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.contactName,
                      style: const TextStyle(
                        color: Color(0xFFF4F4F5),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isVideo ? 'Видеозвонок' : 'Аудиозвонок',
                      style: const TextStyle(
                        color: Color(0xFF71717A),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeString,
                      style: const TextStyle(
                        color: Color(0xFF6C5CE7),
                        fontSize: 16,
                        fontFamily: 'SpaceMono',
                      ),
                    ),
                  ],
                ),
              ),

            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : const Color(0xFF27272A),
                      label: _isMuted ? 'Выкл' : 'Микрофон',
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    _buildCallButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      label: 'Завершить',
                      onTap: _endCall,
                      isLarge: true,
                    ),
                    _buildCallButton(
                      icon: _isSpeaker ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeaker ? const Color(0xFF6C5CE7) : const Color(0xFF27272A),
                      label: _isSpeaker ? 'Динамик' : 'Тихо',
                      onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isLarge ? 68 : 52,
            height: isLarge ? 68 : 52,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: color == Colors.red
                  ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20)]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: isLarge ? 30 : 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
          ),
        ],
      ),
    );
  }
}