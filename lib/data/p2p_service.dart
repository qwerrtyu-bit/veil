// ========== lib/data/p2p_service.dart ==========
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';

class P2PService {
  final _uuid = const Uuid();
  final String _nodeId = const Uuid().v4();
  final String _serverUrl = 'https://veil-qkm4.onrender.com';
  final Map<String, Function(Map<String, dynamic>)> _onMessageCallbacks = {};
  bool _connected = false;
  bool _polling = false;

  String get nodeId => _nodeId;
  bool get isConnected => _connected;

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
        print('📡 Подключён к P2P сети');
        _startPolling();
      }
    } catch (e) {
      print('❌ Ошибка подключения: $e');
      Future.delayed(const Duration(seconds: 3), _register);
    }
  }

  void _startPolling() {
    if (_polling) return;
    _polling = true;
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_connected) { timer.cancel(); _polling = false; return; }
      try {
        final response = await http.get(Uri.parse('$_serverUrl/poll?userId=$_nodeId'));
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
    try {
      await http.post(
        Uri.parse('$_serverUrl/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );
      print('📤 Отправлено через P2P');
    } catch (e) {
      print('⚠️ Ошибка отправки: $e');
    }
  }

  Future<List<Map<String, dynamic>>> syncAllMessages() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/poll?userId=$_nodeId&sync=true'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messages = data['messages'] as List? ?? [];
        return messages.where((m) => m is Map).map((m) => Map<String, dynamic>.from(m as Map)).toList();
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
            if (item is Map) chatMessages.add(Map<String, dynamic>.from(item));
          }
        }
        final exists = chatMessages.any((m) => m['id'] == msg['id']);
        if (!exists) {
          chatMessages.add({
            'text': text,
            'isMe': false,
            'time': msg['timestamp']?.toString().substring(11, 16) ?? '',
            'id': msg['id'],
          });
          box.put(chatId, chatMessages);
        }
      }
    }
  }

  void onMessage(String chatId, Function(Map<String, dynamic>) callback) {
    _onMessageCallbacks[chatId] = callback;
  }
}