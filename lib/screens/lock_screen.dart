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
  bool _obscurePassword = true;
  String? _errorText;
  final _identityService = IdentityService();

  @override
  void dispose() {
    _passwordController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
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

    final isPasswordCorrect = await _identityService.checkPassword(password);
    if (!isPasswordCorrect) {
      setState(() => _errorText = 'Неверный пароль');
      return;
    }

    final totpSecret = await _identityService.getTotpSecret();
    if (totpSecret != null && !_identityService.verifyTotp(totpSecret, totp)) {
      setState(() => _errorText = 'Неверный код 2FA');
      return;
    }

    if (!mounted) return;
    context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFF6C5CE7)),
                ),
                const SizedBox(height: 24),
                Text('Вход в Veil', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Введите пароль и код 2FA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
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
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _unlock,
                    child: const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
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