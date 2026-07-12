import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../data/chat_service.dart';
import '../data/file_service.dart';
import '../data/p2p_service.dart';
import '../widgets/encrypt_animation.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String contactId;
  const ChatScreen({super.key, required this.contactId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _fileService = FileService();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _p2pService = P2PService();
  bool _isRecording = false;
  List<Map<String, dynamic>> _messages = [];
  bool _showEmoji = false;
  Map<String, dynamic>? _replyTo;

  final Map<String, Map<String, String>> _contacts = {
    '1': {'name': 'Аноним', 'initial': 'А', 'status': 'В сети'},
    '2': {'name': 'Крипто Энтузиаст', 'initial': 'К', 'status': 'Был(а) недавно'},
    '3': {'name': 'void', 'initial': 'V', 'status': 'Разработчик'},
    'f120b9055653991a9e97e54a53d31363c2081f8c09e90cbe38e11117f62cac27': {'name': 'ПК', 'initial': 'P', 'status': 'В сети'},
    'd72600aa1aef91d8ae80ad6f8735f029dc1bca7cb74dd03ecea6ad55a13b09e0': {'name': 'iPhone', 'initial': 'i', 'status': 'В сети'},
  };

  @override
  void initState() {
    super.initState();
    _p2pService.start();
    _p2pService.onMessage(widget.contactId, (msg) => _loadMessages());
    _loadMessages();
  }

  void _loadMessages() async {
    final savedMessages = _chatService.loadMessages(widget.contactId);
    final savedFiles = _fileService.loadFiles(widget.contactId);
    final decrypted = <Map<String, dynamic>>[];

    if (savedMessages.isEmpty && savedFiles.isEmpty) {
      final demo = {
        '1': [{'text': 'Привет! 👋', 'isMe': false, 'time': '12:30'}, {'text': 'Привет! Рад тебя видеть в Veil. 🔒', 'isMe': true, 'time': '12:31'}],
        '2': [{'text': 'Скинь свой публичный ключ 🔑', 'isMe': false, 'time': '15:10'}],
        '3': [{'text': 'Новая версия Veil вышла! 🚀', 'isMe': false, 'time': '09:00'}],
      }[widget.contactId] ?? [];
      for (var msg in demo) {
        _chatService.saveMessage(chatId: widget.contactId, text: msg['text'] as String, isMe: msg['isMe'] as bool, time: msg['time'] as String);
      }
    }

    for (final msg in _chatService.loadMessages(widget.contactId)) {
      decrypted.add({'text': msg['text'] as String, 'isMe': msg['isMe'], 'time': msg['time'], 'type': 'text'});
    }

    for (final f in savedFiles) {
      decrypted.add({'type': 'file', 'fileName': f['fileName'], 'text': '📎 ${f['fileName']}', 'isMe': f['isMe'], 'time': f['time']});
    }

    setState(() => _messages = decrypted);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    final message = {'type': 'text', 'text': text, 'isMe': true, 'time': time, 'replyTo': _replyTo};
    setState(() { _messages.add(message); _replyTo = null; });
    _chatService.saveMessage(chatId: widget.contactId, text: text, isMe: true, time: time);
    _p2pService.sendMessage(recipientId: widget.contactId, encryptedText: text, chatId: widget.contactId);
    _messageController.clear();
    _scrollDown();
  }

  void _sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: file.name, bytes: Uint8List.fromList(file.bytes!), isMe: true, time: time, key: null);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'file', 'fileName': file.name, 'text': '📎 ${file.name}', 'isMe': true, 'time': time}));
    _scrollDown();
  }

  void _sendPhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: photo.name, bytes: Uint8List.fromList(bytes), isMe: true, time: time, key: null);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'photo', 'fileName': photo.name, 'text': '📷 Фото', 'isMe': true, 'time': time}));
    _scrollDown();
  }

  void _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(const RecordConfig(), path: '');
      setState(() => _isRecording = true);
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;
    final file = File(path);
    final bytes = await file.readAsBytes();
    final name = 'Голосовое ${DateTime.now().hour}:${DateTime.now().minute}';
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: '$name.m4a', bytes: Uint8List.fromList(bytes), isMe: true, time: time, key: null);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'voice', 'fileName': name, 'text': '🎤 $name', 'isMe': true, 'time': time}));
    _scrollDown();
  }

  void _onEmojiSelected(Category? category, Emoji emoji) {
    _messageController.text += emoji.emoji;
    _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
  }

  void _showDeleteDialog(int index) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: const Color(0xFF1A1A26),
      title: const Text('Удалить сообщение?', style: TextStyle(color: Color(0xFFE0E0E0))),
      content: const Text('Это действие нельзя отменить.', style: TextStyle(color: Color(0xFF888899))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888899)))),
        TextButton(onPressed: () { setState(() => _messages.removeAt(index)); _chatService.deleteMessage(widget.contactId, index); Navigator.pop(ctx); }, child: const Text('Удалить', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ));
  }

  void _replyToMessage(int index) => setState(() => _replyTo = _messages[index]);

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() { _messageController.dispose(); _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final contact = _contacts[widget.contactId] ?? {'name': 'Неизвестный', 'initial': '?', 'status': 'Офлайн'};
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => GoRouter.of(context).go('/chats')),
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: const Color(0xFF4ADE80).withOpacity(0.1), child: Text(contact['initial'] ?? '?', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(contact['name'] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFE0E0E0))),
            Text(contact['status'] ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: contact['status'] == 'В сети' ? const Color(0xFF4ADE80) : const Color(0xFF888899), fontSize: 12)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.verified_user, color: Color(0xFF4ADE80)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.report_outlined, color: Color(0xFFEF4444)), onPressed: () => context.go('/report/${widget.contactId}')),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[index];
            final isMe = msg['isMe'] as bool;
            final isFile = msg['type'] == 'file';
            final isPhoto = msg['type'] == 'photo';
            final isVoice = msg['type'] == 'voice';
            final replyTo = msg['replyTo'] as Map<String, dynamic>?;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
              child: GestureDetector(
                onLongPress: () => _showDeleteDialog(index), onSecondaryTap: () => _showDeleteDialog(index),
                child: Dismissible(
                  key: Key('msg_$index'), direction: DismissDirection.startToEnd,
                  confirmDismiss: (_) async { _replyToMessage(index); return false; },
                  background: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), color: const Color(0xFF4ADE80).withOpacity(0.05), child: const Icon(Icons.reply, color: Color(0xFF4ADE80))),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isMe ? const Color(0xFF4ADE80) : const Color(0xFF1A1A26), borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (replyTo != null) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isMe ? const Color(0xFF0A0A0F).withOpacity(0.3) : const Color(0xFF0A0A0F).withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFF4ADE80), width: 3))), child: Text(replyTo['text'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFF888899), fontStyle: FontStyle.italic))),
                        if (isVoice) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic, size: 20, color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFF4ADE80)), const SizedBox(width: 8), Flexible(child: Text('🎤 Голосовое', style: TextStyle(color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFFE0E0E0), fontSize: 14, decoration: TextDecoration.underline)))])
                        else if (isPhoto) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.image, size: 20, color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFF4ADE80)), const SizedBox(width: 8), Flexible(child: Text('📷 Фото', style: TextStyle(color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFFE0E0E0), fontSize: 14, decoration: TextDecoration.underline)))])
                        else if (isFile) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.insert_drive_file, size: 20, color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFF4ADE80)), const SizedBox(width: 8), Flexible(child: Text(msg['fileName'] ?? 'Файл', style: TextStyle(color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFFE0E0E0), fontSize: 14, decoration: TextDecoration.underline)))])
                        else Text(msg['text'] as String, style: TextStyle(color: isMe ? const Color(0xFF0A0A0F) : const Color(0xFFE0E0E0), fontSize: 16)),
                        const SizedBox(height: 4),
                        Align(alignment: Alignment.bottomRight, child: Text(msg['time'] as String, style: TextStyle(fontSize: 11, color: isMe ? const Color(0xFF0A0A0F).withOpacity(0.7) : const Color(0xFF888899)))),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        )),
        if (_replyTo != null) Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFF4ADE80).withOpacity(0.05), child: Row(children: [
          const Icon(Icons.reply, color: Color(0xFF4ADE80), size: 20), const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ответ на сообщение', style: TextStyle(fontSize: 11, color: const Color(0xFF4ADE80), fontWeight: FontWeight.w600)), Text(_replyTo!['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF888899)))])),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Color(0xFF888899)), onPressed: () => setState(() => _replyTo = null)),
        ])),
        Container(
          decoration: const BoxDecoration(color: Color(0xFF14141F), boxShadow: [BoxShadow(color: Color(0xFF0A0A0F), blurRadius: 10, offset: Offset(0, -2))]),
          child: SafeArea(child: Column(children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFF4ADE80)), onPressed: _sendPhoto),
              IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF4ADE80)), onPressed: _sendFile),
              IconButton(icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: const Color(0xFF4ADE80)), onPressed: () { setState(() => _showEmoji = !_showEmoji); if (_showEmoji) FocusScope.of(context).unfocus(); }),
              Expanded(child: TextField(controller: _messageController, style: const TextStyle(color: Color(0xFFE0E0E0)), decoration: const InputDecoration(hintText: 'Сообщение...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)), maxLines: 5, minLines: 1, onSubmitted: (_) => _sendMessage())),
              const SizedBox(width: 4),
              _isRecording
                  ? Container(decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle), child: Material(color: Colors.transparent, child: InkWell(customBorder: const CircleBorder(), onTap: _stopRecording, child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.stop, color: Colors.white, size: 20)))))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.mic, color: Color(0xFF4ADE80)), onPressed: _startRecording),
                      Container(decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle), child: Material(color: Colors.transparent, child: InkWell(customBorder: const CircleBorder(), onTap: _sendMessage, child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.send, color: Color(0xFF0A0A0F), size: 20))))),
                    ]),
              const SizedBox(width: 4),
            ]),
            if (_showEmoji) SizedBox(height: 300, child: EmojiPicker(onEmojiSelected: _onEmojiSelected)),
          ])),
        ),
      ]),
    );
  }
}