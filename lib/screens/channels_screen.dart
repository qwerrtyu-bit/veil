import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';
import '../data/identity_service.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final List<Map<String, dynamic>> _channels = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadChannels();
  }

  void _loadCurrentUser() async {
    final identityService = IdentityService();
    final key = await identityService.getPublicKey();
    setState(() => _currentUserId = key ?? '');
  }

  void _loadChannels() {
    final box = Hive.box('messages');
    final raw = box.get('channels');
    _channels.clear();
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          _channels.add(Map<String, dynamic>.from(item));
        }
      }
    }
    if (_channels.isEmpty) {
      _channels.addAll([
        {'id': '1', 'name': 'Veil News', 'author': 'void', 'subs': 128, 'description': 'Официальные новости Veil Messenger'},
        {'id': '2', 'name': 'Криптография', 'author': '0xTima', 'subs': 56, 'description': 'Всё о шифровании и безопасности'},
      ]);
      box.put('channels', _channels);
    }
    setState(() {});
  }

  void _createChannel() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Создать канал'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Название канала')),
            const SizedBox(height: 8),
            TextField(controller: descController, decoration: const InputDecoration(hintText: 'Описание')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final box = Hive.box('messages');
              final raw = box.get('channels', defaultValue: <Map<String, dynamic>>[]);
              List<Map<String, dynamic>> list = [];
              if (raw is List) {
                for (final item in raw) {
                  if (item is Map) list.add(Map<String, dynamic>.from(item));
                }
              }
              list.add({
                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                'name': name,
                'author': _currentUserId.isEmpty ? 'void' : _currentUserId,
                'subs': 0,
                'description': descController.text.trim(),
              });
              box.put('channels', list);
              Navigator.pop(ctx);
              _loadChannels();
            },
            child: const Text('Создать', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  void _showChannelManagement(Map<String, dynamic> channel) {
    final isOwner = channel['author'] == _currentUserId || channel['author'] == 'void';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Управление каналом',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF6C5CE7)),
              ),
              title: const Text('Изменить название'),
              onTap: () {
                Navigator.pop(ctx);
                _editChannelName(channel);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description, color: Color(0xFF6C5CE7)),
              ),
              title: const Text('Изменить описание'),
              onTap: () {
                Navigator.pop(ctx);
                _editChannelDescription(channel);
              },
            ),
            if (isOwner) ...[
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Удалить канал', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteChannel(channel);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.orange),
                ),
                title: const Text('Передать владение'),
                onTap: () {
                  Navigator.pop(ctx);
                  _transferOwnership(channel);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _editChannelName(Map<String, dynamic> channel) {
    final controller = TextEditingController(text: channel['name']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Изменить название'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Новое название'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final box = Hive.box('messages');
              final raw = box.get('channels');
              List<Map<String, dynamic>> list = [];
              if (raw is List) {
                for (final item in raw) {
                  if (item is Map) list.add(Map<String, dynamic>.from(item));
                }
              }
              final index = list.indexWhere((c) => c['id'] == channel['id']);
              if (index != -1) {
                list[index]['name'] = newName;
                box.put('channels', list);
                _loadChannels();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Название обновлено'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _editChannelDescription(Map<String, dynamic> channel) {
    final controller = TextEditingController(text: channel['description']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Изменить описание'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Новое описание'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final newDesc = controller.text.trim();
              final box = Hive.box('messages');
              final raw = box.get('channels');
              List<Map<String, dynamic>> list = [];
              if (raw is List) {
                for (final item in raw) {
                  if (item is Map) list.add(Map<String, dynamic>.from(item));
                }
              }
              final index = list.indexWhere((c) => c['id'] == channel['id']);
              if (index != -1) {
                list[index]['description'] = newDesc;
                box.put('channels', list);
                _loadChannels();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Описание обновлено'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteChannel(Map<String, dynamic> channel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Удалить канал?'),
        content: const Text('Все посты и подписчики будут удалены. Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final box = Hive.box('messages');
              final raw = box.get('channels');
              List<Map<String, dynamic>> list = [];
              if (raw is List) {
                for (final item in raw) {
                  if (item is Map) list.add(Map<String, dynamic>.from(item));
                }
              }
              list.removeWhere((c) => c['id'] == channel['id']);
              box.put('channels', list);
              box.delete('channel_posts_${channel['id']}');
              _loadChannels();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Канал удалён'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _transferOwnership(Map<String, dynamic> channel) {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Передать владение'),
        content: TextField(
          controller: keyController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Публичный ключ нового владельца',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final newOwner = keyController.text.trim();
              if (newOwner.isEmpty) return;
              final box = Hive.box('messages');
              final raw = box.get('channels');
              List<Map<String, dynamic>> list = [];
              if (raw is List) {
                for (final item in raw) {
                  if (item is Map) list.add(Map<String, dynamic>.from(item));
                }
              }
              final index = list.indexWhere((c) => c['id'] == channel['id']);
              if (index != -1) {
                list[index]['author'] = newOwner;
                box.put('channels', list);
                _loadChannels();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Владение передано'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Передать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.channels),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createChannel),
        ],
      ),
      body: _channels.isEmpty
          ? const Center(child: Text('Нет каналов', style: TextStyle(color: Color(0xFF888899))))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final ch = _channels[index];
                final isOwner = ch['author'] == _currentUserId || ch['author'] == 'void';
                return Card(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(ch['name']?[0]?.toUpperCase() ?? '#', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ),
                    title: Text(ch['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${ch['subs']} подписчиков · ${ch['description'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.settings, color: Color(0xFF6C5CE7), size: 20),
                            onPressed: () => _showChannelManagement(ch),
                            tooltip: 'Управление каналом',
                          ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF888899)),
                          onPressed: () => context.go('/channel/${ch['id']}', extra: ch),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChannel,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}