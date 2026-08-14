import 'package:flutter/material.dart';

enum TransactionType {
  deposit,      // Пополнение
  withdrawal,   // Списание
  transfer,     // Перевод (общий)
  subscription, // Подписка
}

enum TransactionStatus {
  pending,
  completed,
  failed,
}

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String description;
  final String timestamp;
  final TransactionStatus status;
  final double? fee;
  final String? recipientKey;
  final String? senderKey;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
    this.status = TransactionStatus.completed,
    this.fee,
    this.recipientKey,
    this.senderKey,
  });

  bool get isIncoming {
    return type == TransactionType.deposit ||
           type == TransactionType.transfer;
  }

  bool get isOutgoing {
    return type == TransactionType.withdrawal ||
           type == TransactionType.subscription;
  }

  String get typeDisplay {
    switch (type) {
      case TransactionType.deposit:
        return 'Пополнение';
      case TransactionType.withdrawal:
        return 'Списание';
      case TransactionType.transfer:
        return 'Перевод';
      case TransactionType.subscription:
        return 'Подписка';
    }
  }

  IconData get icon {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return isIncoming ? Icons.call_received : Icons.call_made;
      case TransactionType.subscription:
        return Icons.stars;
    }
  }

  Color get color {
    if (isIncoming) {
      return const Color(0xFF10B981); // Зеленый
    } else {
      return const Color(0xFFEF4444); // Красный
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'description': description,
      'timestamp': timestamp,
      'status': status.name,
      'fee': fee,
      'recipientKey': recipientKey,
      'senderKey': senderKey,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.deposit,
      ),
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.completed,
      ),
      fee: (json['fee'] as num?)?.toDouble(),
      recipientKey: json['recipientKey'] as String?,
      senderKey: json['senderKey'] as String?,
    );
  }
}