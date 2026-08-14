import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/identity_service.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _usePin = false;
  String? _errorText;
  final _identityService = IdentityService();
  int _attempts = 0;
  DateTime? _blockedUntil;
  int _blockLevel = 0;
  bool _hasTotp = false;

  @override
  void initState() {
    super.initState();
    _checkPinMode();
    _checkTotp();
  }

  void _checkPinMode() {
    final box = Hive.box('settings');
    final pin = box.get('login_pin');
    if (pin != null && pin.toString().length == 4) {
      setState(() => _usePin = true);
    }
  }

  Future<void> _checkTotp() async {
    final totpSecret = await _identityService.getTotpSecret();
    setState(() => _hasTotp = totpSecret != null && totpSecret.isNotEmpty);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _totpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final l10n = AppLocalizations.of(context)!;

    if (_usePin) {
      final pin = _pinController.text;
      final savedPin = Hive.box('settings').get('login_pin')?.toString();
      if (pin == savedPin) {
        if (!mounted) return;
        context.go('/chats');
      } else {
        setState(() => _errorText = 'Неверный пин-код');
      }
      return;
    }

    if (_blockedUntil != null && DateTime.now().isBefore(_blockedUntil!)) {
      setState(() => _errorText = l10n.tryLater);
      return;
    }

    final password = _passwordController.text;
    final totp = _totpController.text;

    if (password.isEmpty || password.length < VeilConstants.passwordMinLength) {
      setState(() => _errorText = l10n.enterPassword);
      return;
    }

    if (_hasTotp) {
      if (totp.isEmpty || totp.length != VeilConstants.totpDigits) {
        setState(() => _errorText = l10n.enterCode);
        return;
      }
    }

    final isPasswordCorrect = await _identityService.checkPassword(password);
    if (!isPasswordCorrect) {
      _block();
      return;
    }

    if (_hasTotp) {
      final totpSecret = await _identityService.getTotpSecret();
      if (totpSecret == null || !_identityService.verifyTotp(totpSecret, totp)) {
        _block();
        return;
      }
    }

    _attempts = 0;
    _blockedUntil = null;
    _blockLevel = 0;
    if (!mounted) return;
    context.go('/chats');
  }

  void _block() {
    final l10n = AppLocalizations.of(context)!;
    _attempts++;
    if (_blockLevel == 0 && _attempts >= 5) {
      _blockLevel = 1;
      _blockedUntil = DateTime.now().add(const Duration(minutes: 1));
      setState(() => _errorText = l10n.tryLater);
    } else if (_blockLevel == 1 && _attempts >= 10) {
      _blockLevel = 2;
      _blockedUntil = DateTime.now().add(const Duration(minutes: 2));
      setState(() => _errorText = l10n.tryLater);
    } else if (_blockLevel == 2 && _attempts >= 15) {
      _blockLevel = 3;
      _blockedUntil = DateTime.now().add(const Duration(hours: 1));
      setState(() => _errorText = l10n.tryLater);
    } else if (_blockLevel == 3 && _attempts >= 20) {
      _blockLevel = 4;
      _blockedUntil = DateTime.now().add(const Duration(hours: 24));
      setState(() => _errorText = l10n.tryLater);
    } else {
      setState(() => _errorText = l10n.wrongPassword);
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Восстановить личность?'),
        content: const Text(
          'Вы будете перенаправлены на экран восстановления. Все текущие данные будут сброшены.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Hive.box('secure').clear();
              await Hive.box('settings').clear();
              await Hive.box('contacts').clear();
              await Hive.box('messages').clear();
              if (!mounted) return;
              context.go('/onboarding');
            },
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );
  }

  void _setupPin() {
    final pinController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(l10n.setupPin),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Придумайте 4-значный пин-код для быстрого входа.'),
          const SizedBox(height: 12),
          TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Пин-код'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              final pin = pinController.text;
              if (pin.length == 4) {
                Hive.box('settings').put('login_pin', pin);
                Navigator.pop(ctx);
                setState(() => _usePin = true);
              }
            },
            child: const Text('Сохранить', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_outline_rounded, size: 40, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 24),
                Text(l10n.login, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  _usePin 
                    ? l10n.loginPin 
                    : _hasTotp 
                      ? 'Введите пароль и код 2FA' 
                      : 'Введите пароль',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                if (_usePin) ...[
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Пин-код (4 цифры)',
                      prefixIcon: Icon(Icons.pin),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _usePin = false),
                    child: const Text('Войти с паролем', style: TextStyle(fontSize: 12)),
                  ),
                ] else ...[
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: l10n.enterPassword,
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (_hasTotp) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _totpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: 'Код 2FA (6 цифр)',
                        prefixIcon: Icon(Icons.security),
                        counterText: '',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _setupPin,
                    child: Text(l10n.setupPin, style: const TextStyle(fontSize: 12)),
                  ),
                ],

                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _unlock, child: Text(l10n.login)),
                ),
                const SizedBox(height: 12),
                // ============================================================
                // КНОПКА ВОССТАНОВЛЕНИЯ
                // ============================================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _showResetDialog,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6C5CE7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Восстановить личность',
                      style: TextStyle(color: Color(0xFF6C5CE7)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    _attempts = 0;
                    _blockedUntil = null;
                    _blockLevel = 0;
                    await Hive.box('secure').clear();
                    await Hive.box('settings').clear();
                    await Hive.box('contacts').clear();
                    await Hive.box('messages').clear();
                    if (!mounted) return;
                    context.go('/onboarding');
                  },
                  child: Text(l10n.resetIdentity, style: TextStyle(color: Colors.red[400])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}