import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/footer_buttons.dart';
import 'package:id_ideal_wallet/basicUi/standard/issuance_info.dart';
import 'package:id_ideal_wallet/basicUi/standard/requester_info.dart';
import 'package:id_ideal_wallet/basicUi/standard/secured_widget.dart';
import 'package:id_ideal_wallet/basicUi/standard/show_filter_result.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/payment_utils.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/self_issuance.dart';
import 'package:iso_mdoc/iso_mdoc.dart';
import 'package:provider/provider.dart';
import 'package:sd_jwt/sd_jwt.dart' as sd_jwt;
import 'package:x509b/x509.dart';

import '../functions/didcomm_message_handler.dart';
import '../l10n/app_localizations.dart';

class PresentationRequestDialog extends StatefulWidget {
  final List<FilterResult> results;
  final String? name, purpose;
  final String otherEndpoint;
  final bool askForBackground;
  final String? lnInvoice;
  final Map<String, dynamic>? lnInvoiceRequest;
  final List<VerifiableCredential>? paymentCards;
  final X509Certificate? requesterCert;
  final PresentationDefinition definition;

  const PresentationRequestDialog({
    super.key,
    required this.results,
    required this.otherEndpoint,
    required this.definition,
    this.askForBackground = false,
    this.name,
    this.purpose,
    this.lnInvoice,
    this.lnInvoiceRequest,
    this.paymentCards,
    this.requesterCert,
  });

  @override
  PresentationRequestDialogState createState() =>
      PresentationRequestDialogState();
}

class PresentationRequestDialogState extends State<PresentationRequestDialog> {
  // has same length as widget.results
  List<List<bool>> selected = [];
  List<bool> enoughSelected = [];
  bool dataEntered = true;
  bool send = false;
  bool fulfillable = true;
  bool backgroundAllow = true;
  String amount = '';

  @override
  initState() {
    super.initState();

    for (var res in widget.results) {
      fulfillable = fulfillable && res.fulfilled;
      logger.d('fulfilled: ${res.fulfilled} / fulfillable: $fulfillable');
      if (res.selfIssuable != null && res.selfIssuable!.isNotEmpty) {
        dataEntered = false;
      }
      var selectedCreds = <bool>[];
      int innerPos = 0;
      for (var _ in res.isoMdocCredentials ?? []) {
        if (innerPos == 0) {
          selectedCreds.add(true);
        } else {
          selectedCreds.add(res.submissionRequirement?.min != null &&
              innerPos < res.submissionRequirement!.min!);
        }
        innerPos++;
      }
      for (var _ in res.credentials ?? []) {
        if (innerPos == 0) {
          selectedCreds.add(true);
        } else {
          selectedCreds.add(res.submissionRequirement?.min != null &&
              innerPos < res.submissionRequirement!.min!);
        }
        innerPos++;
      }
      for (var _ in res.sdJwtCredentials ?? []) {
        if (innerPos == 0) {
          selectedCreds.add(true);
        } else {
          selectedCreds.add(res.submissionRequirement?.min != null &&
              innerPos < res.submissionRequirement!.min!);
        }
        innerPos++;
      }

      if (res.nestedResults == null) {
        enoughSelected.add(true);
      }

      for (var n in res.nestedResults ?? <FilterResult>[]) {
        if (n.fulfilled) {
          if (innerPos == 0) {
            selectedCreds.add(true);
          } else {
            selectedCreds.add(res.submissionRequirement?.min != null &&
                innerPos < res.submissionRequirement!.min!);
          }
          innerPos++;
          enoughSelected.add(true);
        }
      }

      selected.add(selectedCreds);
    }

    // getAmount();
  }

  Future<void> getAmount() async {
    if (widget.lnInvoice != null && widget.paymentCards != null) {
      var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
          listen: false);
      var paymentId = widget.paymentCards!.first.id!;
      var lnInKey = wallet.getLnInKey(paymentId);
      var i = await decodeInvoice(lnInKey!, widget.lnInvoice!);
      amount = i.amount.toSat().toStringAsFixed(2);
      logger.d(amount);
      setState(() {});
    }
  }

  List<Widget> buildChilds() {
    List<Widget> childList = [];

    //overall name
    if (widget.name != null) {
      childList.add(
        Text(
          widget.name!,
          style: Theme.of(context).primaryTextTheme.headlineLarge,
        ),
      );
      childList.add(const SizedBox(
        height: 10,
      ));
    }

    // Requesting entity
    if (!inOidcTest) {
      childList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: RequesterInfo(
            requesterUrl: widget.otherEndpoint,
            requesterCert: widget.requesterCert,
            followingText:
                ' ${AppLocalizations.of(context)!.noteGetInformation}:',
          ),
        ),
      );
      childList.add(const SizedBox(
        height: 10,
      ));
    }

    if (widget.askForBackground) {
      childList.add(CheckboxListTile(
          title: Text(AppLocalizations.of(context)!.backgroundPresentation),
          subtitle: Text(AppLocalizations.of(context)!
              .backgroundPresentationNote(widget.otherEndpoint)),
          value: backgroundAllow,
          onChanged: (newValue) {
            if (newValue != null) {
              backgroundAllow = newValue;
              setState(() {});
            }
          }));
      childList.add(const SizedBox(
        height: 10,
      ));
    }

    int outerPos = 0;
    for (var result in widget.results) {
      int credCount = result.selfIssuable?.length ?? 0;
      var selectedCredNames = <String>[];

      // var minCount = result.submissionRequirement?.min ??
      //     result.submissionRequirement?.count ??
      //     (result.submissionRequirement?.max == null ? 1 : 0);
      //
      // if (credCount < minCount) {
      //   logger.d('less creds: $credCount < $minCount');
      //   fulfillable = false;
      // }

      if (result.nestedResults == null) {
        childList.add(
          ShowFilterResult(
            key: UniqueKey(),
            result: result,
            selected: selected[outerPos],
            afterCheck: () => enoughSelected[outerPos] =
                selected[outerPos].fold<int>(0, (p, e) => e ? p + 1 : p) >=
                    (result.submissionRequirement?.min ??
                        result.submissionRequirement?.count ??
                        1),
            additionalChildren: [
              ...selfIssuance(result, outerPos),
              if (!result.fulfilled)
                IssuanceInfo(
                    definition: widget.definition,
                    descriptorIds: result.matchingDescriptorIds)
            ],
          ),
        );
      }
      if (result.nestedResults != null && result.nestedResults!.isNotEmpty) {
        int i = 0;
        int current = outerPos;
        for (var nestedResult in result.nestedResults!) {
          if (nestedResult.fulfilled) {
            int currentI = i;
            var nestedTile = ExpansionTile(
              initiallyExpanded: true,
              title: Text('Option ${i + 1}'),
              leading: Checkbox(
                value: selected[current][currentI],
                onChanged: (bool? newValue) {
                  logger.d(selected);
                  setState(() {
                    if (newValue != null) {
                      selected[current][currentI] = newValue;
                      logger.d(selected);
                      enoughSelected[current] = selected[current]
                              .fold<int>(0, (p, e) => e ? p + 1 : p) >=
                          (result.submissionRequirement?.min ??
                              result.submissionRequirement?.count ??
                              1);
                    }
                  });
                },
              ),
              children: [
                ShowFilterResult(result: nestedResult),
              ],
            );

            childList.add(nestedTile);
            i++;
          }
        }
      }
      outerPos++;
    }

    // overall purpose
    if (widget.purpose != null) {
      childList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: RequesterInfo(
                  requesterUrl: widget.otherEndpoint,
                  followingText:
                      ' ${AppLocalizations.of(context)!.notePresentationPurpose}:\n${widget.purpose}'),
            ),
          ),
        ),
      );
    }

    if (widget.lnInvoice != null) {
      childList.add(const SizedBox(
        height: 10,
      ));
      childList.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).primaryTextTheme.titleMedium,
                children: [
                  TextSpan(
                    text: AppLocalizations.of(navigatorKey.currentContext!)!
                        .paymentInformation,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 1,
                        bottom: 5,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 18,
                        // color: Colors.redAccent.shade700,
                      ),
                    ),
                  ),
                  TextSpan(
                      text:
                          '\n${AppLocalizations.of(navigatorKey.currentContext!)!.paymentInformationDetail}',
                      style: Theme.of(context).primaryTextTheme.bodySmall),
                  TextSpan(
                      text: '$amount sat',
                      style: Theme.of(context).primaryTextTheme.titleLarge),
                ],
              ),
            ),
          ),
        ),
      ));
    }

    if (widget.lnInvoiceRequest != null) {
      childList.add(const SizedBox(
        height: 10,
      ));
      childList.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).primaryTextTheme.titleMedium,
                children: [
                  const TextSpan(
                    text: 'Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                      text:
                          '\n${AppLocalizations.of(navigatorKey.currentContext!)!.funding1}',
                      style: Theme.of(context).primaryTextTheme.bodySmall),
                  TextSpan(
                      text: ' ${widget.lnInvoiceRequest?['amount']} sat ',
                      style: Theme.of(context).primaryTextTheme.titleLarge),
                  TextSpan(
                      text: AppLocalizations.of(navigatorKey.currentContext!)!
                          .funding2,
                      style: Theme.of(context).primaryTextTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ));
    }

    return childList;
  }

  List<Widget> selfIssuance(FilterResult result, int outerPos) {
    var widgetList = <Widget>[];
    if (result.selfIssuable != null && result.selfIssuable!.isNotEmpty) {
      var pos = outerPos;
      dataEntered = false;
      // if ((result.credentials != null && result.credentials!.isNotEmpty) ||
      //     (result.isoMdocCredentials != null &&
      //         result.isoMdocCredentials!.isNotEmpty) ||
      //     (result.sdJwtCredentials != null &&
      //         result.sdJwtCredentials!.isNotEmpty)) {
      //   dataEntered = true;
      // }

      for (var i in result.selfIssuable!) {
        //outerTileExpanded = true;
        widgetList.add(
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: () => onSelfIssue(pos, i),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              child: Text(
                  AppLocalizations.of(navigatorKey.currentContext!)!.enterData),
            ),
          ),
        );
      }
    }
    return widgetList;
  }

  onSelfIssue(int pos, InputDescriptorConstraints i) async {
    Map res;
    int index;
    var target = CredentialSelfIssue(
      input: [i],
      outerPos: pos,
    );
    (res, index) = await navigateClassic(target);
    if (res.isNotEmpty) {
      var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
          listen: false);
      var did = await wallet.newCredentialDid();

      var credSubject = <dynamic, dynamic>{'id': did};
      credSubject.addAll(res);
      var cred = VerifiableCredential(
          context: [credentialsV1Iri, 'https://schema.org', ed25519ContextIri],
          type: ['VerifiableCredential', 'SelfIssuedCredential'],
          id: did,
          issuer: did,
          credentialSubject: credSubject,
          issuanceDate: DateTime.now());
      var (signer, proofType) = await getCredentialSigningStuff(wallet, did);
      await cred.sign(signer, proofType);
      logger.d(cred.toJson());
      widget.results[index].selfIssuable!.remove(i);
      if (widget.results[index].selfIssuable!.isEmpty) {
        widget.results[index].selfIssuable = null;
      }
      var cList = widget.results[index].credentials ?? [];
      cList.add(cred);
      widget.results[index].credentials = cList;
      logger.d(widget.results);
      var m = selected[pos];
      m.insert(widget.results[index].credentials!.length - 1, true);
      dataEntered = true;
      setState(() {});
    }
  }

  (bool, List<FilterResult>) sendAnswer() {
    setState(() {
      send = true;
    });

    List<FilterResult> finalSend = [];

    for (int i = 0; i < widget.results.length; i++) {
      var result = widget.results[i];
      var selectInfo = selected[i];
      List<VerifiableCredential> credList = [];
      List<IssuerSignedObject> credListIso = [];
      List<sd_jwt.SdJws> credListSd = [];
      List<FilterResult> nestedResult = [];

      int innerPos = 0;

      if (result.nestedResults == null) {
        for (var cred in result.isoMdocCredentials ?? <IssuerSignedObject>[]) {
          if (selectInfo[innerPos]) {
            credListIso.add(cred);
          }
          innerPos++;
        }

        for (var cred in result.credentials ?? <VerifiableCredential>[]) {
          if (selectInfo[innerPos]) {
            credList.add(cred);
          }
          innerPos++;
        }

        for (var cred in result.sdJwtCredentials ?? <sd_jwt.SdJws>[]) {
          if (selectInfo[innerPos]) {
            credListSd.add(cred);
          }
          innerPos++;
        }
      } else {
        for (var nest in result.nestedResults!) {
          if (nest.fulfilled) {
            if (selectInfo[innerPos]) {
              nestedResult.add(nest);
            }
            innerPos++;
          }
        }
      }

      finalSend.add(FilterResult(
          credentials: credList.isNotEmpty ? credList : null,
          isoMdocCredentials: credListIso.isNotEmpty ? credListIso : null,
          sdJwtCredentials: credListSd.isNotEmpty ? credListSd : null,
          nestedResults: nestedResult.isNotEmpty ? nestedResult : null,
          matchingDescriptorIds: result.matchingDescriptorIds,
          presentationDefinitionId: result.presentationDefinitionId,
          submissionRequirement: result.submissionRequirement));
    }

    return (backgroundAllow, finalSend);
  }

  void reject() async {
    logger.d('user declined presentation');
    Navigator.of(context).pop((false, null));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SecuredWidget(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: buildChilds(),
                ),
              ),
            ),
          ),
          persistentFooterButtons: [
            if (!dataEntered)
              FooterErrorText(
                  errorMessage: AppLocalizations.of(context)!.missingDataNote,
                  reject: reject)
            else if (!fulfillable)
              FooterErrorText(
                  errorMessage:
                      AppLocalizations.of(context)!.errorNotEnoughCredentials,
                  reject: reject)
            else if (!enoughSelected.fold<bool>(true, (p, e) => p && e))
              FooterErrorText(
                  errorMessage:
                      AppLocalizations.of(context)!.errorNotEnoughSelected,
                  reject: reject)
            else
              FooterButtons(
                positiveText: widget.lnInvoice != null
                    ? AppLocalizations.of(context)!.orderWithPayment
                    : null,
                negativeFunction: reject,
                positiveFunction: () async {
                  try {
                    Navigator.of(context).pop(sendAnswer());
                  } catch (e) {
                    logger.d(e);
                    Navigator.of(context).pop((false, null));
                    showErrorMessage(
                        AppLocalizations.of(navigatorKey.currentContext!)!
                            .sendFailed);
                  }
                },
              )
          ],
        ),
        if (send)
          const Opacity(
            opacity: 0.8,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (send)
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(
                  height: 10,
                ),
                DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    child: Text(
                      '${AppLocalizations.of(context)!.waiting}\n${AppLocalizations.of(context)!.waitingSendPresentation}',
                    ))
              ],
            ),
          ),
      ],
    );
  }
}

class FooterErrorText extends StatelessWidget {
  final void Function() reject;
  final String errorMessage;

  const FooterErrorText(
      {super.key, required this.errorMessage, required this.reject});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).primaryTextTheme.titleMedium,
              children: [
                TextSpan(
                  text: AppLocalizations.of(context)!.attention,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 1,
                      bottom: 5,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Colors.redAccent.shade700,
                    ),
                  ),
                ),
                TextSpan(
                    text: '\n$errorMessage',
                    style: Theme.of(context).primaryTextTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        ElevatedButton(
            onPressed: reject,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
            ),
            child: Text(AppLocalizations.of(context)!.cancel))
      ],
    );
  }
}
