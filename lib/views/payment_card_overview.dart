import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/currency_display.dart';
import 'package:id_ideal_wallet/basicUi/standard/heading.dart';
import 'package:id_ideal_wallet/basicUi/standard/styled_scaffold_title.dart';
import 'package:id_ideal_wallet/basicUi/standard/transaction_preview.dart';
import 'package:id_ideal_wallet/constants/navigation_pages.dart';
import 'package:id_ideal_wallet/functions/payment_utils.dart';
import 'package:id_ideal_wallet/provider/navigation_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/credential_page.dart';
import 'package:provider/provider.dart';

class PaymentCardOverview extends StatefulWidget {
  const PaymentCardOverview({super.key});

  @override
  PaymentCardOverviewState createState() => PaymentCardOverviewState();
}

class PaymentCardOverviewState extends State<PaymentCardOverview> {
  String currentSelection = '';
  bool adding = false;

  @override
  void initState() {
    super.initState();
    var w = Provider.of<WalletProvider>(context, listen: false);
    currentSelection =
        w.paymentCredentials.isEmpty ? '' : w.paymentCredentials.first.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(builder: (context, wallet, child) {
      VerifiableCredential toShow = wallet.paymentCredentials.firstWhere(
          (element) => element.id == currentSelection,
          orElse: () => VerifiableCredential(
              context: [credentialsV1Iri],
              type: [],
              issuer: '',
              credentialSubject: {},
              issuanceDate: DateTime.now()));

      List<Widget> content = [];
      content.add(Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 45,
              child: ElevatedButton(
                  onPressed: () => Provider.of<NavigationProvider>(context,
                          listen: false)
                      .changePage([NavigationPage.topUp], credential: toShow),
                  child: Text(AppLocalizations.of(context)!.receive)),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: SizedBox(
              height: 45,
              child: ElevatedButton(
                  onPressed: () =>
                      Provider.of<NavigationProvider>(context, listen: false)
                          .changePage([NavigationPage.sendSatoshi]),
                  child: Text(AppLocalizations.of(context)!.send)),
            ),
          ),
        ],
      ));
      content.add(Heading(text: AppLocalizations.of(context)!.lastPayments));
      var lastPaymentData = wallet.lastPayments[currentSelection] ?? [];
      if (lastPaymentData.isNotEmpty) {
        var lastPayments = ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: wallet.lastPayments[currentSelection]?.length ?? 0,
            itemBuilder: (context, index) {
              return InkWell(
                child: TransactionPreview(
                    wide: true,
                    title: wallet
                        .lastPayments[currentSelection]![index].otherParty,
                    amount: CurrencyDisplay(
                        amount: wallet
                            .lastPayments[currentSelection]![index].action,
                        symbol: 'sat')),
                onTap: () {
                  if (wallet.lastPayments[currentSelection]![index]
                      .shownAttributes.isNotEmpty) {
                    var cred = wallet.getCredential(wallet
                        .lastPayments[currentSelection]![index]
                        .shownAttributes
                        .first);
                    if (cred != null && cred.w3cCredential.isNotEmpty) {
                      Provider.of<NavigationProvider>(context, listen: false)
                          .changePage([NavigationPage.credentialDetail],
                              credential: VerifiableCredential.fromJson(
                                  cred.w3cCredential));
                    }
                  }
                },
              );
            });
        content.add(lastPayments);
        if (wallet.getAllPayments(currentSelection).length > 3) {
          var additional = TextButton(
            onPressed: () =>
                Provider.of<NavigationProvider>(context, listen: false)
                    .changePage([NavigationPage.paymentOverview],
                        credential: toShow),
            child: Text(AppLocalizations.of(context)!.showMore,
                style: Theme.of(context).primaryTextTheme.titleMedium),
          );
          content.add(additional);
        }
      } else {
        var empty = TransactionPreview(
          title: AppLocalizations.of(context)!.noPayments,
          amount: const CurrencyDisplay(
            symbol: '',
            amount: '',
          ),
        );
        content.add(empty);
      }
      return StyledScaffoldTitle(
        useBackSwipe: false,
        title: 'Lightning Wallet',
        fab: wallet.paymentCredentials.isEmpty && !adding
            ? FloatingActionButton.extended(
                onPressed: () async {
                  setState(() {
                    adding = true;
                  });
                  var did = await wallet.newCredentialDid();
                  issueLNPaymentCard(
                      wallet,
                      {
                        "name": "Lightning Wallet",
                        "version": "1.4",
                        "description": "BTC Lightningcases",
                        "contexttype": "HidyContextLightning",
                        "mainbgimg":
                            "https://hidy.app/styles/hidycontextlnbtc_contextbg.png",
                        "overlaycolor": "#ffffff",
                        "backsidecolor": "#3a3a39",
                        "termsofserviceurl": "",
                        "services": [],
                        "vclayout": {}
                      },
                      externalDid: did);

                  currentSelection = did;
                },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.add))
            : null,
        child: wallet.paymentCredentials.isEmpty
            ? Center(
                child: adding
                    ? const CircularProgressIndicator()
                    : const Text('Keine Karten vorhanden'),
              )
            : Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ContextCard(
                          key: UniqueKey(),
                          //background: overallBackground,
                          context: toShow)
                      //)
                      ),
                  ...content
                ],
              ),
      );
    });
  }
}

Future<void> issueLNPaymentCard(
    WalletProvider wallet, Map<String, dynamic> content,
    {String? externalDid}) async {
  var did = externalDid ?? await wallet.newCredentialDid();
  var contextCred = VerifiableCredential(
      context: [credentialsV1Iri, schemaOrgIri],
      type: ['VerifiableCredential', 'ContextCredential', 'PaymentContext'],
      issuer: did,
      id: did,
      credentialSubject: {
        'id': did,
        'contextId': '2',
        'paymentType': 'LightningMainnetPayment',
        ...content
      },
      issuanceDate: DateTime.now());

  var signed = await signCredential(wallet.wallet, contextCred.toJson());

  await createLNWallet(did);
  await Future.delayed(const Duration(seconds: 1));

  var storageCred = wallet.getCredential(did);

  wallet.storeCredential(signed, storageCred!.hdPath);
  wallet.storeExchangeHistoryEntry(did, DateTime.now(), 'issue', did);
}
