import 'package:flutter_test/flutter_test.dart';
import 'package:sync_vault/src/encryption/encryption_service.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

void main() {
  late EncryptionService encryptionService;
  late SyncVaultLogger logger;

  setUp(() {
    logger = SyncVaultLogger(enabled: false);
    encryptionService = EncryptionService(logger: logger);
  });

  group('EncryptionService', () {
    test('should encrypt and decrypt data successfully', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = 'Hello, World!';

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(decrypted, plainText);
      expect(encrypted, isNot(plainText));
    });

    test('should encrypt JSON data', () async {
      // Arrange
      await encryptionService.initialize();
      final jsonData = {
        'name': 'John Doe',
        'age': 30,
        'active': true,
        'scores': [90, 85, 95],
      };

      // Act
      final encrypted = await encryptionService.encryptJson(jsonData);
      final decrypted = await encryptionService.decryptJson(encrypted);

      // Assert
      expect(decrypted, jsonData);
      expect(encrypted, isA<String>());
    });

    test('should use custom encryption key', () async {
      // Arrange
      const customKey = 'my-super-secret-key-that-is-32-chars-long!';
      await encryptionService.initialize(customKey: customKey);
      const plainText = 'Sensitive data';

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(decrypted, plainText);
    });

    test('should generate different ciphertext for same plaintext', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = 'Test message';

      // Act
      final encrypted1 = await encryptionService.encrypt(plainText);
      final encrypted2 = await encryptionService.encrypt(plainText);

      // Assert
      // Due to random IV, encrypted values should be different
      expect(encrypted1, isNot(encrypted2));

      // But both should decrypt to the same value
      final decrypted1 = await encryptionService.decrypt(encrypted1);
      final decrypted2 = await encryptionService.decrypt(encrypted2);
      expect(decrypted1, plainText);
      expect(decrypted2, plainText);
    });

    test('should handle empty strings', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = '';

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(decrypted, plainText);
    });

    test('should handle special characters', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = '!@#\$%^&*()_+-=[]{}|;:,.<>?~/`"\'\\';

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(decrypted, plainText);
    });

    test('should handle unicode characters', () async {
      // Arrange
      await encryptionService.initialize();
      const plainText = '你好世界 🌍 Привет мир مرحبا بالعالم';

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(decrypted, plainText);
    });

    test('should handle large data', () async {
      // Arrange
      await encryptionService.initialize();
      final plainText = 'A' * 10000; // 10KB of data

      // Act
      final encrypted = await encryptionService.encrypt(plainText);
      final decrypted = await encryptionService.decrypt(encrypted);

      // Assert
      expect(decrypted, plainText);
      expect(decrypted.length, 10000);
    });

    test('should fail to decrypt with wrong ciphertext', () async {
      // Arrange
      await encryptionService.initialize();
      const invalidCiphertext = 'not-a-valid-encrypted-string';

      // Act & Assert
      expect(
            () => encryptionService.decrypt(invalidCiphertext),
        throwsException,
      );
    });
  });
}
