// lib/screens/seed_display_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/identity_service.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';

class SeedDisplayScreen extends ConsumerStatefulWidget {
  const SeedDisplayScreen({super.key});

  @override
  ConsumerState<SeedDisplayScreen> createState() => _SeedDisplayScreenState();
}

class _SeedDisplayScreenState extends ConsumerState<SeedDisplayScreen> {
  final _identityService = IdentityService();
  List<String> _seedWords = [];
  bool _isLoading = true;
  bool _isConfirmed = false;
  String _totpSecret = '';
  bool _showQr = false;

  @override
  void initState() {
    super.initState();
    _generateSeed();
  }

  Future<void> _generateSeed() async {
    final words = _identityService.generateSeedPhrase();
    setState(() {
      _seedWords = words;
      _isLoading = false;
    });
  }

  Future<void> _confirmAndGenerateKeys() async {
    print('1. Нажата кнопка');
    setState(() => _isConfirmed = true);

    print('2. Генерация ключей');
    final keyPair = _identityService.generateKeyPair(_seedWords);
    print('3. Ключи сгенерированы');

    await _identityService.saveKeyPair(
      keyPair['publicKey']!,
      keyPair['privateKey']!,
    );
    print('4. Ключи сохранены');

    await _identityService.saveSeedPhrase(_seedWords.join(' '));
    print('5. Seed-фраза сохранена');

    await _identityService.setHasIdentity(true);
    print('6. HasIdentity установлен');

    _totpSecret = _identityService.generateTotpSecret();
    print('7. TOTP-секрет сгенерирован: $_totpSecret');

    await _identityService.saveTotpSecret(_totpSecret);
    print('8. TOTP-секрет сохранён');

    if (!mounted) return;
    print('9. Устанавливаем _showQr = true');
    setState(() => _showQr = true);
    print('10. _showQr = true');
  }

  void _copySeed() {
    final seedText = _seedWords.join(' ');
    Clipboard.setData(ClipboardData(text: seedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seed-фраза скопирована'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  String _generateTotpUri() {
    return 'otpauth://totp/Veil:user?secret=$_totpSecret&issuer=Veil';
  }

  void _goToProfileSetup() {
    context.go('/setup-profile');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_showQr) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Настройка 2FA'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/onboarding'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Настройте двухфакторную аутентификацию',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Отсканируйте QR-код в приложении Google Authenticator.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _generateTotpUri(),
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Или введите код вручную:',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: SelectableText(
                    _totpSecret,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _totpSecret));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ключ скопирован'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Копировать ключ'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _goToProfileSetup,
                    child: const Text('Готово, настроить профиль'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed-фраза'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copySeed,
            tooltip: 'Скопировать',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Запишите эти ${VeilConstants.seedWordCount} слов на бумагу и храните в надёжном месте. Без них вы не сможете восстановить доступ.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.red[700],
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ваша seed-фраза',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '24 слова в правильном порядке. Никому не показывайте.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _seedWords.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${index + 1}.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _seedWords[index],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'SpaceMono',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Если вы потеряете seed-фразу, доступ к личности будет невозможен. Veil не хранит seed-фразы на серверах.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.orange[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmAndGenerateKeys,
                      child: const Text('Я записал(а) seed-фразу'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}