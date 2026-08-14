import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../data/crypto_service.dart';
import '../data/identity_service.dart';
import '../data/file_service.dart';
import '../widgets/encrypt_animation.dart';
import '../l10n/app_localizations.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _cryptoService = CryptoService();
  final _identityService = IdentityService();
  final _fileService = FileService();
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  bool _showEmoji = false;
  String _groupName = 'Группа';
  SecretKeyData? _sharedKey;
  List<String> _members = [];
  bool _isOwner = false;
  String _groupKey = '';
  String _currentUserKey = '';

  final List<String> _stickers = [
    '👍', '❤️', '😂', '😮', '😢', '😡', '🎉', '🔥', '💯', '✅', '👋', '🤝', '🔒', '🔑', '🛡️', '⚡', '🌟', '💎',
  ];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _sharedKey = _cryptoService.createKeyFromString('veil_group_${widget.groupId}');
    _currentUserKey = await _identityService.getPublicKey() ?? 'unknown';
    await _loadGroup();
  }

  Future<void> _loadGroup() async {
    final groupsBox = Hive.box('messages');
    final rawGroups = groupsBox.get('groups_list');
    List<Map<String, dynamic>> groupsList = [];
    if (rawGroups is List) {
      for (final item in rawGroups) {
        if (item is Map) groupsList.add(Map<String, dynamic>.from(item));
      }
    }
    Map<String, dynamic> group = {'name': 'Группа', 'members': [], 'owner': '', 'key': ''};
    for (final g in groupsList) {
      if (g['id'] == widget.groupId) { group = g; break; }
    }
    setState(() {
      _groupName = group['name'] ?? 'Группа';
      _members = List<String>.from(group['members'] ?? []);
      _groupKey = group['key'] ?? '';
      _isOwner = group['owner'] == _currentUserKey;
    });

    final rawMessages = Hive.box('messages').get('group_${widget.groupId}');
    List<Map<String, dynamic>> encrypted = [];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        if (item is Map) encrypted.add(Map<String, dynamic>.from(item));
      }
    }
    final decrypted = <Map<String, dynamic>>[];
    for (final msg in encrypted) {
      final text = msg['text'] as String;
      String displayText;
      if (_sharedKey != null && text.length > 50) {
        try {
          displayText = await _cryptoService.decrypt(text, _sharedKey!);
        } catch (e) {
          displayText = text;
        }
      } else {
        displayText = text;
      }
      decrypted.add({
        'text': displayText,
        'isMe': msg['isMe'],
        'time': msg['time'],
        'sender': msg['sender'],
      });
    }
    setState(() => _messages = decrypted);
  }

  Future<void> _saveGroupData(Map<String, dynamic> group) async {
    final groupsBox = Hive.box('messages');
    final rawGroups = groupsBox.get('groups_list');
    List<Map<String, dynamic>> groupsList = [];
    if (rawGroups is List) {
      for (final item in rawGroups) {
        if (item is Map) groupsList.add(Map<String, dynamic>.from(item));
      }
    }

    bool found = false;
    for (int i = 0; i < groupsList.length; i++) {
      if (groupsList[i]['id'] == widget.groupId) {
        groupsList[i] = group;
        found = true;
        break;
      }
    }

    if (!found) {
      groupsList.add(group);
    }

    await groupsBox.put('groups_list', groupsList);
  }

  void _sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(
      chatId: widget.groupId,
      fileName: file.name,
      bytes: Uint8List.fromList(file.bytes!),
      isMe: true,
      time: time,
      key: _sharedKey,
    );
    if (!mounted) return;
    final encryptedText = _sharedKey != null
        ? await _cryptoService.encrypt('📎 ${file.name}', _sharedKey!)
        : '📎 ${file.name}';
    _saveMessage(encryptedText, true, time, 'Я');
    _loadGroup();
    _scrollDown();
  }

  void _sendPhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(
      chatId: widget.groupId,
      fileName: photo.name,
      bytes: Uint8List.fromList(bytes),
      isMe: true,
      time: time,
      key: _sharedKey,
    );
    if (!mounted) return;
    final encryptedText = _sharedKey != null
        ? await _cryptoService.encrypt('📷 Фото', _sharedKey!)
        : '📷 Фото';
    _saveMessage(encryptedText, true, time, 'Я');
    _loadGroup();
    _scrollDown();
  }

  void _sendVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (video == null) return;
    final bytes = await video.readAsBytes();
    final name = video.name;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(
      chatId: widget.groupId,
      fileName: name,
      bytes: Uint8List.fromList(bytes),
      isMe: true,
      time: time,
      key: _sharedKey,
    );
    if (!mounted) return;
    final encryptedText = _sharedKey != null
        ? await _cryptoService.encrypt('🎬 Видео', _sharedKey!)
        : '🎬 Видео';
    _saveMessage(encryptedText, true, time, 'Я');
    _loadGroup();
    _scrollDown();
  }

  void _sendVideoMessage() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
    if (video == null) return;
    final bytes = await video.readAsBytes();
    final name = video.name;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(
      chatId: widget.groupId,
      fileName: name,
      bytes: Uint8List.fromList(bytes),
      isMe: true,
      time: time,
      key: _sharedKey,
    );
    if (!mounted) return;
    final encryptedText = _sharedKey != null
        ? await _cryptoService.encrypt('🎬 Видеосообщение', _sharedKey!)
        : '🎬 Видеосообщение';
    _saveMessage(encryptedText, true, time, 'Я');
    _loadGroup();
    _scrollDown();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final encryptedText = _sharedKey != null
        ? await _cryptoService.encrypt(text, _sharedKey!)
        : text;
    final message = {
      'text': text,
      'isMe': true,
      'time': time,
      'sender': 'Я',
      'isEncrypted': _sharedKey != null,
      'animating': _sharedKey != null,
    };
    setState(() => _messages.add(message));
    _saveMessage(encryptedText, true, time, 'Я');
    _messageController.clear();
    _scrollDown();
    if (_sharedKey != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          message['isEncrypted'] = false;
          message['animating'] = false;
        });
      });
    }
  }

  void _saveMessage(String text, bool isMe, String time, String sender) {
    final raw = Hive.box('messages').get('group_${widget.groupId}');
    List<Map<String, dynamic>> messages = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) messages.add(Map<String, dynamic>.from(item));
      }
    }
    messages.add({'text': text, 'isMe': isMe, 'time': time, 'sender': sender});
    Hive.box('messages').put('group_${widget.groupId}', messages);
  }

  void _onTextFieldChanged(String value) {
    if (value.endsWith('\n') && !value.contains('\n\n')) {
      _messageController.text = value.substring(0, value.length - 1);
      _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
      _sendMessage();
    }
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController.text += emoji.emoji;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Стикеры',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _stickers.map((s) {
                return GestureDetector(
                  onTap: () {
                    _messageController.text = s;
                    _sendMessage();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(s, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group, color: Color(0xFF6C5CE7), size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              _groupName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;
                final isAnimating = message['animating'] as bool? ?? false;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF6C5CE7)
                          : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              message['sender'] ?? 'Участник',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isAnimating)
                          EncryptAnimation(
                            text: message['text'] as String,
                            isEncrypting: true,
                            textColor: isMe
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFE0E0E0)
                                    : const Color(0xFF1A1A1A)),
                            fontSize: 16,
                          )
                        else
                          Text(
                            message['text'] as String,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFE0E0E0)
                                      : const Color(0xFF1A1A1A)),
                              fontSize: 16,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          message['time'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: const Color(0xFF6C5CE7),
                        ),
                        onPressed: () {
                          setState(() => _showEmoji = !_showEmoji);
                          if (_showEmoji) FocusScope.of(context).unfocus();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.face, color: Color(0xFF6C5CE7)),
                        onPressed: _showStickerPicker,
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF6C5CE7)),
                        onPressed: _sendPhoto,
                      ),
                      IconButton(
                        icon: const Icon(Icons.video_library, color: Color(0xFF6C5CE7)),
                        onPressed: _sendVideo,
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Color(0xFF6C5CE7)),
                        onPressed: _sendFile,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Сообщение...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          onChanged: _onTextFieldChanged,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                  if (_showEmoji)
                    SizedBox(
                      height: 300,
                      child: EmojiPicker(onEmojiSelected: _onEmojiSelected),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}