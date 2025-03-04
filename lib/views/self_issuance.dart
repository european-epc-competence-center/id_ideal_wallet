import 'dart:convert';

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/currency_display.dart';
import 'package:id_ideal_wallet/basicUi/standard/modal_dismiss_wrapper.dart';
import 'package:id_ideal_wallet/basicUi/standard/payment_finished.dart';
import 'package:id_ideal_wallet/basicUi/standard/styled_scaffold_title.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:json_schema2/json_schema.dart';
import 'package:json_schema_form/json_schema_form.dart';
import 'package:provider/provider.dart';

final emailSchema = JsonSchema.create({
  'type': 'object',
  'properties': {
    'email': {
      'type': 'string',
      'description':
          AppLocalizations.of(navigatorKey.currentContext!)!.mailAddress
    }
  }
});

final socialMediaSchema = JsonSchema.create({
  'type': 'object',
  'properties': {
    'network': {
      'type': 'string',
      'enum': [
        'Facebook',
        'Telegram',
        'Instagram',
        'TikTok',
        'Matrix',
        'Mastodon',
        'LinkedIn',
        'Xing'
      ]
    },
    'username': {
      'type': 'string',
      'description': AppLocalizations.of(navigatorKey.currentContext!)!.username
    }
  }
});

class SelfIssueList extends StatelessWidget {
  const SelfIssueList({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledScaffoldTitle(
        title: AppLocalizations.of(navigatorKey.currentContext!)!.selfIssuable,
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () => navigateClassic(FixedSelfIssue(
                    schema: emailSchema, type: 'EMailCredential')),
                child: Text(AppLocalizations.of(context)!.mailAddress)),
            ElevatedButton(
                onPressed: () => navigateClassic(FixedSelfIssue(
                    schema: socialMediaSchema,
                    type: 'SocialMediaAccountCredential')),
                child: const Text('Social Media Account')),
            // ElevatedButton(
            //     onPressed: () async {
            //       JsonSchema deviceInfoSchema;
            //       var deviceInfo = DeviceInfoPlugin();
            //       if (Platform.isAndroid) {
            //         var info = await deviceInfo.androidInfo;
            //         var androidAidPlugin = const AndroidId();
            //         deviceInfoSchema = JsonSchema.create({
            //           'type': 'object',
            //           'properties': {
            //             'deviceId': {
            //               'type': 'string',
            //               'const': await androidAidPlugin.getId()
            //             },
            //             'deviceModel': {'type': 'string', 'const': info.model},
            //             'deviceManufacturer': {
            //               'type': 'string',
            //               'const': info.manufacturer
            //             },
            //           }
            //         });
            //       } else if (Platform.isIOS) {
            //         var info = await deviceInfo.iosInfo;
            //         deviceInfoSchema = JsonSchema.create({
            //           'type': 'object',
            //           'properties': {
            //             'deviceId': {
            //               'type': 'string',
            //               'const': info.identifierForVendor
            //             },
            //             'deviceModel': {'type': 'string', 'const': info.model},
            //             'deviceManufacturer': {
            //               'type': 'string',
            //               'const': 'Apple'
            //             },
            //           }
            //         });
            //       } else {
            //         throw Exception(
            //             'This should never happen. Unknown Platform');
            //       }
            //
            //       Navigator.of(context).push(MaterialPageRoute(
            //           builder: (context) => FixedSelfIssue(
            //               schema: deviceInfoSchema,
            //               type: 'DeviceInformation')));
            //     },
            //     child: Text(AppLocalizations.of(context)!.deviceInformation))
          ],
        ));
  }
}

class FixedSelfIssue extends StatelessWidget {
  final JsonSchema schema;
  final String type;

  const FixedSelfIssue({super.key, required this.schema, required this.type});

  void afterValidation(Map<dynamic, dynamic> result) async {
    var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
        listen: false);

    var credentialDid = await wallet.newCredentialDid();
    result['id'] = credentialDid;
    var credential = VerifiableCredential(
        context: [
          'https://www.w3.org/2018/credentials/v1',
          ed25519ContextIri,
          'https://schema.org'
        ],
        type: [
          'VerifiableCredential',
          type
        ],
        issuer: credentialDid,
        id: credentialDid,
        credentialSubject: result,
        issuanceDate: DateTime.now());

    var signed = await signCredential(wallet.wallet, credential.toJson());

    logger.d(signed);

    var storageCred = wallet.getCredential(credentialDid);

    wallet.storeCredential(signed, storageCred!.hdPath);
    wallet.storeExchangeHistoryEntry(
        credentialDid, DateTime.now(), 'issue', credentialDid);

    Navigator.pop(navigatorKey.currentContext!);
    Navigator.pop(navigatorKey.currentContext!);
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        context: navigatorKey.currentContext!,
        builder: (context) {
          return ModalDismissWrapper(
            child: PaymentFinished(
              headline: AppLocalizations.of(context)!.stored,
              success: true,
              amount: CurrencyDisplay(
                  amount: type, symbol: '', mainFontSize: 35, centered: true),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return StyledScaffoldTitle(
        title:
            '${AppLocalizations.of(navigatorKey.currentContext!)!.selfIssuance}: $type',
        child: JsonSchemaForm(
          schema: schema,
          controller: SchemaFormController(schema),
          afterValidation: afterValidation,
        ));
  }
}

class CredentialSelfIssue extends StatefulWidget {
  final List<InputDescriptorConstraints> input;
  final int outerPos;

  const CredentialSelfIssue(
      {super.key, required this.input, required this.outerPos});

  @override
  State<StatefulWidget> createState() => CredentialSelfIssueState();
}

class CredentialSelfIssueState extends State<CredentialSelfIssue> {
  late JsonSchema schema;
  late SchemaFormController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();
    for (var i in widget.input) {
      if (i.fields != null) {
        for (var field in i.fields!) {
          if (field.path
              .where(
                  (element) => element.toString().contains('credentialSubject'))
              .isNotEmpty) {
            var givenSchema = field.filter?.toJson();
            if (givenSchema != null) {
              schema = JsonSchema.create(jsonDecode(givenSchema));
              logger.d(schema);
              controller = SchemaFormController(schema);
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Text(
            AppLocalizations.of(context)!.selfIssuance,
            style: Theme.of(context).primaryTextTheme.headlineLarge,
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
              child: JsonSchemaForm(
            schema: schema,
            controller: controller,
            validationButtonText: 'Ok',
            afterValidation: (credData) {
              Navigator.of(context).pop((credData, widget.outerPos));
            },
          ))
        ]),
      ),
    );
  }
}
