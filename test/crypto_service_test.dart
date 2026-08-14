import 'package:flutter_test/flutter_test.dart';
import 'package:veil/data/crypto_service.dart';

void main() {
  late CryptoService cryptoService;

  setUp(() {
    cryptoService = CryptoService();
  });

  group('CryptoService', () {
    test('createKeyFromString - создаёт ключ из строки', () {
      final key = cryptoService.createKeyFromString('test_password');
      expect(key.data.length, 32); // SHA256 даёт 32 байта
    });

    test('createKeyFromString - одинаковые строки дают одинаковый ключ', () {
      final key1 = cryptoService.createKeyFromString('test_password');
      final key2 = cryptoService.createKeyFromString('test_password');
      expect(key1.data, key2.data);
    });

    test('createKeyFromString - разные строки дают разные ключи', () {
      final key1 = cryptoService.createKeyFromString('password1');
      final key2 = cryptoService.createKeyFromString('password2');
      expect(key1.data, isNot(key2.data));
    });

    test('encrypt/decrypt - шифрует и расшифровывает текст', () async {
      const plainText = 'Hello, Veil!';
      final key = cryptoService.createKeyFromString('test_key');

      final encrypted = await cryptoService.encrypt(plainText, key);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(plainText));

      final decrypted = await cryptoService.decrypt(encrypted, key);
      expect(decrypted, plainText);
    });

    test('encrypt/decrypt - работает с русским текстом', () async {
      const plainText = 'Привет, мир!';
      final key = cryptoService.createKeyFromString('test_key');

      final encrypted = await cryptoService.encrypt(plainText, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);
      expect(decrypted, plainText);
    });

    test('encrypt/decrypt - работает с длинным текстом', () async {
      final plainText = 'a' * 10000;
      final key = cryptoService.createKeyFromString('test_key');

      final encrypted = await cryptoService.encrypt(plainText, key);
      final decrypted = await cryptoService.decrypt(encrypted, key);
      expect(decrypted, plainText);
    });

    test('decrypt - выбрасывает ошибку при неправильном ключе', () async {
      const plainText = 'Secret message';
      final key1 = cryptoService.createKeyFromString('correct_key');
      final key2 = cryptoService.createKeyFromString('wrong_key');

      final encrypted = await cryptoService.encrypt(plainText, key1);

      // Проверяем, что ошибка выбрасывается
      expect(
        () async => await cryptoService.decrypt(encrypted, key2),
        throwsException,
      );
    });

    test('decrypt - выбрасывает ошибку при битых данных', () async {
      final key = cryptoService.createKeyFromString('test_key');
      const invalidData = 'not_a_valid_base64_!!!';

      // Проверяем, что ошибка выбрасывается
      expect(
        () async => await cryptoService.decrypt(invalidData, key),
        throwsException,
      );
    });

    test('deriveSharedKey - генерирует общий ключ', () {
      // Используем реальные данные для теста
      const myPrivateKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      const theirPublicKey = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      
      final sharedKey = cryptoService.deriveSharedKey(myPrivateKey, theirPublicKey);
      expect(sharedKey.data.length, 32);
    });

    test('deriveSharedKey - одинаковые ключи дают одинаковый результат', () {
      const myPrivateKey = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      const theirPublicKey = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      
      final key1 = cryptoService.deriveSharedKey(myPrivateKey, theirPublicKey);
      final key2 = cryptoService.deriveSharedKey(myPrivateKey, theirPublicKey);
      expect(key1.data, key2.data);
    });

    test('deriveSharedKey - разные ключи дают разные результаты', () {
      const myPrivateKey1 = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
      const myPrivateKey2 = 'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';
      const theirPublicKey = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';
      
      final key1 = cryptoService.deriveSharedKey(myPrivateKey1, theirPublicKey);
      final key2 = cryptoService.deriveSharedKey(myPrivateKey2, theirPublicKey);
      expect(key1.data, isNot(key2.data));
    });

    test('generateEphemeralKey - генерирует случайный ключ', () {
      final key1 = cryptoService.generateEphemeralKey();
      final key2 = cryptoService.generateEphemeralKey();
      
      expect(key1.data.length, 32);
      expect(key2.data.length, 32);
      expect(key1.data, isNot(key2.data));
    });
  });
}