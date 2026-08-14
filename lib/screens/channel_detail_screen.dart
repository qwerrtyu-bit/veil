import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

class ChannelDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> channel;

  const ChannelDetailScreen({super.key, required this.channel});

  @override
  ConsumerState<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> {
  bool _isSubscribed = false;
  final _postController = TextEditingController();
  List<Map<String, String>> _posts = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.channel['author'] == 'void';
    _loadSubscription();
    _loadPosts();
  }

  void _loadSubscription() {
    try {
      final box = Hive.box('settings');
      final subs = box.get('channel_subs');
      if (subs is List) {
        _isSubscribed = subs.contains(widget.channel['id']);
      }
    } catch (_) {}
    setState(() {});
  }

  void _toggleSubscription() {
    try {
      final box = Hive.box('settings');
      final subs = box.get('channel_subs');
      List<String> subsList = subs is List ? List<String>.from(subs) : [];
      if (_isSubscribed) {
        subsList.remove(widget.channel['id']);
      } else {
        subsList.add(widget.channel['id']?.toString() ?? '');
      }
      box.put('channel_subs', subsList);
      setState(() => _isSubscribed = !_isSubscribed);
    } catch (_) {}
  }

  void _loadPosts() {
    try {
      final box = Hive.box('messages');
      final raw = box.get('channel_posts_${widget.channel['id']}');
      _posts.clear();
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            _posts.add({
              'text': item['text']?.toString() ?? '',
              'time': item['time']?.toString() ?? '',
            });
          }
        }
      }
    } catch (_) {}
    if (_posts.isEmpty && widget.channel['name'] == 'Veil News') {
      _posts.addAll([
        {'text': 'Добро пожаловать в Veil News! 🎉', 'time': '12:00'},
        {'text': 'Новая версия 1.4.0 уже доступна.', 'time': 'Вчера'},
      ]);
    }
    setState(() {});
  }

  void _sendPost() {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    final now = TimeOfDay.now();
    final time = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final box = Hive.box('messages');
    final raw = box.get('channel_posts_${widget.channel['id']}', defaultValue: <Map<String, dynamic>>[]);
    List<Map<String, dynamic>> list = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) list.add(Map<String, dynamic>.from(item));
      }
    }
    list.add({'text': text, 'time': time});
    box.put('channel_posts_${widget.channel['id']}', list);

    _postController.clear();
    _loadPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.channel['name'] ?? 'Канал'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/channels')),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(widget.channel['name']?[0]?.toUpperCase() ?? '#', style: TextStyle(fontSize: 30, color: theme.colorScheme.primary))),
                const SizedBox(height: 12),
                Text(widget.channel['name'] ?? '', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(widget.channel['description'] ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _toggleSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubscribed ? Colors.grey : theme.colorScheme.primary,
                  ),
                  child: Text(_isSubscribed ? 'Отписаться' : 'Подписаться'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 18, backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            child: Text(widget.channel['name']?[0]?.toUpperCase() ?? '#', style: TextStyle(color: theme.colorScheme.primary, fontSize: 14))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.channel['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(post['text'] ?? ''),
                              const SizedBox(height: 4),
                              Text(post['time'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isOwner)
            Container(
              padding: const EdgeInsets.all(8),
              color: theme.colorScheme.surface,
              child: Row(children: [
                Expanded(child: TextField(controller: _postController, decoration: const InputDecoration(hintText: 'Новый пост...', border: InputBorder.none))),
                IconButton(icon: Icon(Icons.send, color: theme.colorScheme.primary), onPressed: _sendPost),
              ]),
            ),
        ],
      ),
    );
  }
}