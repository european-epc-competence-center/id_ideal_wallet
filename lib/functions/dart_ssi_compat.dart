/// Compatibility shim for dart_ssi EECC fork (commit 6fb33d).
///
/// The EECC fork removed several top-level helper functions and Signer
/// implementations that the app relied on. This file re-implements them
/// using the new WalletStore.sign() API, so call sites need minimal changes.
library dart_ssi_compat;

import 'dart:convert';
import 'dart:typed_data';

import 'package:base_codecs/base_codecs.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/exceptions.dart';
import 'package:dart_ssi/src/credentials/jsonLdContext/document_loader.dart';
import 'package:dart_ssi/src/credentials/jsonLdContext/ed25519_signature.dart';
import 'package:dart_ssi/src/credentials/jsonLdContext/json_web_signature_2020_context.dart';
export 'package:dart_ssi/src/util/crypto_provider.dart' show WalletKeyAgreementGenerator;
import 'package:dart_ssi/src/util/utils.dart' as ssi_utils;
import 'package:dart_ssi/wallet.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:http/http.dart';
import 'package:iso_mdoc/iso_mdoc.dart' show CoseAlgorithm, SignatureGenerator;
import 'package:json_ld_processor/json_ld_processor.dart';
import 'package:json_path/json_path.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:sd_jwt/sd_jwt.dart' as sd_jwt;

export 'package:dart_ssi/exceptions.dart' show RevokedException, SignatureException;

// ---------------------------------------------------------------------------
// BigInt helpers – pointycastle 4.x removed these from its public API
// ---------------------------------------------------------------------------

BigInt _decodeBigIntWithSign(int sign, List<int> magnitude) {
  if (sign == 0) return BigInt.zero;
  BigInt result = BigInt.zero;
  for (final byte in magnitude) {
    result = (result << 8) | BigInt.from(byte & 0xff);
  }
  if (sign < 0) {
    final bitLength = result.bitLength;
    final mod = BigInt.one << bitLength;
    result = result - mod;
  }
  return result;
}

Uint8List _encodeBigIntAsUnsigned(BigInt number) {
  if (number == BigInt.zero) return Uint8List(1);
  final byteLength = (number.bitLength + 7) >> 3;
  final result = Uint8List(byteLength);
  var value = number;
  for (int i = byteLength - 1; i >= 0; i--) {
    result[i] = (value & BigInt.from(0xff)).toInt();
    value = value >> 8;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Utility helpers
// ---------------------------------------------------------------------------

/// Converts any credential representation to a [Map<String, dynamic>].
/// Handles [VerifiableCredential] objects, JSON strings, and plain maps.
/// The new dart_ssi credentialToMap only accepts String or Map – this helper
/// bridges the gap for callers that may pass VerifiableCredential objects.
Map<String, dynamic> _toCredMap(dynamic credential) {
  if (credential is VerifiableCredential) return credential.toJson();
  return ssi_utils.credentialToMap(credential);
}

String buildJwsHeader({
  required String alg,
  String? kid,
  String? typ,
  Map<String, dynamic>? extra,
}) {
  final Map<String, dynamic> header = {'alg': alg};
  if (kid != null) header['kid'] = kid;
  if (typ != null) header['typ'] = typ;
  if (extra != null) {
    header.addAll(extra);
    header['crit'] = extra.keys.toList();
  }
  return base64UrlEncode(utf8.encode(jsonEncode(header)));
}

String getHolderDidFromCredential(dynamic credential) {
  final credMap = _toCredMap(credential);
  if (credMap.containsKey('credentialSubject')) {
    final sub = credMap['credentialSubject'];
    if (sub is Map && sub.containsKey('id')) return sub['id'] as String;
    return '';
  } else if (credMap.containsKey('id')) {
    return credMap['id'] as String;
  }
  return '';
}

String getIssuerDidFromCredential(dynamic credential) {
  final credMap = _toCredMap(credential);
  if (!credMap.containsKey('issuer')) return '';
  final issuer = credMap['issuer'];
  if (issuer is String) return issuer;
  if (issuer is Map) return (issuer['id'] as String?) ?? '';
  return '';
}

// ---------------------------------------------------------------------------
// Revocation check
// ---------------------------------------------------------------------------

Future<bool> checkForRevocation(dynamic credential) async {
  final credMap = _toCredMap(credential);
  if (!credMap.containsKey('credentialStatus')) return false;

  final credStatus = credMap['credentialStatus'];

  if (credStatus['type'] == 'RevocationList2020Status') {
    final status = RevocationList2020Status.fromJson(credStatus);
    final res = await get(Uri.parse(status.revocationListCredential),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30), onTimeout: () {
      return Response('Timeout', 408);
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
    final res = await get(Uri.parse(status.statusListCredential),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30), onTimeout: () {
      return Response('Timeout', 408);
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

// ---------------------------------------------------------------------------
// Signer implementations (adapted to use WalletStore.sign instead of raw keys)
// ---------------------------------------------------------------------------

_Signer _signerForDid(String did, Function(Uri, LoadDocumentOptions?)? loader) {
  if (did.startsWith('did:key:z6Mk')) return EdDsaSigner(loader);
  return JsonWebSignature2020Signer(loader);
}

_Signer _signerForType(String type, Function(Uri, LoadDocumentOptions?)? loader) {
  if (type == 'Ed25519Signature2020') return EdDsaSigner(loader);
  return JsonWebSignature2020Signer(loader);
}

abstract class _Signer {
  Future<Map<String, dynamic>> buildProof(
      dynamic data, WalletStore wallet, String did,
      {String? challenge, String? domain, String? proofPurpose});

  Future<String> sign(
      {required dynamic toSign,
      WalletStore? wallet,
      String? did,
      Map<String, dynamic>? jwk,
      bool detached = false,
      dynamic jwsHeader});

  Future<bool> verifyProof(
      dynamic proof, dynamic data, String did,
      {String? challenge,
      Map<String, dynamic>? jwk,
      Future<DidDocument> Function(String)? didResolver});

  Future<bool> verify(String jws,
      {String? did, Map<String, dynamic>? jwk, dynamic data});
}

class EdDsaSigner implements _Signer {
  final Function(Uri, LoadDocumentOptions?)? loadDocument;
  EdDsaSigner(this.loadDocument);

  @override
  Future<Map<String, dynamic>> buildProof(
      dynamic data, WalletStore wallet, String did,
      {String? challenge, String? domain, String? proofPurpose}) async {
    final proofOptions = <String, dynamic>{
      '@context': ed25519ContextIri,
      'type': 'Ed25519Signature2020',
      'proofPurpose': proofPurpose ?? 'assertionMethod',
      'verificationMethod': '$did#${did.split(':')[2]}',
      'created': DateTime.now().toUtc().toIso8601String(),
    };
    if (domain != null) proofOptions['domain'] = domain;
    if (challenge != null) proofOptions['challenge'] = challenge;

    final pOptionsNorm = await JsonLdProcessor.normalize(proofOptions,
        options: JsonLdOptions(safeMode: true, documentLoader: loadDocument));
    final pOptionsHash = sha256.convert(utf8.encode(pOptionsNorm)).bytes;
    final dataHash = await _dataToHash(data);
    final hashToSign = Uint8List.fromList(pOptionsHash + dataHash);

    final signature = await wallet.sign(did, hashToSign);
    proofOptions['proofValue'] = 'z${base58BitcoinEncode(signature)}';
    return proofOptions;
  }

  Future<List<int>> _dataToHash(dynamic data) async {
    if (data is Uint8List) return data;
    if (data is Map<String, dynamic>) {
      final norm = await JsonLdProcessor.normalize(
          Map<String, dynamic>.from(data),
          options: JsonLdOptions(safeMode: true, documentLoader: loadDocument));
      return sha256.convert(utf8.encode(norm)).bytes;
    }
    if (data is String) return sha256.convert(utf8.encode(data)).bytes;
    throw Exception('Unknown datatype for data');
  }

  @override
  Future<String> sign(
      {required dynamic toSign,
      WalletStore? wallet,
      String? did,
      Map<String, dynamic>? jwk,
      bool detached = false,
      dynamic jwsHeader}) async {
    final header =
        (jwsHeader != null ? ssi_utils.credentialToMap(jwsHeader) : null) ??
            {'alg': 'EdDSA', 'crv': 'Ed25519'};

    final encodedHeader = ssi_utils.removePaddingFromBase64(
        base64UrlEncode(utf8.encode(jsonEncode(header))));
    final encodedPayload = ssi_utils.removePaddingFromBase64(base64UrlEncode(
        utf8.encode(toSign is String ? toSign : jsonEncode(toSign))));
    final signingInput = '$encodedHeader.$encodedPayload';

    Uint8List sigBytes;
    if (wallet != null && did != null) {
      sigBytes = await wallet.sign(
          did, Uint8List.fromList(ascii.encode(signingInput)));
    } else if (jwk != null) {
      final privateKey =
          ed.newKeyFromSeed(base64Decode(ssi_utils.addPaddingToBase64(jwk['d'])));
      sigBytes = Uint8List.fromList(
          ed.sign(privateKey, Uint8List.fromList(ascii.encode(signingInput))));
    } else {
      throw Exception('Either wallet+did or jwk must be provided');
    }

    final encodedSig =
        ssi_utils.removePaddingFromBase64(base64UrlEncode(sigBytes));
    return detached
        ? '$encodedHeader..$encodedSig'
        : '$signingInput.$encodedSig';
  }

  @override
  Future<bool> verifyProof(
      dynamic proof, dynamic data, String did,
      {String? challenge,
      Map<String, dynamic>? jwk,
      Future<DidDocument> Function(String)? didResolver}) async {
    if (challenge != null) {
      final c = proof['challenge'];
      if (c == null) throw Exception('Expected challenge in credential');
      if (c != challenge) throw Exception('challenge does not match expected');
    }
    final proofValue = proof.remove('proofValue') as String;
    proof['@context'] = ed25519ContextIri;

    final dataHash = await _dataToHash(data);
    final proofHash = sha256
        .convert(utf8.encode(await JsonLdProcessor.normalize(proof,
            options: JsonLdOptions(
                safeMode: true, documentLoader: loadDocument))))
        .bytes;
    final hashToSign = proofHash + dataHash;

    proof.remove('@context');
    proof['proofValue'] = proofValue;

    final ddo = await (didResolver ?? resolveDidDocument)(did);
    final resolved = ddo.resolveKeyIds().convertAllKeysToJwk();

    final vm = proof['verificationMethod'] as String;
    Map<String, dynamic>? usedJwk;
    for (final k in resolved.verificationMethod ?? []) {
      if (k.id == vm) {
        usedJwk = k.publicKeyJwk;
        break;
      }
    }
    if (usedJwk == null) {
      throw Exception('Cannot find public key for $vm in DID document');
    }
    final pubKey =
        ed.PublicKey(base64Decode(ssi_utils.addPaddingToBase64(usedJwk['x'])));
    return ed.verify(pubKey, Uint8List.fromList(hashToSign),
        base58BitcoinDecode(proofValue.substring(1)));
  }

  @override
  Future<bool> verify(String jws,
      {String? did, Map<String, dynamic>? jwk, dynamic data}) async {
    Map<String, dynamic> signingKey;
    if (did != null) {
      final ddo =
          (await resolveDidDocument(did)).resolveKeyIds().convertAllKeysToJwk();
      signingKey = ddo.verificationMethod!.first.publicKeyJwk!;
    } else if (jwk != null) {
      signingKey = jwk;
    } else {
      throw Exception('Either did or jwk must be provided');
    }
    final parts = jws.split('.');
    if (parts.length != 3) throw Exception('Malformed JWS');
    final payload = data != null
        ? ssi_utils.removePaddingFromBase64(base64UrlEncode(utf8.encode(
            data is String ? data : jsonEncode(data))))
        : parts[1];
    final signingInput = '${parts[0]}.$payload';
    final pubKey = ed.PublicKey(
        base64Decode(ssi_utils.addPaddingToBase64(signingKey['x'])));
    return ed.verify(pubKey, Uint8List.fromList(ascii.encode(signingInput)),
        base64Decode(ssi_utils.addPaddingToBase64(parts[2])));
  }
}

class JsonWebSignature2020Signer implements _Signer {
  final Function(Uri, LoadDocumentOptions?)? loadDocument;
  JsonWebSignature2020Signer(this.loadDocument);

  @override
  Future<Map<String, dynamic>> buildProof(
      dynamic data, WalletStore wallet, String did,
      {String? challenge, String? domain, String? proofPurpose}) async {
    final proofOptions = <String, dynamic>{
      '@context': jsonWebSignature2020ContextIri,
      'type': 'JsonWebSignature2020',
      'proofPurpose': proofPurpose ?? 'assertionMethod',
      'verificationMethod': '$did#${did.split(':')[2]}',
      'created': DateTime.now().toUtc().toIso8601String(),
    };
    if (domain != null) proofOptions['domain'] = domain;
    if (challenge != null) proofOptions['challenge'] = challenge;

    final dataHash = await _dataToHash(data);
    final pOptionsHash = sha256
        .convert(utf8.encode(await JsonLdProcessor.normalize(proofOptions,
            options: JsonLdOptions(
                safeMode: true, documentLoader: loadDocument))))
        .bytes;
    final payload = pOptionsHash + dataHash;

    final alg = _algForDid(did);
    final critical = <String, dynamic>{'b64': false};
    final headerEnc = ssi_utils.removePaddingFromBase64(
        buildJwsHeader(alg: alg, extra: critical));
    final hashToSign =
        Uint8List.fromList(utf8.encode('$headerEnc.') + payload);

    final sigBytes = await wallet.sign(did, hashToSign);
    proofOptions['jws'] = '$headerEnc..${base64UrlEncode(sigBytes)}';
    return proofOptions;
  }

  String _algForDid(String did) {
    if (did.startsWith('did:key:z6Mk')) return 'EdDSA';
    if (did.startsWith('did:key:zQ3s')) return 'ES256K';
    if (did.startsWith('did:key:z82')) return 'ES384';
    if (did.startsWith('did:key:z2J9')) return 'ES512';
    return 'ES256';
  }

  Future<List<int>> _dataToHash(dynamic data) async {
    if (data is Uint8List) return data;
    if (data is Map<String, dynamic>) {
      final norm = await JsonLdProcessor.normalize(
          Map<String, dynamic>.from(data),
          options: JsonLdOptions(safeMode: true, documentLoader: loadDocument));
      return sha256.convert(utf8.encode(norm)).bytes;
    }
    if (data is String) return sha256.convert(utf8.encode(data)).bytes;
    throw Exception('Unknown datatype for data');
  }

  @override
  Future<String> sign(
      {required dynamic toSign,
      WalletStore? wallet,
      String? did,
      Map<String, dynamic>? jwk,
      bool detached = false,
      dynamic jwsHeader}) async {
    final headerMap =
        jwsHeader != null ? ssi_utils.credentialToMap(jwsHeader) : null;
    final alg = headerMap?['alg'] ?? (did != null ? _algForDid(did) : 'ES256');
    final encodedHeader = ssi_utils.removePaddingFromBase64(
        base64UrlEncode(utf8.encode(jsonEncode(headerMap ?? {'alg': alg}))));
    final encodedPayload = ssi_utils.removePaddingFromBase64(base64UrlEncode(
        utf8.encode(toSign is String ? toSign : jsonEncode(toSign))));
    final signingInput = '$encodedHeader.$encodedPayload';

    Uint8List sigBytes;
    if (wallet != null && did != null) {
      sigBytes = await wallet.sign(
          did, Uint8List.fromList(ascii.encode(signingInput)));
    } else if (jwk != null) {
      sigBytes = _signWithJwk(jwk, alg, ascii.encode(signingInput));
    } else {
      throw Exception('Either wallet+did or jwk must be provided');
    }

    final encodedSig =
        ssi_utils.removePaddingFromBase64(base64UrlEncode(sigBytes));
    return detached
        ? '$encodedHeader..$encodedSig'
        : '$signingInput.$encodedSig';
  }

  Uint8List _signWithJwk(
      Map<String, dynamic> jwk, String alg, List<int> data) {
    if (alg == 'EdDSA') {
      final privateKey = ed.newKeyFromSeed(
          base64Decode(ssi_utils.addPaddingToBase64(jwk['d'])));
      return Uint8List.fromList(
          ed.sign(privateKey, Uint8List.fromList(data)));
    }
    final pc.ECDomainParameters curve;
    final pc.Digest digest;
    if (alg == 'ES256') {
      curve = pc.ECCurve_secp256r1();
      digest = pc.SHA256Digest();
    } else if (alg == 'ES384') {
      curve = pc.ECCurve_secp384r1();
      digest = pc.SHA384Digest();
    } else if (alg == 'ES512') {
      curve = pc.ECCurve_secp521r1();
      digest = pc.SHA512Digest();
    } else {
      curve = pc.ECCurve_secp256k1();
      digest = pc.SHA256Digest();
    }
    final dBytes = base64Decode(ssi_utils.addPaddingToBase64(jwk['d']));
    final private = pc.ECPrivateKey(_decodeBigIntWithSign(1, dBytes), curve);
    final signer = pc.ECDSASigner(digest, null);
    signer.init(
        true,
        pc.ParametersWithRandom(
            pc.PrivateKeyParameter<pc.ECPrivateKey>(private),
            pc.SecureRandom('Fortuna')));
    final sig = signer.generateSignature(Uint8List.fromList(data))
        as pc.ECSignature;
    final r = _padTo32(sig.r);
    final s = _padTo32(sig.s);
    return Uint8List.fromList(r + s);
  }

  List<int> _padTo32(BigInt v) {
    final bytes = _encodeBigIntAsUnsigned(v);
    if (bytes.length >= 32) return bytes;
    return List.filled(32 - bytes.length, 0) + bytes;
  }

  @override
  Future<bool> verifyProof(
      dynamic proof, dynamic data, String did,
      {String? challenge,
      Map<String, dynamic>? jwk,
      Future<DidDocument> Function(String)? didResolver}) async {
    if (challenge != null) {
      final c = proof['challenge'];
      if (c == null) throw Exception('Expected challenge in credential');
      if (c != challenge) throw Exception('challenge does not match expected');
    }

    final dataHash = await _dataToHash(data);
    final jws = proof.remove('jws') as String;
    proof['@context'] = jsonWebSignature2020ContextIri;

    final proofHash = sha256
        .convert(utf8.encode(await JsonLdProcessor.normalize(proof,
            options: JsonLdOptions(
                safeMode: true, documentLoader: loadDocument))))
        .bytes;
    final payload = proofHash + dataHash;
    proof['jws'] = jws;
    proof.remove('@context');

    Map<String, dynamic>? usedJwk = jwk;
    if (usedJwk == null) {
      final resolver = didResolver ?? resolveDidDocument;
      final ddo = (await resolver(did)).resolveKeyIds().convertAllKeysToJwk();
      final vm = proof['verificationMethod'] as String;
      for (final k in ddo.verificationMethod ?? []) {
        if (k.id == vm) {
          usedJwk = k.publicKeyJwk;
          break;
        }
      }
    }
    if (usedJwk == null) throw Exception('Cannot find public key');

    final header = jws.split('.').first;
    final decodedHeader = jsonDecode(
        utf8.decode(base64Decode(ssi_utils.addPaddingToBase64(header))));
    final alg = decodedHeader['alg'] as String?;
    if (alg == null) throw Exception('alg missing in JWS header');

    final hashToSign =
        Uint8List.fromList(ascii.encode('$header.') + payload);
    final signature = Uint8List.fromList(
        base64Decode(ssi_utils.addPaddingToBase64(jws.split('.').last)));

    if (alg == 'EdDSA') {
      final pubKey = ed.PublicKey(
          base64Decode(ssi_utils.addPaddingToBase64(usedJwk['x'])));
      return ed.verify(pubKey, hashToSign, signature);
    }

    final pc.ECDomainParameters curve;
    final pc.Digest digest;
    if (alg == 'ES256') {
      curve = pc.ECCurve_secp256r1();
      digest = pc.SHA256Digest();
    } else if (alg == 'ES384') {
      curve = pc.ECCurve_secp384r1();
      digest = pc.SHA384Digest();
    } else if (alg == 'ES512') {
      curve = pc.ECCurve_secp521r1();
      digest = pc.SHA512Digest();
    } else {
      curve = pc.ECCurve_secp256k1();
      digest = pc.SHA256Digest();
    }
    final pubKey = pc.ECPublicKey(
        curve.curve.createPoint(
            _decodeBigIntWithSign(
                1, base64Decode(ssi_utils.addPaddingToBase64(usedJwk['x']))),
            _decodeBigIntWithSign(
                1, base64Decode(ssi_utils.addPaddingToBase64(usedJwk['y'])))),
        curve);
    final verifier = pc.ECDSASigner(digest, null);
    verifier.init(false, pc.PublicKeyParameter<pc.ECPublicKey>(pubKey));
    final half = signature.length ~/ 2;
    final ecSig = pc.ECSignature(
        _decodeBigIntWithSign(1, signature.sublist(0, half)),
        _decodeBigIntWithSign(1, signature.sublist(half)));
    return verifier.verifySignature(hashToSign, ecSig);
  }

  @override
  Future<bool> verify(String jws,
      {String? did, Map<String, dynamic>? jwk, dynamic data}) async {
    Map<String, dynamic> signingKey;
    if (did != null) {
      final ddo =
          (await resolveDidDocument(did)).resolveKeyIds().convertAllKeysToJwk();
      signingKey = ddo.verificationMethod!.first.publicKeyJwk!;
    } else if (jwk != null) {
      signingKey = jwk;
    } else {
      throw Exception('Either did or jwk must be provided');
    }
    final parts = jws.split('.');
    if (parts.length != 3) throw Exception('Malformed JWS');
    final payload = data != null
        ? ssi_utils.removePaddingFromBase64(base64UrlEncode(
            utf8.encode(data is String ? data : jsonEncode(data))))
        : parts[1];
    final signingInput = '${parts[0]}.$payload';
    final header = jsonDecode(
        utf8.decode(base64Decode(ssi_utils.addPaddingToBase64(parts[0]))));
    final alg = header['alg'] as String? ?? 'EdDSA';
    final hashToSign = Uint8List.fromList(ascii.encode(signingInput));
    final signature = base64Decode(ssi_utils.addPaddingToBase64(parts[2]));

    if (alg == 'EdDSA') {
      final pubKey = ed.PublicKey(
          base64Decode(ssi_utils.addPaddingToBase64(signingKey['x'])));
      return ed.verify(pubKey, hashToSign, Uint8List.fromList(signature));
    }

    final pc.ECDomainParameters curve;
    final pc.Digest digest;
    if (alg == 'ES256') {
      curve = pc.ECCurve_secp256r1();
      digest = pc.SHA256Digest();
    } else if (alg == 'ES384') {
      curve = pc.ECCurve_secp384r1();
      digest = pc.SHA384Digest();
    } else {
      curve = pc.ECCurve_secp256k1();
      digest = pc.SHA256Digest();
    }
    final pubKey = pc.ECPublicKey(
        curve.curve.createPoint(
            _decodeBigIntWithSign(
                1, base64Decode(ssi_utils.addPaddingToBase64(signingKey['x']))),
            _decodeBigIntWithSign(
                1, base64Decode(ssi_utils.addPaddingToBase64(signingKey['y'])))),
        curve);
    final verifier = pc.ECDSASigner(digest, null);
    verifier.init(false, pc.PublicKeyParameter<pc.ECPublicKey>(pubKey));
    final half = signature.length ~/ 2;
    final ecSig = pc.ECSignature(
        _decodeBigIntWithSign(1, signature.sublist(0, half)),
        _decodeBigIntWithSign(1, signature.sublist(half)));
    return verifier.verifySignature(hashToSign, ecSig);
  }
}

// ---------------------------------------------------------------------------
// WalletCryptoProvider – implements sd_jwt.CryptoProvider via WalletStore.sign
// ---------------------------------------------------------------------------

class WalletCryptoProvider extends sd_jwt.CryptoProvider {
  final WalletStore _wallet;
  final String _keyId;

  WalletCryptoProvider(this._wallet, this._keyId);

  @override
  sd_jwt.Key generateKeyPair({required sd_jwt.KeyParameters keyParameters}) {
    throw UnsupportedError('Key generation not supported via WalletCryptoProvider');
  }

  @override
  Future<sd_jwt.Signature> sign(
      {required Uint8List data,
      required sd_jwt.SigningAlgorithm algorithm}) async {
    final sigBytes = await _wallet.sign(_keyId, data);
    return sd_jwt.Signature.fromSignatureBytes(sigBytes, algorithm);
  }

  @override
  Future<bool> verify(
      {required Uint8List data,
      required sd_jwt.SigningAlgorithm algorithm,
      required sd_jwt.Signature signature}) async {
    throw UnsupportedError('Verification not supported via WalletCryptoProvider');
  }
}

// ---------------------------------------------------------------------------
// WalletSignatureGenerator – implements iso_mdoc.SignatureGenerator via WalletStore.sign
// ---------------------------------------------------------------------------

class WalletSignatureGenerator extends SignatureGenerator {
  final WalletStore _wallet;
  final String _keyId;

  WalletSignatureGenerator(this._wallet, this._keyId, int coseAlgorithm)
      : super(coseAlgorithm);

  /// Creates a [WalletSignatureGenerator] with the correct COSE algorithm
  /// inferred from the DID key prefix.
  factory WalletSignatureGenerator.forDid(WalletStore wallet, String did) {
    final int alg;
    if (did.startsWith('did:key:z6Mk')) {
      alg = CoseAlgorithm.edDSA;
    } else if (did.startsWith('did:key:z82')) {
      alg = CoseAlgorithm.es384;
    } else if (did.startsWith('did:key:z2J9')) {
      alg = CoseAlgorithm.es512;
    } else {
      alg = CoseAlgorithm.es256;
    }
    return WalletSignatureGenerator(wallet, did, alg);
  }

  @override
  Future<List<int>> generate(List<int> data) async {
    return (await _wallet.sign(_keyId, Uint8List.fromList(data))).toList();
  }

  @override
  Future<bool> verify(List<int> data, List<int> toVerify) async {
    return await _wallet.verify(
        _keyId, Uint8List.fromList(data), Uint8List.fromList(toVerify));
  }
}

// ---------------------------------------------------------------------------
// High-level credential/presentation operations
// ---------------------------------------------------------------------------

Future<String> signCredential(WalletStore wallet, dynamic credentialToSign,
    {Function(Uri, LoadDocumentOptions?)? loadDocumentFunction}) async {
  final Map<String, dynamic> credential = _toCredMap(credentialToSign);

  final issuerDid = getIssuerDidFromCredential(credential);
  if (issuerDid.isEmpty) throw Exception('Could not determine issuer DID');

  final loader = loadDocumentFunction ?? loadDocumentFast;
  final signer = _signerForDid(issuerDid, loader);
  credential['proof'] =
      await signer.buildProof(credential, wallet, issuerDid);
  return jsonEncode(credential);
}

Future<bool> verifyCredential(
    dynamic credential,
    {String? expectedChallenge,
    Map<String, dynamic>? issuerJwk,
    Function(Uri, LoadDocumentOptions?)? loadDocumentFunction}) async {
  final credMap = _toCredMap(credential);
  if (!credMap.containsKey('proof')) {
    throw Exception('No proof section found in credential');
  }

  await checkForRevocation(credential);

  final issuerDid = getIssuerDidFromCredential(credential);
  final proof = credMap['proof'] as Map<String, dynamic>;
  final loader = loadDocumentFunction ?? loadDocumentFast;
  final signer =
      _signerForType(proof['type'] as String? ?? '', loader);
  final credCopy = Map<String, dynamic>.from(credMap)..remove('proof');

  bool verified;
  try {
    verified = await signer.verifyProof(
        Map<String, dynamic>.from(proof), credCopy, issuerDid,
        challenge: expectedChallenge, jwk: issuerJwk);
  } catch (e) {
    throw SignatureException('Unable to verify credential: $e', 'sigErr');
  }
  if (!verified) throw SignatureException('Credential signature invalid', 'sig');
  return verified;
}

Future<String> buildPresentation(
    List<dynamic>? credentials, WalletStore wallet, String challenge,
    {String? holder,
    String? domain,
    List<String>? additionalDids,
    List<dynamic>? disclosedCredentials,
    Function(Uri, LoadDocumentOptions?)? loadDocumentFunction}) async {
  final loader = loadDocumentFunction ?? loadDocumentFast;
  final List<Map<String, dynamic>?> credMapList = [];
  final List<String?> holderDids = [];
  final Set<String> signatureContext = {};
  PresentationSubmission? submission;

  if (credentials != null) {
    for (final element in credentials) {
      if (element is FilterResult) {
        List<InputDescriptorMappingObject> mapping =
            submission?.descriptorMap ?? [];
        for (final cred in element.credentials ?? []) {
          final credEntry = cred.toJson();
          credMapList.add(credEntry);
          final holderDid = getHolderDidFromCredential(credEntry);
          holderDids.add(holderDid);
          signatureContext.add(_contextForDid(holderDid));
          for (final id in element.matchingDescriptorIds) {
            mapping.add(InputDescriptorMappingObject(
                id: id,
                format: 'ldp_vc',
                path: JsonPath(
                    r'$.verifiableCredential[' +
                        '${credMapList.length - 1}]')));
          }
        }
        submission = PresentationSubmission(
            presentationDefinitionId: element.presentationDefinitionId,
            descriptorMap: mapping);
      } else {
        final credMap = _toCredMap(element);
        credMapList.add(credMap);
        if (!VerifiableCredential.fromJson(credMap)
            .type
            .contains('PublicKeyCertificate')) {
          final holderDid = getHolderDidFromCredential(credMap);
          holderDids.add(holderDid);
          signatureContext.add(_contextForDid(holderDid));
        }
      }
    }
  }

  if (holder != null) holderDids.add(holder);
  if (holderDids.isEmpty) throw Exception('No holder DID found');

  final context = [
    'https://www.w3.org/2018/credentials/v1',
    ...signatureContext
  ];
  final type = <String?>['VerifiablePresentation'];
  if (submission != null) {
    context.add(
        'https://identity.foundation/presentation-exchange/submission/v1/');
    type.add('PresentationSubmission');
  }

  final Map<String, dynamic> presentation = {'@context': context, 'type': type};
  if (credMapList.isNotEmpty) {
    presentation['verifiableCredential'] = credMapList;
  }
  if (holder != null) presentation['holder'] = holder;
  if (submission != null) {
    presentation['presentation_submission'] = submission.toJson();
  }
  if (disclosedCredentials != null) {
    presentation['disclosedCredentials'] =
        disclosedCredentials.map(_toCredMap).toList();
    (presentation['type'] as List).add('DisclosedCredentialPresentation');
  }

  final proofList = <Map<String, dynamic>>[];
  for (final holderDid in holderDids) {
    if (holderDid == null || holderDid.isEmpty) continue;
    final signer = _signerForDid(holderDid, loader);
    proofList.add(await signer.buildProof(presentation, wallet, holderDid,
        challenge: challenge, proofPurpose: 'authentication', domain: domain));
  }
  if (additionalDids != null) {
    for (final did in additionalDids) {
      final signer = _signerForDid(did, loader);
      proofList.add(await signer.buildProof(presentation, wallet, did,
          challenge: challenge, proofPurpose: 'authentication', domain: domain));
    }
  }

  presentation['proof'] = proofList;
  return jsonEncode(presentation);
}

String _contextForDid(String did) {
  if (did.startsWith('did:key:z6Mk')) return ed25519ContextIri;
  return jsonWebSignature2020ContextIri;
}

Future<bool> verifyPresentation(
    dynamic presentation, String challenge,
    {Future<DidDocument> Function(String)? didResolver,
    Function(Uri, LoadDocumentOptions?)? loadDocumentFunction}) async {
  final loader = loadDocumentFunction ?? loadDocumentFast;
  final Map<String, dynamic> presentationMap;
  if (presentation is VerifiablePresentation) {
    presentationMap = presentation.toJson();
  } else {
    presentationMap = _toCredMap(presentation);
  }

  var proofs = presentationMap['proof'];
  if (proofs is Map<String, dynamic>) proofs = [proofs];
  final proofList = List<Map<String, dynamic>>.from(proofs as List);
  presentationMap.remove('proof');

  if (presentationMap.containsKey('verifiableCredential')) {
    final credentials = presentationMap['verifiableCredential'] as List;
    for (final vc in credentials) {
      if (!VerifiableCredential.fromJson(vc)
          .type
          .contains('PublicKeyCertificate')) {
        await verifyCredential(vc, loadDocumentFunction: loader);
      }
    }
  }

  for (final proof in proofList) {
    final did = proof['verificationMethod'] as String? ?? '';
    final holderDid = did.contains('#') ? did.split('#').first : did;
    final signer =
        _signerForType(proof['type'] as String? ?? '', loader);
    final verified = await signer.verifyProof(
        Map<String, dynamic>.from(proof),
        Map<String, dynamic>.from(presentationMap),
        holderDid,
        challenge: challenge,
        didResolver: didResolver);
    if (!verified) throw SignatureException('Presentation proof invalid', 'sig');
  }

  presentationMap['proof'] = proofList;
  return true;
}

Future<String> signStringOrJson({
  WalletStore? wallet,
  String? didToSignWith,
  Map<String, dynamic>? jwk,
  required dynamic toSign,
  bool detached = false,
  dynamic jwsHeader,
}) async {
  _Signer signer;
  if (jwk != null) {
    final crv = jwk['crv'] as String? ?? '';
    signer = crv == 'Ed25519' ? EdDsaSigner(null) : JsonWebSignature2020Signer(null);
  } else if (didToSignWith != null) {
    signer = _signerForDid(didToSignWith, null);
  } else {
    throw Exception('Either jwk or didToSignWith must be provided');
  }
  return signer.sign(
      toSign: toSign,
      wallet: wallet,
      did: didToSignWith,
      jwk: jwk,
      detached: detached,
      jwsHeader: jwsHeader);
}
