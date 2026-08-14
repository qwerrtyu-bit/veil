import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/gift_card_request.dart';
import '../data/identity_service.dart';
import '../providers/wallet_provider.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';

class GiftCardScreen extends ConsumerStatefulWidget {
  const GiftCardScreen({super.key});

  @override
  ConsumerState<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends ConsumerState<GiftCardScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _amountController = TextEditingController();

  GiftCardRequest? _card;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorText;
  String? _successMessage;
  String? _cardCode;
  double _cardAmount = 0;
  String _cardRecipient = '';

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
  setState(() => _isLoading = true);
  try {
    final identityService = IdentityService();
    final publicKey = await identityService.getPublicKey();

    if (publicKey != null) {
      final box = Hive.box('gift_requests');
      final cards = box.get('cards');
      
      if (cards is List && cards.isNotEmpty) {
        // Правильно приводим Map
        final lastCardRaw = cards.last as Map;
        final lastCard = Map<String, dynamic>.from(lastCardRaw);
        
        if (lastCard['status'] == 'active') {
          setState(() {
            _cardCode = lastCard['giftCardCode']?.toString();
            _cardAmount = (lastCard['amount'] as num).toDouble();
            _cardRecipient = '${lastCard['firstName'] ?? ''} ${lastCard['lastName'] ?? ''}'.trim();
            _card = GiftCardRequest.fromJson(lastCard);
          });
        }
      }
    }
  } catch (e) {
    print('❌ Ошибка загрузки карты: $e');
  }
  setState(() => _isLoading = false);
}

  Future<void> _createGiftCard() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final amountText = _amountController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorText = 'Заполните имя и фамилию');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 10 || amount > 10000) {
      setState(() => _errorText = 'Сумма должна быть от 10 до 10000 VLC');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final identityService = IdentityService();
      final publicKey = await identityService.getPublicKey();

      if (publicKey == null) {
        setState(() {
          _errorText = 'Ошибка: личность не найдена';
          _isSubmitting = false;
        });
        return;
      }

      // Запрос к серверу
      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/giftcard/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'recipient': '$firstName $lastName',
          'publicKey': publicKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cardData = data['card'] as Map;

        setState(() {
          _cardCode = cardData['code'];
          _cardAmount = (cardData['amount'] as num).toDouble();
          _cardRecipient = cardData['recipient'];
          _isSubmitting = false;
          _firstNameController.clear();
          _lastNameController.clear();
          _amountController.clear();
          _successMessage = '✅ Карта создана! Код: ${cardData['code']}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Карта создана! Код: ${cardData['code']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorText = 'Ошибка создания карты';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Ошибка сети: $e';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _activateGiftCard(String code) async {
    try {
      final identityService = IdentityService();
      final publicKey = await identityService.getPublicKey();

      if (publicKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка: личность не найдена'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/giftcard/activate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'userId': publicKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final amount = (data['amount'] as num).toDouble();

        // Обновляем баланс локально
        ref.read(walletProvider.notifier).addVlc(
          amount,
          'Активация подарочной карты',
        );

        setState(() {
          _card = null;
          _cardCode = null;
          _successMessage = '✅ Карта активирована! +$amount VLC';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Карта активирована! +$amount VLC'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка активации карты'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сети: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyCode() {
    if (_cardCode == null) return;
    Clipboard.setData(ClipboardData(text: _cardCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Код скопирован'),
        backgroundColor: Color(0xFF6C5CE7),
      ),
    );
  }

  void _showQRDialog() {
    if (_cardCode == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR-код карты',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _cardCode!,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _cardCode!,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Копировать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _activateGiftCard(_cardCode!);
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Активировать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ============================================================
    // ЕСТЬ АКТИВНАЯ КАРТА
    // ============================================================
    if (_cardCode != null && _card != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Подарочная карта'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/wallet'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Анимированная карта
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: _buildCard(theme, isDark),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showQRDialog,
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('Показать QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Копировать код'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _card = null;
                      _cardCode = null;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Создать новую карту'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ============================================================
    // ФОРМА СОЗДАНИЯ КАРТЫ
    // ============================================================
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Подарочная карта'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/wallet'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Создайте подарочную карту',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Получите код для активации',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Форма
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Имя получателя',
                hintText: 'Иван',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия получателя',
                hintText: 'Петров',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Сумма (VLC)',
                hintText: '100',
                prefixIcon: Icon(Icons.currency_ruble),
                suffixText: 'VLC',
                helperText: 'От 10 до 10000 VLC',
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
                onPressed: _isSubmitting ? null : _createGiftCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Создать карту'),
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
                      'Карта создаётся мгновенно. Код можно активировать в любой момент.',
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

  Widget _buildCard(ThemeData theme, bool isDark) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VEIL',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            '${_cardAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'VLC',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Text(
                  _cardRecipient.isNotEmpty ? _cardRecipient[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cardRecipient,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Получатель',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _cardCode ?? '----',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                GestureDetector(
                  onTap: _copyCode,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}