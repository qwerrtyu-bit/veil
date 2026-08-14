import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/wallet_provider.dart';
import '../l10n/app_localizations.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _keyController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  static const double _fee = 0.1;

  void _transfer() {
    final key = _keyController.text.trim();
    final amountText = _amountController.text.trim();

    if (key.isEmpty) {
      setState(() => _errorText = 'Введите публичный ключ получателя');
      return;
    }

    if (key.length < 32) {
      setState(() => _errorText = 'Неверный формат публичного ключа');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
      return;
    }

    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    // Проверяем баланс
    final walletState = ref.read(walletProvider);
    final totalNeeded = amount + _fee;

    if (walletState.vlcBalance < totalNeeded) {
      setState(() {
        _errorText = 'Недостаточно средств (нужно ${totalNeeded.toStringAsFixed(2)} VLC с учётом комиссии)';
        _isLoading = false;
      });
      return;
    }

    // Имитация перевода
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ref.read(walletProvider.notifier).transferVlc(
            key,
            amount,
            description: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : 'Перевод пользователю',
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Перевод выполнен успешно!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/wallet');
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletProvider);
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0;
    final totalWithFee = amount > 0 ? amount + _fee : 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Перевод VLC'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/wallet'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Баланс
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Доступно:',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '${walletState.vlcBalance.toStringAsFixed(2)} VLC',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Получатель
            Text(
              'Получатель',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Публичный ключ получателя',
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // TODO: QR-сканер для ключа
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR-сканер будет добавлен позже'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Сумма
            Text(
              'Сумма',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Введите сумму',
                prefixIcon: Icon(Icons.currency_ruble),
                suffixText: 'VLC',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Комиссия
            if (amount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Комиссия:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    '${_fee.toStringAsFixed(2)} VLC',
                    style: const TextStyle(fontSize: 13, fontFamily: 'SpaceMono'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Итого:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${totalWithFee.toStringAsFixed(2)} VLC',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SpaceMono',
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Примечание
            Text(
              'Примечание (необязательно)',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Что это за перевод?',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),

            if (_errorText != null)
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
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Информация
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
                      'Комиссия 0.1 VLC за перевод. Максимум 500 VLC за один перевод, до 5 переводов в день.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _transfer,
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
                    : const Text('Отправить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}