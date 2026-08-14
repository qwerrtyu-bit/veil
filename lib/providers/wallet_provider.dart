import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/wallet_model.dart';

// ============================================================
// МОДЕЛЬ СОСТОЯНИЯ
// ============================================================

class WalletState {
  final double vlcBalance;
  final double rubBalance;
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.vlcBalance = 0.0,
    this.rubBalance = 0.0,
    this.transactions = const [],
    this.isLoading = true,
    this.error,
  });

  WalletState copyWith({
    double? vlcBalance,
    double? rubBalance,
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      vlcBalance: vlcBalance ?? this.vlcBalance,
      rubBalance: rubBalance ?? this.rubBalance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ============================================================
// PROVIDER
// ============================================================

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState()) {
    _loadWallet();
  }

  void _loadWallet() {
    try {
      final box = Hive.box('wallet');
      final balance = box.get('vlc_balance', defaultValue: 0.0);
      final transactionsRaw = box.get('transactions', defaultValue: <Map<String, dynamic>>[]);
      
      final transactions = <Transaction>[];
      if (transactionsRaw is List) {
        for (final item in transactionsRaw) {
          if (item is Map) {
            try {
              final map = Map<String, dynamic>.from(item);
              transactions.add(Transaction.fromJson(map));
            } catch (_) {}
          }
        }
      }

      state = state.copyWith(
        vlcBalance: balance.toDouble(),
        transactions: transactions,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        error: 'Ошибка загрузки кошелька',
        isLoading: false,
      );
    }
  }

  void _saveWallet() {
    try {
      final box = Hive.box('wallet');
      box.put('vlc_balance', state.vlcBalance);
      box.put('transactions', state.transactions.map((t) => t.toJson()).toList());
    } catch (_) {}
  }

  // Добавление VLC на баланс
  void addVlc(double amount, String description) {
    if (amount <= 0) return;

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: TransactionType.deposit,
      description: description,
      timestamp: DateTime.now().toIso8601String(),
      status: TransactionStatus.completed,
    );

    final newBalance = state.vlcBalance + amount;
    state = state.copyWith(
      vlcBalance: newBalance,
      transactions: [transaction, ...state.transactions],
    );
    _saveWallet();
  }

  // Списание VLC (для подписок)
  bool paySubscription(double amount, String planName) {
    if (amount <= 0) return false;
    if (state.vlcBalance < amount) return false;

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: TransactionType.subscription,
      description: 'Подписка $planName',
      timestamp: DateTime.now().toIso8601String(),
      status: TransactionStatus.completed,
      fee: 0.0,
    );

    final newBalance = state.vlcBalance - amount;
    state = state.copyWith(
      vlcBalance: newBalance,
      transactions: [transaction, ...state.transactions],
    );
    _saveWallet();
    return true;
  }

  // Перевод VLC другому пользователю (исходящий)
  bool transferVlc(String recipientKey, double amount, {String? description}) {
    if (amount <= 0) return false;
    if (state.vlcBalance < amount + 0.1) return false;

    final fee = 0.1;
    final totalAmount = amount + fee;

    final outgoingTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: totalAmount,
      type: TransactionType.transfer,
      description: description ?? 'Перевод пользователю',
      timestamp: DateTime.now().toIso8601String(),
      status: TransactionStatus.completed,
      fee: fee,
      recipientKey: recipientKey,
    );

    final newBalance = state.vlcBalance - totalAmount;
    state = state.copyWith(
      vlcBalance: newBalance,
      transactions: [outgoingTransaction, ...state.transactions],
    );
    _saveWallet();
    return true;
  }

  // Получение перевода (входящий)
  void receiveTransfer(double amount, String senderKey, {String? description}) {
    if (amount <= 0) return;

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: TransactionType.transfer,
      description: description ?? 'Перевод от пользователя',
      timestamp: DateTime.now().toIso8601String(),
      status: TransactionStatus.completed,
      senderKey: senderKey,
    );

    final newBalance = state.vlcBalance + amount;
    state = state.copyWith(
      vlcBalance: newBalance,
      transactions: [transaction, ...state.transactions],
    );
    _saveWallet();
  }

  // Очистка ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Сброс кошелька (при удалении аккаунта)
  void reset() {
    state = const WalletState();
    try {
      final box = Hive.box('wallet');
      box.clear();
    } catch (_) {}
  }
}