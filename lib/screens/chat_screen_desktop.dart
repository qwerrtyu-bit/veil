// ========== lib/screens/chat_screen_desktop.dart ==========
import 'dart:convert';
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
import '../data/crypto_service.dart';
import '../data/file_service.dart';
import '../data/identity_service.dart';
import '../data/p2p_service.dart';
import '../widgets/encrypt_animation.dart';

class ChatScreenDesktop extends ConsumerStatefulWidget {
  final String contactId;
  const ChatScreenDesktop({super.key, required this.contactId});
  @override
  ConsumerState<ChatScreenDesktop> createState() => _ChatScreenDesktopState();
}

class _ChatScreenDesktopState extends ConsumerState<ChatScreenDesktop>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _cryptoService = CryptoService();
  final _fileService = FileService();
  final _identityService = IdentityService();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _p2pService = P2PService();
  bool _isRecording = false;
  List<Map<String, dynamic>> _messages = [];
  bool _showEmoji = false;
  Map<String, dynamic>? _replyTo;
  SecretKeyData? _sharedKey;
  int _selfDestruct = 0;
  bool _showMediaPanel = false;
  late AnimationController _mediaController;
  late Animation<double> _mediaAnimation;

  final List<String> _stickers = [
    '👍', '❤️', '😂', '😮', '😢', '😡', '🎉', '🔥', '💯', '✅', '👋', '🤝', '🔒', '🔑', '🛡️', '⚡', '🌟', '💎',
  ];

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
    _mediaController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _mediaAnimation = CurvedAnimation(parent: _mediaController, curve: Curves.easeOutBack);
    _p2pService.start();
    _p2pService.onMessage(widget.contactId, (msg) => _loadMessages());
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    final myPrivateKey = await _identityService.getPrivateKey();
    if (myPrivateKey != null) {
      _sharedKey = _cryptoService.deriveSharedKey(myPrivateKey, widget.contactId);
    } else {
      _sharedKey = _cryptoService.createKeyFromString('veil_chat_${widget.contactId}');
    }
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
        final text = msg['text'] as String;
        final encrypted = _sharedKey != null ? await _cryptoService.encrypt(text, _sharedKey!) : text;
        _chatService.saveMessage(chatId: widget.contactId, text: encrypted, isMe: msg['isMe'] as bool, time: msg['time'] as String);
      }
    }
    for (final msg in _chatService.loadMessages(widget.contactId)) {
      final t = msg['text'] as String; String display = t;
      if (_sharedKey != null && t.length > 50 && t.contains('\$')) {
        try {
          final parts = t.split('\$'); final encryptedKey = parts[0]; final encryptedMessage = parts[1];
          final keyBase64 = await _cryptoService.decrypt(encryptedKey, _sharedKey!);
          display = await _cryptoService.decrypt(encryptedMessage, SecretKeyData(base64.decode(keyBase64)));
        } catch (_) {}
      }
      decrypted.add({'text': display, 'isMe': msg['isMe'], 'time': msg['time'], 'type': 'text'});
    }
    for (final f in savedFiles) {
      decrypted.add({'type': 'file', 'fileName': f['fileName'], 'text': '📎 ${f['fileName']}', 'isMe': f['isMe'], 'time': f['time']});
    }
    setState(() => _messages = decrypted);
  }

  void _onTextFieldChanged(String value) {
    if (value.endsWith('\n') && !value.contains('\n\n')) {
      _messageController.text = value.substring(0, value.length - 1);
      _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
      _sendMessage();
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim(); if (text.isEmpty) return;
    final now = TimeOfDay.now(); final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    String encryptedText;
    if (_sharedKey != null) {
      final ephemeralKey = _cryptoService.generateEphemeralKey();
      final encryptedMessage = await _cryptoService.encrypt(text, ephemeralKey);
      final encryptedKey = await _cryptoService.encrypt(base64.encode(ephemeralKey.data), _sharedKey!);
      encryptedText = '$encryptedKey\$$encryptedMessage';
    } else {
      encryptedText = text;
    }
    final message = {'type': 'text', 'text': text, 'isMe': true, 'time': time, 'isEncrypted': _sharedKey != null, 'animating': _sharedKey != null, 'replyTo': _replyTo};
    setState(() { _messages.add(message); _replyTo = null; });
    _chatService.saveMessage(chatId: widget.contactId, text: encryptedText, isMe: true, time: time);
    _p2pService.sendMessage(recipientId: widget.contactId, encryptedText: encryptedText, chatId: widget.contactId);
    _messageController.clear(); _scrollDown();
    if (_sharedKey != null) { Future.delayed(const Duration(milliseconds: 1200), () { if (!mounted) return; setState(() { message['isEncrypted'] = false; message['animating'] = false; }); }); }
    if (_selfDestruct > 0) { Future.delayed(Duration(seconds: _selfDestruct), () { if (!mounted) return; final idx = _messages.indexOf(message); if (idx >= 0) { setState(() => _messages.removeAt(idx)); _chatService.deleteMessage(widget.contactId, idx); } }); }
  }

  void _toggleMediaPanel() {
    if (_showMediaPanel) { _mediaController.reverse(); } else { _mediaController.forward(); }
    setState(() => _showMediaPanel = !_showMediaPanel);
  }

  void _sendVideoMessage() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 30));
    if (video == null) return;
    final bytes = await video.readAsBytes(); final name = video.name;
    final now = TimeOfDay.now(); final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: name, bytes: Uint8List.fromList(bytes), isMe: true, time: time, key: _sharedKey);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'video_msg', 'fileName': name, 'text': '🎬 Видеосообщение', 'isMe': true, 'time': time}));
    _scrollDown();
  }

  void _showStickerPicker() {
    showModalBottomSheet(context: context, backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Стикеры', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: _stickers.map((s) => GestureDetector(onTap: () { _messageController.text = s; _sendMessage(); Navigator.pop(ctx); },
          child: Container(width: 56, height: 56, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(s, style: const TextStyle(fontSize: 28)))),)).toList()),
        const SizedBox(height: 16),
      ])),
    );
  }

  void _sendVideo() async {
    final video = await _imagePicker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (video == null) return;
    final bytes = await video.readAsBytes(); final name = video.name;
    final now = TimeOfDay.now(); final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: name, bytes: Uint8List.fromList(bytes), isMe: true, time: time, key: _sharedKey);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'video', 'fileName': name, 'text': '🎬 Видео', 'isMe': true, 'time': time}));
    _scrollDown();
  }

  void _setSelfDestruct() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface, title: Text('Самоуничтожение', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildTimerOption(0, 'Выкл'), _buildTimerOption(5, '5 секунд'), _buildTimerOption(30, '30 секунд'), _buildTimerOption(60, '1 минута'), _buildTimerOption(300, '5 минут'),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть'))],
    ));
  }

  Widget _buildTimerOption(int seconds, String label) {
    return ListTile(
      title: Text(label, style: TextStyle(color: _selfDestruct == seconds ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)),
      leading: Icon(_selfDestruct == seconds ? Icons.timer : Icons.timer_outlined, color: _selfDestruct == seconds ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
      onTap: () { setState(() => _selfDestruct = seconds); Navigator.pop(context); },
    );
  }

  void _sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first; if (file.bytes == null) return;
    final now = TimeOfDay.now(); final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: file.name, bytes: Uint8List.fromList(file.bytes!), isMe: true, time: time, key: _sharedKey);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'file', 'fileName': file.name, 'text': '📎 ${file.name}', 'isMe': true, 'time': time})); _scrollDown();
  }

  void _sendPhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (photo == null) return;
    final bytes = await photo.readAsBytes(); final now = TimeOfDay.now(); final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: photo.name, bytes: Uint8List.fromList(bytes), isMe: true, time: time, key: _sharedKey);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'photo', 'fileName': photo.name, 'text': '📷 Фото', 'isMe': true, 'time': time})); _scrollDown();
  }

  void _startRecording() async { if (await _audioRecorder.hasPermission()) { await _audioRecorder.start(const RecordConfig(), path: ''); setState(() => _isRecording = true); } }
  void _stopRecording() async {
    if (!_isRecording) return; final path = await _audioRecorder.stop(); setState(() => _isRecording = false);
    if (path == null) return; final file = File(path); final bytes = await file.readAsBytes();
    final name = 'Голосовое ${DateTime.now().hour}:${DateTime.now().minute}'; final now = TimeOfDay.now(); final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    await _fileService.saveFile(chatId: widget.contactId, fileName: '$name.m4a', bytes: Uint8List.fromList(bytes), isMe: true, time: time, key: _sharedKey);
    if (!mounted) return;
    setState(() => _messages.add({'type': 'voice', 'fileName': name, 'text': '🎤 $name', 'isMe': true, 'time': time})); _scrollDown();
  }

  void _onEmojiSelected(Category? category, Emoji emoji) { _messageController.text += emoji.emoji; _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length)); }
  void _showDeleteDialog(int index) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text('Удалить сообщение?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      content: Text('Это действие нельзя отменить.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')), TextButton(onPressed: () { setState(() => _messages.removeAt(index)); _chatService.deleteMessage(widget.contactId, index); Navigator.pop(ctx); }, child: const Text('Удалить', style: TextStyle(color: Color(0xFFEF4444))))],
    ));
  }
  void _replyToMessage(int index) => setState(() => _replyTo = _messages[index]);
  void _scrollDown() { Future.delayed(const Duration(milliseconds: 100), () { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }
  @override
  void dispose() { _messageController.dispose(); _scrollController.dispose(); _mediaController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contact = _contacts[widget.contactId] ?? {'name': 'Неизвестный', 'initial': '?', 'status': 'Офлайн'};
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => GoRouter.of(context).go('/chats')),
        title: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: theme.colorScheme.primary.withOpacity(0.1), child: Text(contact['initial'] ?? '?', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14))),
          const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(contact['name'] ?? '', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            Text(contact['status'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: contact['status'] == 'В сети' ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Color(0xFF10B981)), onPressed: () => context.go('/call/${widget.contactId}', extra: {'name': contact['name'], 'isVideo': false})),
          IconButton(icon: const Icon(Icons.videocam, color: Color(0xFF10B981)), onPressed: () => context.go('/call/${widget.contactId}', extra: {'name': contact['name'], 'isVideo': true})),
          IconButton(icon: const Icon(Icons.report_outlined, color: Colors.red), onPressed: () => context.go('/report/${widget.contactId}')),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(16), itemCount: _messages.length, itemBuilder: (context, index) {
          final msg = _messages[index]; final isMe = msg['isMe'] as bool;
          final isFile = msg['type'] == 'file'; final isPhoto = msg['type'] == 'photo'; final isVoice = msg['type'] == 'voice';
          final isVideo = msg['type'] == 'video'; final isVideoMsg = msg['type'] == 'video_msg';
          final isAnimating = msg['animating'] as bool? ?? false; final replyTo = msg['replyTo'] as Map<String, dynamic>?;
          return TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
            child: GestureDetector(onLongPress: () => _showDeleteDialog(index), onSecondaryTap: () => _showDeleteDialog(index),
              child: Dismissible(key: Key('msg_$index'), direction: DismissDirection.startToEnd, confirmDismiss: (_) async { _replyToMessage(index); return false; },
                background: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), color: theme.colorScheme.primary.withOpacity(0.05), child: Icon(Icons.reply, color: theme.colorScheme.primary)),
                child: Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(margin: const EdgeInsets.only(bottom: 12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isMe ? theme.colorScheme.primary : theme.colorScheme.surface, borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (replyTo != null) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: isMe ? Colors.white : theme.colorScheme.primary, width: 3))), child: Text(replyTo['text'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600], fontStyle: FontStyle.italic))),
                      if (isVoice) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.mic, size: 20, color: isMe ? Colors.white : theme.colorScheme.primary), const SizedBox(width: 8), Flexible(child: Text('🎤 Голосовое', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 14, decoration: TextDecoration.underline)))])
                      else if (isVideoMsg) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.videocam, size: 20, color: isMe ? Colors.white : theme.colorScheme.primary), const SizedBox(width: 8), Flexible(child: Text('🎬 Видеосообщение', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 14, decoration: TextDecoration.underline)))])
                      else if (isVideo) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.video_library, size: 20, color: isMe ? Colors.white : theme.colorScheme.primary), const SizedBox(width: 8), Flexible(child: Text('🎬 Видео', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 14, decoration: TextDecoration.underline)))])
                      else if (isPhoto) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.image, size: 20, color: isMe ? Colors.white : theme.colorScheme.primary), const SizedBox(width: 8), Flexible(child: Text('📷 Фото', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 14, decoration: TextDecoration.underline)))])
                      else if (isFile) Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.insert_drive_file, size: 20, color: isMe ? Colors.white : theme.colorScheme.primary), const SizedBox(width: 8), Flexible(child: Text(msg['fileName'] ?? 'Файл', style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 14, decoration: TextDecoration.underline)))])
                      else if (isAnimating) EncryptAnimation(text: msg['text'] as String, isEncrypting: true, textColor: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 16)
                      else Text(msg['text'] as String, style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface, fontSize: 16)),
                      const SizedBox(height: 4), Align(alignment: Alignment.bottomRight, child: Text(msg['time'] as String, style: TextStyle(fontSize: 11, color: isMe ? Colors.white.withOpacity(0.7) : theme.colorScheme.onSurface.withOpacity(0.5)))),
                    ]),
                  ),
                ),
              ),
            ),
          );
        })),
        if (_replyTo != null) Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: theme.colorScheme.primary.withOpacity(0.05), child: Row(children: [
          Icon(Icons.reply, color: theme.colorScheme.primary, size: 20), const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ответ на сообщение', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)), Text(_replyTo!['text'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)))])),
          IconButton(icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)), onPressed: () => setState(() => _replyTo = null)),
        ])),
        Container(decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
          child: SafeArea(child: Column(children: [
            Row(children: [
              IconButton(icon: Icon(_selfDestruct > 0 ? Icons.timer : Icons.timer_outlined, color: _selfDestruct > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5)), onPressed: _setSelfDestruct),
              IconButton(icon: const Icon(Icons.video_library, color: Color(0xFF10B981)), onPressed: _sendVideo),
              IconButton(icon: Icon(Icons.camera_alt, color: theme.colorScheme.primary), onPressed: _sendPhoto),
              IconButton(icon: Icon(Icons.attach_file, color: theme.colorScheme.primary), onPressed: _sendFile),
              IconButton(icon: Icon(Icons.face, color: theme.colorScheme.primary), onPressed: _showStickerPicker),
              IconButton(icon: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, color: theme.colorScheme.primary), onPressed: () { setState(() => _showEmoji = !_showEmoji); if (_showEmoji) FocusScope.of(context).unfocus(); }),
              Expanded(child: TextField(controller: _messageController, style: TextStyle(color: theme.colorScheme.onSurface), decoration: const InputDecoration(hintText: 'Сообщение...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8)), maxLines: 5, minLines: 1, onChanged: _onTextFieldChanged)),
              const SizedBox(width: 4),
              _isRecording
                  ? Container(decoration: BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle), child: Material(color: Colors.transparent, child: InkWell(customBorder: const CircleBorder(), onTap: _stopRecording, child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.stop, color: Colors.white, size: 20)))))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(duration: const Duration(milliseconds: 300), width: _showMediaPanel ? 120 : 0,
                        child: _showMediaPanel
                            ? ScaleTransition(scale: _mediaAnimation, child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: IconButton(icon: Icon(Icons.mic, color: theme.colorScheme.primary), onPressed: () { _toggleMediaPanel(); _startRecording(); })),
                                const SizedBox(width: 4),
                                Container(decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: IconButton(icon: Icon(Icons.videocam, color: theme.colorScheme.primary), onPressed: () { _toggleMediaPanel(); _sendVideoMessage(); })),
                              ]))
                            : const SizedBox(),
                      ),
                      IconButton(icon: Icon(_showMediaPanel ? Icons.close : Icons.mic, color: theme.colorScheme.primary), onPressed: _toggleMediaPanel),
                      Container(decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle), child: Material(color: Colors.transparent, child: InkWell(customBorder: const CircleBorder(), onTap: _sendMessage, child: Padding(padding: EdgeInsets.all(12), child: Icon(Icons.send, color: theme.colorScheme.onPrimary, size: 20))))),
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