import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final List<Map<String, dynamic>> _channels = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
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
                'author': 'void',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Каналы'),
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
                    onTap: () => context.go('/channel/${ch['id']}', extra: ch),
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