import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:veil/data/chat_service.dart';

void main() {
  late ChatService chatService;

  setUpAll(() async {
    // Инициализируем Hive в памяти (без path_provider)
    Hive.init('test_memory');
    await Hive.openBox('messages');
    await Hive.openBox('settings');
  });

  setUp(() {
    chatService = ChatService();
    final box = Hive.box('messages');
    box.clear();
    final settingsBox = Hive.box('settings');
    settingsBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('ChatService', () {
    const testChatId = 'test_chat_1';

    test('saveMessage - сохраняет сообщение в чате', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Hello, Veil!',
        isMe: true,
        time: '12:00',
      );

      final messages = chatService.loadMessages(testChatId);
      expect(messages.length, 1);
      expect(messages[0]['text'], 'Hello, Veil!');
      expect(messages[0]['isMe'], true);
      expect(messages[0]['time'], '12:00');
    });

    test('loadMessages - загружает все сообщения из чата', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 2',
        isMe: false,
        time: '12:01',
      );

      final messages = chatService.loadMessages(testChatId);
      expect(messages.length, 2);
      expect(messages[0]['text'], 'Message 1');
      expect(messages[1]['text'], 'Message 2');
    });

    test('loadMessages - возвращает пустой список для несуществующего чата', () {
      final messages = chatService.loadMessages('non_existent_chat');
      expect(messages, []);
    });

    test('deleteMessage - удаляет сообщение по индексу', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 2',
        isMe: true,
        time: '12:01',
      );

      chatService.deleteMessage(testChatId, 0);
      final messages = chatService.loadMessages(testChatId);
      expect(messages.length, 1);
      expect(messages[0]['text'], 'Message 2');
    });

    test('deleteMessage - не удаляет при неверном индексе', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );

      chatService.deleteMessage(testChatId, 5);
      final messages = chatService.loadMessages(testChatId);
      expect(messages.length, 1);
    });

    test('deleteChat - удаляет весь чат', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );

      chatService.deleteChat(testChatId);
      final messages = chatService.loadMessages(testChatId);
      expect(messages, []);
    });

    test('getLastMessage - возвращает последнее сообщение', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 2',
        isMe: false,
        time: '12:01',
      );

      final last = chatService.getLastMessage(testChatId);
      expect(last, isNotNull);
      expect(last!['text'], 'Message 2');
      expect(last['time'], '12:01');
    });

    test('getLastMessage - возвращает null для пустого чата', () {
      final last = chatService.getLastMessage(testChatId);
      expect(last, isNull);
    });

    test('getUnreadCount - считает непрочитанные сообщения', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 2',
        isMe: false,
        time: '12:01',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 3',
        isMe: false,
        time: '12:02',
      );

      final unread = chatService.getUnreadCount(testChatId);
      expect(unread, 2);
    });

    test('markAsRead - отмечает сообщение как прочитанное', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: false,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 2',
        isMe: false,
        time: '12:01',
      );

      chatService.markAsRead(testChatId, 0);
      final messages = chatService.loadMessages(testChatId);
      expect(messages[0]['isRead'], true);
      expect(messages[1]['isRead'], false);
    });

    test('markAllAsRead - отмечает все сообщения как прочитанные', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: false,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 2',
        isMe: false,
        time: '12:01',
      );

      chatService.markAllAsRead(testChatId);
      final messages = chatService.loadMessages(testChatId);
      expect(messages[0]['isRead'], true);
      expect(messages[1]['isRead'], true);
    });

    test('toggleReaction - добавляет и удаляет реакцию', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );

      chatService.toggleReaction(testChatId, 0, '👍', 'user1');
      final messages = chatService.loadMessages(testChatId);
      expect(messages[0]['reactions']['👍'], contains('user1'));

      chatService.toggleReaction(testChatId, 0, '👍', 'user1');
      final messages2 = chatService.loadMessages(testChatId);
      expect(messages2[0]['reactions']['👍'], isNot(contains('user1')));
    });

    test('toggleReaction - несколько реакций на одно сообщение', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );

      chatService.toggleReaction(testChatId, 0, '👍', 'user1');
      chatService.toggleReaction(testChatId, 0, '❤️', 'user2');

      final messages = chatService.loadMessages(testChatId);
      expect(messages[0]['reactions']['👍'], contains('user1'));
      expect(messages[0]['reactions']['❤️'], contains('user2'));
    });

    test('togglePin - закрепляет и открепляет сообщение', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Message 1',
        isMe: true,
        time: '12:00',
      );

      chatService.togglePin(testChatId, 0);
      final pinned = chatService.getPinnedMessage(testChatId);
      expect(pinned, isNotNull);
      expect(pinned!['text'], 'Message 1');

      chatService.togglePin(testChatId, 0);
      final pinned2 = chatService.getPinnedMessage(testChatId);
      expect(pinned2, isNull);
    });

    test('getPinnedMessage - возвращает закреплённое сообщение', () {
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Pinned message',
        isMe: true,
        time: '12:00',
      );
      chatService.saveMessage(
        chatId: testChatId,
        text: 'Normal message',
        isMe: true,
        time: '12:01',
      );

      chatService.togglePin(testChatId, 0);
      final pinned = chatService.getPinnedMessage(testChatId);
      expect(pinned!['text'], 'Pinned message');
    });

    test('setChatExpiry - устанавливает таймер автоудаления', () {
      chatService.setChatExpiry(testChatId, Duration(minutes: 5));
      final remaining = chatService.getChatExpiry(testChatId);
      expect(remaining, isNotNull);
      // Используем больше или равно 4 (из-за округления)
      expect(remaining!.inMinutes >= 4, true);
    });

    test('removeChatExpiry - удаляет таймер автоудаления', () {
      chatService.setChatExpiry(testChatId, Duration(minutes: 5));
      chatService.removeChatExpiry(testChatId);
      final remaining = chatService.getChatExpiry(testChatId);
      expect(remaining, isNull);
    });
  });
}