import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../data/identity_service.dart';
import '../data/crypto_service.dart';

class BackupService {
  final _identityService = IdentityService();
  final _cryptoService = CryptoService();

  /// Создать бэкап всех данных
  Future<String?> exportBackup(String password) async {
    try {
      // Собираем все данные
      final data = await _collectAllData();
      
      // Преобразуем в JSON
      final jsonString = jsonEncode(data);
      
      // Шифруем паролем
      final key = _cryptoService.createKeyFromString(password);
      final encrypted = await _cryptoService.encrypt(jsonString, key);
      
      // Сохраняем файл через FilePicker
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить бэкап Veil',
        fileName: 'veil_backup_${DateTime.now().toIso8601String().substring(0, 10)}.veilbackup',
      );
      
      if (result != null) {
        // Записываем данные в файл
        final file = File(result);
        await file.writeAsString(encrypted);
        return result;
      }
      
      return null;
    } catch (e) {
      throw Exception('Ошибка создания бэкапа: $e');
    }
  }

  /// Восстановить из бэкапа
  Future<bool> importBackup(String filePath, String password) async {
    try {
      // Читаем файл
      final file = File(filePath);
      final encrypted = await file.readAsString();
      
      // Расшифровываем
      final key = _cryptoService.createKeyFromString(password);
      final decrypted = await _cryptoService.decrypt(encrypted, key);
      
      // Парсим JSON
      final data = jsonDecode(decrypted) as Map<String, dynamic>;
      
      // Восстанавливаем данные
      await _restoreAllData(data);
      
      return true;
    } catch (e) {
      throw Exception('Ошибка восстановления бэкапа: $e');
    }
  }

  /// Собрать все данные
  Future<Map<String, dynamic>> _collectAllData() async {
    // Seed-фраза
    final seedPhrase = await _identityService.getSeedPhrase();
    
    // Ключи
    final publicKey = await _identityService.getPublicKey();
    final privateKey = await _identityService.getPrivateKey();
    
    // Настройки
    final settingsBox = Hive.box('settings');
    final settings = settingsBox.toMap();
    
    // Контакты
    final contactsBox = Hive.box('contacts');
    final contacts = contactsBox.toMap();
    
    // Сообщения (ТОЛЬКО зашифрованные, не читаем!)
    final messagesBox = Hive.box('messages');
    final messages = messagesBox.toMap();
    
    // Кошелёк
    final walletBox = Hive.box('wallet');
    final wallet = walletBox.toMap();
    
    // TOTP секрет
    final totpSecret = await _identityService.getTotpSecret();
    
    return {
      'version': '2.1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'seed': seedPhrase,
      'publicKey': publicKey,
      'privateKey': privateKey,
      'totpSecret': totpSecret,
      'settings': settings,
      'contacts': contacts,
      'messages': messages,
      'wallet': wallet,
    };
  }

  /// Восстановить данные
  Future<void> _restoreAllData(Map<String, dynamic> data) async {
    // 1. Восстанавливаем Seed
    if (data['seed'] != null) {
      await _identityService.saveSeedPhrase(data['seed']);
    }
    
    // 2. Восстанавливаем ключи
    if (data['publicKey'] != null && data['privateKey'] != null) {
      await _identityService.saveKeyPair(
        data['publicKey'],
        data['privateKey'],
      );
    }
    
    // 3. Восстанавливаем TOTP
    if (data['totpSecret'] != null) {
      await _identityService.saveTotpSecret(data['totpSecret']);
    }
    
    // 4. Восстанавливаем настройки
    if (data['settings'] != null) {
      final settingsBox = Hive.box('settings');
      await settingsBox.clear();
      for (final entry in (data['settings'] as Map).entries) {
        await settingsBox.put(entry.key, entry.value);
      }
    }
    
    // 5. Восстанавливаем контакты
    if (data['contacts'] != null) {
      final contactsBox = Hive.box('contacts');
      await contactsBox.clear();
      for (final entry in (data['contacts'] as Map).entries) {
        await contactsBox.put(entry.key, entry.value);
      }
    }
    
    // 6. Восстанавливаем сообщения
    if (data['messages'] != null) {
      final messagesBox = Hive.box('messages');
      await messagesBox.clear();
      for (final entry in (data['messages'] as Map).entries) {
        await messagesBox.put(entry.key, entry.value);
      }
    }
    
    // 7. Восстанавливаем кошелёк
    if (data['wallet'] != null) {
      final walletBox = Hive.box('wallet');
      await walletBox.clear();
      for (final entry in (data['wallet'] as Map).entries) {
        await walletBox.put(entry.key, entry.value);
      }
    }
    
    // 8. Устанавливаем флаг, что личность существует
    await _identityService.setHasIdentity(true);
  }

  /// Получить размер бэкапа (для информации)
  Future<int> getBackupSize(Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    return utf8.encode(jsonString).length;
  }
}