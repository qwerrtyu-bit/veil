import 'package:hive_flutter/hive_flutter.dart';

class ChatService {
  final Box _messagesBox = Hive.box('messages');
  final Box _settingsBox = Hive.box('settings');

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
      'reactions': <String, List<String>>{},
      'isPinned': false,
      'isRead': isMe ? true : false,
    });
    _saveChatMessages(chatId, chatMessages);
  }

  List<Map<String, dynamic>> loadMessages(String chatId) {
    _checkChatExpiry(chatId);
    return _getChatMessages(chatId);
  }

  List<Map<String, dynamic>> _getChatMessages(String chatId) {
    final data = _messagesBox.get(chatId);
    if (data == null) return [];
    if (data is! List) return [];

    final List<Map<String, dynamic>> result = [];
    for (final item in data) {
      if (item is Map) {
        final reactions = item['reactions'] as Map? ?? {};
        result.add({
          'text': '${item['text'] ?? ''}',
          'isMe': item['isMe'] == true,
          'time': '${item['time'] ?? ''}',
          'reactions': reactions.map((key, value) {
            final list = value is List ? List<String>.from(value) : <String>[];
            return MapEntry(key.toString(), list);
          }),
          'isPinned': item['isPinned'] == true,
          'isRead': item['isRead'] == true,
        });
      }
    }
    return result;
  }

  void _saveChatMessages(String chatId, List<Map<String, dynamic>> messages) {
    final toSave = messages.map((m) => {
      'text': m['text'],
      'isMe': m['isMe'],
      'time': m['time'],
      'reactions': m['reactions'] ?? {},
      'isPinned': m['isPinned'] ?? false,
      'isRead': m['isRead'] ?? false,
    }).toList();
    _messagesBox.put(chatId, toSave);
  }

  void deleteMessage(String chatId, int index) {
    final messages = _getChatMessages(chatId);
    if (index >= 0 && index < messages.length) {
      final isPinned = messages[index]['isPinned'] ?? false;
      messages.removeAt(index);
      if (isPinned) {
        _settingsBox.delete('pinned_$chatId');
      }
      _saveChatMessages(chatId, messages);
    }
  }

  void deleteChat(String chatId) {
    _messagesBox.delete(chatId);
    _settingsBox.delete('chat_expiry_$chatId');
    _settingsBox.delete('pinned_$chatId');
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
    final messages = _getChatMessages(chatId);
    int count = 0;
    for (final msg in messages) {
      if (msg['isMe'] == false && msg['isRead'] == false) {
        count++;
      }
    }
    return count;
  }

  void markAsRead(String chatId, int messageIndex) {
    final messages = _getChatMessages(chatId);
    if (messageIndex < 0 || messageIndex >= messages.length) return;
    if (messages[messageIndex]['isMe'] == false && messages[messageIndex]['isRead'] == false) {
      messages[messageIndex]['isRead'] = true;
      _saveChatMessages(chatId, messages);
    }
  }

  void markAllAsRead(String chatId) {
    final messages = _getChatMessages(chatId);
    bool changed = false;
    for (final msg in messages) {
      if (msg['isMe'] == false && msg['isRead'] == false) {
        msg['isRead'] = true;
        changed = true;
      }
    }
    if (changed) {
      _saveChatMessages(chatId, messages);
    }
  }

  // === Реакции ===
  void toggleReaction(String chatId, int messageIndex, String emoji, String userId) {
    final messages = _getChatMessages(chatId);
    if (messageIndex < 0 || messageIndex >= messages.length) return;

    final message = messages[messageIndex];
    Map<String, List<String>> reactions = {};

    if (message['reactions'] is Map) {
      final raw = message['reactions'] as Map;
      reactions = raw.map((key, value) {
        final list = value is List ? List<String>.from(value) : <String>[];
        return MapEntry(key.toString(), list);
      });
    }

    if (!reactions.containsKey(emoji)) {
      reactions[emoji] = [];
    }

    if (reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.remove(userId);
      if (reactions[emoji]!.isEmpty) {
        reactions.remove(emoji);
      }
    } else {
      reactions[emoji]!.add(userId);
    }

    message['reactions'] = reactions;
    _saveChatMessages(chatId, messages);
  }

  // === Закрепление ===
  void togglePin(String chatId, int messageIndex) {
    final messages = _getChatMessages(chatId);
    if (messageIndex < 0 || messageIndex >= messages.length) return;

    final message = messages[messageIndex];
    final bool isPinned = message['isPinned'] ?? false;

    if (isPinned) {
      _settingsBox.delete('pinned_$chatId');
      message['isPinned'] = false;
    } else {
      _settingsBox.put('pinned_$chatId', messageIndex);
      message['isPinned'] = true;
    }

    _saveChatMessages(chatId, messages);
  }

  Map<String, dynamic>? getPinnedMessage(String chatId) {
    final pinnedIndex = _settingsBox.get('pinned_$chatId');
    if (pinnedIndex == null) return null;
    final messages = _getChatMessages(chatId);
    if (pinnedIndex < 0 || pinnedIndex >= messages.length) return null;
    return messages[pinnedIndex];
  }

  // === Таймер автоудаления чата ===
  void setChatExpiry(String chatId, Duration duration) {
    final expiryTime = DateTime.now().add(duration);
    _settingsBox.put('chat_expiry_$chatId', expiryTime.toIso8601String());
  }

  void removeChatExpiry(String chatId) {
    _settingsBox.delete('chat_expiry_$chatId');
  }

  Duration? getChatExpiry(String chatId) {
    final raw = _settingsBox.get('chat_expiry_$chatId');
    if (raw == null) return null;
    try {
      final expiry = DateTime.parse(raw.toString());
      final remaining = expiry.difference(DateTime.now());
      if (remaining.isNegative) return Duration.zero;
      return remaining;
    } catch (_) {
      return null;
    }
  }

  void _checkChatExpiry(String chatId) {
    final raw = _settingsBox.get('chat_expiry_$chatId');
    if (raw == null) return;
    try {
      final expiry = DateTime.parse(raw.toString());
      if (DateTime.now().isAfter(expiry)) {
        _messagesBox.delete(chatId);
        _settingsBox.delete('chat_expiry_$chatId');
        _settingsBox.delete('pinned_$chatId');
      }
    } catch (_) {}
  }

  void editMessage(String chatId, int index, String newText, String newTime) {
  final messages = _getChatMessages(chatId);
  if (index < 0 || index >= messages.length) return;
  
  messages[index]['text'] = newText;
  messages[index]['isEdited'] = true;
  messages[index]['editTime'] = newTime;
  
  _saveChatMessages(chatId, messages);
}
    /// Поиск сообщений по тексту в одном чате
  List<Map<String, dynamic>> searchMessages(String chatId, String query) {
    if (query.isEmpty) return [];
    
    final messages = loadMessages(chatId);
    final lowerQuery = query.toLowerCase();
    
    return messages.where((msg) {
      final text = msg['text'] as String? ?? '';
      return text.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Поиск по всем чатам
  Map<String, List<Map<String, dynamic>>> searchAllChats(String query) {
    if (query.isEmpty) return {};
    
    final result = <String, List<Map<String, dynamic>>>{};
    final box = Hive.box('messages');
    
    // Получаем все ключи (чаты)
    for (final key in box.keys) {
      final chatId = key.toString();
      
      // Пропускаем служебные ключи
      if (chatId.startsWith('group_') || 
          chatId.startsWith('files_') || 
          chatId.startsWith('channel_') ||
          chatId == 'notes' ||
          chatId == 'stories' ||
          chatId == 'plugins' ||
          chatId == 'channels') {
        continue;
      }
      
      final found = searchMessages(chatId, query);
      if (found.isNotEmpty) {
        result[chatId] = found;
      }
    }
    
    return result;
  }

  /// Получить имя контакта по ID
  String getContactName(String chatId) {
    try {
      final contactsBox = Hive.box('contacts');
      final data = contactsBox.get(chatId);
      if (data is Map) {
        return data['name']?.toString() ?? 'Контакт';
      }
    } catch (_) {}
    return 'Контакт';
  }
}