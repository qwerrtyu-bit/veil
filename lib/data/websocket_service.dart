import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final Map<String, Function(Map<String, dynamic>)> _messageHandlers = {};
  final List<Function(Map<String, dynamic>)> _signalHandlers = [];
  final List<Function(Map<String, dynamic>)> _incomingCallHandlers = [];
  bool _connected = false;
  String? _userId;
  Timer? _pingTimer;

  bool get isConnected => _connected;

  void connect(String userId, {Function(Map<String, dynamic>)? onMessage}) {
    if (_connected) {
      print('⚠️ WebSocket уже подключён, игнорируем повторный вызов');
      return;
    }

    _userId = userId;

    if (onMessage != null) {
      _messageHandlers['default'] = onMessage;
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${VeilConstants.wsUrl}?userId=$userId'),
      );

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          _connected = false;
          print('🔌 WebSocket отключён');
          _pingTimer?.cancel();
        },
        onError: (error) {
          print('⚠️ WebSocket ошибка: $error');
          _connected = false;
          _pingTimer?.cancel();
        },
      );

      _connected = true;
      _startPing();
      print('🔗 WebSocket подключён: $userId');
    } catch (e) {
      print('❌ Ошибка подключения WebSocket: $e');
      _connected = false;
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_connected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {
          _connected = false;
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;

      if (data['type'] == 'pong') {
        return;
      }

      if (data['type'] == 'signal') {
        if (data['type'] == 'offer') {
          for (final handler in _incomingCallHandlers) {
            handler(data);
          }
        }
        for (final handler in _signalHandlers) {
          handler(data);
        }
        return;
      }

      if (data['type'] == 'ack') {
        print('✅ ACK получен');
        return;
      }

      if (data['chatId'] != null) {
        final chatId = data['chatId'] as String;
        if (_messageHandlers.containsKey(chatId)) {
          _messageHandlers[chatId]!(data);
        } else if (_messageHandlers.containsKey('default')) {
          _messageHandlers['default']!(data);
        }
      }
    } catch (e) {
      print('⚠️ Ошибка обработки WS: $e');
    }
  }

  void sendSignal(Map<String, dynamic> signal) {
    if (!_connected) {
      print('⚠️ WebSocket не подключён, сигнал не отправлен');
      return;
    }

    final message = {
      'type': 'signal',
      ...signal,
    };

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('❌ Ошибка отправки сигнала: $e');
      _connected = false;
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!_connected) {
      print('⚠️ WebSocket не подключён');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('❌ Ошибка отправки: $e');
      _connected = false;
    }
  }

  void onMessage(String chatId, Function(Map<String, dynamic>) handler) {
    _messageHandlers[chatId] = handler;
  }

  void onSignal(Function(Map<String, dynamic>) handler) {
    _signalHandlers.add(handler);
  }

  void onIncomingCall(Function(Map<String, dynamic>) handler) {
    _incomingCallHandlers.add(handler);
  }

  void removeHandler(String chatId) {
    _messageHandlers.remove(chatId);
  }

  void disconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _messageHandlers.clear();
    _signalHandlers.clear();
    _incomingCallHandlers.clear();
    print('🔌 WebSocket отключён (по запросу)');
  }
}