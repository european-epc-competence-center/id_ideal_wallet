import 'dart:convert';
import 'dart:io';

import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/exceptions.dart';
import 'package:json_ld_processor/json_ld_processor.dart' show LoadDocumentOptions;
import 'package:dart_ssi/util.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:id_ideal_wallet/constants/root_certificates.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/oidc_handler.dart';
import 'package:iso_mdoc/iso_mdoc.dart' show CoseAlgorithm;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:random_password_generator/random_password_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x509b/x509.dart' as x509;

export 'package:dart_ssi/exceptions.dart' show RevokedException, SignatureException;

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
        await wallet.openBoxes(password: pw);
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

Future navigateClassic(Widget newView) {
  return Navigator.of(navigatorKey.currentContext!).push(Platform.isIOS
      ? CupertinoPageRoute(builder: (context) => newView)
      : MaterialPageRoute(builder: (context) => newView));
}

class AboData {
  String name, url, pictureUrl;

  AboData(this.name, this.url, this.pictureUrl);

  factory AboData.fromJson(dynamic jsonData) {
    var data = credentialToMap(jsonData);

    return AboData(data['name'] ?? '', data['url'],
        data['mainbgimg'] ?? data['mainbgimage']);
  }

  String getComparableUrl() {
    var asUri = Uri.parse(url);
    return removeTrailingSlash('${asUri.scheme}://${asUri.host}${asUri.path}');
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url, 'mainbgimage': pictureUrl};
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// Extracts the holder DID from a [VerifiableCredential]'s credentialSubject.
String getHolderDid(VerifiableCredential vc) =>
    (vc.credentialSubject['id'] as String?) ?? '';

/// Extracts the issuer DID from the [issuer] field of a [VerifiableCredential].
String getIssuerDid(dynamic issuer) {
  if (issuer is String) return issuer;
  if (issuer is Map) return (issuer['id'] as String?) ?? '';
  return '';
}

/// Returns the COSE algorithm integer for a did:key DID.
int getCoseAlgorithmForDid(String did) {
  if (did.startsWith('did:key:z6Mk')) return CoseAlgorithm.edDSA;
  if (did.startsWith('did:key:zQ3s')) return CoseAlgorithm.es256;
  if (did.startsWith('did:key:zDn')) return CoseAlgorithm.es256;
  if (did.startsWith('did:key:z82')) return CoseAlgorithm.es384;
  if (did.startsWith('did:key:z2J9')) return CoseAlgorithm.es512;
  return CoseAlgorithm.es256;
}

/// Returns a [WalletCredentialSigner] and [LdpProofType] appropriate for [did].
Future<(WalletCredentialSigner, LdpProofType)> getCredentialSigningStuff(
    WalletStore wallet, String did) async {
  final keyInfo = await wallet.getKeyInformation(did);
  String alg = 'EdDSA';
  LdpProofType type = LdpProofType.ed25519Signature2020;
  final crv = keyInfo['crv'] as String?;
  if (crv == 'P-256' || crv == 'secp256k1') {
    alg = 'ES256';
    type = LdpProofType.jsonWebSignature2020;
  } else if (crv == 'P-384') {
    alg = 'ES384';
    type = LdpProofType.jsonWebSignature2020;
  } else if (crv == 'P-521') {
    alg = 'ES512';
    type = LdpProofType.jsonWebSignature2020;
  }
  return (
    WalletCredentialSigner(
        wallet, did, alg, '$did#${did.split(':').last}'),
    type
  );
}


/// Checks whether [vc] has been revoked.
///
/// Throws [RevokedException] if the credential is revoked or the status
/// list cannot be fetched. Returns `false` if the credential is not revoked.
Future<bool> checkForRevocation(VerifiableCredential vc) async {
  if (vc.status == null) return false;

  final credStatus = vc.status!.toJson();

  if (credStatus['type'] == 'RevocationList2020Status') {
    final status = RevocationList2020Status.fromJson(credStatus);
    final res = await http.get(Uri.parse(status.revocationListCredential),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30), onTimeout: () {
      return http.Response('Timeout', 408);
    });
    if (res.statusCode == 200) {
      final revCred = RevocationList2020Credential.fromJson(res.body);
      try {
        await revCred.verify();
      } on SignatureException catch (_) {
        throw RevokedException(
            'could not verify RevocationListCredential', 'revErr');
      }
      final revoked = revCred.isRevoked(int.parse(status.revocationListIndex));
      if (revoked) throw RevokedException('Credential is revoked', 'rev');
    } else {
      throw RevokedException(
          'Error loading status list from ${status.revocationListCredential}',
          'revErr');
    }
  } else if (credStatus['type'] == 'StatusList2021Entry') {
    final status = StatusList2021Entry.fromJson(credStatus);
    final res = await http.get(Uri.parse(status.statusListCredential),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30), onTimeout: () {
      return http.Response('Timeout', 408);
    });
    if (res.statusCode == 200) {
      final revCred = StatusList2021Credential.fromJson(res.body);
      try {
        await revCred.verify();
      } on SignatureException catch (_) {
        throw RevokedException(
            'could not verify RevocationListCredential', 'revErr');
      }
      final revoked = revCred.isRevoked(int.parse(status.statusListIndex));
      if (revoked) throw RevokedException('Credential is revoked', 'rev');
    } else {
      throw RevokedException(
          'Error loading status list from ${status.statusListCredential}',
          'revErr');
    }
  } else {
    throw RevokedException(
        'Unknown Status-method : ${credStatus['type']}', 'revErr');
  }
  return false;
}

/// Builds a signed [VerifiablePresentation] from a list of [FilterResult]s.
///
/// Each unique holder DID in the credentials gets an individual proof added.
Future<VerifiablePresentation> buildW3cPresentation(
    List<FilterResult> filterResults,
    WalletStore wallet,
    String challenge,
    {String? domain,
    Function(Uri, LoadDocumentOptions?)? loadDocument}) async {
  final loader = loadDocument ?? loadDocumentFast;
  final vp = VerifiablePresentation.fromFilterResults(filterResults);
  final signedDids = <String>{};
  for (final vc in vp.verifiableCredential ?? <VerifiableCredential>[]) {
    final holderDid = getHolderDid(vc);
    if (holderDid.isEmpty || signedDids.contains(holderDid)) continue;
    signedDids.add(holderDid);
    final (signer, proofType) = await getCredentialSigningStuff(wallet, holderDid);
    await vp.addProof(signer, proofType,
        challenge: challenge, domain: domain, loadDocument: loader);
  }
  return vp;
}
