import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/currency_display.dart';
import 'package:id_ideal_wallet/basicUi/standard/modal_dismiss_wrapper.dart';
import 'package:id_ideal_wallet/basicUi/standard/payment_finished.dart';
import 'package:id_ideal_wallet/constants/kaprion_context.dart';
import 'package:id_ideal_wallet/functions/payment_utils.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/views/credential_offer_new.dart';
import 'package:id_ideal_wallet/views/payment_method_selection.dart';
import 'package:uuid/uuid.dart';

import '../constants/server_address.dart';
import '../provider/wallet_provider.dart';
import 'didcomm_message_handler.dart';

bool handleProposeCredential(ProposeCredential message, WalletProvider wallet) {
  throw Exception('We should never get such a message');
}

Future<bool> handleRequestCredential(
    RequestCredential message, WalletProvider wallet) async {
  String threadId;
  logger.d('Request Credential received');
  if (message.threadId != null) {
    threadId = message.threadId!;
  } else {
    threadId = message.id;
  }

  // Are there any previous messages?
  var entry = wallet.getConversation(threadId);

  // no -> This is a Problem: We have never offered sth.
  if (entry == null) {
    throw Exception('There is no offer');
  }

  var myDid = entry.myDid;

  var issueMessage = IssueCredential(
      threadId: threadId,
      credentials: [message.detail!.first.credential],
      replyUrl: '$relay/buffer/$myDid',
      from: myDid,
      to: [message.from!]);

  sendMessage(myDid, determineReplyUrl(message.replyUrl, message.replyTo),
      wallet, issueMessage, message.from!);

  return true;
}

Future<bool> handleOfferCredential(
    OfferCredential message, WalletProvider wallet) async {
  String threadId;
  logger.d('Offer Credential received');
  if (message.threadId != null) {
    threadId = message.threadId!;
  } else {
    threadId = message.id;
  }

  //Are there any previous messages?
  var entry = wallet.getConversation(threadId);
  String myDid;
  if (entry == null) {
    myDid = await wallet.newConnectionDid();
  } else {
    myDid = entry.myDid;
  }

  //payment requested?
  String? toPay;
  String? invoice;
  String? paymentId, lnInKey, lnAdminKey;

  if (message.attachments!.length > 1) {
    logger.d('with payment (or credential manifest + fulfillment)');
    var paymentReq = message.attachments!.where(
        (element) => element.format != null && element.format == 'lnInvoice');
    if (paymentReq.isNotEmpty) {
      invoice = paymentReq.first.data.json!['lnInvoice'] ?? '';

      var paymentTypes = wallet.paymentCredentials;

      if (paymentTypes.isEmpty) {
        showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.noPaymentMethod,
          AppLocalizations.of(navigatorKey.currentContext!)!
              .noPaymentMethodNote,
        );
        return false;
      }

      // String paymentId;
      if (paymentTypes.length > 1) {
        int? selectedIndex =
            await Future.delayed(const Duration(seconds: 1), () async {
          return await Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                  builder: (context) =>
                      PaymentMethodSelector(paymentMethods: paymentTypes)));
        });
        logger.d(selectedIndex);
        if (selectedIndex == null) {
          return false;
        } else {
          paymentId = paymentTypes[selectedIndex].id!;
        }
      } else {
        paymentId = paymentTypes.first.id!;
      }

      lnInKey = wallet.getLnInKey(paymentId);
      lnAdminKey = wallet.getLnAdminKey(paymentId);
      var decoded = await decodeInvoice(lnInKey!, invoice!);
      toPay = decoded.amount.toSat().toString();
      logger.d(toPay);
      logger.d(decoded.amount.milliSatoshi);
    }
  }
  Map<String, String> paymentDetails = {};
  DidcommPlaintextMessage? lastMessage;
  if (entry != null) {
    lastMessage = DidcommPlaintextMessage.fromJson(entry.lastMessage);
  }
  logger.d(lastMessage?.type);
  //No
  if (lastMessage == null ||
      entry?.protocol == DidcommProtocol.discoverFeature.value ||
      lastMessage.attachments == null ||
      lastMessage.attachments!.isEmpty) {
    logger.d(message.fulfillment?.verifiableCredential);
    if (message.detail != null && message.detail!.isEmpty) {
      message.detail = null;
    }
    //show data to user
    var res = await showCupertinoModalPopup(
      context: navigatorKey.currentContext!,
      barrierColor: Colors.white,
      builder: (BuildContext context) => CredentialOfferDialogNew(
        credentials: message.detail?.map((e) => e.credential).toList() ??
            message.fulfillment?.verifiableCredential ??
            [],
        toPay: toPay,
      ),
    );

    //pay the credential
    if (res) {
      for (var entry in message.detail ?? <LdProofVcDetail>[]) {
        if (entry.credential.type.contains('PieceOfArt')) {
          wallet.addIssuanceProcess(threadId);
        }
      }
      if (invoice != null) {
        try {
          if (lnAdminKey != null) {
            await payInvoice(lnAdminKey, invoice);
            wallet.getLnBalance(paymentId!);
          } else {
            showErrorMessage('Fatel error', 'kein Zahlungskonto gefunden');
            return false;
          }
          logger.d('erfolgreich bezahlt');
          paymentDetails['paymentId'] = paymentId;
          paymentDetails['value'] = '-$toPay';
          paymentDetails['note'] =
              '${getTypeToShow(message.detail!.first.credential.type)} empfangen';

          showModalBottomSheet(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
              ),
              context: navigatorKey.currentContext!,
              builder: (context) {
                return ModalDismissWrapper(
                  child: PaymentFinished(
                    headline: AppLocalizations.of(navigatorKey.currentContext!)!
                        .paymentSuccessful,
                    success: true,
                    amount: CurrencyDisplay(
                        amount: "-$toPay",
                        symbol: 'sat',
                        mainFontSize: 35,
                        centered: true),
                  ),
                );
              });
        } catch (e) {
          showModalBottomSheet(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10)),
              ),
              context: navigatorKey.currentContext!,
              builder: (context) {
                return PaymentFinished(
                  headline: AppLocalizations.of(context)!.paymentFailed,
                  success: false,
                  amount: CurrencyDisplay(
                      amount: "-$toPay",
                      symbol: 'sat',
                      mainFontSize: 35,
                      centered: true),
                  additionalInfo: Column(children: [
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.paymentFailedNote,
                        style: const TextStyle(color: Colors.red)),
                  ]),
                );
              });
        }
      }
    } else {
      logger.d('user declined credential');
      var reply = determineReplyUrl(message.replyUrl, message.replyTo);
      var problem = ProblemReport(
          replyUrl: '$relay/buffer/$myDid',
          returnRoute: ReturnRouteValue.thread,
          to: [message.from!],
          from: myDid,
          parentThreadId: message.threadId ?? message.id,
          code: 'e.p.user.decline');

      // TODO: sendMessage(myDid, reply, wallet, problem, message.from!);
      return false;
    }
  } else if (lastMessage.type == DidcommMessages.requestCredential ||
      lastMessage.type == DidcommMessages.issueCredential) {
    showErrorMessage(
        AppLocalizations.of(navigatorKey.currentContext!)!.finishProcess,
        AppLocalizations.of(navigatorKey.currentContext!)!.finishProcessNote);
    return false;
  }

  //check, if we control did
  logger.d(message.detail);
  if (message.detail != null && message.detail!.isNotEmpty) {
    for (var credDetail in message.detail!) {
      var subject = credDetail.credential.credentialSubject;
      if (subject.containsKey('id')) {
        String id = subject['id'];
        String? private;
        try {
          private = await wallet.getPrivateKeyForCredentialDid(id);
        } catch (e) {
          _sendProposeCredential(message, wallet, myDid, paymentDetails);
          return false;
        }
        if (private == null) {
          _sendProposeCredential(message, wallet, myDid, paymentDetails);
          return false;
        }
      } else {
        // Issuer likes to issue credential without id (not bound to holder)
        _sendRequestCredential(message, wallet, myDid, paymentDetails);
        return false;
      }
    }
    await _sendRequestCredential(message, wallet, myDid, paymentDetails);
  } else if (message.credentialManifest != null) {
    var request = RequestCredential(
        replyUrl: '$relay/buffer/$myDid',
        threadId: message.threadId ?? message.id,
        returnRoute: ReturnRouteValue.thread,
        parentThreadId: message.parentThreadId,
        from: myDid,
        to: [message.from!]);

    var con = wallet.getConnection(myDid);

    sendMessage(myDid, con!.otherDid, wallet, request, message.from!);
  }
  return false;
}

_sendRequestCredential(
  OfferCredential offer,
  WalletProvider wallet,
  String myDid,
  Map<String, String> paymentDetails,
) async {
  List<LdProofVcDetail> detail = [];
  for (var d in offer.detail!) {
    detail.add(LdProofVcDetail(
        credential: d.credential,
        options: LdProofVcDetailOptions(
            proofType: d.options.proofType,
            challenge: d.credential.proof == null
                ? const Uuid().v4()
                : d.credential.proof!.challenge!)));
  }
  var message = RequestCredential(
      detail: detail,
      replyUrl: '$relay/buffer/$myDid',
      threadId: offer.threadId ?? offer.id,
      returnRoute: ReturnRouteValue.thread,
      from: myDid,
      to: [offer.from!]);

  if (paymentDetails.isNotEmpty) {
    wallet.storePayment(paymentDetails['paymentId']!, paymentDetails['value']!,
        paymentDetails['note']!,
        belongingCredentials: [
          '${detail.first.credential.issuanceDate.toIso8601String()}${paymentDetails['note']!}'
        ]);
  }
  sendMessage(myDid, determineReplyUrl(offer.replyUrl, offer.replyTo), wallet,
      message, offer.from!);
}

_sendProposeCredential(OfferCredential offer, WalletProvider wallet,
    String myDid, Map<String, String> paymentDetails) async {
  List<LdProofVcDetail> detail = [];
  var firstDid = '';
  for (int i = 0; i < offer.detail!.length; i++) {
    var credDid = await wallet.newCredentialDid();
    if (i == 0) {
      firstDid = credDid;
    }
    var offeredCred = offer.detail![i].credential;
    logger.d('Das wurde angeboten: ${offeredCred.toJson()}');
    var credSubject = offeredCred.credentialSubject;
    logger.d(offeredCred.status);
    credSubject['id'] = credDid;
    var newCred = VerifiableCredential(
        id: credDid,
        context: offeredCred.context,
        type: offeredCred.type,
        issuer: offeredCred.issuer,
        credentialSubject: credSubject,
        issuanceDate: offeredCred.issuanceDate,
        credentialSchema: offeredCred.credentialSchema,
        status: offeredCred.status,
        expirationDate: offeredCred.expirationDate);
    logger.d('Das geht zurück : ${newCred.toJson()}');
    detail.add(LdProofVcDetail(
        credential: newCred, options: offer.detail!.first.options));
  }
  var message = ProposeCredential(
      threadId: offer.threadId ?? offer.id,
      from: myDid,
      to: [offer.from!],
      replyUrl: '$relay/buffer/$myDid',
      returnRoute: ReturnRouteValue.thread,
      detail: detail);

  //Sign attachment with credentialDid
  for (var a in message.attachments!) {
    await a.data.sign(wallet.wallet, firstDid);
    var verify = await a.data.verifyJws(firstDid);
    logger.d(verify);
  }

  logger.d(message.toJson());

  if (paymentDetails.isNotEmpty) {
    wallet.storePayment(paymentDetails['paymentId']!, paymentDetails['value']!,
        paymentDetails['note']!,
        belongingCredentials: [firstDid]);
  }

  sendMessage(myDid, determineReplyUrl(offer.replyUrl, offer.replyTo), wallet,
      message, offer.from!);
}

Future<bool> handleIssueCredential(
    IssueCredential message, WalletProvider wallet) async {
  logger.d('Mir wurden Credentials ausgestellt');

  var entry = wallet.getConversation(message.threadId!);
  if (entry == null) {
    throw Exception(
        'Something went wrong. There could not be an issue message without request');
  }

  var previosMessage = DidcommPlaintextMessage.fromJson(entry.lastMessage);
  logger.d(previosMessage.type);
  if (previosMessage.type == DidcommMessages.requestCredential) {
    if (message.credentials != null && message.credentials!.isNotEmpty) {
      for (int i = 0; i < message.credentials!.length; i++) {
        var req = RequestCredential.fromJson(previosMessage.toJson());
        var cred = message.credentials![i];
        var challenge = req.detail![i].options.challenge;
        var verified = true;
        try {
          verified = await verifyCredential(cred, expectedChallenge: challenge);
        } catch (e) {
          showErrorMessage(
              AppLocalizations.of(navigatorKey.currentContext!)!
                  .wrongCredential,
              AppLocalizations.of(navigatorKey.currentContext!)!
                  .wrongCredentialNote);
          return false;
        }
        if (verified) {
          var credDid = getHolderDidFromCredential(cred.toJson());
          Credential? storageCred;
          if (credDid != '') {
            storageCred = wallet.getCredential(credDid);
            if (storageCred == null) {
              throw Exception(
                  'No hd path for credential found. Sure we control it?');
            }
          }

          var type = getTypeToShow(cred.type);
          if (credDid == '') {
            credDid = '${cred.issuanceDate.toIso8601String()}$type';
          }

          if (type == 'PaymentReceipt') {
            wallet.storeCredential(cred.toString(), storageCred?.hdPath ?? '',
                newDid: cred.credentialSubject['receiptId']);
          } else {
            wallet.storeCredential(cred.toString(), storageCred?.hdPath ?? '',
                newDid: credDid);
            wallet.storeExchangeHistoryEntry(
                credDid, DateTime.now(), 'issue', message.from!);

            wallet.removeIssuanceProcess(message.threadId ?? '');

            showSuccessMessage(
                AppLocalizations.of(navigatorKey.currentContext!)!
                    .credentialReceived,
                type);
          }
        } else {
          throw Exception('Credential signature is wrong');
        }

        wallet.storeConversation(message, entry.myDid);

        if (message.pleaseAck != null && message.pleaseAck!.isNotEmpty) {
          var ack = EmptyMessage(
              from: entry.myDid,
              to: [message.from!],
              ack: [message.id],
              threadId: message.threadId ?? message.id);

          sendMessage(
              entry.myDid,
              determineReplyUrl(message.replyUrl, message.replyTo),
              wallet,
              ack,
              message.from!);
        }
      }
    } else if (message.credentialFulfillment != null) {
      var myDid = message.to!.first;
      var connection = wallet.getConnection(myDid);
      logger.d(connection);
      logger.d(message.credentialFulfillment!.toJson());

      VerifiableCredential? myCred;
      String? issuerDid;
      VerifiableCredential? issuerCertCredential;

      if (connection == null) {
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .wrongCredentialNote);
        throw Exception('Big Problem: no connection');
      }

      for (var v in message.credentialFulfillment!.verifiableCredential!) {
        logger.d(v.toJson());
        var holderDid = getHolderDidFromCredential(v.toJson());
        logger.d('$holderDid ?== $myDid');
        if (holderDid == myDid) {
          myCred = v;
          issuerDid = getIssuerDidFromCredential(myCred);
          //break;
          //message.credentialFulfillment!.verifiableCredential!.remove(v);
        }
        logger.d('$holderDid ?== $issuerDid');
        if (issuerDid != null && holderDid == issuerDid) {
          issuerCertCredential = v;
        }
        if (issuerCertCredential != null && myCred != null) {
          break;
        }
      }

      if (myCred == null && issuerCertCredential == null) {
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.saveError,
            AppLocalizations.of(navigatorKey.currentContext!)!.saveErrorNote);
        throw Exception('Cant find my Credential');
      }

      Map? issuerJwk =
          issuerCertCredential?.credentialSubject['publicKey']['publicKeyJwk'];
      if (issuerJwk == null) {
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .wrongCredentialNote);
        throw Exception('no issuer jwk');
      }

      try {
        await verifyCredential(myCred,
            issuerJwk: issuerJwk.cast<String, dynamic>(),
            loadDocumentFunction: loadDocumentKaprion);

        wallet.storeCredential(myCred.toString(), connection.hdPath,
            keyType: KeyType.p384);

        // wallet.storeConfig(
        //     'certCreds:$issuerDid',
        //     jsonEncode(message.credentialFulfillment!.verifiableCredential!
        //         .sublist(1)
        //         .map((e) => e.toJson())
        //         .toList()));

        wallet.storeExchangeHistoryEntry(
            myDid, DateTime.now(), 'issue', message.from!);

        showSuccessMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!
                .credentialReceived,
            getTypeToShow(myCred!.type));
      } catch (e) {
        logger.d(e);
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.wrongCredential,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .wrongCredentialNote);
      }
    }
  } else {
    throw Exception(
        'Issue credential could only follow to request credential message');
  }
  return false;
}
