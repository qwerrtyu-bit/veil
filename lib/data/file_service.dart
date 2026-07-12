import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'crypto_service.dart';

class FileService {
  final _cryptoService = CryptoService();
  final _filesBox = Hive.box('messages');

  /// Сохраняет зашифрованный файл
  Future<void> saveFile({
    required String chatId,
    required String fileName,
    required Uint8List bytes,
    required bool isMe,
    required String time,
    SecretKeyData? key,
  }) async {
    // Шифруем байты
    String encryptedData;
    if (key != null) {
      encryptedData = await _cryptoService.encrypt(base64.encode(bytes), key);
    } else {
      encryptedData = base64.encode(bytes);
    }

    final chatFiles = _getChatFiles(chatId);
    chatFiles.add({
      'type': 'file',
      'fileName': fileName,
      'data': encryptedData,
      'isMe': isMe,
      'time': time,
      'isEncrypted': key != null,
    });
    _filesBox.put('files_$chatId', chatFiles);
  }

  /// Загружает файлы чата
  List<Map<String, dynamic>> loadFiles(String chatId) {
    return _getChatFiles(chatId);
  }

  List<Map<String, dynamic>> _getChatFiles(String chatId) {
    final data = _filesBox.get('files_$chatId');
    if (data == null) return [];
    if (data is List) {
      return data.where((item) => item is Map).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }
}