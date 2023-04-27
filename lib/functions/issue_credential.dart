import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/currency_display.dart';
import 'package:id_ideal_wallet/basicUi/standard/modal_dismiss_wrapper.dart';
import 'package:id_ideal_wallet/basicUi/standard/payment_finished.dart';
import 'package:id_ideal_wallet/functions/payment_utils.dart';
import 'package:uuid/uuid.dart';

import '../constants/server_address.dart';
import '../provider/wallet_provider.dart';
import '../views/offer_credential_dialog.dart';
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

  //payment requested?
  String? toPay;
  String? invoice;
  String? paymentId, lnInKey, lnAdminKey;

  if (message.attachments!.length > 1) {
    logger.d('with payment');
    var paymentReq = message.attachments!.where(
        (element) => element.format != null && element.format == 'lnInvoice');
    if (paymentReq.isNotEmpty) {
      invoice = paymentReq.first.data.json!['lnInvoice'] ?? '';

      var paymentTypes = wallet.getSuitablePaymentCredentials(invoice!);

      if (paymentTypes.isEmpty) {
        await showModalBottomSheet(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            context: navigatorKey.currentContext!,
            builder: (context) {
              return PaymentFinished(
                headline: "Zahlung nicht möglich",
                success: false,
                amount: CurrencyDisplay(
                    amount: "-$toPay",
                    symbol: '€',
                    mainFontSize: 35,
                    centered: true),
                additionalInfo: Column(children: const [
                  SizedBox(height: 20),
                  Text(
                      "Sie besitzen kein LN-Wallet. \nBitte legen Sie sich eines an und sorgen für ausreichend Deckung.",
                      style: TextStyle(color: Colors.red),
                      overflow: TextOverflow.ellipsis),
                ]),
              );
            });
        return false;
      }

      //TODO: ask user which to use
      paymentId = paymentTypes.first.id!;
      var paymentType = paymentTypes.first.credentialSubject['paymentType'];

      if (paymentType != 'SimulatedPayment') {
        lnInKey = wallet.getLnInKey(paymentId);
        lnAdminKey = wallet.getLnAdminKey(paymentId);
        var decoded = await decodeInvoice(lnInKey!, invoice);
        toPay = decoded.amount.toEuro().toStringAsFixed(2);
        logger.d(toPay);
        logger.d(decoded.amount.milliSatoshi);
      } else {
        toPay = invoice;
      }
    }
  }
  Map<String, String> paymentDetails = {};
  //No
  if (entry == null ||
      entry.protocol == DidcommProtocol.discoverFeature.value) {
    //show data to user
    var res = await showCupertinoModalPopup(
        context: navigatorKey.currentContext!,
        barrierColor: Colors.white,
        builder: (BuildContext context) =>
            buildOfferCredentialDialog(context, message.detail!, toPay));

    //pay the credential
    if (res) {
      if (invoice != null) {
        try {
          if (lnAdminKey != null) {
            await payInvoice(lnAdminKey, invoice);
            wallet.getLnBalance(paymentId!);
          } else {
            wallet.fakePay(paymentId!, double.parse(toPay!));
          }
          logger.d('erfolgreich bezahlt');
          paymentDetails['paymentId'] = paymentId;
          paymentDetails['value'] = '-$toPay';
          paymentDetails['note'] =
              '${message.detail!.first.credential.type.firstWhere((element) => element != 'VerifiableCredential')} empfangen';

          showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              context: navigatorKey.currentContext!,
              builder: (context) {
                return ModalDismissWrapper(
                  child: PaymentFinished(
                    headline: "Zahlung erfolgreich",
                    success: true,
                    amount: CurrencyDisplay(
                        amount: "-$toPay",
                        symbol: '€',
                        mainFontSize: 35,
                        centered: true),
                  ),
                );
              });
        } catch (e) {
          showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              context: navigatorKey.currentContext!,
              builder: (context) {
                return PaymentFinished(
                  headline: "Zahlung fehlgeschlagen",
                  success: false,
                  amount: CurrencyDisplay(
                      amount: "-$toPay",
                      symbol: '€',
                      mainFontSize: 35,
                      centered: true),
                  additionalInfo: Column(children: const [
                    SizedBox(height: 20),
                    Text("Zahlung konnte nicht durchgeführt werden",
                        style: TextStyle(color: Colors.red)),
                  ]),
                );
              });
        }
      }
    } else {
      logger.d('user declined credential');
      // TODO: send problem report
      return false;
    }
  }

  if (entry == null) {
    myDid = await wallet.newConnectionDid();
  } else {
    myDid = entry.myDid;
  }

  //check, if we control did
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
  if (previosMessage.type == DidcommMessages.requestCredential) {
    for (int i = 0; i < message.credentials!.length; i++) {
      var req = RequestCredential.fromJson(previosMessage.toJson());
      var cred = message.credentials![i];
      var challenge = req.detail![i].options.challenge;
      var verified = await verifyCredential(cred, expectedChallenge: challenge);
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

        var type = cred.type
            .firstWhere((element) => element != 'VerifiableCredential');
        if (credDid == '') {
          credDid = '${cred.issuanceDate.toIso8601String()}$type';
        }

        if (type == 'PaymentReceipt') {
          wallet.storeCredential(cred.toString(), storageCred?.hdPath ?? '',
              cred.credentialSubject['receiptId']);
        } else {
          wallet.storeCredential(
              cred.toString(), storageCred?.hdPath ?? '', credDid);
          wallet.storeExchangeHistoryEntry(
              credDid, DateTime.now(), 'issue', message.from!);

          showModalBottomSheet(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              context: navigatorKey.currentContext!,
              builder: (context) {
                return ModalDismissWrapper(
                  child: PaymentFinished(
                    headline: "Credential empfangen",
                    success: true,
                    amount: CurrencyDisplay(
                        amount: type,
                        symbol: '',
                        mainFontSize: 35,
                        centered: true),
                  ),
                );
              });
        }
      } else {
        throw Exception('Credential signature is wrong');
      }

      wallet.storeConversation(message, entry.myDid);

      var ack = EmptyMessage(
          from: entry.myDid,
          ack: [message.id],
          threadId: message.threadId ?? message.id);

      sendMessage(
          entry.myDid,
          determineReplyUrl(message.replyUrl, message.replyTo),
          wallet,
          ack,
          message.from!);
    }
  } else {
    throw Exception(
        'Issue credential could only follow to request credential message');
  }
  return false;
}
