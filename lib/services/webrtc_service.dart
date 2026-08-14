import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import '../data/websocket_service.dart';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isCallActive = false;
  String? _currentRoomId;

  // 🔧 Рендереры — НЕ FINAL, чтобы можно было пересоздавать
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  WebSocketService? _webSocket;
  final Map<String, Function(Map<String, dynamic>)> _signalHandlers = {};

  final Map<String, dynamic> _configuration = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {
      'urls': [
        'turn:openrelay.metered.ca:80',
        'turn:openrelay.metered.ca:443',
        'turn:openrelay.metered.ca:5349',
      ],
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ],
  'sdpSemantics': 'unified-plan',
  'iceConnectionStateTimeout': 30,  // <-- ДОБАВЛЕНО
  'iceGatheringTimeout': 20,        // <-- ДОБАВЛЕНО
};

  RTCVideoRenderer? get localRenderer => _localRenderer;
  RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  bool get isCallActive => _isCallActive;

  //рендеры (инициализация)

  Future<void> initRenderers() async {
    try {
      // Уничтожаем старые рендереры
      _localRenderer?.dispose();
      _remoteRenderer?.dispose();
      
      // Создаём новые
      _localRenderer = RTCVideoRenderer();
      _remoteRenderer = RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      print('📺 Рендереры созданы');
    } catch (e) {
      print('❌ Ошибка создания рендереров: $e');
      rethrow;
    }
  }

  Future<void> initLocalStream() async {
    try {
      final constraints = {
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': 640,
          'height': 480,
        }
      };

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      
      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
      }
      
      print('📸 Локальный стрим получен');
    } catch (e) {
      print('❌ Ошибка получения стрима: $e');
      rethrow;
    }
  }

  Future<void> switchCamera() async {
    if (_localStream == null) return;
    final tracks = _localStream!.getVideoTracks();
    if (tracks.isNotEmpty) {
      await tracks.first.switchCamera();
    }
  }

  void initSignalChannel(WebSocketService webSocket, String roomId) {
    _webSocket = webSocket;
    _currentRoomId = roomId;
    _webSocket!.onSignal((signal) {
      handleSignal(signal);
    });
    print('🔗 Сигнальный канал: $roomId');
  }

  //звонки

  Future<void> startCall(String roomId) async {
    _currentRoomId = roomId;
    await _createPeerConnection();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _sendSignal(roomId, {
      'type': 'offer',
      'sdp': offer.sdp,
      'from': 'caller',
    });

    _isCallActive = true;
    print('📞 Звонок начат: $roomId');
  }

  Future<void> acceptCall(String roomId) async {
    _currentRoomId = roomId;
    await _createPeerConnection();

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    _isCallActive = true;
    print('📞 Звонок принят: $roomId');
  }

  Future<void> createAnswer() async {
    if (_peerConnection == null) return;

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _sendSignal(_currentRoomId!, {
      'type': 'answer',
      'sdp': answer.sdp,
    });

    print('📤 Answer отправлен');
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection не инициализирован');
    }
    await _peerConnection!.setRemoteDescription(description);
  }

  //обработка сигналов

  void handleSignal(Map<String, dynamic> signal) {
    final type = signal['type'] as String;

    switch (type) {
      case 'offer':
        _handleOffer(signal);
        break;
      case 'answer':
        _handleAnswer(signal);
        break;
      case 'candidate':
        _handleCandidate(signal);
        break;
      case 'hangup':
        _hangUp();
        break;
      default:
        print('⚠️ Неизвестный сигнал: $type');
    }
  }

  void _handleOffer(Map<String, dynamic> signal) {
    final sdp = signal['sdp'] as String;
    final roomId = signal['roomId'] as String;
    print('📥 Offer из комнаты: $roomId');
    _notifyIncomingCall(roomId, sdp);
  }

  Future<void> _handleAnswer(Map<String, dynamic> signal) async {
    final sdp = signal['sdp'] as String;
    print('📥 Answer получен');
    final description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection?.setRemoteDescription(description);
  }

  Future<void> _handleCandidate(Map<String, dynamic> signal) async {
    final candidate = signal['candidate'] as String;
    final sdpMid = signal['sdpMid'] as String;
    final sdpMLineIndex = signal['sdpMLineIndex'] as int;

    print('🧊 ICE candidate получен');
    final iceCandidate = RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);
    await _peerConnection?.addCandidate(iceCandidate);
  }

  //вспомогательные

  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendSignal(_currentRoomId!, {
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
        print('🧊 ICE candidate отправлен');
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' || event.track.kind == 'audio') {
        _remoteStream = event.streams.first;
        if (_remoteRenderer != null) {
          _remoteRenderer!.srcObject = _remoteStream;
          _notifyRemoteStream();
          print('📥 Удалённый стрим получен');
        }
      }
    };

    _peerConnection!.onConnectionState = (state) {
      print('🔗 Состояние: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _hangUp();
      }
    };
  }

  void _sendSignal(String roomId, Map<String, dynamic> data) {
    final signal = {'roomId': roomId, ...data};
    if (_webSocket != null && _webSocket!.isConnected) {
      _webSocket!.sendSignal(signal);
    } else {
      for (final handler in _signalHandlers.values) {
        handler(signal);
      }
      print('⚠️ WebSocket не подключён');
    }
  }

  void setSignalHandler(Function(Map<String, dynamic>) handler) {
    _signalHandlers['default'] = handler;
  }

  // завершение звонка
 

  void hangUp() {
    try {
      _sendSignal(_currentRoomId ?? '', {'type': 'hangup'});
      _hangUp();
    } catch (e) {
      print('⚠️ Ошибка hangUp: $e');
      _hangUp();
    }
  }

  void _hangUp() {
    try {
      _peerConnection?.close();
      _peerConnection = null;
      _remoteStream = null;
      _isCallActive = false;
      _currentRoomId = null;

      // Очищаем рендереры
      if (_remoteRenderer != null) {
        try {
          _remoteRenderer!.srcObject = null;
        } catch (_) {}
      }
      if (_localRenderer != null) {
        try {
          _localRenderer!.srcObject = null;
        } catch (_) {}
      }

      print('📞 Звонок завершён');
    } catch (e) {
      print('⚠️ Ошибка при завершении: $e');
    }
  }

  void dispose() {
    try {
      _hangUp();
      _localStream?.dispose();
      _localStream = null;

      _localRenderer?.dispose();
      _localRenderer = null;
      _remoteRenderer?.dispose();
      _remoteRenderer = null;

      print('🧹 Ресурсы очищены');
    } catch (e) {
      print('⚠️ Ошибка dispose: $e');
    }
  }

  
  // ноутификэйшн (ноутификации)
  

  final List<Function(String, String)> _callListeners = [];

  void onIncomingCall(Function(String roomId, String sdp) callback) {
    _callListeners.add(callback);
  }

  void _notifyIncomingCall(String roomId, String sdp) {
    for (final listener in _callListeners) {
      listener(roomId, sdp);
    }
  }

  final List<Function()> _streamListeners = [];

  void onRemoteStream(Function() callback) {
    _streamListeners.add(callback);
  }

  void _notifyRemoteStream() {
    for (final listener in _streamListeners) {
      listener();
    }
  }
}