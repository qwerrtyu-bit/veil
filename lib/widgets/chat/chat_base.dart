import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../../data/chat_service.dart';
import '../../data/crypto_service.dart';
import '../../data/file_service.dart';
import '../../data/identity_service.dart';
import '../../models/subscription_model.dart';
import '../../models/wallpaper.dart';
import '../../core/constants.dart';

class ChatBase extends ChangeNotifier {
  final String contactId;

  final ChatService chatService = ChatService();
  final CryptoService cryptoService = CryptoService();
  final FileService fileService = FileService();
  final IdentityService identityService = IdentityService();

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> filteredMessages = [];
  Map<String, dynamic>? replyTo;
  SecretKeyData? sharedKey;
  int selfDestruct = 0;
  bool isSearching = false;
  String searchQuery = '';
  String? currentUserId;

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  final ScrollController scrollController = ScrollController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final List<String> reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡', '🔥', '🎉'];
  final List<String> stickers = [
    '👍', '❤️', '😂', '😮', '😢', '😡', '🎉', '🔥', '💯', '✅',
    '👋', '🤝', '🔒', '🔑', '🛡️', '⚡', '🌟', '💎'
  ];

  final Map<String, String> _usernameCache = {};

  ChatBase({
    required this.contactId,
  }) {
    _init();
  }

  void setTyping(bool typing) {
    if (_isTyping != typing) {
      _isTyping = typing;
      notifyListeners();
    }
  }

  String _sanitizeText(String text) {
    if (text.isEmpty) return '';
    final cleaned = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    try {
      final bytes = utf8.encode(cleaned);
      return utf8.decode(bytes);
    } catch (_) {
      return '⚠️ Повреждённое сообщение';
    }
  }

  Future<String?> _getUsername(String publicKey) async {
    if (_usernameCache.containsKey(publicKey)) {
      return _usernameCache[publicKey];
    }
    try {
      final response = await http.get(
        Uri.parse('${VeilConstants.serverUrl}/username/get?ownerId=$publicKey'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final username = data['username'] as String?;
        if (username != null && username.isNotEmpty) {
          _usernameCache[publicKey] = username;
          return username;
        }
      }
    } catch (_) {}
    return null;
  }

  SubscriptionTier _getCurrentTier() {
    try {
      final box = Hive.box('settings');
      final tierStr = box.get('subscription_tier');
      if (tierStr != null) {
        return SubscriptionTier.values.firstWhere(
          (t) => t.toString() == tierStr,
          orElse: () => SubscriptionTier.free,
        );
      }
    } catch (_) {}
    return SubscriptionTier.free;
  }

  Future<void> _init() async {
    final myPrivateKey = await identityService.getPrivateKey();
    currentUserId = await identityService.getPublicKey() ?? 'unknown';
    
    if (myPrivateKey != null) {
      sharedKey = cryptoService.deriveSharedKey(myPrivateKey, contactId);
    } else {
      sharedKey = cryptoService.createKeyFromString('veil_chat_$contactId');
    }
    
    await loadMessages();
  }

  Future<void> loadMessages() async {
    final savedMessages = chatService.loadMessages(contactId);
    final savedFiles = fileService.loadFiles(contactId);
    final decrypted = <Map<String, dynamic>>[];

    final Set<String> senderKeys = {};
    for (final msg in savedMessages) {
      final sender = msg['sender'] as String?;
      if (sender != null && sender != currentUserId) {
        senderKeys.add(sender);
      }
    }

    for (final key in senderKeys) {
      await _getUsername(key);
    }

    for (final msg in savedMessages) {
      final String display = await _decryptMessage(msg);
      final senderKey = msg['sender'] as String?;
      final senderUsername = senderKey != null && senderKey != currentUserId
          ? _usernameCache[senderKey]
          : null;

      decrypted.add({
        'text': _sanitizeText(display),
        'isMe': msg['isMe'] ?? false,
        'time': msg['time'] ?? '',
        'type': 'text',
        'reactions': msg['reactions'] ?? {},
        'isPinned': msg['isPinned'] ?? false,
        'isRead': msg['isRead'] ?? true,
        'sender': senderKey,
        'senderUsername': senderUsername,
      });
    }

    for (final f in savedFiles) {
      decrypted.add({
        'type': 'file',
        'fileName': f['fileName'] ?? '',
        'text': '📎 ${f['fileName'] ?? ''}',
        'isMe': f['isMe'] ?? false,
        'time': f['time'] ?? '',
        'reactions': {},
        'isPinned': false,
        'isRead': true,
        'sender': null,
        'senderUsername': null,
      });
    }

    messages = decrypted;
    filteredMessages = decrypted;
    chatService.markAllAsRead(contactId);
    notifyListeners();
  }

  Future<String> _decryptMessage(Map<String, dynamic> msg) async {
    final String text = msg['text'] as String? ?? '';
    if (sharedKey == null || text.length <= 50 || !text.contains('\$')) {
      return _sanitizeText(text);
    }

    try {
      final parts = text.split('\$');
      if (parts.length < 2) return _sanitizeText(text);

      final String encryptedKey = parts[0];
      final String encryptedMessage = parts[1];
      final String keyBase64 = await cryptoService.decrypt(encryptedKey, sharedKey!);
      final String decryptedMessage = await cryptoService.decrypt(
        encryptedMessage,
        SecretKeyData(base64.decode(keyBase64)),
      );
      return _sanitizeText(decryptedMessage);
    } catch (_) {
      return _sanitizeText(text);
    }
  }

  Future<void> sendMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final String time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    String encryptedText = text;
    if (sharedKey != null) {
      final ephemeralKey = cryptoService.generateEphemeralKey();
      final String encryptedMessage = await cryptoService.encrypt(text, ephemeralKey);
      final String keyBase64 = base64.encode(ephemeralKey.data);
      final String encryptedKey = await cryptoService.encrypt(keyBase64, sharedKey!);
      encryptedText = '$encryptedKey\$$encryptedMessage';
    }

    final Map<String, dynamic> message = {
      'type': 'text',
      'text': text,
      'isMe': true,
      'time': time,
      'isEncrypted': sharedKey != null,
      'animating': sharedKey != null,
      'replyTo': replyTo,
      'reactions': <String, List<String>>{},
      'isPinned': false,
      'isRead': true,
      'sender': currentUserId,
      'senderUsername': null,
    };

    messages.add(message);
    filteredMessages = messages;
    replyTo = null;
    notifyListeners();

    chatService.saveMessage(
      chatId: contactId,
      text: encryptedText,
      isMe: true,
      time: time,
    );

    messageController.clear();
    scrollDown();

    if (sharedKey != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        message['isEncrypted'] = false;
        message['animating'] = false;
        notifyListeners();
      });
    }

    if (selfDestruct > 0) {
      Future.delayed(Duration(seconds: selfDestruct), () {
        final int idx = messages.indexOf(message);
        if (idx >= 0) {
          messages.removeAt(idx);
          filteredMessages = messages;
          chatService.deleteMessage(contactId, idx);
          notifyListeners();
        }
      });
    }
  }

  Future<void> sendPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      final now = TimeOfDay.now();
      final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      await fileService.saveFile(
        chatId: contactId,
        fileName: photo.name,
        bytes: bytes,
        isMe: true,
        time: time,
        key: sharedKey,
      );

      messages.add({
        'type': 'photo',
        'fileName': photo.name,
        'text': '📷 Фото',
        'imageData': base64Encode(bytes),
        'isMe': true,
        'time': time,
        'reactions': <String, List<String>>{},
        'isPinned': false,
        'isRead': true,
        'sender': currentUserId,
        'senderUsername': null,
      });
      
      filteredMessages = messages;
      notifyListeners();
      scrollDown();
    } catch (e) {
      print('❌ Ошибка отправки фото: $e');
      _onSnackBar?.call('Не удалось отправить фото');
    }
  }

  Future<void> sendVideo() async {
    try {
      final video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      
      if (video == null) return;

      final bytes = await video.readAsBytes();
      final now = TimeOfDay.now();
      final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      await fileService.saveFile(
        chatId: contactId,
        fileName: video.name,
        bytes: bytes,
        isMe: true,
        time: time,
        key: sharedKey,
      );

      messages.add({
        'type': 'video',
        'fileName': video.name,
        'text': '🎬 Видео',
        'isMe': true,
        'time': time,
        'reactions': <String, List<String>>{},
        'isPinned': false,
        'isRead': true,
        'sender': currentUserId,
        'senderUsername': null,
      });
      
      filteredMessages = messages;
      notifyListeners();
      scrollDown();
    } catch (e) {
      print('❌ Ошибка отправки видео: $e');
      _onSnackBar?.call('Не удалось отправить видео');
    }
  }

  Future<void> sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    
    final file = result.files.first;
    if (file.bytes == null) return;

    final now = TimeOfDay.now();
    final String time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    await fileService.saveFile(
      chatId: contactId,
      fileName: file.name,
      bytes: Uint8List.fromList(file.bytes!),
      isMe: true,
      time: time,
      key: sharedKey,
    );

    messages.add({
      'type': 'file',
      'fileName': file.name,
      'text': '📎 ${file.name}',
      'isMe': true,
      'time': time,
      'reactions': <String, List<String>>{},
      'isPinned': false,
      'isRead': true,
      'sender': currentUserId,
      'senderUsername': null,
    });
    filteredMessages = messages;
    notifyListeners();
    scrollDown();
  }

  Future<void> sendVideoMessage() async {
    final video = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );
    if (video == null) return;

    final bytes = await video.readAsBytes();
    final now = TimeOfDay.now();
    final String time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    await fileService.saveFile(
      chatId: contactId,
      fileName: video.name,
      bytes: Uint8List.fromList(bytes),
      isMe: true,
      time: time,
      key: sharedKey,
    );

    messages.add({
      'type': 'video_msg',
      'fileName': video.name,
      'text': '🎬 Видеосообщение',
      'isMe': true,
      'time': time,
      'reactions': <String, List<String>>{},
      'isPinned': false,
      'isRead': true,
      'sender': currentUserId,
      'senderUsername': null,
    });
    filteredMessages = messages;
    notifyListeners();
    scrollDown();
  }

  Future<void> sendVoiceMessage(File audioFile, Duration duration) async {
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final bytes = await audioFile.readAsBytes();

    await fileService.saveFile(
      chatId: contactId,
      fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
      bytes: bytes,
      isMe: true,
      time: time,
      key: sharedKey,
    );

    messages.add({
      'type': 'voice',
      'text': '🎤 Голосовое сообщение',
      'isMe': true,
      'time': time,
      'duration': duration.inSeconds,
      'reactions': <String, List<String>>{},
      'isPinned': false,
      'isRead': true,
      'sender': currentUserId,
      'senderUsername': null,
    });
    
    filteredMessages = messages;
    notifyListeners();
    scrollDown();
  }

  void toggleReaction(int index, String emoji) {
    if (currentUserId == null) return;

    final currentTier = _getCurrentTier();
    final plan = SubscriptionPlan.getPlan(currentTier);
    final Map<String, dynamic> msg = messages[index];
    final Map<String, List<String>> reactions = (msg['reactions'] as Map? ?? {}).map(
      (key, value) => MapEntry(key.toString(), List<String>.from(value as List? ?? [])),
    );

    int totalReactions = 0;
    for (final entry in reactions.entries) {
      totalReactions += entry.value.length;
    }

    if (totalReactions >= plan.maxReactionsPerMessage) {
      _onReactionLimitExceeded?.call(plan.maxReactionsPerMessage);
      return;
    }

    chatService.toggleReaction(contactId, index, emoji, currentUserId!);
    _updateMessageReactions(index, emoji);
  }

  void _updateMessageReactions(int index, String emoji) {
    final Map<String, dynamic> msg = messages[index];
    Map<String, List<String>> reactions = {};
    
    if (msg['reactions'] is Map) {
      final raw = msg['reactions'] as Map;
      reactions = raw.map((key, value) {
        final list = value is List ? List<String>.from(value) : <String>[];
        return MapEntry(key.toString(), list);
      });
    }

    if (!reactions.containsKey(emoji)) {
      reactions[emoji] = [];
    }

    final String userId = currentUserId ?? 'unknown';

    if (reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.remove(userId);
      if (reactions[emoji]!.isEmpty) {
        reactions.remove(emoji);
      }
    } else {
      reactions[emoji]!.add(userId);
    }

    msg['reactions'] = reactions;
    messages[index] = msg;
    filteredMessages = messages;
    notifyListeners();
  }

  void togglePin(int index) {
    chatService.togglePin(contactId, index);
    loadMessages();
  }

  void deleteMessage(int index) {
    messages.removeAt(index);
    filteredMessages = messages;
    chatService.deleteMessage(contactId, index);
    notifyListeners();
  }

  void toggleSearch() {
    isSearching = !isSearching;
    if (!isSearching) {
      searchController.clear();
      filteredMessages = messages;
    }
    notifyListeners();
  }

  void filterMessages(String query) {
    searchQuery = query;
    if (query.isEmpty) {
      filteredMessages = messages;
    } else {
      filteredMessages = messages.where((msg) {
        final String text = msg['text'] as String? ?? '';
        return _sanitizeText(text).toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void replyToMessage(int index) {
    replyTo = filteredMessages[index];
    notifyListeners();
  }

  void clearReply() {
    replyTo = null;
    notifyListeners();
  }

  void setSelfDestruct(int seconds) {
    selfDestruct = seconds;
    notifyListeners();
  }

  void scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void Function(int maxReactions)? _onReactionLimitExceeded;
  void Function(String message)? _onSnackBar;

  void setCallbacks({
    void Function(int maxReactions)? onReactionLimitExceeded,
    void Function(String message)? onSnackBar,
  }) {
    _onReactionLimitExceeded = onReactionLimitExceeded;
    _onSnackBar = onSnackBar;
  }

  void editMessage(int index, String newText) {
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    
    final Map<String, dynamic> msg = messages[index];
    
    msg['text'] = newText;
    msg['isEdited'] = true;
    msg['editTime'] = time;
    
    messages[index] = msg;
    filteredMessages = messages;
    notifyListeners();
    
    chatService.editMessage(contactId, index, newText, time);
  }

  void forwardMessage(int index, String targetChatId) {
    final Map<String, dynamic> msg = filteredMessages[index];
    final String text = msg['text'] as String? ?? '';
    
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    chatService.saveMessage(
      chatId: targetChatId,
      text: text,
      isMe: true,
      time: time,
    );
  }

  void sendSticker(String sticker) {
    messageController.text = sticker;
    sendMessage();
  }

  String? getWallpaperId() {
    try {
      final box = Hive.box('settings');
      return box.get('wallpaper_$contactId');
    } catch (_) {
      return null;
    }
  }

  Decoration? getWallpaperDecoration() {
    final id = getWallpaperId();
    if (id == null) return null;

    for (final wallpaper in Wallpaper.defaults) {
      if (wallpaper.id == id) {
        return wallpaper.decoration;
      }
    }

    try {
      final box = Hive.box('wallpapers');
      final raw = box.get('custom_wallpapers');
      if (raw is List) {
        for (final item in raw) {
          if (item is Map && item['id'] == id) {
            final path = item['imagePath'] as String?;
            if (path != null && File(path).existsSync()) {
              return BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(path)),
                  fit: BoxFit.cover,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  void dispose() {
    messageController.dispose();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}