import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/chat_service.dart';
import '../../data/identity_service.dart';
import '../../widgets/chat/chat_message_bubble.dart';
import '../../widgets/chat/chat_input.dart';
import '../../widgets/encrypt_animation.dart';
import '../../l10n/app_localizations.dart';
import '../../plugins/plugin_manager.dart';
import '../../plugins/plugin_api.dart';

class ChatPanel extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final VoidCallback onToggleInfo;

  const ChatPanel({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.onToggleInfo,
  });

  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _identityService = IdentityService();
  
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _showEmoji = false;
  bool _isLoading = true;
  String? _currentUserId;
  int _selfDestruct = 0;

  final List<String> _reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡', '🔥', '🎉'];
  Map<String, dynamic>? _replyTo;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final key = await _identityService.getPublicKey();
    setState(() => _currentUserId = key ?? 'unknown');
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final messages = _chatService.loadMessages(widget.chatId);
    setState(() {
      _messages = messages;
      _filteredMessages = messages;
      _isLoading = false;
    });
    _scrollDown();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final message = {
      'text': text,
      'isMe': true,
      'time': time,
      'reactions': <String, List<String>>{},
      'isPinned': false,
      'isRead': true,
      'replyTo': _replyTo,
      'animating': true,
    };

    setState(() {
      _messages.add(message);
      _filteredMessages = _messages;
      _replyTo = null;
    });

    _chatService.saveMessage(
      chatId: widget.chatId,
      text: text,
      isMe: true,
      time: time,
    );

    _messageController.clear();
    _scrollDown();

    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        final index = _messages.indexOf(message);
        if (index != -1) {
          _messages[index]['animating'] = false;
          _filteredMessages = _messages;
        }
      });
    });
  }

  void _toggleReaction(int index, String emoji) {
    if (_currentUserId == null) return;

    final message = _messages[index];
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

    if (reactions[emoji]!.contains(_currentUserId)) {
      reactions[emoji]!.remove(_currentUserId);
      if (reactions[emoji]!.isEmpty) {
        reactions.remove(emoji);
      }
    } else {
      reactions[emoji]!.add(_currentUserId!);
    }

    message['reactions'] = reactions;
    _chatService.toggleReaction(widget.chatId, index, emoji, _currentUserId!);
    
    setState(() {
      _messages[index] = message;
      _filteredMessages = _messages;
    });
  }

  void _togglePin(int index) {
    final message = _messages[index];
    final isPinned = message['isPinned'] as bool? ?? false;
    
    setState(() {
      _messages[index]['isPinned'] = !isPinned;
      _filteredMessages = _messages;
    });
    
    _chatService.togglePin(widget.chatId, index);
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
      _filteredMessages = _messages;
    });
    _chatService.deleteMessage(widget.chatId, index);
  }

  void _replyToMessage(int index) {
    setState(() {
      _replyTo = _messages[index];
    });
    FocusScope.of(context).requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyTo = null;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _filteredMessages = _messages;
      }
    });
  }

  void _filterMessages(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMessages = _messages;
      } else {
        _filteredMessages = _messages.where((msg) {
          final text = msg['text'] as String? ?? '';
          return text.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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

  void _sendPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отправка фото в разработке')),
    );
  }

  void _sendVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отправка видео в разработке')),
    );
  }

  void _sendFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отправка файлов в разработке')),
    );
  }

  void _showStickerPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Стикеры в разработке')),
    );
  }

  void _showSelfDestructDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Самоуничтожение в разработке')),
    );
  }

  void _sendVoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Голосовые сообщения в разработке')),
    );
  }

  void _showPluginsMenu() {
    final manager = PluginManager();
    final installed = manager.getInstalledPlugins();
    
    if (installed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет установленных плагинов'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
            const Text(
              'Плагины',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...installed.map((id) {
              String name = id;
              String icon = '🧩';
              
              switch (id) {
                case 'veil.translator':
                  name = 'Veil Translator';
                  icon = '🌐';
                  break;
                case 'veil.reminder':
                  name = 'Veil Reminder';
                  icon = '⏰';
                  break;
                case 'veil.stats':
                  name = 'Veil Stats';
                  icon = '📊';
                  break;
                case 'veil.scheduler':
                  name = 'Veil Scheduler';
                  icon = '📅';
                  break;
                case 'veil.safe_backup':
                  name = 'Veil Safe Backup';
                  icon = '💾';
                  break;
              }

              return ListTile(
                leading: Text(icon, style: const TextStyle(fontSize: 24)),
                title: Text(name),
                subtitle: const Text('Активен'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Выбран плагин: $name'),
                      backgroundColor: const Color(0xFF6C5CE7),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F12) : Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: _filterMessages,
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                    child: Text(
                      widget.chatName.isNotEmpty ? widget.chatName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: const Color(0xFF6C5CE7),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatName,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'В сети',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              size: 20,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: widget.onToggleInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPinnedMessage(theme),
          if (_replyTo != null)
            _buildReplyBar(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет сообщений',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredMessages.length,
                        itemBuilder: (context, index) {
                          final realIndex = _messages.indexOf(_filteredMessages[index]);
                          final message = _filteredMessages[index];
                          final isMe = message['isMe'] as bool;
                          final isAnimating = message['animating'] as bool? ?? false;

                          return GestureDetector(
                            onLongPress: () => _showContextMenu(realIndex),
                            child: ChatMessageBubble(
                              message: message,
                              isMe: isMe,
                              isAnimating: isAnimating,
                              currentUserId: _currentUserId,
                              onReply: () => _replyToMessage(realIndex),
                              onLongPress: () {},
                            ),
                          );
                        },
                      ),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onEmojiToggle: () => setState(() => _showEmoji = !_showEmoji),
            onStickerPicker: _showStickerPicker,
            onPhoto: _sendPhoto,
            onVideo: _sendVideo,
            onFile: _sendFile,
            onSelfDestruct: _showSelfDestructDialog,
            onVoice: _sendVoice,
            onPlugins: _showPluginsMenu,
            showEmoji: _showEmoji,
            selfDestruct: _selfDestruct,
            isLoading: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedMessage(ThemeData theme) {
    final pinned = _chatService.getPinnedMessage(widget.chatId);
    if (pinned == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6C5CE7).withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, color: const Color(0xFF6C5CE7), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Закреплено',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  pinned['text'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: () {
              final messages = _chatService.loadMessages(widget.chatId);
              for (int i = 0; i < messages.length; i++) {
                if (messages[i]['isPinned'] == true) {
                  _chatService.togglePin(widget.chatId, i);
                  _loadMessages();
                  break;
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            color: const Color(0xFF6C5CE7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ответ на сообщение',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyTo?['text'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16),
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  void _showContextMenu(int index) {
    final message = _messages[index];
    final isPinned = message['isPinned'] as bool? ?? false;

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
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(ctx);
                _replyToMessage(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Реакции'),
              onTap: () {
                Navigator.pop(ctx);
                _showReactionPicker(index);
              },
            ),
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(isPinned ? 'Открепить' : 'Закрепить'),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deleteMessage(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(int index) {
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
              'Выберите реакцию',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _reactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    _toggleReaction(index, emoji);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
}