import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../data/identity_service.dart';
import '../providers/wallet_provider.dart';

class UsernameShopScreen extends ConsumerStatefulWidget {
  const UsernameShopScreen({super.key});

  @override
  ConsumerState<UsernameShopScreen> createState() => _UsernameShopScreenState();
}

class _UsernameShopScreenState extends ConsumerState<UsernameShopScreen> {
  final _usernameController = TextEditingController();
  String _selectedTier = 'all';
  bool _isLoading = false;
  String? _errorText;
  String? _successText;
  List<Map<String, dynamic>> _premiumUsernames = [];

  final Map<String, Map<String, dynamic>> _tiers = {
    'free': {'label': 'Бесплатные', 'icon': '🆓', 'color': Color(0xFF10B981)},
    'short': {'label': 'Короткие (4 символа)', 'icon': '💎', 'color': Color(0xFF6C5CE7), 'price': 1000},
    'exclusive': {'label': 'Эксклюзивные (3 символа)', 'icon': '👑', 'color': Color(0xFFF59E0B), 'price': 5000},
    'premium': {'label': 'Премиум (2 символа)', 'icon': '⭐', 'color': Color(0xFFEF4444), 'price': 25000},
    'legendary': {'label': 'Легендарные (1 символ)', 'icon': '🔥', 'color': Color(0xFFEC4899), 'price': 100000},
  };

  @override
  void initState() {
    super.initState();
    _loadPremiumUsernames();
  }

  Future<void> _loadPremiumUsernames() async {
    try {
      final response = await http.get(
        Uri.parse('${VeilConstants.serverUrl}/username/premium'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final available = data['available'] as List? ?? [];
        setState(() {
          _premiumUsernames = available.map((u) => {
            'username': u,
            'tier': _getTierByLength(u.length),
          }).toList();
        });
      }
    } catch (e) {
      print('Ошибка загрузки премиум-юзернеймов: $e');
    }
  }

  String _getTierByLength(int length) {
    if (length >= 5) return 'free';
    if (length == 4) return 'short';
    if (length == 3) return 'exclusive';
    if (length == 2) return 'premium';
    return 'legendary';
  }

  Future<void> _purchaseUsername() async {
    final username = _usernameController.text.trim().toLowerCase();
    if (username.isEmpty) {
      setState(() => _errorText = 'Введите юзернейм');
      return;
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(username)) {
      setState(() => _errorText = 'Только буквы, цифры и _');
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

      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/username/purchase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'ownerId': publicKey,
          'ownerType': 'user',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final price = data['price'] as int;
        final tier = data['tier'] as String;

        // Обновляем баланс
        ref.read(walletProvider.notifier).addVlc(
          -price.toDouble(),
          'Покупка юзернейма @$username',
        );

        setState(() {
          _successText = '✅ Куплен юзернейм @$username (${_tiers[tier]?['label'] ?? tier}) за $price VLC!';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Юзернейм @$username куплен!'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          context.go('/profile');
        });
      } else if (response.statusCode == 402) {
        setState(() {
          _errorText = '❌ Недостаточно VLC на балансе';
          _isLoading = false;
        });
      } else if (response.statusCode == 409) {
        setState(() {
          _errorText = '❌ Юзернейм уже занят';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorText = '❌ Ошибка: ${response.statusCode}';
          _isLoading = false;
        });
      }
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
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Магазин юзернеймов'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 Баланс VLC',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${walletState.vlcBalance.toStringAsFixed(2)} VLC',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Поиск юзернейма
            Text(
              'Проверить юзернейм',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '@',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'username',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _purchaseUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                        : const Text('Купить юзернейм'),
                  ),
                ),
              ],
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
            ],

            if (_successText != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_successText!, style: const TextStyle(color: Colors.green)),
              ),
            ],

            const SizedBox(height: 32),

            // Цены
            Text(
              '📋 Цены на юзернеймы',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            ..._tiers.entries.map((entry) {
              final tier = entry.key;
              final data = entry.value;
              final isFree = tier == 'free';
              final price = data['price'] as int?;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: data['color'].withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(data['icon'], style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['label'],
                            style: TextStyle(
                              color: data['color'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isFree ? 'Бесплатно' : '$price VLC',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: data['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isFree ? 'Доступен' : 'Купить',
                        style: TextStyle(
                          color: data['color'],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}