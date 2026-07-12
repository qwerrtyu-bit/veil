import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:x25519/x25519.dart' as x25519;

class SecretKeyData {
  final Uint8List data;
  SecretKeyData(this.data);
}

class CryptoService {
  final _random = Random.secure();

  SecretKeyData createKeyFromString(String input) {
    final bytes = utf8.encode(input);
    final digest = SHA256Digest();
    final hash = digest.process(Uint8List.fromList(bytes));
    return SecretKeyData(hash);
  }

  Future<String> encrypt(String plainText, SecretKeyData key) async {
    final message = utf8.encode(plainText);
    final nonce = _generateNonce();
    final chacha = ChaCha20Engine()..init(true, ParametersWithIV(KeyParameter(key.data), nonce));
    final encrypted = Uint8List(message.length);
    chacha.processBytes(message, 0, message.length, encrypted, 0);
    final combined = Uint8List(nonce.length + encrypted.length);
    combined.setAll(0, nonce);
    combined.setAll(nonce.length, encrypted);
    return base64.encode(combined);
  }

  Future<String> decrypt(String encryptedBase64, SecretKeyData key) async {
    final combined = base64.decode(encryptedBase64);
    final nonce = combined.sublist(0, 8);
    final cipherText = combined.sublist(8);
    final chacha = ChaCha20Engine()..init(false, ParametersWithIV(KeyParameter(key.data), nonce));
    final decrypted = Uint8List(cipherText.length);
    chacha.processBytes(cipherText, 0, cipherText.length, decrypted, 0);
    return utf8.decode(decrypted);
  }

  SecretKeyData deriveSharedKey(String myPrivateKeyHex, String theirPublicKeyHex) {
    final myPrivateKey = _hexToBytes(myPrivateKeyHex);
    final theirPublicKey = _hexToBytes(theirPublicKeyHex);
    final x25519Private = _ed25519ToX25519Private(myPrivateKey);
    final x25519Public = _ed25519ToX25519Public(theirPublicKey);
    final sharedSecret = x25519.X25519(x25519Private, x25519Public);
    return SecretKeyData(Uint8List.fromList(sharedSecret));
  }

    SecretKeyData generateEphemeralKey() {
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return SecretKeyData(bytes);
  }

  Uint8List _ed25519ToX25519Private(Uint8List ed25519Private) {
    final hash = SHA256Digest().process(ed25519Private);
    final x25519 = Uint8List.fromList(hash.sublist(0, 32));
    x25519[0] &= 248;
    x25519[31] &= 127;
    x25519[31] |= 64;
    return x25519;
  }

  Uint8List _ed25519ToX25519Public(Uint8List ed25519Public) {
    return Uint8List.fromList(ed25519Public.sublist(0, 32));
  }

  Uint8List _hexToBytes(String hex) {
    if (hex.length < 2 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      return SHA256Digest().process(utf8.encode(hex));
    }
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(result);
  }

  Uint8List _generateNonce() {
    final nonce = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      nonce[i] = _random.nextInt(256);
    }
    return nonce;
  }
}