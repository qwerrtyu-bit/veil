import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../providers/wallet_provider.dart';
import '../models/wallet_model.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import '../data/identity_service.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _showRub = false;
  bool _isLoading = true;
  String? _errorText;

  // График баланса (последние 7 дней)
  final List<Map<String, dynamic>> _chartData = [
    {'day': 'Пн', 'value': 120},
    {'day': 'Вт', 'value': 80},
    {'day': 'Ср', 'value': 200},
    {'day': 'Чт', 'value': 150},
    {'day': 'Пт', 'value': 300},
    {'day': 'Сб', 'value': 250},
    {'day': 'Вс', 'value': 180},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем баланс с сервера
      final walletNotifier = ref.read(walletProvider.notifier);
      final identityService = IdentityService();
      final publicKey = await identityService.getPublicKey();

      if (publicKey != null) {
        final response = await http.get(
          Uri.parse('${VeilConstants.serverUrl}/wallet/balance?userId=$publicKey'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
          // Обновляем локальный баланс
          // (пока просто сохраняем в state)
        }
      }
    } catch (e) {
      setState(() => _errorText = 'Ошибка загрузки баланса');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(walletProvider);
    final isDark = theme.brightness == Brightness.dark;

    final currentBalance = _showRub
        ? walletState.rubBalance
        : walletState.vlcBalance;
    final currencySymbol = _showRub ? '₽' : 'VLC';
    final recentTransactions = walletState.transactions.take(5).toList();

    // Фильтруем транзакции по типу
    final incoming = walletState.transactions.where((t) => t.isIncoming).toList();
    final outgoing = walletState.transactions.where((t) => t.isOutgoing).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('VeilBank'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/wallet/history'),
            tooltip: 'История',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================================
                  // КАРТОЧКА БАЛАНСА (СОВРЕМЕННЫЙ ДИЗАЙН)
                  // ============================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                            : [const Color(0xFF6C5CE7), const Color(0xFF8B7CF0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Общий баланс',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${currentBalance.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'SpaceMono',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      currencySymbol,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Переключатель валюты
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  _buildCurrencyToggle('VLC', !_showRub, () {
                                    setState(() => _showRub = false);
                                  }),
                                  _buildCurrencyToggle('₽', _showRub, () {
                                    setState(() => _showRub = true);
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
//график мини - упрощенная версия
Container(
  height: 50,
  width: double.infinity,
  padding: const EdgeInsets.symmetric(vertical: 2),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: _chartData.map((data) {
      final value = (data['value'] as int).toDouble();
      final maxValue = 300.0;
      final height = (value / maxValue) * 35; // максимальная высота 35px
      
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 6,
            height: height.clamp(2.0, 35.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data['day'],
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ],
      );
    }).toList(),
  ),
),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickAction(
                              icon: Icons.add,
                              label: 'Пополнить',
                              color: Colors.white,
                              onTap: () => context.go('/wallet/deposit'),
                            ),
                            _buildQuickAction(
                              icon: Icons.send,
                              label: 'Перевести',
                              color: Colors.white,
                              onTap: () => context.go('/wallet/transfer'),
                            ),
                            _buildQuickAction(
                              icon: Icons.history,
                              label: 'История',
                              color: Colors.white,
                              onTap: () => context.go('/wallet/history'),
                            ),
                            _buildQuickAction(
                              icon: Icons.card_giftcard,
                              label: 'Карта',
                              color: Colors.white,
                              onTap: () => context.go('/gift-card'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================================
                  // СТАТИСТИКА (входящие/исходящие)
                  // ============================================================
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Поступило',
                          amount: incoming.fold(0.0, (sum, t) => sum + t.amount),
                          color: const Color(0xFF10B981),
                          icon: Icons.arrow_downward,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Отправлено',
                          amount: outgoing.fold(0.0, (sum, t) => sum + t.amount),
                          color: const Color(0xFFEF4444),
                          icon: Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ============================================================
                  // ПОСЛЕДНИЕ ТРАНЗАКЦИИ
                  // ============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Последние операции',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/wallet/history'),
                        child: const Text('Все'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (recentTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Нет транзакций',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ...recentTransactions.map((transaction) {
                      return _buildTransactionTile(transaction, theme);
                    }),

                  const SizedBox(height: 16),

                  // ============================================================
                  // КУРС VLC
                  // ============================================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Color(0xFF6C5CE7),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Курс VLC',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '1 VLC = 1 ₽ (фиксированный)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
  // ============================================================

  Widget _buildCurrencyToggle(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0A0A0F) : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'SpaceMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction transaction, ThemeData theme) {
    final isIncoming = transaction.isIncoming;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction.icon,
              color: transaction.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeDisplay,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncoming ? '+' : '-'} ${transaction.amount.toStringAsFixed(2)} VLC',
                style: TextStyle(
                  color: transaction.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatTime(transaction.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) {
        return '${diff.inDays} дн. назад';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} ч. назад';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} мин. назад';
      } else {
        return 'Только что';
      }
    } catch (_) {
      return timestamp.substring(0, 16).replaceAll('T', ' ');
    }
  }
}