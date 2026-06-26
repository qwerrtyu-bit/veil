import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/crypto_service.dart';
import '../widgets/encrypt_animation.dart';

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
  List<Map<String, dynamic>> _messages = [];
  bool _showEmoji = false;
  String _groupName = 'Группа';
  SecretKey? _sharedKey;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _sharedKey = await _cryptoService.createKeyFromString('veil_group_${widget.groupId}');
    _loadGroup();
  }

  void _loadGroup() async {
    final groupsBox = Hive.box('messages');
    final rawGroups = groupsBox.get('groups_list');
    List<Map<String, dynamic>> groupsList = [];
    if (rawGroups is List) {
      for (final item in rawGroups) {
        if (item is Map) groupsList.add(Map<String, dynamic>.from(item));
      }
    }
    Map<String, dynamic> group = {'name': 'Группа'};
    for (final g in groupsList) {
      if (g['id'] == widget.groupId) { group = g; break; }
    }
    setState(() => _groupName = group['name'] ?? 'Группа');

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
      decrypted.add({'text': displayText, 'isMe': msg['isMe'], 'time': msg['time'], 'sender': msg['sender']});
    }
    setState(() => _messages = decrypted);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final encryptedText = _sharedKey != null ? await _cryptoService.encrypt(text, _sharedKey!) : text;
    final message = {'text': text, 'isMe': true, 'time': time, 'sender': 'Я', 'isEncrypted': _sharedKey != null, 'animating': _sharedKey != null};
    setState(() => _messages.add(message));
    _saveMessage(encryptedText, true, time);
    _messageController.clear();
    _scrollDown();
    if (_sharedKey != null) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() { message['isEncrypted'] = false; message['animating'] = false; });
      });
    }
  }

  void _saveMessage(String text, bool isMe, String time) {
    final raw = Hive.box('messages').get('group_${widget.groupId}');
    List<Map<String, dynamic>> messages = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) messages.add(Map<String, dynamic>.from(item));
      }
    }
    messages.add({'text': text, 'isMe': isMe, 'time': time, 'sender': 'Я'});
    Hive.box('messages').put('group_${widget.groupId}', messages);
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController.text += emoji.emoji;
    _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() { _messageController.dispose(); _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.group, color: Color(0xFF6C5CE7), size: 20)),
          const SizedBox(width: 8),
          Text(_groupName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            final isMe = message['isMe'] as bool;
            final isEncrypted = message['isEncrypted'] as bool? ?? false;
            final isAnimating = message['animating'] as bool? ?? false;
            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF6C5CE7) : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (!isMe) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(message['sender'] ?? 'Участник', style: const TextStyle(fontSize: 11, color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold))),
                  if (isAnimating) EncryptAnimation(text: message['text'] as String, isEncrypting: true, textColor: isMe ? Colors.white : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A)), fontSize: 16)
                  else Text(message['text'] as String, style: TextStyle(color: isMe ? Colors.white : (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A)), fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(message['time'] as String, style: TextStyle(fontSize: 11, color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[500])),
                ]),
              ),
            );
          },
        )),
        Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
          child: SafeArea(child: Column(children: [
            Row(children: [
              IconButton(icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: const Color(0xFF6C5CE7)), onPressed: () { setState(() => _showEmoji = !_showEmoji); if (_showEmoji) FocusScope.of(context).unfocus(); }),
              Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Сообщение...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)), maxLines: 5, minLines: 1)),
              const SizedBox(width: 4),
              Container(decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage)),
            ]),
            if (_showEmoji) SizedBox(height: 300, child: EmojiPicker(onEmojiSelected: _onEmojiSelected)),
          ])),
        ),
      ]),
    );
  }
}