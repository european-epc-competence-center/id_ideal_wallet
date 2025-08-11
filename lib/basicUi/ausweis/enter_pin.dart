import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/footer_buttons.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EnterPin extends StatefulWidget {
  const EnterPin({super.key});

  @override
  EnterPinState createState() => EnterPinState();
}

class EnterPinState extends State<EnterPin> {
  final controller = TextEditingController();
  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<AusweisProvider>(builder: (context, ausweis, child) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.pinEntry,
                style: Theme.of(context).primaryTextTheme.headlineLarge,
              ),
              Text(AppLocalizations.of(context)!.enterPinInstruction),
              const SizedBox(
                height: 10,
              ),
              Form(
                  key: formKey,
                  child: TextFormField(
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.number,
                    controller: controller,
                    maxLength: 6,
                    validator: (input) {
                      if (input == null || input.length != 6) {
                        return AppLocalizations.of(context)!.pinMustBe6Digits;
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.idCardPin,
                        suffixIcon: const Icon(Icons.remove_red_eye_outlined)),
                  )),
              const SizedBox(
                height: 10,
              ),
              Text(AppLocalizations.of(context)!.remainingAttempts(ausweis.pinRetry)),
              if (ausweis.pinRetry == 2)
                Text(AppLocalizations.of(context)!.pinRetry2Warning),
              if (ausweis.pinRetry == 1)
                Text(AppLocalizations.of(context)!.pinRetry1Warning),
              const SizedBox(
                height: 20,
              ),
              Text(AppLocalizations.of(context)!.fiveDigitPinInfo)
            ],
          ),
        ),
        persistentFooterButtons: [
          FooterButtons(
            positiveFunction: () {
              if (formKey.currentState!.validate()) {
                ausweis.setPin(controller.text);
              }
            },
            negativeFunction: () => ausweis.cancel(context),
          )
        ],
      );
    });
  }
}
