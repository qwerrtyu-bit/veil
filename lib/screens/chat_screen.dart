import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/chat_service.dart';
import '../data/crypto_service.dart';
import '../data/file_service.dart';
import '../data/identity_service.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_model.dart';
import '../widgets/chat/chat_base.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/encrypt_animation.dart';
import '../widgets/message_context_menu.dart';
import '../widgets/markdown_parser.dart';
import '../services/export_service.dart';
import '../core/icons.dart';
import '../widgets/chat/voice_recorder.dart';
import '../plugins/plugin_manager.dart';

class ChatScreenMobile extends ConsumerStatefulWidget {
  final String contactId;
  const ChatScreenMobile({super.key, required this.contactId});
  @override
  ConsumerState<ChatScreenMobile> createState() => _ChatScreenMobileState();
}

class _ChatScreenMobileState extends ConsumerState<ChatScreenMobile> {
  late ChatBase _chat;
  bool _showEmoji = false;
  final _chatService = ChatService();
  final _cryptoService = CryptoService();
  final _fileService = FileService();
  final _identityService = IdentityService();
  final _imagePicker = ImagePicker();
  final _exportService = ExportService();

  final Map<String, Map<String, String>> _contacts = {};

  @override
  void initState() {
    super.initState();
    _chat = ChatBase(contactId: widget.contactId);
    _chat.setCallbacks(
      onReactionLimitExceeded: (max) {
        _showSnackBar('Достигнут лимит реакций ($max) для вашего тарифа');
      },
      onSnackBar: _showSnackBar,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  void _toggleSearch() => _chat.toggleSearch();
  void _filterMessages(String query) => _chat.filterMessages(query);

  void _showEditDialog(int index) {
    final msg = _chat.filteredMessages[index];
    final controller = TextEditingController(text: msg['text'] as String);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Новый текст',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                _chat.editMessage(index, newText);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Color(0xFF6C5CE7))),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(int index) {
    final contacts = Hive.box('contacts');
    final List<Map<String, dynamic>> chatList = [];

    for (final key in contacts.keys) {
      final data = contacts.get(key);
      if (data is Map) {
        chatList.add({
          'id': key.toString(),
          'name': data['name']?.toString() ?? 'Контакт',
          'type': 'contact',
        });
      }
    }

    final groupsBox = Hive.box('messages');
    final rawGroups = groupsBox.get('groups_list');
    if (rawGroups is List) {
      for (final item in rawGroups) {
        if (item is Map) {
          chatList.add({
            'id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Группа',
            'type': 'group',
          });
        }
      }
    }

    if (chatList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет чатов для пересылки'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Переслать в чат'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, i) {
              final chat = chatList[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: chat['type'] == 'group'
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFF10B981),
                  child: Text(
                    chat['name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(chat['name']),
                onTap: () {
                  Navigator.pop(ctx);
                  _chat.forwardMessage(index, chat['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Сообщение переслано в "${chat['name']}"'),
                      backgroundColor: const Color(0xFF6C5CE7),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(int index) {
    final msg = _chat.filteredMessages[index];
    final isPinned = msg['isPinned'] as bool? ?? false;
    final isMe = msg['isMe'] as bool? ?? false;

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
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.forward_outlined),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(ctx);
                _showForwardDialog(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(ctx);
                _chat.replyToMessage(index);
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
                _chat.togglePin(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _chat.deleteMessage(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecorder(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: VoiceRecorder(
          onSend: (file, duration) {
            _chat.sendVoiceMessage(file, duration);
          },
        ),
      ),
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
              default:
                name = id;
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
              children: _chat.reactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    _chat.toggleReaction(index, emoji);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
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

  Future<void> _exportChat() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Экспорт чата'),
        content: const Text('Выберите формат:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'txt'),
            child: const Text('TXT'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'json'),
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Экспорт чата (в разработке)'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDeleteDialog(int index) {
    final msg = _chat.filteredMessages[index];
    final isPinned = msg['isPinned'] as bool? ?? false;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Удалить сообщение?'),
        content: Text(
          isPinned 
            ? 'Это сообщение закреплено. Удалить его?'
            : 'Это действие нельзя отменить.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              _chat.deleteMessage(index);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      if (_showEmoji) FocusScope.of(context).unfocus();
    });
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
              children: _chat.stickers.map((s) {
                return GestureDetector(
                  onTap: () {
                    _chat.messageController.text = s;
                    _chat.sendMessage();
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

  void _showSelfDestructDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Самоуничтожение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimerOption(0, 'Выкл'),
            _buildTimerOption(5, '5 секунд'),
            _buildTimerOption(30, '30 секунд'),
            _buildTimerOption(60, '1 минута'),
            _buildTimerOption(300, '5 минут'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerOption(int seconds, String label) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: _chat.selfDestruct == seconds
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      leading: Icon(
        _chat.selfDestruct == seconds ? Icons.timer : Icons.timer_outlined,
        color: _chat.selfDestruct == seconds
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      onTap: () {
        _chat.setSelfDestruct(seconds);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallpaperDecoration = _chat.getWallpaperDecoration();
    final contact = _contacts[widget.contactId] ?? {
      'name': 'Неизвестный',
      'initial': '?',
      'status': 'Офлайн'
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: _chat.isSearching ? const Icon(Icons.close) : const Icon(Icons.arrow_back),
          onPressed: () {
            if (_chat.isSearching) {
              _chat.toggleSearch();
            } else {
              GoRouter.of(context).go('/chats');
            }
          },
        ),
        title: _chat.isSearching
            ? TextField(
                controller: _chat.searchController,
                autofocus: true,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _chat.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: () {
                            _chat.searchController.clear();
                            _chat.filterMessages('');
                          },
                        )
                      : null,
                ),
                onChanged: _chat.filterMessages,
              )
            : Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.go(
                        '/contact-profile/${widget.contactId}',
                        extra: {
                          'name': contact['name'],
                          'key': widget.contactId,
                        },
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        contact['initial'] ?? '?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'] ?? '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        contact['status'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: contact['status'] == 'В сети'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: [
          if (!_chat.isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _chat.toggleSearch,
              tooltip: 'Поиск',
            ),
            IconButton(
              icon: const Icon(Icons.wallpaper_outlined),
              onPressed: () => context.go(
                '/wallpaper/${widget.contactId}',
                extra: {'name': contact['name']},
              ),
              tooltip: 'Обои',
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Color(0xFF10B981)),
              onPressed: () => context.go(
                '/call/${widget.contactId}',
                extra: {'name': contact['name'], 'isVideo': false},
              ),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Color(0xFF10B981)),
              onPressed: () => context.go(
                '/call/${widget.contactId}',
                extra: {'name': contact['name'], 'isVideo': true},
              ),
            ),
            IconButton(
              icon: const Icon(Icons.report_outlined, color: Colors.red),
              onPressed: () => context.go('/report/${widget.contactId}'),
            ),
          ],
        ],
      ),
      body: Container(
        decoration: wallpaperDecoration ?? BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: AnimatedBuilder(
          animation: _chat,
          builder: (context, child) {
            final pinned = _chat.chatService.getPinnedMessage(widget.contactId);
            
            return Column(
              children: [
                if (pinned != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.push_pin, color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Закреплено',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
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
                          icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: () {
                            final messages = _chat.chatService.loadMessages(widget.contactId);
                            for (int i = 0; i < messages.length; i++) {
                              if (messages[i]['isPinned'] == true) {
                                _chat.chatService.togglePin(widget.contactId, i);
                                _chat.loadMessages();
                                break;
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _chat.scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _chat.filteredMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chat.filteredMessages[index];
                      final isMe = msg['isMe'] as bool;
                      final isAnimating = msg['animating'] as bool? ?? false;
                      final replyTo = msg['replyTo'] as Map<String, dynamic>?;
                      final isPinned = msg['isPinned'] as bool? ?? false;

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        ),
                        child: GestureDetector(
                          onLongPress: () => _showContextMenu(index),
                          child: Dismissible(
                            key: Key('msg_$index'),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (_) async {
                              _chat.replyToMessage(index);
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              color: theme.colorScheme.primary.withOpacity(0.05),
                              child: Icon(Icons.reply, color: theme.colorScheme.primary),
                            ),
                            child: ChatMessageBubble(
                              message: msg,
                              isMe: isMe,
                              isAnimating: isAnimating,
                              currentUserId: _chat.currentUserId,
                              onLongPress: () => _showDeleteDialog(index),
                              onReply: () => _chat.replyToMessage(index),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_chat.replyTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.black.withOpacity(0.3),
                    child: Row(
                      children: [
                        Icon(Icons.reply, color: theme.colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ответ на сообщение',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _chat.replyTo!['text'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: _chat.clearReply,
                        ),
                      ],
                    ),
                  ),
                ChatInput(
                  controller: _chat.messageController,
                  onSend: _chat.sendMessage,
                  onEmojiToggle: _toggleEmoji,
                  onStickerPicker: _showStickerPicker,
                  onPhoto: _chat.sendPhoto,
                  onVideo: _chat.sendVideo,
                  onFile: _chat.sendFile,
                  onSelfDestruct: _showSelfDestructDialog,
                  onVoice: () => _showVoiceRecorder(context),
                  onPlugins: _showPluginsMenu,
                  showEmoji: _showEmoji,
                  selfDestruct: _chat.selfDestruct,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}