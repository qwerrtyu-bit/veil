import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../app.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../data/identity_service.dart';
import '../services/admin_service.dart';
import '../services/gift_card_request_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _screenshotProtection = false;
  bool _darkTheme = false;
  bool _notificationsEnabled = true;
  bool _autoStart = false;
  bool _isAdmin = false;
  final _identityService = IdentityService();
  final _giftService = GiftCardRequestService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkAdmin();
  }

  Future<void> _loadSettings() async {
    final box = Hive.box('settings');
    setState(() {
      _darkTheme = box.get('darkTheme', defaultValue: false);
      _screenshotProtection = box.get('screenshotProtection', defaultValue: false);
      _notificationsEnabled = box.get('notifications', defaultValue: true);
      _autoStart = box.get('autoStart', defaultValue: false);
    });
  }

  Future<void> _checkAdmin() async {
    final adminService = AdminService();
    final isAdmin = await adminService.isAdmin();
    setState(() => _isAdmin = isAdmin);
  }

  void _toggleDarkTheme(bool value) {
    setState(() => _darkTheme = value);
    themeNotifier.value = value;
  }

  void _toggleScreenshotProtection(bool value) {
    setState(() => _screenshotProtection = value);
    Hive.box('settings').put('screenshotProtection', value);

    if (value) {
      if (Platform.isAndroid || Platform.isIOS) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Защита от скриншотов включена (Android/iOS)'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Защита от скриншотов включена. На Windows будет работать в следующей версии.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Защита от скриншотов выключена'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _showClearCardsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Очистить данные карт?'),
        content: const Text(
          'Все заявки и подарочные карты будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              _giftService.clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Все данные карт удалены'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Удалить аккаунт?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Все ваши ключи, контакты, сообщения и заметки будут удалены без возможности восстановления. Seed-фраза больше не поможет.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Введите пароль для подтверждения',
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () async {
                  final password = passwordController.text;
                  if (password.isEmpty) {
                    setDialogState(() {
                      errorText = 'Введите пароль';
                    });
                    return;
                  }

                  final isCorrect = await _identityService.checkPassword(password);
                  if (!isCorrect) {
                    setDialogState(() {
                      errorText = 'Неверный пароль';
                    });
                    return;
                  }

                  await Hive.box('secure').clear();
                  await Hive.box('settings').clear();
                  await Hive.box('contacts').clear();
                  await Hive.box('messages').clear();

                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Аккаунт удалён'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  context.go('/onboarding');
                },
                child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Выйти из аккаунта?'),
        content: const Text(
          'Вы выйдете из аккаунта, но ваши ключи и seed-фраза сохранятся. При следующем входе вам нужно будет только ввести пароль.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await Hive.box('settings').clear();
              await Hive.box('contacts').clear();
              await Hive.box('messages').clear();

              if (!context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Вы вышли из аккаунта'),
                  backgroundColor: Colors.orange,
                ),
              );
              context.go('/lock');
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final box = Hive.box('settings');
    final avatarId = box.get('profileAvatar', defaultValue: 'void');
    final customImage = box.get('customAvatar');
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
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 64,
            height: 64,
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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(avatars[avatarId] ?? '🔒', style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  String _getProfileName() =>
      Hive.box('settings').get('profileName', defaultValue: 'void');
  String _getProfileBio() =>
      Hive.box('settings').get('profileBio', defaultValue: 'Разработчик Veil');

  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/profile'),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getProfileName(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getProfileBio(),
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.qr_code, color: Color(0xFF6C5CE7)),
                    onPressed: () => context.go('/qr-display'),
                    tooltip: 'Мой QR-код',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6C5CE7)),
                    onPressed: () => context.go('/edit-profile'),
                    tooltip: 'Редактировать профиль',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      );

  Widget _buildCard(List<Widget> children) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: children),
        ),
      );

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) =>
      ListTile(
        leading: Icon(icon, color: textColor ?? const Color(0xFF6C5CE7)),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      );

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF6C5CE7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        value: value,
        activeColor: const Color(0xFF6C5CE7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onChanged: onChanged,
      );

  Widget _buildDivider() => const Divider(height: 1, indent: 72);

  Widget _buildLocaleTile(String currentLocale) {
    return ListTile(
      leading: const Icon(Icons.language, color: Color(0xFF6C5CE7)),
      title: const Text('Язык / Language'),
      subtitle: Text(currentLocale == 'ru' ? 'Русский' : 'English'),
      trailing: DropdownButton<String>(
        value: currentLocale,
        items: const [
          DropdownMenuItem(value: 'ru', child: Text('Русский')),
          DropdownMenuItem(value: 'en', child: Text('English')),
        ],
        onChanged: (value) {
          if (value != null) {
            Hive.box('settings').put('language', value);
            ref.read(localeProvider.notifier).setLocale(value);
            setState(() {});
          }
        },
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Сбросить личность?'),
        content: const Text(
            'Все ваши ключи, контакты и сообщения будут удалены. Seed-фраза вам больше не поможет. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await Hive.box('secure').clear();
              await Hive.box('settings').clear();
              await Hive.box('contacts').clear();
              await Hive.box('messages').clear();
              if (!mounted) return;
              Navigator.pop(ctx);
              context.go('/onboarding');
            },
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(VeilConstants.appName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Версия: ${VeilConstants.version}'),
            const SizedBox(height: 8),
            Text(
              '"${VeilConstants.tagline}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Создано 0xTima (void)\n\nZero Knowledge. Zero Trust.\nНикто не может прочитать ваши сообщения. Даже разработчик.',
              style: TextStyle(fontSize: 13),
            ),
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

  void _showApiDocs(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Документация API'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Доступные эндпоинты:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildApiDocRow('GET', '/wallet/balance?userId={id}', 'Получить баланс'),
              _buildApiDocRow('POST', '/wallet/transfer', 'Перевод средств'),
              _buildApiDocRow('GET', '/wallet/transactions?userId={id}', 'История транзакций'),
              _buildApiDocRow('POST', '/giftcard/create', 'Создать подарочную карту'),
              _buildApiDocRow('POST', '/giftcard/activate', 'Активировать карту'),
              const SizedBox(height: 16),
              const Text(
                'Аутентификация:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Добавьте заголовок: Authorization: Bearer {ваш_api_ключ}',
                style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11),
              ),
              const SizedBox(height: 16),
              const Text(
                'Полная документация:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'https://docs.veil.app/api',
                style: TextStyle(color: Color(0xFF6C5CE7)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/api-keys');
            },
            child: const Text('Перейти к ключам'),
          ),
        ],
      ),
    );
  }

  Widget _buildApiDocRow(String method, String endpoint, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: method == 'GET' ? Colors.green : const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endpoint,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Hive.box('settings').get('language', defaultValue: 'ru');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(context, l10n),
          const SizedBox(height: 16),

          _buildSectionTitle('Тарифы Veil'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(
              icon: Icons.stars,
              title: 'Тарифы Veil',
              subtitle: 'Управление подпиской',
              onTap: () => context.go('/subscription'),
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionTitle('Общее'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(
              icon: Icons.extension_outlined,
              title: 'Плагины',
              subtitle: 'Установка и управление',
              onTap: () => context.go('/plugins'),
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.help_outline,
              title: 'FAQ',
              subtitle: 'Часто задаваемые вопросы',
              onTap: () => context.go('/faq'),
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionTitle(l10n.settings),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(
              icon: Icons.lock_outline,
              title: 'Сменить пароль',
              subtitle: 'Изменить пароль входа',
              onTap: () => context.go('/change-password'),
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.verified_user,
              title: 'Кодовые слова',
              subtitle: 'Проверить безопасность чатов',
              onTap: () => context.go('/safety-words'),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.screenshot_monitor_outlined,
              title: 'Защита от скриншотов',
              subtitle: 'Запретить снимки экрана в чатах',
              value: _screenshotProtection,
              onChanged: _toggleScreenshotProtection,
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionTitle('Приложение'),
          const SizedBox(height: 8),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Тёмная тема',
              subtitle: 'Тёмное оформление приложения',
              value: _darkTheme,
              onChanged: _toggleDarkTheme,
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Уведомления',
              subtitle: 'Звук и всплывающие уведомления',
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                Hive.box('settings').put('notifications', val);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.start,
              title: 'Автозапуск',
              subtitle: 'Запускать при старте системы',
              value: _autoStart,
              onChanged: (val) {
                setState(() => _autoStart = val);
                Hive.box('settings').put('autoStart', val);
              },
            ),
            _buildDivider(),
            _buildLocaleTile(currentLocale),
          ]),
          const SizedBox(height: 16),

          _buildSectionTitle('Для разработчиков'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(
              icon: Icons.key,
              title: 'API доступ',
              subtitle: 'Управление API ключами (Dev/Pro)',
              onTap: () => context.go('/api-keys'),
            ),
            _buildTile(
  icon: Icons.smart_toy,
  title: 'Боты',
  subtitle: 'Создание и управление ботами',
  onTap: () => context.go('/bots'),
),
            _buildDivider(),
            _buildTile(
              icon: Icons.code,
              title: 'Документация API',
              subtitle: 'Документация для разработчиков',
              onTap: () => _showApiDocs(context),
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionTitle('О приложении'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(
              icon: Icons.info_outline,
              title: 'О Veil',
              subtitle: 'Версия ${VeilConstants.version}',
              onTap: () => _showAboutDialog(context),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionTitle('Опасная зона'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(
              icon: Icons.logout,
              title: 'Выйти из аккаунта',
              subtitle: 'Сохранить личность, очистить сессию',
              textColor: Colors.orange,
              onTap: _showLogoutDialog,
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.delete_forever,
              title: 'Сбросить личность',
              subtitle: 'Удалить все данные без пароля',
              textColor: Colors.orange,
              onTap: () => _showResetDialog(context),
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.person_remove,
              title: 'Удалить аккаунт',
              subtitle: 'Полное удаление с подтверждением пароля',
              textColor: Colors.red,
              onTap: _showDeleteAccountDialog,
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.card_giftcard,
              title: 'Подарочная карта Veil',
              subtitle: 'Оформить и просмотреть карту',
              onTap: () => context.go('/gift-card'),
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.account_balance_wallet,
              title: 'VeilBank',
              subtitle: 'Кошелёк, баланс, переводы',
              onTap: () => context.go('/wallet'),
            ),
            _buildDivider(),
            if (_isAdmin) ...[
              _buildTile(
                icon: Icons.cleaning_services,
                title: 'Очистить данные карт (админ)',
                subtitle: 'Удалить все заявки и карты',
                textColor: Colors.orange,
                onTap: () => _showClearCardsDialog(context),
              ),
              _buildDivider(),
            ],
            _buildTile(
              icon: Icons.admin_panel_settings,
              title: 'Управление ролями',
              subtitle: 'Администраторы, модераторы, бета-тестеры',
              onTap: () => context.go('/roles'),
            ),
            _buildDivider(),
            _buildTile(
              icon: Icons.notifications_active,
              title: 'Тест уведомлений',
              subtitle: 'Проверить работу уведомлений',
              onTap: () {
                NotificationService().testNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Тестовое уведомление отправлено!'),
                    backgroundColor: Color(0xFF6C5CE7),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}