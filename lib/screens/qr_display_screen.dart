// lib/screens/qr_display_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/identity_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/profile_card.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  const QrDisplayScreen({super.key});

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen> {
  final _identityService = IdentityService();
  String _publicKey = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _identityService.getPublicKey();
    setState(() {
      _publicKey = key ?? 'Ключ не найден';
      _isLoading = false;
    });
  }

  void _shareQr() {
    final shareText = '''
Veil — говори свободно.

Мой публичный ключ:
$_publicKey

Добавь меня в Veil:
veil://add?key=$_publicKey

Скачать Veil: https://github.com/qwerrtyu-bit/veil
''';

    Share.share(shareText);
  }

  void _copyKey() {
    Clipboard.setData(ClipboardData(text: _publicKey));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ключ скопирован'),
        backgroundColor: Color(0xFF6C5CE7),
      ),
    );
  }

  void _shareToTelegram() {
    final url = 'https://t.me/share/url?url=veil://add?key=$_publicKey';
    _launchUrl(url);
  }

  void _shareToWhatsApp() {
    final url = 'https://api.whatsapp.com/send?text=veil://add?key=$_publicKey';
    _launchUrl(url);
  }

  void _shareToViber() {
    final url = 'viber://forward?text=veil://add?key=$_publicKey';
    _launchUrl(url);
  }

  void _shareToMax() {
    final shareText = Uri.encodeComponent('veil://add?key=$_publicKey');
    final url = 'https://max.ru/:share?text=$shareText';
    _launchUrl(url);
  }

  void _shareToEmail() {
    final subject = Uri.encodeComponent('Veil — добавь меня в контакты');
    final body = Uri.encodeComponent('veil://add?key=$_publicKey');
    final url = 'mailto:?subject=$subject&body=$body';
    _launchUrl(url);
  }

  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: _publicKey));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ссылка не открылась. Ключ скопирован в буфер.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Clipboard.setData(ClipboardData(text: _publicKey));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ссылка не открылась. Ключ скопирован в буфер.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _shareProfileCard() {
    final settingsBox = Hive.box('settings');
    final displayName = settingsBox.get('profileName', defaultValue: 'void');
    final displayBio = settingsBox.get('profileBio', defaultValue: 'Разработчик Veil');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ProfileCard(
          publicKey: _publicKey,
          displayName: displayName,
          displayBio: displayBio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой QR-код'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chats'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQr,
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Покажите этот код собеседнику',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // QR-код
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _publicKey,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Публичный ключ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _publicKey.length > 40
                                ? '${_publicKey.substring(0, 20)}…${_publicKey.substring(_publicKey.length - 20)}'
                                : _publicKey,
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: _copyKey,
                          tooltip: 'Копировать ключ',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Кнопки шеринга
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _shareQr,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Поделиться'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _copyKey,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Копировать'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _shareProfileCard,
                        icon: const Icon(Icons.credit_card_outlined, size: 18),
                        label: const Text('Карточка Veil'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6C5CE7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Отправить в мессенджер:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: '💬',
                        label: 'Telegram',
                        onTap: _shareToTelegram,
                        color: const Color(0xFF0088CC),
                      ),
                      _buildSocialButton(
                        icon: '💬',
                        label: 'WhatsApp',
                        onTap: _shareToWhatsApp,
                        color: const Color(0xFF25D366),
                      ),
                      _buildSocialButton(
                        icon: '💬',
                        label: 'Viber',
                        onTap: _shareToViber,
                        color: const Color(0xFF7360F2),
                      ),
                      _buildSocialButton(
                        icon: '💬',
                        label: 'MAX',
                        onTap: _shareToMax,
                        color: const Color(0xFF00B4D8),
                      ),
                      _buildSocialButton(
                        icon: '✉️',
                        label: 'Email',
                        onTap: _shareToEmail,
                        color: const Color(0xFFEA4335),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Ссылка для добавления
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Ссылка для добавления в Veil:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          'veil://add?key=$_publicKey',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 11,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}