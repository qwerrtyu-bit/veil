import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/identity_service.dart';
import '../core/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPinMode();
  }

  void _checkPinMode() {
    final box = Hive.box('settings');
    final pin = box.get('login_pin');
    if (pin != null && pin.toString().length == 4) {
      setState(() => _usePin = true);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _totpController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
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
      setState(() => _errorText = 'Повторите попытку позже');
      return;
    }

    final password = _passwordController.text;
    final totp = _totpController.text;

    if (password.length < VeilConstants.passwordMinLength) {
      setState(() => _errorText = 'Введите пароль');
      return;
    }

    if (totp.length != VeilConstants.totpDigits) {
      setState(() => _errorText = 'Введите 6-значный код');
      return;
    }

    final ok = await _identityService.checkPassword(password);
    if (!ok) {
      _block();
      return;
    }

    final totpSecret = await _identityService.getTotpSecret();
    if (totpSecret != null && !_identityService.verifyTotp(totpSecret, totp)) {
      _block();
      return;
    }

    _attempts = 0;
    _blockedUntil = null;
    _blockLevel = 0;
    if (!mounted) return;
    context.go('/chats');
  }

  void _block() {
    _attempts++;
    if (_blockLevel == 0 && _attempts >= 5) {
      _blockLevel = 1;
      _blockedUntil = DateTime.now().add(const Duration(minutes: 1));
      setState(() => _errorText = 'Повторите попытку позже');
    } else if (_blockLevel == 1 && _attempts >= 10) {
      _blockLevel = 2;
      _blockedUntil = DateTime.now().add(const Duration(minutes: 2));
      setState(() => _errorText = 'Повторите попытку позже');
    } else if (_blockLevel == 2 && _attempts >= 15) {
      _blockLevel = 3;
      _blockedUntil = DateTime.now().add(const Duration(hours: 1));
      setState(() => _errorText = 'Повторите попытку позже');
    } else if (_blockLevel == 3 && _attempts >= 20) {
      _blockLevel = 4;
      _blockedUntil = DateTime.now().add(const Duration(hours: 24));
      setState(() => _errorText = 'Повторите попытку позже');
    } else {
      setState(() => _errorText = 'Неверный пароль или код');
    }
  }

  void _setupPin() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Настроить быстрый вход'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Придумайте 4-значный пин-код для быстрого входа без пароля и 2FA.'),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
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
                Text('Вход в Veil', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(_usePin ? 'Введите пин-код' : 'Введите пароль и код 2FA',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
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
                      hintText: 'Пароль',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _totpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'Код 2FA',
                      prefixIcon: Icon(Icons.security),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _setupPin,
                    child: const Text('Настроить быстрый вход (пин)', style: TextStyle(fontSize: 12)),
                  ),
                ],

                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _unlock, child: const Text('Войти')),
                ),
                const SizedBox(height: 16),
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
                  child: Text('Сбросить личность', style: TextStyle(color: Colors.red[400])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}