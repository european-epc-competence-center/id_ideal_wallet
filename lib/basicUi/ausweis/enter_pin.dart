import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/footer_buttons.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
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
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.enterPin,
                style: Theme.of(context).primaryTextTheme.headlineLarge,
              ),
              Text(AppLocalizations.of(context)!.enterPinNote),
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
                        return AppLocalizations.of(context)!.pinLengthNote;
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'PIN',
                        suffixIcon: Icon(Icons.remove_red_eye_outlined)),
                  )),
              const SizedBox(
                height: 10,
              ),
              Text(
                  '${AppLocalizations.of(context)!.remainingTry} ${ausweis.pinRetry}'),
              if (ausweis.pinRetry == 2)
                Text(AppLocalizations.of(context)!.retryNote2),
              if (ausweis.pinRetry == 1)
                Text(AppLocalizations.of(context)!.retryNote1),
              const SizedBox(
                height: 20,
              ),
              Text(AppLocalizations.of(context)!.note5digit)
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
            negativeFunction: () => ausweis.cancel(),
          )
        ],
      );
    });
  }
}
