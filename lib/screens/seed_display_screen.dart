import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/identity_service.dart';
import '../core/constants.dart';

class SeedDisplayScreen extends ConsumerStatefulWidget {
  const SeedDisplayScreen({super.key});

  @override
  ConsumerState<SeedDisplayScreen> createState() => _SeedDisplayScreenState();
}

class _SeedDisplayScreenState extends ConsumerState<SeedDisplayScreen> {
  final _identityService = IdentityService();
  List<String> _seedWords = [];
  String _totpSecret = '';
  bool _isLoading = true;
  bool _hasCopied = false;
  bool _showTotp = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final words = _identityService.generateSeedPhrase();
    final secret = _identityService.generateTotpSecret();

    setState(() {
      _seedWords = words;
      _totpSecret = secret;
      _isLoading = false;
    });
  }

  Future<void> _saveIdentity() async {
    final secureStorage = Hive.box('secure');

    await secureStorage.put('has_identity', 'true');
    await secureStorage.put('seed_phrase', _seedWords.join(' '));
    await _identityService.saveTotpSecret(_totpSecret);

    final keyPair = _identityService.generateKeyPair(_seedWords);
    await _identityService.saveKeyPair(keyPair['publicKey']!, keyPair['privateKey']!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Личность создана!'),
        backgroundColor: Colors.green,
      ),
    );

    context.go('/lock');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/create-identity'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ЗАПИШИТЕ эти слова на бумагу. Это единственный способ восстановить доступ.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange[800],
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Ваша seed-фраза', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${VeilConstants.seedWordCount} слов. Порядок важен.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _seedWords.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}. ${_seedWords[index]}',
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () => setState(() => _showTotp = !_showTotp),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.security, color: Color(0xFF6C5CE7), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Двухфакторная аутентификация (2FA)',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6C5CE7),
                                      ),
                                ),
                                const Spacer(),
                                Icon(_showTotp ? Icons.expand_less : Icons.expand_more,
                                    color: const Color(0xFF6C5CE7)),
                              ],
                            ),
                            if (_showTotp) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Отсканируйте этот код в Google Authenticator или Aegis:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: QrImageView(
                                    data: 'otpauth://totp/Veil?secret=$_totpSecret&issuer=Veil&algorithm=SHA1&digits=6&period=30',
                                    version: QrVersions.auto,
                                    size: 180,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Или введите код вручную:',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0B0D17) : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _totpSecret,
                                  style: GoogleFonts.spaceMono(fontSize: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveIdentity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Я записал(а), продолжить'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _seedWords.join(' ')));
                          setState(() => _hasCopied = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seed-фраза скопирована'),
                              backgroundColor: Color(0xFF6C5CE7),
                            ),
                          );
                        },
                        child: Text(_hasCopied ? 'Скопировано' : 'Скопировать в буфер'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}