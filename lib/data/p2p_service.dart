import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import 'websocket_service.dart';
import '../services/notification_service.dart';

class P2PService {
  final _uuid = const Uuid();
  final String _nodeId = const Uuid().v4();
  final String _serverUrl = VeilConstants.serverUrl;
  final Map<String, Function(Map<String, dynamic>)> _onMessageCallbacks = {};
  bool _connected = false;
  bool _polling = false;
  late WebSocketService _webSocket;

  String get nodeId => _nodeId;
  bool get isConnected => _connected;

  P2PService() {
    _webSocket = WebSocketService();
  }

  void start() {
    print('🟢 P2P узел запущен: ${_nodeId.substring(0, 8)}');
    _register();
  }

  Future<void> _register() async {
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': _nodeId}),
      );
      
      if (response.statusCode == 200) {
        _connected = true;
        print('📡 Подключён к P2P сети (HTTP)');
        
        _webSocket.connect(_nodeId, onMessage: _handleWebSocketMessage);
        
        _startPolling();
      }
    } catch (e) {
      print('❌ Ошибка подключения: $e');
      Future.delayed(const Duration(seconds: 3), _register);
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    if (data['type'] == 'ack') return;
    
    final chatId = data['chatId'] as String?;
    if (chatId != null && _onMessageCallbacks.containsKey(chatId)) {
      _onMessageCallbacks[chatId]!(data);
    }
    
    // 🔔 ПОКАЗЫВАЕМ УВЕДОМЛЕНИЕ
    try {
      final text = data['text'] as String? ?? 'Новое сообщение';
      final sender = data['from'] as String? ?? 'Кто-то';
      
      // Получаем имя контакта
      String contactName = sender;
      try {
        final contactsBox = Hive.box('contacts');
        final contact = contactsBox.get(sender);
        if (contact is Map) {
          contactName = contact['name']?.toString() ?? sender;
        }
      } catch (_) {}
      
      NotificationService().showWindowsNotification(
        '📩 $contactName',
        text.length > 50 ? '${text.substring(0, 50)}...' : text,
      );
    } catch (e) {
      print('⚠️ Ошибка уведомления: $e');
    }
  }

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_connected) {
        timer.cancel();
        _polling = false;
        return;
      }

      if (_webSocket.isConnected) return;

      try {
        final response = await http.get(
          Uri.parse('$_serverUrl/poll?userId=$_nodeId'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final messages = data['messages'] as List? ?? [];
          
          for (final msg in messages) {
            if (msg is Map<String, dynamic>) {
              final chatId = msg['chatId'] as String?;
              if (chatId != null && _onMessageCallbacks.containsKey(chatId)) {
                _onMessageCallbacks[chatId]!(msg);
              }
            }
          }
        }
      } catch (e) {}
    });
  }

  Future<void> sendMessage({
    required String recipientId,
    required String encryptedText,
    required String chatId,
  }) async {
    final message = {
      'id': _uuid.v4(),
      'from': _nodeId,
      'to': recipientId,
      'chatId': chatId,
      'text': encryptedText,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (_webSocket.isConnected) {
      _webSocket.sendMessage(message);
      print('📤 Отправлено через WebSocket');
      return;
    }

    try {
      await http.post(
        Uri.parse('$_serverUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );
      print('📤 Отправлено через HTTP');
    } catch (e) {
      print('⚠️ Ошибка отправки: $e');
    }
  }

  Future<List<Map<String, dynamic>>> syncAllMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/poll?userId=$_nodeId&sync=true'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messages = data['messages'] as List? ?? [];
        return messages.whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      print('⚠️ Ошибка синхронизации: $e');
    }
    return [];
  }

  Future<void> applySync(List<Map<String, dynamic>> messages) async {
    final box = Hive.box('messages');
    
    for (final msg in messages) {
      final chatId = msg['chatId'] as String?;
      final text = msg['text'] as String?;
      
      if (chatId != null && text != null) {
        final raw = box.get(chatId);
        List<Map<String, dynamic>> chatMessages = [];
        
        if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              chatMessages.add(Map<String, dynamic>.from(item));
            }
          }
        }
        
        final exists = chatMessages.any((m) => m['id'] == msg['id']);
        if (!exists) {
          final time = msg['timestamp']?.toString().substring(11, 16) ?? '';
          chatMessages.add({
            'text': text,
            'isMe': false,
            'time': time,
            'id': msg['id'],
          });
          box.put(chatId, chatMessages);
        }
      }
    }
  }

  void onMessage(String chatId, Function(Map<String, dynamic>) callback) {
    _onMessageCallbacks[chatId] = callback;
    _webSocket.onMessage(chatId, callback);
  }

  void disconnect() {
    _webSocket.disconnect();
    _connected = false;
    _polling = false;
  }

  void reconnect() {
    if (_nodeId.isNotEmpty) {
      _webSocket.disconnect();
      _webSocket.connect(_nodeId);
    }
  }
}