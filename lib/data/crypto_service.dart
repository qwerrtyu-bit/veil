import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  final _algorithm = Xchacha20.poly1305Aead();

  /// Создаёт ключ из строки (для демо)
  Future<SecretKey> createKeyFromString(String input) async {
    final hash = await Sha256().hash(utf8.encode(input));
    return SecretKey(hash.bytes);
  }

  /// Шифрует сообщение
  Future<String> encrypt(String plainText, SecretKey key) async {
    final message = utf8.encode(plainText);
    final secretBox = await _algorithm.encrypt(
      message,
      secretKey: key,
    );

    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return base64.encode(combined);
  }

  /// Расшифровывает сообщение
  Future<String> decrypt(String encryptedBase64, SecretKey key) async {
    final combined = base64.decode(encryptedBase64);

    final nonce = combined.sublist(0, 24);
    final cipherText = combined.sublist(24, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final decrypted = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(decrypted);
  }
}