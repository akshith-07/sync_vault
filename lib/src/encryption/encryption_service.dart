import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Service for encrypting and decrypting data
class EncryptionService {
  static const String _keyStorageKey = 'sync_vault_encryption_key';
  static const String _ivStorageKey = 'sync_vault_encryption_iv';

  final FlutterSecureStorage _secureStorage;
  final SyncVaultLogger _logger;
  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;

  EncryptionService({
    required SyncVaultLogger logger,
    FlutterSecureStorage? secureStorage,
  })  : _logger = logger,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize the encryption service
  Future<void> initialize({String? customKey}) async {
    try {
      if (customKey != null) {
        // Use custom key
        final keyBytes = _deriveKey(customKey);
        _key = encrypt.Key(keyBytes);
      } else {
        // Load or generate key
        String? storedKey = await _secureStorage.read(key: _keyStorageKey);
        if (storedKey == null) {
          // Generate new key
          _key = encrypt.Key.fromSecureRandom(32);
          await _secureStorage.write(
            key: _keyStorageKey,
            value: base64Encode(_key!.bytes),
          );
          _logger.info('Generated new encryption key');
        } else {
          // Use stored key
          _key = encrypt.Key(base64Decode(storedKey));
          _logger.info('Loaded encryption key from secure storage');
        }
      }

      // Load or generate IV
      String? storedIV = await _secureStorage.read(key: _ivStorageKey);
      if (storedIV == null) {
        _iv = encrypt.IV.fromSecureRandom(16);
        await _secureStorage.write(
          key: _ivStorageKey,
          value: base64Encode(_iv!.bytes),
        );
      } else {
        _iv = encrypt.IV(base64Decode(storedIV));
      }

      _encrypter = encrypt.Encrypter(encrypt.AES(_key!));
      _logger.info('Encryption service initialized');
    } catch (e, stack) {
      throw EncryptionException(
        'Failed to initialize encryption service',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Derive a key from a password/string
  Uint8List _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return Uint8List.fromList(hash.bytes);
  }

  /// Encrypt a string
  String encryptString(String plainText) {
    _ensureInitialized();
    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e, stack) {
      throw EncryptionException(
        'Failed to encrypt string',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Decrypt a string
  String decryptString(String encryptedText) {
    _ensureInitialized();
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv);
    } catch (e, stack) {
      throw EncryptionException(
        'Failed to decrypt string',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Encrypt JSON data
  String encryptJson(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encryptString(jsonString);
  }

  /// Decrypt JSON data
  Map<String, dynamic> decryptJson(String encryptedData) {
    final jsonString = decryptString(encryptedData);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Encrypt bytes
  Uint8List encryptBytes(Uint8List data) {
    _ensureInitialized();
    try {
      final encrypted = _encrypter!.encryptBytes(data, iv: _iv);
      return encrypted.bytes;
    } catch (e, stack) {
      throw EncryptionException(
        'Failed to encrypt bytes',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Decrypt bytes
  Uint8List decryptBytes(Uint8List encryptedData) {
    _ensureInitialized();
    try {
      final encrypted = encrypt.Encrypted(encryptedData);
      return Uint8List.fromList(_encrypter!.decryptBytes(encrypted, iv: _iv));
    } catch (e, stack) {
      throw EncryptionException(
        'Failed to decrypt bytes',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Clear stored encryption keys
  Future<void> clearKeys() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);
      await _secureStorage.delete(key: _ivStorageKey);
      _key = null;
      _iv = null;
      _encrypter = null;
      _logger.warning('Encryption keys cleared');
    } catch (e, stack) {
      throw EncryptionException(
        'Failed to clear encryption keys',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  void _ensureInitialized() {
    if (_encrypter == null) {
      throw EncryptionException('Encryption service not initialized');
    }
  }
}
