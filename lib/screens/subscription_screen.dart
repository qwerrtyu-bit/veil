// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import '../providers/wallet_provider.dart';
import '../l10n/app_localizations.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isProcessing = false;

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.isFree) {
      ref.read(subscriptionProvider.notifier).setTier(plan.tier);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Тариф Free активирован'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final walletState = ref.read(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);

    if (walletState.vlcBalance < plan.price) {
      setState(() => _isProcessing = false);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Недостаточно средств'),
          content: Text(
            'Для активации ${_getPlanName(plan.tier)} нужно ${plan.price} VLC. '
            'Ваш баланс: ${walletState.vlcBalance.toStringAsFixed(2)} VLC.\n\n'
            'Пополнить баланс?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Пополнить'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        context.go('/wallet/deposit');
      }
      return;
    }

    final success = walletNotifier.paySubscription(plan.price.toDouble(), _getPlanName(plan.tier));

    if (success) {
      ref.read(subscriptionProvider.notifier).setTier(plan.tier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Подписка ${_getPlanName(plan.tier)} активирована!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка оплаты. Попробуйте позже.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  String _getPlanName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.plus:
        return 'Plus';
      case SubscriptionTier.dev:
        return 'Dev';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  String _getPlanDescription(SubscriptionTier tier, AppLocalizations l10n) {
    switch (tier) {
      case SubscriptionTier.free:
        return l10n.freeDesc;
      case SubscriptionTier.plus:
        return l10n.plusDesc;
      case SubscriptionTier.dev:
        return l10n.devDesc;
      case SubscriptionTier.pro:
        return l10n.proDesc;
    }
  }

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.circle_outlined;
      case SubscriptionTier.plus:
        return Icons.add_circle_outline;
      case SubscriptionTier.dev:
        return Icons.code;
      case SubscriptionTier.pro:
        return Icons.star;
    }
  }

  Color _getTierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const Color(0xFF10B981);
      case SubscriptionTier.plus:
        return const Color(0xFF3B82F6);
      case SubscriptionTier.dev:
        return const Color(0xFFF59E0B);
      case SubscriptionTier.pro:
        return const Color(0xFF6C5CE7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentTier = ref.watch(subscriptionProvider);
    final currentPlan = SubscriptionPlan.getPlan(currentTier);
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.subscription),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF6C5CE7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Баланс VeilBank:',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${walletState.vlcBalance.toStringAsFixed(2)} VLC',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SpaceMono',
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.go('/wallet'),
                        child: const Text('Пополнить'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF0)],
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
                      Text(
                        l10n.currentPlan,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentTier == SubscriptionTier.free
                              ? l10n.free
                              : '${currentPlan.price} ₽/мес',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getPlanName(currentTier),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPlanDescription(currentTier, l10n),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ...SubscriptionPlan.plans.map((plan) {
              final isCurrent = plan.tier == currentTier;
              return _buildPlanCard(plan, isCurrent, l10n);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, bool isCurrent, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isFree = plan.isFree;
    final tierColor = _getTierColor(plan.tier);
    final walletState = ref.watch(walletProvider);
    final canAfford = walletState.vlcBalance >= plan.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCurrent
            ? tierColor.withOpacity(0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? tierColor : Colors.grey.withOpacity(0.1),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: tierColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getTierIcon(plan.tier),
                    color: tierColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getPlanName(plan.tier),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isCurrent ? tierColor : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: tierColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Активен',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPlanDescription(plan.tier, l10n),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isFree ? l10n.free : '${plan.price} ₽',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isCurrent ? tierColor : null,
                      ),
                    ),
                    if (!isFree)
                      Text(
                        'в месяц',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!isCurrent && !isFree)
                      SizedBox(
                        width: 120,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _subscribe(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAfford ? tierColor : Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            canAfford ? 'Оплатить' : 'Не хватает',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!isCurrent && isFree)
                      SizedBox(
                        width: 120,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => _subscribe(plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tierColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Выбрать',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (isCurrent) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plan.features.map((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: tierColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          feature,
                          style: TextStyle(
                            fontSize: 12,
                            color: tierColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}