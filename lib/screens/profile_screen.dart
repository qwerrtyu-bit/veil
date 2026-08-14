import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../data/identity_service.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';

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
  String _username = '';
  String _usernameTier = 'free';
  bool _hasUsername = false;
  bool _showFullKey = false;
  bool _isLoading = true;
  bool _isEditingUsername = false;
  final _usernameController = TextEditingController();

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

    if (key != null) {
      await _loadUsername(key);
    }
  }

  Future<void> _loadUsername(String publicKey) async {
    try {
      final response = await http.get(
        Uri.parse('${VeilConstants.serverUrl}/username/get?ownerId=$publicKey'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _username = data['username'] ?? '';
          _hasUsername = _username.isNotEmpty;
          _usernameTier = data['tier'] ?? 'free';
        });
      }
    } catch (e) {
      print('Ошибка загрузки юзернейма: $e');
    }
  }

  Future<void> _registerUsername() async {
    final username = _usernameController.text.trim().toLowerCase();
    
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите юзернейм'), backgroundColor: Colors.red),
      );
      return;
    }

    if (username.length < 3 || username.length > 32) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Юзернейм должен быть 3-32 символа'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Только буквы, цифры и _'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isEditingUsername = false);

    try {
      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/username/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'ownerType': 'user',
          'ownerId': _publicKey,
          'displayName': _displayName,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _username = username;
          _hasUsername = true;
          _usernameTier = 'free';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Юзернейм @$username зарегистрирован!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Этот юзернейм уже занят'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Ошибка регистрации'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyUsernameLink() {
    final link = 'veil://user/$_username';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ссылка скопирована'),
        backgroundColor: Color(0xFF6C5CE7),
      ),
    );
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

    if (avatarId == 'custom' && customImage != null) {
      try {
        final bytes = base64Decode(customImage);
        return ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
          ),
        );
      } catch (_) {
        return _buildFallbackAvatar(avatars, avatarId);
      }
    }

    return _buildFallbackAvatar(avatars, avatarId);
  }

  Widget _buildFallbackAvatar(Map<String, String> avatars, String avatarId) {
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
      child: Center(
        child: Text(
          avatars[avatarId] ?? '🔒',
          style: const TextStyle(fontSize: 45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
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
                  
                  // ============================================================
                  // ЮЗЕРНЕЙМ
                  // ============================================================
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
                              const Icon(Icons.alternate_email, size: 20, color: Color(0xFF6C5CE7)),
                              const SizedBox(width: 8),
                              Text(
                                'Юзернейм',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const Spacer(),
                              if (_hasUsername)
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: _copyUsernameLink,
                                  tooltip: 'Копировать ссылку',
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_hasUsername)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0B0D17) : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    '@',
                                    style: TextStyle(
                                      color: Color(0xFF6C5CE7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _username,
                                      style: TextStyle(
                                        fontFamily: 'SpaceMono',
                                        fontSize: 14,
                                        color: const Color(0xFF6C5CE7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _usernameTier == 'free'
                                          ? Colors.grey.withOpacity(0.2)
                                          : const Color(0xFFF59E0B).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _usernameTier == 'free' ? 'обычный' : '💎 премиум',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _usernameTier == 'free' ? Colors.grey : const Color(0xFFF59E0B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Column(
                              children: [
                                if (!_isEditingUsername)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() => _isEditingUsername = true);
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Зарегистрировать юзернейм'),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF6C5CE7)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            '@',
                                            style: TextStyle(
                                              color: Color(0xFF6C5CE7),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: _usernameController,
                                              autofocus: true,
                                              style: TextStyle(
                                                fontFamily: 'SpaceMono',
                                                fontSize: 14,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: 'ваш_юзернейм',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() => _isEditingUsername = false);
                                              },
                                              child: const Text('Отмена'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: _registerUsername,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF6C5CE7),
                                              ),
                                              child: const Text('Зарегистрировать'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Только буквы, цифры и _. 3-32 символа.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          // ============================================================
                          // КНОПКА МАГАЗИНА ЮЗЕРНЕЙМОВ
                          // ============================================================
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.go('/username-shop'),
                              icon: const Icon(Icons.shopping_bag, size: 18),
                              label: Text(
                                _hasUsername 
                                  ? '💎 Купить премиум-юзернейм' 
                                  : '💎 Магазин юзернеймов',
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFF59E0B)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ============================================================
                  // QR-код
                  // ============================================================
                  const SizedBox(height: 16),
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
                  
                  // ============================================================
                  // Публичный ключ
                  // ============================================================
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
                    title: l10n.settings,
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
            Text('Версия: 2.5.0'),
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