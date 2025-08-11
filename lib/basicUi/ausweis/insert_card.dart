import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class InsertCard extends StatelessWidget {
  const InsertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.readIdCardData,
                style: Theme.of(context).primaryTextTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.insertCardInstruction),
            ],
          )),
      persistentFooterButtons: [
        ElevatedButton(
            onPressed: () =>
                Provider.of<AusweisProvider>(context, listen: false).cancel(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(45),
            ),
            child: Text(AppLocalizations.of(context)!.cancelProcess)),
      ],
    );
  }
}
