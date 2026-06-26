import 'package:hive_flutter/hive_flutter.dart';

class ChatService {
  final Box _messagesBox = Hive.box('messages');

  void saveMessage({
    required String chatId,
    required String text,
    required bool isMe,
    required String time,
  }) {
    final chatMessages = _getChatMessages(chatId);
    chatMessages.add({
      'text': text,
      'isMe': isMe,
      'time': time,
    });
    // Сохраняем как простой список Map
    final toSave = chatMessages.map((m) => {
      'text': m['text'],
      'isMe': m['isMe'],
      'time': m['time'],
    }).toList();
    _messagesBox.put(chatId, toSave);
  }

  List<Map<String, dynamic>> loadMessages(String chatId) {
    return _getChatMessages(chatId);
  }

  List<Map<String, dynamic>> _getChatMessages(String chatId) {
    final data = _messagesBox.get(chatId);
    if (data == null) return [];
    if (data is! List) return [];
    
    final List<Map<String, dynamic>> result = [];
    for (final item in data) {
      if (item is Map) {
        result.add({
          'text': '${item['text'] ?? ''}',
          'isMe': item['isMe'] == true,
          'time': '${item['time'] ?? ''}',
        });
      }
    }
    return result;
  }

  void deleteMessage(String chatId, int index) {
    final messages = _getChatMessages(chatId);
    if (index >= 0 && index < messages.length) {
      messages.removeAt(index);
      final toSave = messages.map((m) => {
        'text': m['text'],
        'isMe': m['isMe'],
        'time': m['time'],
      }).toList();
      _messagesBox.put(chatId, toSave);
    }
  }

  void deleteChat(String chatId) {
    _messagesBox.delete(chatId);
  }

  Map<String, String>? getLastMessage(String chatId) {
    final messages = _getChatMessages(chatId);
    if (messages.isEmpty) return null;
    final last = messages.last;
    return {
      'text': '${last['text']}',
      'time': '${last['time']}',
    };
  }

  int getUnreadCount(String chatId) {
    return 0;
  }
}