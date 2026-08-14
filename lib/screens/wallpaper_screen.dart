import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/wallpaper.dart';
import '../models/wallpaper_time.dart';

class WallpaperScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;

  const WallpaperScreen({
    super.key,
    required this.chatId,
    required this.chatName,
  });

  @override
  ConsumerState<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends ConsumerState<WallpaperScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _currentWallpaperId;
  final List<Wallpaper> _customWallpapers = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentWallpaper();
    _loadCustomWallpapers();
  }

  void _loadCurrentWallpaper() {
    final box = Hive.box('settings');
    _currentWallpaperId = box.get('wallpaper_${widget.chatId}');
    setState(() {});
  }

  void _loadCustomWallpapers() {
    final box = Hive.box('wallpapers');
    final raw = box.get('custom_wallpapers');
    if (raw is List) {
      _customWallpapers.clear();
      for (final item in raw) {
        if (item is Map) {
          _customWallpapers.add(Wallpaper(
            id: item['id'] as String,
            name: item['name'] as String,
            type: WallpaperType.image,
            imagePath: item['imagePath'] as String,
          ));
        }
      }
    }
    setState(() {});
  }

  void _selectWallpaper(Wallpaper wallpaper) {
    final box = Hive.box('settings');
    box.put('wallpaper_${widget.chatId}', wallpaper.id);
    setState(() {
      _currentWallpaperId = wallpaper.id;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Обои "${wallpaper.name}" установлены для "${widget.chatName}"'),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      context.go('/chat/${widget.chatId}');
    });
  }

  void _selectDynamicWallpaper() {
    final box = Hive.box('settings');
    box.put('wallpaper_${widget.chatId}', 'dynamic');
    setState(() {
      _currentWallpaperId = 'dynamic';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Динамические обои включены для "${widget.chatName}"'),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      context.go('/chat/${widget.chatId}');
    });
  }

  Future<void> _pickCustomWallpaper() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (image == null) return;

    final String path = image.path;
    final String id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final String name = image.name;

    final customWallpaper = Wallpaper(
      id: id,
      name: name,
      type: WallpaperType.image,
      imagePath: path,
    );

    final box = Hive.box('wallpapers');
    final raw = box.get('custom_wallpapers');
    List<Map<String, dynamic>> list = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }
    list.add({
      'id': id,
      'name': name,
      'imagePath': path,
    });
    await box.put('custom_wallpapers', list);

    _loadCustomWallpapers();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Обои добавлены!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteCustomWallpaper(String id) {
    final box = Hive.box('wallpapers');
    final raw = box.get('custom_wallpapers');
    List<Map<String, dynamic>> list = [];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Map<String, dynamic>.from(item));
        }
      }
    }
    list.removeWhere((item) => item['id'] == id);
    box.put('custom_wallpapers', list);
    _loadCustomWallpapers();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Обои удалены'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetWallpaper() {
    final box = Hive.box('settings');
    box.delete('wallpaper_${widget.chatId}');
    setState(() {
      _currentWallpaperId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Обои сброшены на стандартные'),
        backgroundColor: Colors.orange,
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      context.go('/chat/${widget.chatId}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allWallpapers = [
      ...Wallpaper.defaults,
      ..._customWallpapers,
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Обои для "${widget.chatName}"'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chat/${widget.chatId}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _pickCustomWallpaper,
            tooltip: 'Добавить свои обои',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetWallpaper,
            tooltip: 'Сбросить обои',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выберите фон для чата',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Установите один из обоев, добавьте свой или включите динамические',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Динамические обои
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _currentWallpaperId == 'dynamic'
                      ? const Color(0xFF6C5CE7)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFFFF9A9E),
                        Color(0xFFFAD0C4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: const Text('Динамические обои'),
                subtitle: const Text('Автоматически меняются в зависимости от времени суток'),
                trailing: _currentWallpaperId == 'dynamic'
                    ? const Icon(Icons.check_circle, color: Color(0xFF6C5CE7))
                    : null,
                onTap: _selectDynamicWallpaper,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: allWallpapers.length,
              itemBuilder: (context, index) {
                final wallpaper = allWallpapers[index];
                final isSelected = _currentWallpaperId == wallpaper.id;
                final isCustom = wallpaper.type == WallpaperType.image;

                return GestureDetector(
                  onTap: () => _selectWallpaper(wallpaper),
                  onLongPress: isCustom ? () => _deleteCustomWallpaper(wallpaper.id) : null,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6C5CE7)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: isCustom && wallpaper.imagePath != null
                              ? Image.file(
                                  File(wallpaper.imagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: wallpaper.decoration,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            wallpaper.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C5CE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      if (isCustom)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GestureDetector(
                            onTap: () => _deleteCustomWallpaper(wallpaper.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}