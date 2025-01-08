import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:bip39/bip39.dart' as bip39;

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  encrypt.Key? _key;

  EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  String encryptData(String plainText, Uint8List password) {
    _key = encrypt.Key(password);

    if (_key == null) {
      throw Exception('Encryption key is not initialized.');
    }

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final ivBase64 = iv.base64;
    final encryptedBase64 = encrypted.base64;

    return '$ivBase64:$encryptedBase64'; // Prepend salt, IV, and encrypted text
  }

  Future<String> decryptData(String password, String encryptedData) async {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format.');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    // Derive the key using the extracted salt
    final key = encrypt.Key(Uint8List.fromList(utf8.encode(password)));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  String createMemonic(){
    return bip39.generateMnemonic();
  }

  String getPasswordFromMemonic(String memonic){
    return bip39.mnemonicToSeedHex(memonic).substring(0, 32); //@dev: AES key length is 32 bytes
  }
}