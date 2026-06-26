import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedAvatar = 'void';
  String? _customImageBase64;
  bool _isLoading = true;
  final _picker = ImagePicker();

  final List<Map<String, String>> _avatars = [
    {'id': 'void', 'emoji': '🔒', 'label': 'Замок'},
    {'id': 'ghost', 'emoji': '👻', 'label': 'Призрак'},
    {'id': 'ninja', 'emoji': '🥷', 'label': 'Ниндзя'},
    {'id': 'hacker', 'emoji': '💻', 'label': 'Хакер'},
    {'id': 'mask', 'emoji': '🎭', 'label': 'Маска'},
    {'id': 'eye', 'emoji': '👁️', 'label': 'Глаз'},
    {'id': 'fire', 'emoji': '🔥', 'label': 'Огонь'},
    {'id': 'star', 'emoji': '⭐', 'label': 'Звезда'},
    {'id': 'custom', 'emoji': '📷', 'label': 'Своё фото'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final settingsBox = Hive.box('settings');
    setState(() {
      _nameController.text = settingsBox.get('profileName', defaultValue: 'void');
      _bioController.text = settingsBox.get('profileBio', defaultValue: 'Разработчик Veil');
      _selectedAvatar = settingsBox.get('profileAvatar', defaultValue: 'void');
      _customImageBase64 = settingsBox.get('customAvatar');
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      setState(() {
        _customImageBase64 = base64;
        _selectedAvatar = 'custom';
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя не может быть пустым'), backgroundColor: Colors.red),
      );
      return;
    }

    final settingsBox = Hive.box('settings');
    await settingsBox.put('profileName', name);
    await settingsBox.put('profileBio', bio);
    await settingsBox.put('profileAvatar', _selectedAvatar);
    if (_customImageBase64 != null) {
      await settingsBox.put('customAvatar', _customImageBase64);
    } else {
      await settingsBox.delete('customAvatar');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль обновлён!'), backgroundColor: Colors.green),
    );

    context.go('/profile');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактировать профиль')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Сохранить',
                style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Текущий аватар
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFF6C5CE7),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _selectedAvatar == 'custom' && _customImageBase64 != null
                            ? Image.memory(
                                base64Decode(_customImageBase64!),
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              )
                            : Center(
                                child: Text(
                                  _avatars.firstWhere(
                                    (a) => a['id'] == _selectedAvatar,
                                    orElse: () => {'emoji': '🔒'},
                                  )['emoji']!,
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: Text(
                'Выбрать фото',
                style: TextStyle(color: const Color(0xFF6C5CE7)),
              ),
            ),
            const SizedBox(height: 24),

            // Выбор эмодзи-аватара
            Text(
              'Или выберите эмодзи',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars
                  .where((a) => a['id'] != 'custom')
                  .map((avatar) {
                final isSelected = _selectedAvatar == avatar['id'];
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedAvatar = avatar['id']!;
                    _customImageBase64 = null;
                  }),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C5CE7)
                          : (isDark ? const Color(0xFF1A1A2E) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFE0E0E0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(avatar['emoji']!, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Имя
            Text(
              'Имя',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Ваше имя'),
              maxLength: 30,
            ),
            const SizedBox(height: 16),

            // Био
            Text(
              'Статус',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(hintText: 'О себе'),
              maxLength: 50,
            ),
          ],
        ),
      ),
    );
  }
}