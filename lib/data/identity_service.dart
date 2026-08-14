import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bip39_mnemonic/bip39_mnemonic.dart' as bip39;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class IdentityService {
  final _secureStorage = const FlutterSecureStorage();
  Box get _hiveSecure => Hive.box('secure');

  // === Управление личностью ===

  Future<bool> hasIdentity() async {
    if (kIsWeb) {
      final has = _hiveSecure.get('has_identity');
      return has == true;
    }
    final has = await _secureStorage.read(key: 'has_identity');
    if (has == 'true') return true;
    final oldHas = _hiveSecure.get('has_identity');
    if (oldHas == true) {
      await _secureStorage.write(key: 'has_identity', value: 'true');
      await _hiveSecure.delete('has_identity');
      return true;
    }
    return false;
  }

  Future<void> setHasIdentity(bool value) async {
    if (kIsWeb) {
      await _hiveSecure.put('has_identity', value);
      return;
    }
    await _secureStorage.write(key: 'has_identity', value: value ? 'true' : 'false');
  }

  Future<void> saveSeedPhrase(String phrase) async {
    if (kIsWeb) {
      await _hiveSecure.put('seed_phrase', phrase);
      return;
    }
    await _secureStorage.write(key: 'seed_phrase', value: phrase);
  }

  Future<String?> getSeedPhrase() async {
    if (kIsWeb) {
      return _hiveSecure.get('seed_phrase');
    }
    final phrase = await _secureStorage.read(key: 'seed_phrase');
    if (phrase == null) {
      final oldPhrase = _hiveSecure.get('seed_phrase');
      if (oldPhrase != null) {
        await _secureStorage.write(key: 'seed_phrase', value: oldPhrase);
        await _hiveSecure.delete('seed_phrase');
        return oldPhrase;
      }
      return null;
    }
    return phrase;
  }

  // === Пароль ===

  Future<void> savePassword(String password) async {
    final hashed = hashPassword(password);
    if (kIsWeb) {
      await _hiveSecure.put('password_hash', hashed);
      return;
    }
    await _secureStorage.write(key: 'password_hash', value: hashed);
    await _secureStorage.delete(key: 'password');
  }

  Future<bool> checkPassword(String password) async {
    String? storedHash;
    if (kIsWeb) {
      storedHash = _hiveSecure.get('password_hash');
    } else {
      storedHash = await _secureStorage.read(key: 'password_hash');
    }

    if (storedHash == null) {
      final oldPassword = _hiveSecure.get('password');
      if (oldPassword != null && oldPassword == password) {
        await savePassword(password);
        return true;
      }
      return false;
    }
    return verifyPassword(password, storedHash);
  }

  // === Ключи ===

  Future<void> saveKeyPair(String publicKey, String privateKey) async {
    if (kIsWeb) {
      await _hiveSecure.put('public_key', publicKey);
      await _hiveSecure.put('private_key', privateKey);
      return;
    }
    await _secureStorage.write(key: 'public_key', value: publicKey);
    await _secureStorage.write(key: 'private_key', value: privateKey);
  }

  Future<String?> getPublicKey() async {
    if (kIsWeb) {
      return _hiveSecure.get('public_key');
    }
    final key = await _secureStorage.read(key: 'public_key');
    if (key == null) {
      final oldKey = _hiveSecure.get('public_key');
      if (oldKey != null) {
        await _secureStorage.write(key: 'public_key', value: oldKey);
        await _hiveSecure.delete('public_key');
        return oldKey;
      }
      return null;
    }
    return key;
  }

  Future<String?> getPrivateKey() async {
    if (kIsWeb) {
      return _hiveSecure.get('private_key');
    }
    final key = await _secureStorage.read(key: 'private_key');
    if (key == null) {
      final oldKey = _hiveSecure.get('private_key');
      if (oldKey != null) {
        await _secureStorage.write(key: 'private_key', value: oldKey);
        await _hiveSecure.delete('private_key');
        return oldKey;
      }
      return null;
    }
    return key;
  }

  // === TOTP ===

  Future<void> saveTotpSecret(String secret) async {
    if (kIsWeb) {
      await _hiveSecure.put('totp_secret', secret);
      return;
    }
    await _secureStorage.write(key: 'totp_secret', value: secret);
  }

  Future<String?> getTotpSecret() async {
    if (kIsWeb) {
      return _hiveSecure.get('totp_secret');
    }
    final secret = await _secureStorage.read(key: 'totp_secret');
    if (secret == null) {
      final oldSecret = _hiveSecure.get('totp_secret');
      if (oldSecret != null) {
        await _secureStorage.write(key: 'totp_secret', value: oldSecret);
        await _hiveSecure.delete('totp_secret');
        return oldSecret;
      }
      return null;
    }
    return secret;
  }

  // === Остальные методы без изменений ===

  String hashPassword(String password) {
    final salt = _randomString(16);
    var hash = _simpleHash('$salt$password');
    for (int i = 0; i < 10000; i++) {
      hash = _simpleHash('$hash$salt$password');
    }
    return '$salt:$hash';
  }

  bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      final salt = parts[0];
      var hash = _simpleHash('$salt$password');
      for (int i = 0; i < 10000; i++) {
        hash = _simpleHash('$hash$salt$password');
      }
      return hash == parts[1];
    } catch (e) {
      return false;
    }
  }

  String generateTotpSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  bool verifyTotp(String secret, String code) {
    if (code.length != 6) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (int offset = -1; offset <= 1; offset++) {
      final counter = (now + offset * 30) ~/ 30;
      final expected = _generateTotpCode(secret, counter);
      if (expected == code) return true;
    }
    return false;
  }

  Map<String, String> generateKeyPair(List<String> seedWords) {
    final phrase = seedWords.join(' ');
    final seed = _deriveSeed(phrase);
    return _generateEd25519KeyPair(seed);
  }

  List<String> generateSeedPhrase() {
    final random = Random.secure();
    final entropy = List<int>.generate(32, (_) => random.nextInt(256));
    final mnemonic = bip39.Mnemonic(entropy, bip39.Language.english);
    return mnemonic.words;
  }

  bool isValidSeedPhrase(List<String> words) {
    if (words.length != 24) return false;
    for (final word in words) {
      if (word.trim().isEmpty) return false;
      if (word.contains(' ')) return false;
    }
    return true;
  }

  String _generateTotpCode(String secret, int counter) {
    final key = _base32Decode(secret);
    final counterBytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      counterBytes[7 - i] = (counter >> (8 * i)) & 0xFF;
    }
    final hmac = _hmacSha1(Uint8List.fromList(key), counterBytes);
    final offset = hmac[19] & 0x0F;
    final binary = ((hmac[offset] & 0x7F) << 24) |
        ((hmac[offset + 1] & 0xFF) << 16) |
        ((hmac[offset + 2] & 0xFF) << 8) |
        (hmac[offset + 3] & 0xFF);
    return (binary % 1000000).toString().padLeft(6, '0');
  }

  String _simpleHash(String input) {
    final bytes = utf8.encode(input);
    int h1 = 0x67452301, h2 = 0xEFCDAB89, h3 = 0x98BADCFE, h4 = 0x10325476;
    for (int i = 0; i < bytes.length; i++) {
      h1 = ((h1 << 5) - h1 + bytes[i]) & 0xFFFFFFFF;
      h2 = ((h2 << 7) - h2 + bytes[i] + i) & 0xFFFFFFFF;
      h3 = ((h3 << 3) + h3 + bytes[i] * 31) & 0xFFFFFFFF;
      h4 = ((h4 << 11) - h4 + bytes[i] * 17) & 0xFFFFFFFF;
    }
    return h1.toRadixString(16) + h2.toRadixString(16) + h3.toRadixString(16) + h4.toRadixString(16);
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  List<int> _base32Decode(String base32) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final result = <int>[];
    int buffer = 0, bitsLeft = 0;
    for (int i = 0; i < base32.length; i++) {
      final char = base32[i].toUpperCase();
      if (char == '=') break;
      final value = alphabet.indexOf(char);
      if (value == -1) continue;
      buffer = (buffer << 5) | value;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        result.add((buffer >> bitsLeft) & 0xFF);
      }
    }
    return result;
  }

  Uint8List _hmacSha1(Uint8List key, Uint8List message) {
    const blockSize = 64;
    if (key.length > blockSize) {
      key = Uint8List.fromList(_sha1(key));
    }
    if (key.length < blockSize) {
      key = Uint8List.fromList([...key, ...List.filled(blockSize - key.length, 0)]);
    }
    final oKeyPad = Uint8List(blockSize);
    final iKeyPad = Uint8List(blockSize);
    for (int i = 0; i < blockSize; i++) {
      oKeyPad[i] = key[i] ^ 0x5C;
      iKeyPad[i] = key[i] ^ 0x36;
    }
    return Uint8List.fromList(_sha1(Uint8List.fromList([...oKeyPad, ..._sha1(Uint8List.fromList([...iKeyPad, ...message]))])));
  }

  List<int> _sha1(Uint8List data) {
    int h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE, h3 = 0x10325476, h4 = 0xC3D2E1F0;
    final padded = _padSha1(data);
    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      final w = List.filled(80, 0);
      for (int i = 0; i < 16; i++) {
        w[i] = (padded[chunk + i * 4] << 24) | (padded[chunk + i * 4 + 1] << 16) | (padded[chunk + i * 4 + 2] << 8) | padded[chunk + i * 4 + 3];
      }
      for (int i = 16; i < 80; i++) {
        w[i] = _rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
      }
      int a = h0, b = h1, c = h2, d = h3, e = h4;
      for (int i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) { f = (b & c) | ((~b) & d); k = 0x5A827999; }
        else if (i < 40) { f = b ^ c ^ d; k = 0x6ED9EBA1; }
        else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
        else { f = b ^ c ^ d; k = 0xCA62C1D6; }
        final temp = (_rotl(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d; d = c; c = _rotl(b, 30); b = a; a = temp;
      }
      h0 = (h0 + a) & 0xFFFFFFFF; h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF; h3 = (h3 + d) & 0xFFFFFFFF; h4 = (h4 + e) & 0xFFFFFFFF;
    }
    final result = <int>[];
    for (final h in [h0, h1, h2, h3, h4]) {
      result.addAll([(h >> 24) & 0xFF, (h >> 16) & 0xFF, (h >> 8) & 0xFF, h & 0xFF]);
    }
    return result;
  }

  Uint8List _padSha1(Uint8List data) {
    final ml = data.length * 8;
    final result = <int>[...data, 0x80];
    while ((result.length * 8) % 512 != 448) { result.add(0); }
    for (int i = 7; i >= 0; i--) { result.add((ml >> (i * 8)) & 0xFF); }
    return Uint8List.fromList(result);
  }

  int _rotl(int value, int shift) {
    return ((value << shift) | (value >> (32 - shift))) & 0xFFFFFFFF;
  }

  Uint8List _deriveSeed(String phrase) {
    return Uint8List.fromList(_sha256(utf8.encode(phrase)));
  }

  Uint8List _sha256(Uint8List data) {
    int h0 = 0x6A09E667, h1 = 0xBB67AE85, h2 = 0x3C6EF372, h3 = 0xA54FF53A;
    int h4 = 0x510E527F, h5 = 0x9B05688C, h6 = 0x1F83D9AB, h7 = 0x5BE0CD19;
    final padded = _padSha256(data);
    for (int chunk = 0; chunk < padded.length; chunk += 64) {
      final w = List.filled(64, 0);
      for (int i = 0; i < 16; i++) {
        w[i] = (padded[chunk + i * 4] << 24) | (padded[chunk + i * 4 + 1] << 16) | (padded[chunk + i * 4 + 2] << 8) | padded[chunk + i * 4 + 3];
      }
      for (int i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }
      int a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
      for (int i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = (h + s1 + ch + _sha256K[i] + w[i]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xFFFFFFFF;
        h = g; g = f; f = e; e = (d + temp1) & 0xFFFFFFFF;
        d = c; c = b; b = a; a = (temp1 + temp2) & 0xFFFFFFFF;
      }
      h0 = (h0 + a) & 0xFFFFFFFF; h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF; h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF; h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF; h7 = (h7 + h) & 0xFFFFFFFF;
    }
    final result = <int>[];
    for (final val in [h0, h1, h2, h3, h4, h5, h6, h7]) {
      result.addAll([(val >> 24) & 0xFF, (val >> 16) & 0xFF, (val >> 8) & 0xFF, val & 0xFF]);
    }
    return Uint8List.fromList(result);
  }

  Uint8List _padSha256(Uint8List data) {
    final ml = data.length * 8;
    final result = <int>[...data, 0x80];
    while ((result.length * 8) % 512 != 448) { result.add(0); }
    for (int i = 7; i >= 0; i--) { result.add((ml >> (i * 8)) & 0xFF); }
    return Uint8List.fromList(result);
  }

  int _rotr(int value, int shift) {
    return ((value >> shift) | (value << (32 - shift))) & 0xFFFFFFFF;
  }

  Map<String, String> _generateEd25519KeyPair(Uint8List seed) {
    final privateKey = _sha512(seed).sublist(0, 32);
    final clamped = Uint8List.fromList(privateKey);
    clamped[0] &= 248;
    clamped[31] &= 127;
    clamped[31] |= 64;
    final publicKey = _sha256(Uint8List.fromList(clamped));
    return {
      'publicKey': _bytesToHex(publicKey),
      'privateKey': _bytesToHex(clamped),
    };
  }

  Uint8List _sha512(Uint8List data) {
    final first = _sha256(data);
    return _sha256(Uint8List.fromList([...first, ...data]));
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  static const _sha256K = [
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1, 0x923F82A4, 0xAB1C5ED5,
    0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3, 0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174,
    0xE49B69C1, 0xEFBE4786, 0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147, 0x06CA6351, 0x14292967,
    0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13, 0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85,
    0xA2BFE8A1, 0xA81A664B, 0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A, 0x5B9CCA4F, 0x682E6FF3,
    0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208, 0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
  ];
}