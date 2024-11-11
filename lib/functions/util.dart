import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_ssi/util.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:id_ideal_wallet/constants/root_certificates.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:iso_mdoc/iso_mdoc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:os_keystore_backend/os_keystore_backend.dart';
import 'package:random_password_generator/random_password_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x509b/x509.dart' as x509;

void printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

Future<bool> isOnboard() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool? onboard = prefs.getBool('onboard');
  return onboard ?? false;
}

Future<bool> checkAuthSupport() {
  var auth = LocalAuthentication();
  return auth.isDeviceSupported();
}

Future<bool> openWallet(WalletStore wallet) async {
  try {
    if (!wallet.isWalletOpen()) {
      var messages = AndroidAuthMessages(
          signInTitle:
              AppLocalizations.of(navigatorKey.currentContext!)!.openWallet,
          cancelButton:
              AppLocalizations.of(navigatorKey.currentContext!)!.cancel,
          biometricHint:
              AppLocalizations.of(navigatorKey.currentContext!)!.verifyIdentity,
          goToSettingsButton:
              AppLocalizations.of(navigatorKey.currentContext!)!.openSettings,
          goToSettingsDescription:
              '${AppLocalizations.of(navigatorKey.currentContext!)!.technicNoteBad}\n${AppLocalizations.of(navigatorKey.currentContext!)!.noteGoToSettings}');
      var iosMessage = IOSAuthMessages(
        cancelButton: AppLocalizations.of(navigatorKey.currentContext!)!.cancel,
        goToSettingsButton:
            AppLocalizations.of(navigatorKey.currentContext!)!.openSettings,
        goToSettingsDescription:
            '${AppLocalizations.of(navigatorKey.currentContext!)!.technicNoteBad}\n${AppLocalizations.of(navigatorKey.currentContext!)!.noteGoToSettings}',
      );
      var auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) return false;
      logger.d('device supported');
      var didAuthWork = false;

      didAuthWork = await auth.authenticate(
          localizedReason: AppLocalizations.of(navigatorKey.currentContext!)!
              .localizedReason,
          authMessages: [messages, iosMessage]);

      if (didAuthWork) {
        const storage = FlutterSecureStorage();
        String? pw = await storage.read(key: 'password');
        if (pw == null) {
          pw = RandomPasswordGenerator().randomPassword(
              letters: true,
              uppercase: true,
              numbers: true,
              specialChar: true,
              passwordLength: 20);
          await storage.write(key: 'password', value: pw);
        }
        await wallet.openBoxes(
            password: pw,
            keyStorage: Platform.isAndroid
                ? {
                    'software': SoftwareKeyStoreBackend(),
                    'system': OsKeyStore()
                  }
                : null);
      } else {
        return false;
      }
    } else {
      return true;
    }
    return true;
  } catch (e) {
    logger.d(e);
    return false;
  }
}

Future<bool> verifyIssuerCert(x509.X509Certificate issuerCert) async {
  var certChain = await x509.buildCertificateChain(issuerCert, rootCerts);
  var verify = await x509.verifyCertificateChain(certChain);
  return verify;
}

String getTypeToShow(List<String> types) {
  return types.firstWhere(
      (element) =>
          element != 'VerifiableCredential' &&
          (!element.contains('HidyContext') && element != 'IsoMdlCredential'),
      orElse: () => '');
}

void showScaffoldMessenger(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: const Duration(seconds: 2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(30.0),
      ),
    ),
    backgroundColor: Colors.black.withOpacity(0.6),
    behavior: SnackBarBehavior.floating,
    content: Text(message),
  ));
}

// source: https://stackoverflow.com/questions/50081213/how-do-i-use-hexadecimal-color-strings-in-flutter
extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

int? getCoseAlgorithmForDid(String did) {
  if (did.startsWith('did:key:z6Mk')) {
    return CoseAlgorithm.edDSA;
  } else if (did.startsWith('did:key:zQ3s')) {
    return CoseAlgorithm.es256;
  } else if (did.startsWith('did:key:zDn')) {
    return CoseAlgorithm.es256;
  } else if (did.startsWith('did:key:z82')) {
    return CoseAlgorithm.es384;
  } else if (did.startsWith('did:key:z2J9')) {
    return CoseAlgorithm.es512;
  } else {
    return null;
  }
}

class OsKeyStore extends KeyStoreBackend {
  final _instance = OsKeystoreBackend();

  @override
  FutureOr<Uint8List> calculateKeyAgreement(
      String keyId, Map<String, dynamic> otherPublicKey) {
    // TODO: implement calculateKeyAgreement
    throw UnimplementedError();
  }

  @override
  void deleteKey(String keyId) {
    _instance.deleteKey(keyId);
  }

  @override
  FutureOr export() {
    throw Exception('Export not supported');
  }

  @override
  FutureOr<String> generateKey(KeyType keyType) {
    String curve;
    if (keyType == KeyType.p256) {
      curve = 'secp256r1';
    } else if (keyType == KeyType.p384) {
      curve = 'secp384r1';
    } else if (keyType == KeyType.p521) {
      curve = 'secp521r1';
    } else {
      throw Exception('Unsupported KeyType');
    }
    return _instance.generateKey(curve, false);
  }

  @override
  FutureOr<Map<String, dynamic>> getKeyInformation(String keyId) async {
    var p = (await _instance.getKeyInfo(keyId))
        .map((k, v) => MapEntry(k as String, v));
    if (p.containsKey('x5c')) {
      String? x, y, crv;
      (x, y, crv) = _parseCert((p['x5c'] as List).first);
      if (x != null) {
        p['x'] = x;
      }
      if (y != null) {
        p['y'] = y;
      }
      if (crv != null) {
        p['crv'] = crv;
      }
    }
    return p;
  }

  @override
  FutureOr<bool> hasKey(String keyId) {
    return _instance.hasKey(keyId);
  }

  @override
  FutureOr<void> import(data) {
    throw Exception('import not supported');
  }

  @override
  FutureOr<void> initializeStorage() {}

  @override
  FutureOr<Uint8List> signData(Uint8List data, String keyId) {
    return _instance.sign(keyId, data);
  }

  @override
  FutureOr<bool> verify(
      Uint8List signature, Uint8List signedData, String keyId) {
    return _instance.verify(keyId, signedData, signature);
  }

  (String? x, String? y, String? crv) _parseCert(String cert) {
    var k = CoseKey.fromCertificate(cert);
    if (k.x != null && k.y != null && k.crv != null) {
      String? crv;
      if (k.crv == CoseCurve.p521) {
        crv = 'P-521';
      } else if (k.crv == CoseCurve.p384) {
        crv = 'P-384';
      } else if (k.crv == CoseCurve.p256) {
        crv = 'P-256';
      }
      return (
        removePaddingFromBase64(base64UrlEncode(k.x!)),
        removePaddingFromBase64(base64UrlEncode(k.y!)),
        crv
      );
    }
    return (null, null, null);
  }
}
