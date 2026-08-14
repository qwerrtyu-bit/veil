import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';

class BalanceSyncService {
  // Синхронизация баланса с сервера
  static Future<void> syncBalance(String publicKey) async {
    try {
      final response = await http.get(
        Uri.parse('${VeilConstants.serverUrl}/wallet/balance?userId=$publicKey'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balance = data['balance'] as num? ?? 0;
        final box = Hive.box('wallet');
        await box.put('vlc_balance', balance.toDouble());
        print('✅ Баланс синхронизирован: $balance VLC');
      }
    } catch (e) {
      print('❌ Ошибка синхронизации баланса: $e');
    }
  }

  // Отправка баланса на сервер
  static Future<void> pushBalance(String publicKey, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/wallet/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': publicKey,
          'balance': amount,
        }),
      );
      if (response.statusCode == 200) {
        print('✅ Баланс отправлен на сервер: $amount VLC');
      }
    } catch (e) {
      print('❌ Ошибка отправки баланса: $e');
    }
  }

  // Добавление VLC с синхронизацией
  static Future<void> addVlcAndSync(String publicKey, double amount, String description) async {
    try {
      final box = Hive.box('wallet');

      // 1. Обновляем локально
      final currentBalance = box.get('vlc_balance', defaultValue: 0.0);
      final newBalance = currentBalance + amount;
      await box.put('vlc_balance', newBalance);

      // 2. Добавляем транзакцию локально
      final transactions = box.get('transactions', defaultValue: <Map>[]);
      final List<Map> updatedTransactions = List<Map>.from(transactions);
      updatedTransactions.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'amount': amount,
        'type': 'deposit',
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
      });
      await box.put('transactions', updatedTransactions);

      // 3. Отправляем на сервер
      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/wallet/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': publicKey,
          'balance': newBalance,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Баланс обновлён: $newBalance VLC');
      } else {
        print('⚠️ Сервер не обновлён, но локально баланс сохранён');
      }
    } catch (e) {
      print('❌ Ошибка обновления баланса: $e');
    }
  }

  // Списание VLC с синхронизацией (для покупок)
  static Future<bool> deductVlcAndSync(String publicKey, double amount, String description) async {
    try {
      final box = Hive.box('wallet');

      // 1. Проверяем баланс
      final currentBalance = box.get('vlc_balance', defaultValue: 0.0);
      if (currentBalance < amount) {
        return false;
      }

      final newBalance = currentBalance - amount;

      // 2. Обновляем локально
      await box.put('vlc_balance', newBalance);

      // 3. Добавляем транзакцию локально
      final transactions = box.get('transactions', defaultValue: <Map>[]);
      final List<Map> updatedTransactions = List<Map>.from(transactions);
      updatedTransactions.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'amount': -amount,
        'type': 'purchase',
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'completed',
      });
      await box.put('transactions', updatedTransactions);

      // 4. Отправляем на сервер
      final response = await http.post(
        Uri.parse('${VeilConstants.serverUrl}/wallet/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': publicKey,
          'balance': newBalance,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Баланс обновлён: $newBalance VLC');
        return true;
      } else {
        // Откат локального изменения
        await box.put('vlc_balance', currentBalance);
        print('⚠️ Сервер не обновлён, баланс восстановлен');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка списания баланса: $e');
      return false;
    }
  }
}