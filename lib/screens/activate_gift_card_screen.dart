import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/gift_card_request_service.dart';
import '../providers/wallet_provider.dart';
import '../data/identity_service.dart';

class ActivateGiftCardScreen extends ConsumerStatefulWidget {
  const ActivateGiftCardScreen({super.key});

  @override
  ConsumerState<ActivateGiftCardScreen> createState() =>
      _ActivateGiftCardScreenState();
}

class _ActivateGiftCardScreenState extends ConsumerState<ActivateGiftCardScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  String? _successMessage;

  final _giftService = GiftCardRequestService();

  Future<void> _activate() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _errorText = 'Введите код подарочной карты');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _successMessage = null;
    });

    final card = _giftService.getCardByCode(code);

    if (card == null) {
      setState(() {
        _errorText = 'Неверный код или карта уже активирована';
        _isLoading = false;
      });
      return;
    }

    final identityService = IdentityService();
    final publicKey = await identityService.getPublicKey();

    if (publicKey == null) {
      setState(() {
        _errorText = 'Ошибка: личность не найдена';
        _isLoading = false;
      });
      return;
    }

    final success = _giftService.activateCard(code, publicKey);

    if (success == false) {
      setState(() {
        _errorText = 'Ошибка активации. Попробуйте позже.';
        _isLoading = false;
      });
      return;
    }

    ref.read(walletProvider.notifier).addVlc(
          card.amount,
          'Активация подарочной карты (${card.firstName} ${card.lastName})',
        );

    // ✅ ИСПРАВЛЕНО
    if (mounted == false) return;

    setState(() {
      _isLoading = false;
      _successMessage = 'Карта активирована! +${card.amount.toStringAsFixed(2)} VLC';
      _codeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Карта активирована! +${card.amount.toStringAsFixed(2)} VLC'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      // ✅ ИСПРАВЛЕНО
      if (mounted == false) return;
      context.go('/wallet');
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Активация подарочной карты'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '💳 Введите код подарочной карты',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Код вы получаете после оформления заявки.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 20,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX-XXXX',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.card_giftcard),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Активировать'),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Подарочные карты Veil выдаются только после оформления заявки.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
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
}