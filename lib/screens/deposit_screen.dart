import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/wallet_provider.dart';
import '../data/identity_service.dart';
import '../services/balance_sync_service.dart';
import '../l10n/app_localizations.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'card';
  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'card', 'icon': Icons.credit_card, 'label': 'Банковская карта', 'color': Color(0xFF3B82F6)},
    {'id': 'sbp', 'icon': Icons.qr_code, 'label': 'СБП (Россия)', 'color': Color(0xFF10B981)},
    {'id': 'crypto', 'icon': Icons.currency_bitcoin, 'label': 'Криптовалюта', 'color': Color(0xFFF59E0B)},
    {'id': 'gift', 'icon': Icons.card_giftcard, 'label': 'Подарочная карта Veil', 'color': Color(0xFF6C5CE7)},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _deposit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorText = 'Введите сумму');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Введите корректную сумму');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _successText = null;
    });

    try {
      final identityService = IdentityService();
      final publicKey = await identityService.getPublicKey();

      if (publicKey == null) {
        setState(() {
          _errorText = 'Личность не найдена';
          _isLoading = false;
        });
        return;
      }

      // Добавляем VLC локально
      ref.read(walletProvider.notifier).addVlc(
            amount,
            'Пополнение через ${_methods.firstWhere((m) => m['id'] == _selectedMethod)['label']}',
          );

      // Синхронизируем с сервером
      await BalanceSyncService.addVlcAndSync(
        publicKey,
        amount,
        'Пополнение через ${_methods.firstWhere((m) => m['id'] == _selectedMethod)['label']}',
      );

      setState(() {
        _isLoading = false;
        _successText = '✅ Баланс пополнен на ${amount.toStringAsFixed(2)} VLC';
        _amountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Баланс пополнен на ${amount.toStringAsFixed(2)} VLC'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/wallet');
        }
      });

    } catch (e) {
      setState(() {
        _errorText = '❌ Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Пополнение баланса'),
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
            // Сумма
            Text(
              'Сумма пополнения',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Введите сумму',
                prefixIcon: const Icon(Icons.currency_ruble),
                suffixText: '₽',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [100, 500, 1000, 5000].map((amount) {
                return ActionChip(
                  label: Text('$amount ₽'),
                  onPressed: () {
                    setState(() {
                      _amountController.text = amount.toString();
                    });
                  },
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Способ пополнения
            Text(
              'Способ пополнения',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._methods.map((method) {
              final isSelected = _selectedMethod == method['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = method['id']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? method['color'].withOpacity(0.08)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? method['color'] : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: method['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          method['icon'],
                          color: isSelected ? method['color'] : Colors.grey[400],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method['label'],
                          style: TextStyle(
                            color: isSelected ? method['color'] : null,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: method['color'],
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Информация о комиссии
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
                      'Комиссия за пополнение: 0%. Средства зачисляются мгновенно.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
                child: Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],

            if (_successText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successText!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _deposit,
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
                    : const Text('Пополнить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}