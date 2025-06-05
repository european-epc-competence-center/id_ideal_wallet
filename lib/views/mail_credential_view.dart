import 'dart:convert';

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:id_ideal_wallet/basicUi/standard/styled_scaffold_title.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/didcomm_message_handler.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';

class MailCredentialView extends StatefulWidget {
  const MailCredentialView({super.key});

  @override
  MailCredentialViewState createState() => MailCredentialViewState();
}

class MailCredentialViewState extends State<MailCredentialView> {
  var controller = TextEditingController();

  void sendMail() async {
    var address = controller.text;
    var res = await post(
        Uri.parse('https://test.hidy.app/walletcontext/pmm/sendmailvc'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': address}));

    if (res.statusCode != 200) {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.backupRestoreError,
          AppLocalizations.of(navigatorKey.currentContext!)!.sendMailFailed);
      logger.d('${res.statusCode} / ${res.body}');
    } else {
      showSuccessMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.newMailAddress,
          AppLocalizations.of(navigatorKey.currentContext!)!.checkMails);
      controller.text = '';
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {});
    }
  }

  void deleteMail(VerifiableCredential c, WalletProvider wallet) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.delete,
            ),
            content: Text(AppLocalizations.of(context)!.deleteMail),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel)),
              TextButton(
                  onPressed: () {
                    logger.d(c.toJson());
                    wallet.deleteCredential(
                        c.id ??
                            c.credentialSubject['id'] ??
                            '${c.issuanceDate.toIso8601String()}${getTypeToShow(c.type)}',
                        true);
                    Navigator.of(context).pop();
                  },
                  child: Text('Ok'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return StyledScaffoldTitle(
      title: 'E-Mail',
      child: Consumer<WalletProvider>(builder: (context, wallet, w) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card.outlined(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.verifiedMail,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (wallet.mailCredentials.isNotEmpty)
                        ...wallet.mailCredentials.map((c) => ListTile(
                              title: Text(c.credentialSubject['Email'] == ''
                                  ? c.credentialSubject['email']
                                  : c.credentialSubject['Email']),
                              trailing: IconButton(
                                  onPressed: () => deleteMail(c, wallet),
                                  icon: Icon(Icons.delete)),
                            ))
                      else
                        ListTile(
                          title:
                              Text(AppLocalizations.of(context)!.noMailAddress),
                        ),
                    ]),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Card.outlined(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.newMailAddress,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    TextField(
                      decoration: InputDecoration(
                          border: OutlineInputBorder(), hintText: 'E-Mail'),
                      controller: controller,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      ElevatedButton(
                          onPressed: sendMail,
                          child: Text(AppLocalizations.of(context)!.add))
                    ]),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
