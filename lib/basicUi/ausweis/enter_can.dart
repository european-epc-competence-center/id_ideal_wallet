import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/footer_buttons.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EnterCan extends StatefulWidget {
  const EnterCan({super.key});

  @override
  EnterCanState createState() => EnterCanState();
}

class EnterCanState extends State<EnterCan> {
  final controller = TextEditingController();
  var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.canEntry,
              style: Theme.of(context).primaryTextTheme.headlineLarge,
            ),
            Text(AppLocalizations.of(context)!.enterCanInstruction),
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
                      return AppLocalizations.of(context)!.canMustBe6Digits;
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'CAN',
                      suffixIcon: Icon(Icons.remove_red_eye_outlined)),
                )),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
      persistentFooterButtons: [
        FooterButtons(
          positiveFunction: () {
            if (formKey.currentState!.validate()) {
              Provider.of<AusweisProvider>(context, listen: false)
                  .setCan(controller.text);
            }
          },
          negativeFunction: () =>
              Provider.of<AusweisProvider>(context, listen: false).cancel(context),
        )
      ],
    );
  }
}
