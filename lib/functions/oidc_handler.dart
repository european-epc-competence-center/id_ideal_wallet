import 'dart:async';
import 'dart:convert';

import 'package:cbor/cbor.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto_keys/crypto_keys.dart';
import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/did.dart';
import 'package:dart_ssi/oid.dart';
import 'package:dart_ssi/util.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/didcomm_message_handler.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/ausweis_view.dart';
import 'package:id_ideal_wallet/views/credential_offer_new.dart';
import 'package:id_ideal_wallet/views/presentation_request.dart';
import 'package:id_ideal_wallet/views/web_view.dart';
import 'package:iso_mdoc/iso_mdoc.dart';
import 'package:provider/provider.dart';
import 'package:sd_jwt/sd_jwt.dart' as sd_jwt;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:x509b/x509.dart' as x509;

String removeTrailingSlash(String base64Input) {
  while (base64Input.endsWith('/')) {
    base64Input = base64Input.substring(0, base64Input.length - 1);
  }
  return base64Input;
}

Map<String, dynamic> findClaims(Map? claimsDescription) {
  var claims = <String, dynamic>{};
  claimsDescription ??= {};

  for (var key in claimsDescription.keys) {
    var value = claimsDescription[key];
    if (value is CredentialSubjectMetadata) {
      var displayList = value.display ?? <OidDisplayObject>[];
      var locale =
          AppLocalizations.of(navigatorKey.currentContext!)!.localeName;
      String? defaultName, localName, localeDes, defaultDes;
      for (var d in displayList) {
        if (d.locale != null && d.locale!.startsWith('en')) {
          defaultName = d.name;
          defaultDes = d.description;
        }
        if (d.locale != null && d.locale!.startsWith(locale)) {
          localName = d.name;
          localeDes = d.description;
        }
      }
      claims[localName ?? defaultName ?? key] = localeDes ?? defaultDes ?? '';
    } else if (value is Map) {
      claims.addAll(findClaims(value));
    } else if (value is List) {
      for (var v in value) {
        claims.addAll(findClaims(v));
      }
    }
  }

  logger.d(claims);
  return claims;
}

Future<void> handleOfferOid(String offerUri) async {
  var offer = OidCredentialOffer.fromUri(offerUri);

  var issuerString = removeTrailingSlash(offer.credentialIssuer);
  logger.d('$issuerString/.well-known/openid-credential-issuer');

  // get metadata
  var issuerMetaReq = await get(
      Uri.parse('$issuerString/.well-known/openid-credential-issuer'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 20), onTimeout: () {
    return Response('Timeout', 400);
  });

  if (issuerMetaReq.statusCode != 200) {
    logger.d(
        'Bad Status code: ${issuerMetaReq.statusCode} /${issuerMetaReq.body}');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.oidMetadataError,
        AppLocalizations.of(navigatorKey.currentContext!)!
            .oidMetadataErrorNote);
    return;
  }

  CredentialIssuerMetaData issuerMetadata;
  try {
    issuerMetadata = CredentialIssuerMetaData.fromJson(issuerMetaReq.body);
  } catch (e) {
    logger.d('Failed parsing issuer metadata');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.oidMetadataError,
        AppLocalizations.of(navigatorKey.currentContext!)!
            .oidMetadataErrorNote);
    return;
  }

  logger.d(offer.credentials);
  List<String> credentialToRequest = offer.credentialConfigurationIds ?? [];
  List<CredentialsSupportedObject> offeredCredentials = [];

  for (var c in offer.credentials ?? []) {
    if (c is String) {
      // type from credentialsSupported
      credentialToRequest.add(c);
    } else {
      c as CredentialsSupportedObject;
      offeredCredentials.add(c);
    }
  }
  for (var s in issuerMetadata.credentialsSupported.values) {
    logger.d(s.toJson());
  }
  for (String t in credentialToRequest) {
    var credConfig = issuerMetadata.credentialsSupported[t];
    if (credConfig == null) {
      logger.d('credential without config');
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.oidMetadataError,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .oidMetadataErrorNote);
      return;
    }
    offeredCredentials.add(credConfig);
  }

  dynamic res = true;
  res = await Future.delayed(const Duration(seconds: 1), () async {
    return await showCupertinoModalPopup(
      context: navigatorKey.currentContext!,
      barrierColor: Colors.white,
      builder: (BuildContext context) => CredentialOfferDialogNew(
          oidcIssuer: issuerString,
          isOid: true,
          requestOidcTan: offer.grants != null &&
              offer.grants!.containsKey(GrantType.preAuthType) &&
              (offer.grants![GrantType.preAuthType] as PreAuthCodeGrant)
                      .txCode !=
                  null &&
              (offer.grants![GrantType.preAuthType] as PreAuthCodeGrant)
                  .txCode!,
          credentials: offeredCredentials
              .map((e) => VerifiableCredential(
                  context: [credentialsV1Iri],
                  type: e.credentialType ?? [],
                  issuer: {'OidEndpoint': issuerString, 'id': issuerString},
                  credentialSubject: findClaims(e.claims),
                  issuanceDate: DateTime.now()))
              .toList()),
    );
  });

  if (res is String || res) {
    logger.d(res);
    logger.d(issuerString);
    logger.d(offer.credentials);

    var authserver = issuerString;
    if (issuerMetadata.authorizationServer != null &&
        issuerMetadata.authorizationServer!.isNotEmpty) {
      authserver = issuerMetadata.authorizationServer!.first;
    }

    if (offer.grants != null &&
        offer.grants!.containsKey('authorization_code')) {
      var authGrant =
          offer.grants![GrantType.authType] as AuthorizationCodeGrant;
      if (authGrant.authorizationServer != null) {
        authserver = authGrant.authorizationServer!;
      }

      authserver = removeTrailingSlash(authserver);

      logger.d('auth server: $authserver');
      // get MetaData
      Map? authServerMetaData;
      Map? clientMetaData = knownAuthServer[authserver.trim()];
      logger.d('authServer: ${knownAuthServer.keys}');
      if (clientMetaData == null) {
        logger.d('no client metadata for $authserver');
        showErrorMessage(AppLocalizations.of(navigatorKey.currentContext!)!
            .unknownAuthServer);
        return;
      }

      var state = const Uuid().v4();
      String pkceCodeVerifier =
          '${const Uuid().v4().toString()}-${const Uuid().v4().toString()}';
      String pkceCodeChallenge = removePaddingFromBase64(
          base64UrlEncode(sha256.convert(utf8.encode(pkceCodeVerifier)).bytes));
      logger.d(offeredCredentials.map((e) => e.toJson()).toList());
      Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
          .storeConfig(
              state,
              jsonEncode({
                'offer': offer.toJson(),
                'authServer': authserver,
                'credentials':
                    offeredCredentials.map((e) => e.toJson()).toList(),
                'codeVerifier': pkceCodeVerifier
              }));

      String clientId = clientMetaData['client_id'];
      String redirectUri =
          clientMetaData['redirect_uri'] ?? 'https://wallet.bccm.dev/redirect';

      String authServerQuery = 'response_type=code&client_id=$clientId';
      authServerQuery +=
          '&redirect_uri=${Uri.encodeQueryComponent(redirectUri)}';
      authServerQuery += '&state=$state';
      authServerQuery += '&code_challenge=$pkceCodeChallenge';
      authServerQuery += '&code_challenge_method=S256';

      authServerMetaData = await getAuthServerMetaData(authserver);
      if (authServerMetaData == null) {
        // without config we assume standard endpoint
        launchUrl(Uri.parse('$authserver/authorize?$authServerQuery'));
        logger.d('$authserver without config');
        return;
      }

      String authIssuer = authServerMetaData['issuer'];
      if (authIssuer != authserver) {
        logger.d('$authIssuer != $authserver');
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.oidMetadataError,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .oidMetadataErrorNote);
        return;
      }

      // can we do pushed authorization requests?
      var parEndpoint =
          authServerMetaData['pushed_authorization_request_endpoint'];
      if (parEndpoint != null) {
        if (offeredCredentials.length == 1 &&
            offeredCredentials.first.scope != null) {
          authServerQuery += '&scope=${offeredCredentials.first.scope}';
        } else {
          List<Map> authDetails = [];
          for (var entry in offeredCredentials) {
            var details = AuthorizationDetailsObject(
                format: entry.format,
                credentialConfigurationId: entry.credentialId,
                credentialType: entry.credentialType);
            authDetails.add(details.toJson());
          }
          authServerQuery +=
              '&authorization_details=${Uri.encodeQueryComponent(jsonEncode(authDetails))}';
        }
        logger.d(authServerQuery);

        var parResponse = await post(Uri.parse(parEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: authServerQuery);

        if (parResponse.statusCode == 201 || parResponse.statusCode == 200) {
          logger.d(parResponse.body);
          var decoded = jsonDecode(parResponse.body);
          var requestUri = decoded['request_uri'];
          String authRequest = authServerMetaData['authorization_endpoint'] ??
              '$authserver/authorize';
          authRequest +=
              '?client_id=$clientId&redirect_uri=${Uri.encodeQueryComponent(redirectUri)}';
          authRequest +=
              '&request_uri=${Uri.encodeQueryComponent(requestUri)}&state=$state&response_type=code';
          authRequest += '&nonce=abcdefg';
          if (offeredCredentials.length == 1 &&
              offeredCredentials.first.scope != null) {
            authRequest += '&scope=${offeredCredentials.first.scope}';
          }
          logger.d(authRequest);
          if (clientMetaData['pidIssuer'] != null &&
              clientMetaData['pidIssuer']) {
            navigateClassic(const AusweisView());
            Provider.of<AusweisProvider>(navigatorKey.currentContext!,
                    listen: false)
                .startProgress(authRequest, true);
          } else {
            navigateClassic(WebViewWindow(
                initialUrl: authRequest,
                title: AppLocalizations.of(navigatorKey.currentContext!)!
                    .authorization));
          }
          //launchUrl(Uri.parse(authRequest));
          return;
        } else {
          showErrorMessage(
              AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
              AppLocalizations.of(navigatorKey.currentContext!)!
                  .oidAuthFailedNote);
          logger.d(
              'Par request failed: ${parResponse.statusCode} / ${parResponse.body}');
          return;
        }
      } else {
        // if not, use redirect and authorization endpoint
        var authEndpoint = authServerMetaData['authorization_endpoint'];
        if (authEndpoint != null) {
          launchUrl(Uri.parse('$authEndpoint?$authServerQuery'));
          return;
        } else {
          showErrorMessage(
              AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
              AppLocalizations.of(navigatorKey.currentContext!)!
                  .oidAuthFailedNote);
        }
      }
    } else if (offer.grants != null &&
        offer.grants!.containsKey(GrantType.preAuthType)) {
      var authServerMeta = await getAuthServerMetaData(authserver);

      var tokenEndpoint =
          authServerMeta?['token_endpoint'] ?? '$authserver/token';

      logger.d(tokenEndpoint);

      var preAuthGrant =
          offer.grants![GrantType.preAuthType] as PreAuthCodeGrant;
      //send token Request
      var preAuthCode = preAuthGrant.preAuthCode;

      logger.d(preAuthCode);
      logger.d('Token-Endpoint: $tokenEndpoint');

      var tokenRes = await post(Uri.parse(tokenEndpoint),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body:
                  'grant_type=${GrantType.preAuthType}&pre-authorized_code=$preAuthCode${preAuthGrant.txCode != null && preAuthGrant.txCode! ? '&user_pin=$res' : ''}')
          .timeout(const Duration(seconds: 20), onTimeout: () {
        return Response('Timeout', 400);
      });
      if (tokenRes.statusCode == 200) {
        logger.d(jsonDecode(tokenRes.body));
        OidTokenResponse tokenResponse =
            OidTokenResponse.fromJson(tokenRes.body);

        logger.d('Access-Token : ${tokenResponse.accessToken}');

        for (var credMetadata in offeredCredentials) {
          getCredential(issuerString, issuerMetadata, credMetadata,
              tokenResponse, null, null, null, null);
        }
      } else {
        logger.d(tokenRes.statusCode);
        logger.d(tokenRes.body);

        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .oidAuthFailedNote);
        return;
      }
    } else {
      logger.d('Unbekannte Authentifizierungsmethode');
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
          AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailedNote);
      return;
    }
  }
}

Future<Map?> getAuthServerMetaData(String authServer) async {
  var OidonfigRes =
      await get(Uri.parse('$authServer/.well-known/openid-configuration'));
  if (OidonfigRes.statusCode == 200) {
    return jsonDecode(OidonfigRes.body);
  } else {
    logger.d(
        'status Oidonfig $authServer: ${OidonfigRes.statusCode} / ${OidonfigRes.body}');
    var oauthConfigRes = await get(
        Uri.parse('$authServer/.well-known/oauth-authorization-server'));
    if (oauthConfigRes.statusCode == 200) {
      return jsonDecode(oauthConfigRes.body);
    } else {
      return null;
    }
  }
}

Future<void> handleRedirect(String uri, [String? dpopNonce]) async {
  // Provider.of<NavigationProvider>(navigatorKey.currentContext!, listen: false)
  //     .goBack();
  Navigator.of(navigatorKey.currentContext!).popUntil((route) => route.isFirst);
  logger.d('redirected uri: $uri');
  var asUri = Uri.parse(uri);
  var state = asUri.queryParameters['state'];
  var code = asUri.queryParameters['code'];
  logger.d('state: $state');
  if (state == null) {
    logger.d('Prozess nicht auffindbar');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailedNote);
    return;
  }
  if (code == null) {
    logger.d('Keinen Auth-Code empfangen');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailedNote);
    return;
  }

  var storedData =
      Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
          .getConfig(state);

  if (storedData == null) {
    logger.d('Prozess nicht auffindbar');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailedNote);
    return;
  }

  var parsed = jsonDecode(storedData);
  String authServer = parsed['authServer'];
  String codeVerifier = parsed['codeVerifier'];
  OidCredentialOffer offer = OidCredentialOffer.fromJson(parsed['offer']);
  List<CredentialsSupportedObject> credentialMetadata =
      (parsed['credentials'] as List)
          .map((e) => CredentialsSupportedObject.fromJson(e))
          .toList();
  logger.d('authServer: $authServer, codeVerifier: $codeVerifier');

  Map? clientMetaData = knownAuthServer[authServer];
  if (clientMetaData == null) {
    showErrorMessage(
      AppLocalizations.of(navigatorKey.currentContext!)!.unknownAuthServer,
    );
    return;
  }

  String clientId = clientMetaData['client_id'];
  String redirectUri =
      clientMetaData['redirect_uri'] ?? 'https://wallet.bccm.dev/redirect';

  var authServerMetaData = await getAuthServerMetaData(authServer);
  String tokenEndpoint =
      authServerMetaData?['token_endpoint'] ?? '$authServer/token';
  logger.d('tokenEndpoint: $tokenEndpoint');

  String parameter = 'grant_type=authorization_code';
  parameter += '&code=$code';
  parameter += '&client_id=$clientId';
  parameter += '&redirect_uri=$redirectUri';
  parameter += '&state=$state';
  parameter += '&code_verifier=$codeVerifier';

  var headers = <String, String>{
    'Content-Type': 'application/x-www-form-urlencoded'
  };

  String? dpopDid, dpopJti;
  if (clientMetaData['dpop'] ?? false) {
    // generate Dpop header
    var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
        listen: false);
    dpopDid = await wallet.newCredentialDid(KeyType.p256);
    var dpopJwk = multibaseKeyToJwk(dpopDid.replaceAll('did:key:', ''));
    dpopJti = const Uuid().v4();

    var dpopPayload = {
      'jti': dpopJti,
      'htm': 'POST',
      'htu': tokenEndpoint,
      'nonce': dpopNonce
    };
    var jwt =
        sd_jwt.Jwt(additionalClaims: dpopPayload, issuedAt: DateTime.now());
    var dpopJws = await jwt.sign(
        signer: WalletCryptoProviderForSdJwt(wallet.wallet, dpopDid),
        header: sd_jwt.JwsJoseHeader(
            algorithm: sd_jwt.SigningAlgorithm.ecdsaSha256Prime,
            jsonWebKey: sd_jwt.Jwk.fromJson(dpopJwk),
            type: 'dpop+jwt'));
    logger.d(dpopPayload);

    headers['DPoP'] = dpopJws.toCompactSerialization();
  }

  var tokenRes =
      await post(Uri.parse(tokenEndpoint), headers: headers, body: parameter)
          .timeout(const Duration(seconds: 20), onTimeout: () {
    return Response('Timeout', 400);
  });

  if (tokenRes.statusCode == 200) {
    logger.d(
        'successful token request: ${jsonDecode(tokenRes.body).keys.toList()}');
    var decoded = OidTokenResponse.fromJson(tokenRes.body);
    logger.d(tokenRes.headers);
    // var payload = decoded.accessToken!.split('.')[1];
    // logger.d(
    //     'decodedPayload: ${jsonDecode(utf8.decode((base64Decode(addPaddingToBase64(payload)))))}');
    getCredential(
        removeTrailingSlash(offer.credentialIssuer),
        null,
        credentialMetadata.first,
        decoded,
        clientId,
        dpopDid,
        dpopJti,
        tokenRes.headers['dpop-nonce']);
  } else {
    logger.d('Error token request: ${tokenRes.statusCode} / ${tokenRes.body}');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailed,
        AppLocalizations.of(navigatorKey.currentContext!)!.oidAuthFailedNote);
  }
}

Future<(String, dynamic, KeyType)> buildJwt(
    List<String> algValues,
    List<String> bindingMethods,
    WalletProvider wallet,
    String? cNonce,
    String credentialIssuer,
    String? clientId,
    [KeyStore keystore = KeyStore.software]) async {
  String credentialDid, alg, crv;
  KeyType keyType;
  if (algValues.contains('ES256')) {
    credentialDid =
        await wallet.newCredentialDid(KeyType.p256, keystore, <String, dynamic>{
      'attestationChallenge': 'abc',
      //'userAuthenticationRequired': true
    });
    alg = 'ES256';
    crv = 'P-256';
    keyType = KeyType.p256;
  } else if (algValues.contains('ES384')) {
    credentialDid = await wallet.newCredentialDid(KeyType.p384, keystore);
    alg = 'ES384';
    crv = 'P-384';
    keyType = KeyType.p384;
  } else if (algValues.contains('ES512')) {
    credentialDid = await wallet.newCredentialDid(KeyType.p521, keystore);
    alg = 'ES512';
    crv = 'P-521';
    keyType = KeyType.p521;
  } else {
    credentialDid = await wallet.newCredentialDid();
    alg = 'EdDSA';
    crv = 'Ed25519';
    keyType = KeyType.ed25519;
  }
  // create JWT
  var ddo = resolveDidKey(credentialDid).convertAllKeysToJwk().resolveKeyIds();
  var jwk = ddo.verificationMethod!.first.publicKeyJwk!;
  jwk.remove('kid');
  var header = <String, dynamic>{
    'typ': 'openid4vci-proof+jwt',
    'alg': alg,
    'crv': crv,
    // 'kid': credentialDid,
    // 'kid':
    //     'did:jwk:${removePaddingFromBase64(base64UrlEncode(utf8.encode(jsonEncode(jwk))))}#0',
    //'jwk': ddo.verificationMethod!.first.publicKeyJwk
    //#${credentialDid.split(':').last
  };

  logger.d('binding methods: $bindingMethods');

  if (bindingMethods.isEmpty || bindingMethods.contains('did:key')) {
    header['kid'] = credentialDid;
  } else if (bindingMethods.contains('jwk') ||
      bindingMethods.contains('cose_key')) {
    header['jwk'] = ddo.verificationMethod!.first.publicKeyJwk;
  } else if (bindingMethods.contains('did:jwk')) {
    header['kid'] =
        'did:jwk:${removePaddingFromBase64(base64UrlEncode(utf8.encode(jsonEncode(jwk))))}#0';
  } else {
    showErrorMessage(
      AppLocalizations.of(navigatorKey.currentContext!)!
          .credentialDownloadFailed,
    );
    throw Exception('unsupported binding method');
  }
  logger.d(header);
  logger.d(credentialDid);
  var headerParsed = sd_jwt.JoseHeader.fromJson(header);
  var jwt = sd_jwt.Jwt(
      audience: credentialIssuer,
      issuedAt: DateTime.now(),
      issuer: clientId,
      additionalClaims: cNonce != null ? {'nonce': cNonce} : null);
  var keyId = keystore == KeyStore.software
      ? credentialDid
      : wallet.getOsKeyStoreIdForDid(credentialDid);
  var jws = await jwt.sign(
      signer: WalletCryptoProviderForSdJwt(wallet.wallet, keyId!),
      header: headerParsed as sd_jwt.JwsJoseHeader);

  return (credentialDid, jws.toCompactSerialization(), keyType);
}

Future<void> getCredential(
    String credentialIssuer,
    CredentialIssuerMetaData? metadata,
    CredentialsSupportedObject credentialMetadata,
    OidTokenResponse tokenResponse,
    String? clientId,
    String? dpopDid,
    String? dpopJti,
    String? dpopNonce) async {
  if (metadata == null) {
    // get metadata
    var issuerMetaReq = await get(
        Uri.parse('$credentialIssuer/.well-known/openid-credential-issuer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }).timeout(const Duration(seconds: 20), onTimeout: () {
      return Response('Timeout', 400);
    });

    if (issuerMetaReq.statusCode != 200) {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.oidMetadataError,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .oidMetadataErrorNote);
      return;
    }

    metadata = CredentialIssuerMetaData.fromJson(issuerMetaReq.body);
  }

  if (tokenResponse.cNonce == null) {
    logger.d('need new c_nonce');
    if (metadata.nonceEndpoint != null) {
      var nonceResponse = await post(Uri.parse(metadata.nonceEndpoint!));
      if (nonceResponse.statusCode == 200 || nonceResponse.statusCode == 201) {
        try {
          tokenResponse.cNonce = jsonDecode(nonceResponse.body)['c_nonce'];
        } catch (e) {
          logger.d('Keine nonce: $e');
          showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!
                .credentialDownloadFailed,
          );
          return;
        }
      } else {
        showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!
              .credentialDownloadFailed,
        );
        return;
      }
    } else {
      // send false cred request to get cNonce
      var credentialRequest = OidCredentialRequest(
        format: credentialMetadata.format,
        credentialType: credentialMetadata.credentialType,
      );

      var credentialResponse =
          await post(Uri.parse(metadata.credentialEndpoint),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer ${tokenResponse.accessToken}'
                  },
                  body: credentialRequest.toString())
              .timeout(const Duration(seconds: 20), onTimeout: () {
        return Response('Timeout', 400);
      });

      if (credentialResponse.statusCode != 200) {
        try {
          tokenResponse.cNonce = jsonDecode(credentialResponse.body)['c_nonce'];
        } catch (e) {
          logger.d('Keine nonce: $e');
          showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!
                .credentialDownloadFailed,
          );
          return;
        }
      }
    }
  }

  logger.d('c_nonce: ${tokenResponse.cNonce}');
  var wallet =
      Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false);

  String proofType;
  String credentialDid;
  dynamic proofValue;
  KeyType keyType;
  KeyStore k = KeyStore.software;

  if (credentialMetadata.format == OidCredentialFormat.msoMdoc &&
      credentialMetadata.credentialType != null &&
      credentialMetadata.credentialType!
          .contains(MobileDriversLicense.docType)) {
    k = KeyStore.system;
    logger.d('other keystore');
  }

  if (credentialMetadata.proofTypesSupported == null) {
    proofType = 'jwt';
    (credentialDid, proofValue, keyType) = await buildJwt([],
        credentialMetadata.cryptographicBindingMethods ?? [],
        wallet,
        tokenResponse.cNonce,
        credentialIssuer,
        clientId,
        k);
  } else if (credentialMetadata.proofTypesSupported!.containsKey('ldp_vp')) {
    proofType = 'ldp_vp';
    credentialDid = await wallet.newCredentialDid();
    // create VP
    var presentation = VerifiablePresentation(holder: credentialDid);
    var (signer, type) = await getCredentialSigningStuff(wallet, credentialDid);
    presentation.addProof(signer, type,
        challenge: tokenResponse.cNonce, domain: credentialIssuer);
    // end VP creation
    proofValue = presentation.toJson();
    keyType = KeyType.ed25519;
  } else if (credentialMetadata.proofTypesSupported!.containsKey('jwt')) {
    proofType = 'jwt';
    (credentialDid, proofValue, keyType) = await buildJwt(
        credentialMetadata
                .proofTypesSupported?['jwt']?.signingAlgValuesSupported
                .cast<String>() ??
            [],
        credentialMetadata.cryptographicBindingMethods ?? [],
        wallet,
        tokenResponse.cNonce,
        credentialIssuer,
        clientId,
        k);
  } else {
    logger.d('Proof type nicht unterstützt');
    showErrorMessage(
      AppLocalizations.of(navigatorKey.currentContext!)!
          .credentialDownloadFailed,
    );
    return;
  }

  var credentialRequest = OidCredentialRequest(
      format: credentialMetadata.format,
      credentialType: credentialMetadata.credentialType,
      context: credentialMetadata.context,
      proof: [
        CredentialRequestProof(proofType: proofType, proofValue: proofValue)
      ]);

  KeyPair? decryptionKey;
  if (metadata.credentialResponseEncryptionRequired ?? false) {
    var alg = metadata.credentialResponseEncryptionAlgSupported!;
    if (alg.contains('RSA-OAEP-256')) {
      credentialRequest.responseEncryptionAlg = 'RSA-OAEP-256';
      decryptionKey = KeyPair.generateRsa();
      var jwk = {
        'alg': 'RSA-OAEP-256',
        'kty': 'RSA',
        'use': 'enc',
        'e': removePaddingFromBase64(base64UrlEncode(x509
            .bigIntToByteData(
                (decryptionKey.publicKey as RsaPublicKey).exponent)
            .buffer
            .asUint8List())),
        'n': removePaddingFromBase64(base64UrlEncode(x509
            .bigIntToByteData((decryptionKey.publicKey as RsaPublicKey).modulus)
            .buffer
            .asUint8List()))
      };
      credentialRequest.responseEncryptionJwk = jwk;
      credentialRequest.responseEncryptionEnc =
          metadata.credentialResponseEncryptionEncSupported!.first;
    }
  }

  logger.d(credentialRequest.toJson());

  logger.d('credential Endpoint: ${metadata.credentialEndpoint}');

  var headers = <String, String>{
    'Content-Type': 'application/json',
  };
  if (dpopDid != null && dpopJti != null) {
    headers['Authorization'] = 'DPoP ${tokenResponse.accessToken}';
    var dpopPayload = {
      'jti': dpopJti,
      'htm': 'POST',
      'htu': metadata.credentialEndpoint,
      'nonce': dpopNonce,
      'ath': removePaddingFromBase64(base64UrlEncode(
          sha256.convert(ascii.encode(tokenResponse.accessToken!)).bytes))
    };
    var jwt =
        sd_jwt.Jwt(additionalClaims: dpopPayload, issuedAt: DateTime.now());
    var dpopJwk = multibaseKeyToJwk(dpopDid.replaceAll('did:key:', ''));
    var dpopJws = await jwt.sign(
        signer: WalletCryptoProviderForSdJwt(wallet.wallet, dpopDid),
        header: sd_jwt.JwsJoseHeader(
            algorithm: sd_jwt.SigningAlgorithm.ecdsaSha256Prime,
            jsonWebKey: sd_jwt.Jwk.fromJson(dpopJwk),
            type: 'dpop+jwt'));
    logger.d(dpopPayload);

    headers['DPoP'] = dpopJws.toCompactSerialization();

    logger.d(dpopPayload);
  } else {
    headers['Authorization'] = 'Bearer ${tokenResponse.accessToken}';
  }

  var credentialResponse = await post(Uri.parse(metadata.credentialEndpoint),
          headers: headers, body: credentialRequest.toString())
      .timeout(const Duration(seconds: 20), onTimeout: () {
    return Response('Timeout', 400);
  });

  if (credentialResponse.statusCode == 200) {
    OidCredentialResponse decodedCredentialResponse;
    logger.d(credentialResponse.body);
    if (decryptionKey != null) {
      try {
        decodedCredentialResponse =
            decryptResponse(decryptionKey, credentialResponse.body);
      } catch (e) {
        logger.d('Fehler beim Entschlüsseln');
        showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!
              .credentialDownloadFailed,
        );
        return;
      }
    } else {
      decodedCredentialResponse =
          OidCredentialResponse.fromJson(credentialResponse.body);
    }
    var format = credentialMetadata.format;

    if (decodedCredentialResponse.transactionId != null) {
      // deferred flow
      if (metadata.deferredCredentialEndpoint == null) {
        logger.d('No deferred endpoint');
        showErrorMessage(AppLocalizations.of(navigatorKey.currentContext!)!
            .credentialDownloadFailed);
        return;
      }
      logger.d('deferred request after 3 seconds');
      Timer(
          const Duration(seconds: 3),
          () => sendDeferredRequest(
              format,
              credentialDid,
              wallet,
              keyType,
              credentialIssuer,
              tokenResponse.accessToken!,
              metadata!.deferredCredentialEndpoint!,
              decodedCredentialResponse.transactionId!,
              decryptionKey));
    } else {
      storeCredential(format, decodedCredentialResponse.credential,
          credentialDid, wallet, credentialIssuer);
    }
  } else {
    logger.d(credentialResponse.statusCode);
    logger.d(credentialResponse.headers);
    logger.d(credentialResponse.body);

    showErrorMessage(AppLocalizations.of(navigatorKey.currentContext!)!
        .credentialDownloadFailed);
  }
}

OidCredentialResponse decryptResponse(KeyPair decryptionKey, String data) {
  logger.d('decryption');
  var split = data.split('.');
  logger.d('length: ${split.length}');
  var header =
      jsonDecode(utf8.decode(base64Decode(addPaddingToBase64(split.first))));
  logger.d(header);
  var encryptedKey = base64Decode(addPaddingToBase64(split[1]));
  var iv = base64Decode(addPaddingToBase64(split[2]));
  var cipher = base64Decode(addPaddingToBase64(split[3]));
  var tag = base64Decode(addPaddingToBase64(split[4]));

  var encryptor = decryptionKey.privateKey!
      .createEncrypter(algorithms.encryption.rsa.oaep256);
  var decrypted = encryptor.decrypt(EncryptionResult(encryptedKey));

  logger.d(iv);

  var symmetric = SymmetricKey(keyValue: decrypted);
  Encrypter symmetricDecrypt;
  var enc = header['enc'];
  if (enc == 'A128CBC-HS256') {
    symmetricDecrypt =
        symmetric.createEncrypter(algorithms.encryption.aes.cbcWithHmac.sha256);
  } else if (enc == 'A192CBC-HS384') {
    symmetricDecrypt =
        symmetric.createEncrypter(algorithms.encryption.aes.cbcWithHmac.sha384);
  } else if (enc == 'A256CBC-HS512') {
    symmetricDecrypt =
        symmetric.createEncrypter(algorithms.encryption.aes.cbcWithHmac.sha512);
  } else if (enc == 'A128GCM' || enc == 'A192GCM' || enc == 'A256GCM') {
    symmetricDecrypt = symmetric.createEncrypter(algorithms.encryption.aes.gcm);
  } else {
    throw Exception('Unknown encryption');
  }
  var decrypted2 = symmetricDecrypt.decrypt(EncryptionResult(cipher,
      initializationVector: iv,
      authenticationTag: tag,
      additionalAuthenticatedData: ascii.encode(split.first)));
  logger.d(utf8.decode(decrypted2));
  return OidCredentialResponse.fromJson(utf8.decode(decrypted2));
}

sendDeferredRequest(
    String format,
    String credentialDid,
    WalletProvider wallet,
    KeyType keyType,
    String credentialIssuer,
    String authToken,
    String endpoint,
    String transactionId,
    KeyPair? decryptionKey) async {
  var credentialResponse = await post(Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken'
          },
          body: jsonEncode({'transaction_id': transactionId}))
      .timeout(const Duration(seconds: 20), onTimeout: () {
    return Response('Timeout', 400);
  });

  if (credentialResponse.statusCode == 200) {
    OidCredentialResponse decodedCredentialResponse;

    if (decryptionKey != null) {
      try {
        decodedCredentialResponse =
            decryptResponse(decryptionKey, credentialResponse.body);
      } catch (e) {
        showErrorMessage(AppLocalizations.of(navigatorKey.currentContext!)!
            .credentialDownloadFailed);
        return;
      }
    } else {
      decodedCredentialResponse =
          OidCredentialResponse.fromJson(credentialResponse.body);
    }
    storeCredential(format, decodedCredentialResponse.credential, credentialDid,
        wallet, credentialIssuer);
  } else {
    logger.d('${credentialResponse.statusCode} / ${credentialResponse.body}');
    var parsedBody = jsonDecode(credentialResponse.body);
    var error = parsedBody['error'];
    if (error == 'issuance_pending') {
      int interval = parsedBody['interval'] ?? 5;
      Timer(
          Duration(seconds: interval),
          () => sendDeferredRequest(
              format,
              credentialDid,
              wallet,
              keyType,
              credentialIssuer,
              authToken,
              endpoint,
              transactionId,
              decryptionKey));
    } else {
      showErrorMessage(AppLocalizations.of(navigatorKey.currentContext!)!
          .credentialDownloadFailed);
    }
  }
}

storeCredential(String format, dynamic credential, String credentialDid,
    WalletProvider wallet, String credentialIssuer) async {
  if (format == OidCredentialFormat.msoMdoc) {
    printWrapped(credential);
    logger.d(cborDecode(base64Decode(addPaddingToBase64(credential))));
    var data = IssuerSignedObject.fromCbor(
        base64Decode(addPaddingToBase64(credential)));
    var doc = data;
    var verified = await verifyMso(doc);
    if (verified) {
      var signedData = MobileSecurityObject.fromCbor(doc.issuerAuth.payload);
      logger.d(signedData.deviceKeyInfo.deviceKey);
      var did = coseKeyToDid(signedData.deviceKeyInfo.deviceKey);
      logger.d('$did == $credentialDid');
      if (did != credentialDid) {
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .wrongCredentialNote2);
        return;
      }
      logger.d(wallet.getOsKeyStoreIdForDid(did));
      var credSubject = <String, dynamic>{'id': credentialDid};
      doc.items.forEach((key, value) {
        for (var i in value) {
          credSubject[i.dataElementIdentifier] = i.dataElementValue.toString();
        }
      });

      var vc = VerifiableCredential(
          context: [
            credentialsV1Iri,
            'schema.org'
          ],
          type: [
            'IsoMdlCredential',
            signedData.docType
          ],
          issuer: {
            'name': 'IsoMdlIssuer',
            'certificate':
                base64UrlEncode(doc.issuerAuth.unprotected.x509chain!.first)
          },
          credentialSubject: credSubject,
          issuanceDate: signedData.validityInfo.validFrom,
          expirationDate: signedData.validityInfo.validUntil);

      logger.d(vc.toJson());

      // var storageCred = wallet.getCredential(credentialDid);
      //
      // if (storageCred == null) {
      //   showErrorMessage(
      //       AppLocalizations.of(navigatorKey.currentContext!)!.saveError,
      //       AppLocalizations.of(navigatorKey.currentContext!)!.saveErrorNote);
      //   return;
      // }

      wallet.storeCredential(
        vc,
        credentialDid,
        isoMdlData: '$isoPrefix:${base64Encode(doc.toEncodedCbor())}',
      );
      wallet.storeExchangeHistoryEntry(
          credentialDid, DateTime.now(), 'issue', credentialIssuer);

      showSuccessMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.credentialReceived,
          signedData.docType);
    }
  } else if (format == OidCredentialFormat.sdJwt) {
    printWrapped(credential);
    var parsed = sd_jwt.SdJws.fromCompactSerialization(credential);
    logger.d(parsed.jsonContent());
    var iss = parsed.jsonContent()['payload']['iss'];
    var issMetaUrl = '$iss/.well-known/jwt-vc-issuer';

    logger.d(issMetaUrl);

    var metaRes = await get(Uri.parse(issMetaUrl));
    if (metaRes.statusCode != 200) {
      logger.d('Kein Public Key, Verifikation nicht möglich');
      showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
      );
      return;
    }

    var data = jsonDecode(metaRes.body);
    var jwks = data['jwks'];
    logger.d(jwks);
    List keys = jwks['keys'];
    logger.d(keys);
    Map k = keys.first;
    var jwk = sd_jwt.Jwk.fromJson(
        k.map((key, value) => MapEntry(key as String, value)));
    var sd = sd_jwt.SdJwt.fromSdJws(parsed);
    var verified = await sd.verify(parsed,
        sd_jwt.PointyCastleCryptoProvider(jwk.key as sd_jwt.EcPublicKey));

    if (!verified) {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .wrongCredentialNote);
    }

    var cnf = sd.confirmation!.toJson();
    logger.d(cnf['jwk']);
    var multibase = jwkToMultiBase(cnf['jwk']);
    logger.d('$credentialDid, did:key:$multibase');
    var restoredDid = 'did:key:$multibase';
    if (restoredDid != credentialDid) {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .wrongCredentialNote2);
    }

    var claims = sd.additionalClaims ?? {};
    var type = claims.remove('vct');
    claims['id'] = restoredDid;

    var vc = VerifiableCredential(
        id: restoredDid,
        context: [credentialsV1Iri, schemaOrgIri],
        type: ['VerifiableCredential', type],
        issuer: {
          'id': credentialIssuer,
          if (jwk.x509CertificateChain != null)
            'certificate': jwk.x509CertificateChain!.first
        },
        credentialSubject: claims,
        issuanceDate: sd.issuedAt,
        expirationDate: sd.expirationTime);

    // var storageCred = wallet.getCredential(restoredDid);
    // if (storageCred == null) {
    //   showErrorMessage(
    //       AppLocalizations.of(navigatorKey.currentContext!)!.saveError,
    //       AppLocalizations.of(navigatorKey.currentContext!)!.saveErrorNote);
    //   return;
    // }

    wallet.storeCredential(vc, restoredDid,
        isoMdlData: '$sdPrefix:$credential');
    wallet.storeExchangeHistoryEntry(
        credentialDid, DateTime.now(), 'issue', credentialIssuer);

    showSuccessMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.credentialReceived,
        type);
    return;
  } else {
    logger.d(credential);
    var asVc = VerifiableCredential.fromJson(credential);

    var verified = false;
    try {
      verified = await asVc.verify(loadDocument: loadDocumentFast);
    } catch (e) {
      showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
        AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredentialNote,
      );
      return;
    }

    logger.d(verified);
    if (verified) {
      var credDid = asVc.credentialSubject['id'];
      logger.d(credDid);
      // var storageCred = wallet.getCredential(credDid.split('#').first);
      // if (storageCred == null) {
      //   showErrorMessage(
      //       AppLocalizations.of(navigatorKey.currentContext!)!.saveError,
      //       AppLocalizations.of(navigatorKey.currentContext!)!.saveErrorNote);
      //   return;
      // }

      wallet.storeCredential(asVc, credDid);
      wallet.storeExchangeHistoryEntry(
          credDid, DateTime.now(), 'issue', credentialIssuer);

      showSuccessMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.credentialReceived,
          getTypeToShow(asVc.type));
    }
  }
}

Future<void> handlePresentationRequestOid(String request) async {
  var asUri = Uri.parse(request);
  PresentationDefinition? definition;
  String? nonce, responseUri;
  ClientMetaData? clientMetaData;

  nonce = asUri.queryParameters['nonce'];
  var redirectUri = asUri.queryParameters['redirect_uri'];
  var requestUri = asUri.queryParameters['request_uri'];
  var clientId = asUri.queryParameters['client_id'];
  var presDef = asUri.queryParameters['presentation_definition'];
  var presDefUri = asUri.queryParameters['presentation_definition_uri'];
  var state = asUri.queryParameters['state'];
  var responseMode = asUri.queryParameters['response_mode'];
  logger.d('State: $state');

  if (clientId == null) {
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsTitle,
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsNote);
    logger.d('client id null');
    return;
  }

  if (presDef != null) {
    // Case 1: Every relevant information is in original query-parameters
    logger.d(presDef);
    definition = PresentationDefinition.fromJson(presDef);
  } else if (presDefUri != null) {
    // Case 2: presentation definition must be fetched
    logger.d(presDefUri);
    var res = await get(Uri.parse(presDefUri), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    });
    if (res.statusCode == 200) {
      definition = PresentationDefinition.fromJson(res.body);
    } else {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.downloadFailed,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .downloadFailedExplanation);
      logger.d('no presentation definition found at $presDefUri');
      return;
    }
  } else {
    // Case 3: the total request must be fetched
    logger.d(requestUri);
    logger.d(clientId);

    if (requestUri == null) {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.downloadFailed,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .downloadFailedExplanation);
      logger.d('requestUri null');
      return;
    }
    logger.d(requestUri);
    var requestRaw = await get(Uri.parse(requestUri), headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    });
    logger.d(requestRaw.statusCode);
    if (requestRaw.statusCode != 200) {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.downloadFailed,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .downloadFailedExplanation);
      logger.d('Request nicht gefunden');
      return;
    }
    logger.d(requestRaw.headers);
    logger.d(requestRaw.body);

    RequestObject requestObject;
    if (isRawJson(requestRaw.body)) {
      logger.d('raw json');
      requestObject = RequestObject.fromJson(requestRaw.body);
    } else {
      // it is a jwt/jws (as normally expected)
      logger.d('jwt');
      var payload = requestRaw.body.split('.')[1];
      logger.d(
          jsonDecode(utf8.decode(base64Decode(addPaddingToBase64(payload)))));
      requestObject = RequestObject.fromJson(
          utf8.decode(base64Decode(addPaddingToBase64(payload))));
    }

    if (requestObject.clientMetaDataUri != null) {
      var metaDataResponse =
          await get(Uri.parse(requestObject.clientMetaDataUri!));
      if (metaDataResponse.statusCode == 200) {
        clientMetaData = ClientMetaData.fromJson(metaDataResponse.body);
      }
    } else {
      clientMetaData = requestObject.clientMetaData;
    }

    logger.d(requestObject.nonce);
    logger.d(requestObject.presentationDefinition);
    logger.d(requestObject.responseMode);
    redirectUri = requestObject.redirectUri;
    logger.d(redirectUri);
    definition = requestObject.presentationDefinition;
    nonce = requestObject.nonce;
    responseMode = requestObject.responseMode;
    responseUri = requestObject.responseUri;
    state = requestObject.state;
  }

  if (nonce == null) {
    logger.d('no nonce');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsTitle,
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsNote);
    return;
  }

  logger.d('Response Mode: $responseMode');

  var wallet =
      Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false);

  var allCreds = wallet.allCredentials();
  var isoCreds = wallet.isoMdocCredentials;
  List<VerifiableCredential> creds = [];
  List<IssuerSignedObject> isoCredsParsed = [];
  List<sd_jwt.SdJws> sdJwtCredentials = [];
  allCreds.forEach((key, value) {
    if (value.verifiableCredential != '') {
      var vc = VerifiableCredential.fromJson(value.verifiableCredential);
      var type = getTypeToShow(vc.type);
      if (type != 'PaymentReceipt') {
        creds.add(vc);
      }
    }
  });

  for (var cred in isoCreds) {
    isoCredsParsed.add(IssuerSignedObject.fromCbor(
        base64Decode(cred.metadata.replaceAll('$isoPrefix:', ''))));
  }

  for (var c in wallet.sdJwtCredentials) {
    sdJwtCredentials.add(sd_jwt.SdJws.fromCompactSerialization(
        c.metadata.replaceAll('$sdPrefix:', '')));
  }

  if (definition == null) {
    logger.d('No presentation definition');
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsTitle,
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsNote);
    return;
  }

  try {
    logger.d(isoCredsParsed.length);
    var filtered = searchCredentialsForPresentationDefinition(definition,
        credentials: creds,
        isoMdocCredentials: isoCredsParsed,
        sdJwtCredentials: sdJwtCredentials);
    logger.d(
        'successfully filtered: sdLength: ${filtered.first.sdJwtCredentials?.length}');

    var target = PresentationRequestDialog(
      definition: definition,
      definitionHash: '',
      otherEndpoint: responseUri ?? redirectUri ?? clientId,
      receiverDid: clientId,
      myDid: 'myDid',
      results: filtered,
      isOidc: true,
      nonce: nonce,
      oidcState: state,
      oidcResponseMode: responseMode,
      oidcClientMetadata: clientMetaData,
      oidcRedirectUri: redirectUri,
    );

    navigateClassic(target);
  } catch (e) {
    logger.e(e);
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsTitle,
        AppLocalizations.of(navigatorKey.currentContext!)!.noCredentialsNote);
  }
}
