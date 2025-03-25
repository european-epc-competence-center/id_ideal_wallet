import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:pointycastle/api.dart';

class EncryptionService {
  static String encryptData(String plainText, Uint8List password) {
    final iv = getSecureRandom().nextBytes(16);
    var algorithm = PaddedBlockCipher('AES/CBC/PKCS7');
    algorithm.init(
        true,
        PaddedBlockCipherParameters(
            ParametersWithIV(KeyParameter(password), iv), null));

    final encrypted = algorithm.process(utf8.encode(plainText));
    final ivBase64 = base64Encode(iv);
    final encryptedBase64 = base64Encode(encrypted);

    return '$ivBase64:$encryptedBase64'; // Prepend salt, IV, and encrypted text
  }

  static String decryptData(Uint8List password, String encryptedData) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format.');
    }

    final iv = base64Decode(parts[0]);
    final encrypted = base64Decode(parts[1]);

    var algorithm = PaddedBlockCipher('AES/CBC/PKCS7');
    algorithm.init(
        false,
        PaddedBlockCipherParameters(
            ParametersWithIV(KeyParameter(password), iv), null));

    final decrypted = algorithm.process(encrypted);

    return utf8.decode(decrypted);
  }

  static String createMnemonic() {
    return bip39.generateMnemonic();
  }

  static Uint8List getPasswordFromMnemonic(String mnemonic) {
    return bip39
        .mnemonicToSeed(mnemonic)
        .sublist(0, 32); //@dev: AES key length is 32 bytes
  }
}
