import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/identity_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _identityService = IdentityService();
  String _publicKey = '';
  String _displayName = 'void';
  String _displayBio = 'Разработчик Veil';
  bool _showFullKey = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final key = await _identityService.getPublicKey();
    final settingsBox = Hive.box('settings');
    setState(() {
      _publicKey = key ?? 'Ключ не найден';
      _displayName = settingsBox.get('profileName', defaultValue: 'void');
      _displayBio = settingsBox.get('profileBio', defaultValue: 'Разработчик Veil');
      _isLoading = false;
    });
  }

  Widget _buildAvatar() {
    final settingsBox = Hive.box('settings');
    final avatarId = settingsBox.get('profileAvatar', defaultValue: 'void');
    final customImage = settingsBox.get('customAvatar');
    const avatars = {
      'void': '🔒',
      'ghost': '👻',
      'ninja': '🥷',
      'hacker': '💻',
      'mask': '🎭',
      'eye': '👁️',
      'fire': '🔥',
      'star': '⭐',
    };

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: avatarId == 'custom' && customImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Image.memory(
                base64Decode(customImage),
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Text(
                avatars[avatarId] ?? '🔒',
                style: const TextStyle(fontSize: 45),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/edit-profile'),
            tooltip: 'Редактировать профиль',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatar(),
                  const SizedBox(height: 24),
                  Text(
                    _displayName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _displayBio,
                      style: TextStyle(
                        color: const Color(0xFF6C5CE7),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Мой QR-код',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: _publicKey,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Покажите этот код для добавления в контакты',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key, size: 20, color: Color(0xFF6C5CE7)),
                              const SizedBox(width: 8),
                              Text(
                                'Публичный ключ',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  _showFullKey ? Icons.visibility : Icons.visibility_off,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _showFullKey = !_showFullKey),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _publicKey));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ключ скопирован'),
                                      backgroundColor: Color(0xFF6C5CE7),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0B0D17) : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _showFullKey
                                  ? _publicKey
                                  : '${_publicKey.substring(0, 8)}••••••••••••••••••••${_publicKey.length > 16 ? _publicKey.substring(_publicKey.length - 8) : ''}',
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 12,
                                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    icon: Icons.qr_code,
                    title: 'Показать QR отдельно',
                    subtitle: 'На весь экран',
                    onTap: () => context.go('/qr-display'),
                  ),
                  const SizedBox(height: 10),
                  _buildButton(
                    icon: Icons.settings_outlined,
                    title: 'Настройки',
                    subtitle: 'Безопасность, оформление, сброс',
                    onTap: () => context.go('/settings'),
                  ),
                  const SizedBox(height: 10),
                  _buildButton(
                    icon: Icons.report,
                    title: 'Жалобы',
                    subtitle: 'Список жалоб от пользователей',
                    onTap: () => context.go('/reports-list'),
                  ),
                  const SizedBox(height: 10),
                  _buildButton(
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    subtitle: 'Версия 1.0.0',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C5CE7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Veil'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Версия: 1.0.0'),
            SizedBox(height: 8),
            Text('"Говори свободно."', style: TextStyle(fontStyle: FontStyle.italic)),
            SizedBox(height: 16),
            Text(
              'Создано 0xTima (void)\n\nZero Knowledge. Zero Trust.\nНикто не может прочитать ваши сообщения. Даже разработчик.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}