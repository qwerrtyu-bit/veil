import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/identity_service.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import '../services/admin_service.dart';
class RestoreIdentityScreen extends ConsumerStatefulWidget {
  const RestoreIdentityScreen({super.key});

  @override
  ConsumerState<RestoreIdentityScreen> createState() => _RestoreIdentityScreenState();
}

class _RestoreIdentityScreenState extends ConsumerState<RestoreIdentityScreen> {
  final List<TextEditingController> _wordControllers = [];
  final _identityService = IdentityService();
  String? _errorText;
  bool _isRestoring = false;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPasswordFields = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < VeilConstants.seedWordCount; i++) {
      _wordControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var c in _wordControllers) {
      c.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _verifySeed() {
    final l10n = AppLocalizations.of(context)!;
    final words = _wordControllers.map((c) => c.text.trim().toLowerCase()).toList();

    if (words.any((w) => w.isEmpty)) {
      setState(() {
        _errorText = 'Заполните все ${VeilConstants.seedWordCount} слов';
      });
      return;
    }

    if (!_identityService.isValidSeedPhrase(words)) {
      setState(() {
        _errorText = 'Неверная seed-фраза. Проверьте слова и порядок.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _showPasswordFields = true;
    });
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final words = _wordControllers.map((c) => c.text.trim().toLowerCase()).toList();

    if (!_identityService.isValidSeedPhrase(words)) {
      setState(() {
        _errorText = 'Неверная seed-фраза. Проверьте слова и порядок.';
        _showPasswordFields = false;
      });
      return;
    }

    if (password.length < VeilConstants.passwordMinLength) {
      setState(() {
        _errorText = 'Пароль должен быть не менее ${VeilConstants.passwordMinLength} символов';
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorText = 'Пароли не совпадают';
      });
      return;
    }

    setState(() {
      _isRestoring = true;
      _errorText = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    final seedPhrase = words.join(' ');
    await _identityService.saveSeedPhrase(seedPhrase);
    await _identityService.setHasIdentity(true);
    await _identityService.savePassword(password);

    final keyPair = _identityService.generateKeyPair(words);
    await _identityService.saveKeyPair(keyPair['publicKey']!, keyPair['privateKey']!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Личность восстановлена!'),
        backgroundColor: Colors.green,
      ),
    );

    context.go('/lock');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showPasswordFields) {
              setState(() {
                _showPasswordFields = false;
              });
            } else {
              context.go('/onboarding');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Восстановление личности',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Введите вашу seed-фразу из ${VeilConstants.seedWordCount} слов в правильном порядке.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 24),

              if (!_showPasswordFields) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: VeilConstants.seedWordCount,
                  itemBuilder: (context, index) {
                    return TextField(
                      controller: _wordControllers[index],
                      decoration: InputDecoration(
                        hintText: '${index + 1}',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_errorText != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifySeed,
                    child: const Text('Продолжить'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Скопируйте seed-фразу в буфер и вставьте'),
                        ),
                      );
                    },
                    child: const Text('Вставить из буфера'),
                  ),
                ),
              ] else ...[
                Text(
                  'Придумайте новый пароль',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Этот пароль будет защищать вашу восстановленную личность.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Новый пароль (минимум 8 символов)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Подтвердите пароль',
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isRestoring ? null : _restore,
                    child: _isRestoring
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Восстановить личность'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}