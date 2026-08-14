import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _stories = [];

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  void _loadStories() {
    final box = Hive.box('messages');
    final raw = box.get('stories', defaultValue: <Map<String, dynamic>>[]);
    if (raw is List) {
      _stories = raw.where((item) => item is Map).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      final now = DateTime.now();
      _stories.removeWhere((s) {
        final timestamp = DateTime.tryParse(s['timestamp'] as String? ?? '');
        return timestamp == null || now.difference(timestamp).inHours > 24;
      });
      box.put('stories', _stories);
    }
    setState(() {});
  }

  Future<void> _addStory() async {
    final photo = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 720, imageQuality: 70);
    if (photo == null) return;

    final bytes = await photo.readAsBytes();
    final story = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'image': base64.encode(bytes),
      'timestamp': DateTime.now().toIso8601String(),
      'views': 0,
    };

    _stories.add(story);
    Hive.box('messages').put('stories', _stories);
    setState(() {});
  }

  void _viewStory(int index) {
    setState(() {
      _stories[index]['views'] = (_stories[index]['views'] as int? ?? 0) + 1;
    });
    Hive.box('messages').put('stories', _stories);

    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Container(
          color: Colors.black,
          child: Center(
            child: Image.memory(
              base64.decode(_stories[index]['image'] as String),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(l10n.stories),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
        actions: [
          IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _addStory),
        ],
      ),
      body: _stories.isEmpty
          ? Center(
              child: Text('Нет статусов', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                final timestamp = DateTime.tryParse(story['timestamp'] as String? ?? '') ?? DateTime.now();
                final hoursLeft = 24 - DateTime.now().difference(timestamp).inHours;

                return GestureDetector(
                  onTap: () => _viewStory(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4ADE80), width: 2),
                      image: DecorationImage(
                        image: MemoryImage(base64.decode(story['image'] as String)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                        ),
                      ),
                      child: Text(
                        '${hoursLeft} ч',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}