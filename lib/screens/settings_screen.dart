import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../app.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  void _toggleDarkTheme(bool value) {
    setState(() => _darkTheme = value);
    themeNotifier.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/chats')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(context),
          const SizedBox(height: 16),
          _buildSectionTitle('Безопасность'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(icon: Icons.lock_outline, title: 'Сменить пароль', subtitle: 'Изменить пароль входа', onTap: () => context.go('/change-password')),
            _buildDivider(),
            _buildTile(icon: Icons.verified_user, title: 'Кодовые слова', subtitle: 'Проверить безопасность чатов', onTap: () => context.go('/safety-words')),
            _buildDivider(),
            _buildSwitchTile(icon: Icons.screenshot_monitor_outlined, title: 'Защита от скриншотов', subtitle: 'Запретить снимки экрана в чатах', value: _screenshotProtection, onChanged: (val) { setState(() => _screenshotProtection = val); Hive.box('settings').put('screenshotProtection', val); }),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Приложение'),
          const SizedBox(height: 8),
          _buildCard([
            _buildSwitchTile(icon: Icons.dark_mode, title: 'Тёмная тема', subtitle: 'Тёмное оформление приложения', value: _darkTheme, onChanged: _toggleDarkTheme),
            _buildDivider(),
            _buildSwitchTile(icon: Icons.notifications_outlined, title: 'Уведомления', subtitle: 'Звук и всплывающие уведомления', value: _notificationsEnabled, onChanged: (val) { setState(() => _notificationsEnabled = val); Hive.box('settings').put('notifications', val); }),
            _buildDivider(),
            _buildSwitchTile(icon: Icons.start, title: 'Автозапуск', subtitle: 'Запускать при старте системы', value: _autoStart, onChanged: (val) { setState(() => _autoStart = val); Hive.box('settings').put('autoStart', val); }),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('О приложении'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(icon: Icons.info_outline, title: 'О Veil', subtitle: 'Версия ${VeilConstants.version}', onTap: () => _showAboutDialog(context)),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Опасная зона'),
          const SizedBox(height: 8),
          _buildCard([
            _buildTile(icon: Icons.delete_forever, title: 'Сбросить личность', subtitle: 'Удалить все данные', textColor: Colors.red, onTap: () => _showResetDialog(context)),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/profile'),
          child: Row(children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)]), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(_getAvatarEmoji(), style: const TextStyle(fontSize: 28)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_getProfileName(), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text(_getProfileBio(), style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ])),
            Column(children: [
              IconButton(icon: const Icon(Icons.qr_code, color: Color(0xFF6C5CE7)), onPressed: () => context.go('/qr-display'), tooltip: 'Мой QR-код'),
              IconButton(icon: const Icon(Icons.edit, color: Color(0xFF6C5CE7)), onPressed: () => context.go('/edit-profile'), tooltip: 'Редактировать профиль'),
            ]),
          ]),
        ),
      ),
    );
  }

  String _getAvatarEmoji() {
    final box = Hive.box('settings');
    final avatarId = box.get('profileAvatar', defaultValue: 'void');
    const avatars = {'void': '🔒', 'ghost': '👻', 'ninja': '🥷', 'hacker': '💻', 'mask': '🎭', 'eye': '👁️', 'fire': '🔥', 'star': '⭐'};
    return avatars[avatarId] ?? '🔒';
  }

  String _getProfileName() => Hive.box('settings').get('profileName', defaultValue: 'void');
  String _getProfileBio() => Hive.box('settings').get('profileBio', defaultValue: 'Разработчик Veil');

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(left: 4), child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)));
  Widget _buildCard(List<Widget> children) => Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: children)));
  Widget _buildTile({required IconData icon, required String title, required String subtitle, Color? textColor, required VoidCallback onTap}) => ListTile(leading: Icon(icon, color: textColor ?? const Color(0xFF6C5CE7)), title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)), subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)), trailing: const Icon(Icons.chevron_right, size: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onTap: onTap);
  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) => SwitchListTile(secondary: Icon(icon, color: const Color(0xFF6C5CE7)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)), subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)), value: value, activeColor: const Color(0xFF6C5CE7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onChanged: onChanged);
  Widget _buildDivider() => const Divider(height: 1, indent: 72);

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Сбросить личность?'),
        content: const Text('Все ваши ключи, контакты и сообщения будут удалены. Seed-фраза вам больше не поможет. Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(onPressed: () async { await Hive.box('secure').clear(); await Hive.box('settings').clear(); await Hive.box('contacts').clear(); await Hive.box('messages').clear(); if (!mounted) return; Navigator.pop(ctx); context.go('/onboarding'); }, child: const Text('Сбросить', style: TextStyle(color: Colors.red))),
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
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Версия: ${VeilConstants.version}'), const SizedBox(height: 8),
          Text('"${VeilConstants.tagline}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600])), const SizedBox(height: 16),
          const Text('Создано 0xTima (void)\n\nZero Knowledge. Zero Trust.\nНикто не может прочитать ваши сообщения. Даже разработчик.', style: TextStyle(fontSize: 13)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть'))],
      ),
    );
  }
}