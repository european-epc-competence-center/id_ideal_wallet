import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/ausweis_data.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/enter_can.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/enter_pin.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/enter_puk.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/errro_page.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/insert_card.dart';
import 'package:id_ideal_wallet/basicUi/ausweis/main_content.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class AusweisView extends StatefulWidget {
  const AusweisView({super.key});

  @override
  AusweisViewState createState() => AusweisViewState();
}

class AusweisViewState extends State<AusweisView> {
  @override
  void initState() {
    super.initState();

    final ausweis = Provider.of<AusweisProvider>(context, listen: false);
    ausweis.startListening();
    // Removed automatic startProgress() - let user see the information and decide when to start
  }

  Widget getBody(AusweisProvider ausweis) {
    if (ausweis.screen == AusweisScreen.enterPin) {
      return const EnterPin();
    } else if (ausweis.screen == AusweisScreen.insertCard) {
      return const InsertCard();
    } else if (ausweis.screen == AusweisScreen.start) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.credit_card,
              size: 80,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              'Ausweisdaten auslesen',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Was passiert als nächstes?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.nfc, 'NFC-Verbindung wird hergestellt'),
                    _buildInfoRow(Icons.security, 'Sichere Datenübertragung'),
                    _buildInfoRow(Icons.pin, 'PIN-Eingabe erforderlich'),
                    if (ausweis.selfInfo) ...[
                      _buildInfoRow(Icons.account_box, 'Persönliche Daten werden gelesen'),
                      _buildInfoRow(Icons.save, 'Daten werden als Nachweis gespeichert'),
                    ] else ...[
                      _buildInfoRow(Icons.share, 'Daten werden an anfragende Stelle übermittelt'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (ausweis.tcTokenUrl != null) ...[
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Externe Anfrage erkannt',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () {
                ausweis.startProgress(ausweis.tcTokenUrl);
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                ausweis.selfInfo 
                  ? 'Ausweisdaten in Credential umwandeln'
                  : 'Ausweis-Authentifizierung starten',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (ausweis.screen == AusweisScreen.finish) {
      return const AusweisData();
    } else if (ausweis.screen == AusweisScreen.enterCan) {
      return const EnterCan();
    } else if (ausweis.screen == AusweisScreen.enterPuk) {
      return const EnterPuk();
    } else if (ausweis.screen == AusweisScreen.error) {
      return const ErrorPage();
    } else {
      return const MainContent();
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Provider.of<AusweisProvider>(navigatorKey.currentContext!, listen: false)
        .reset(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AusweisProvider>(builder: (context, ausweis, child) {
      return Scaffold(
        appBar: ausweis.screen == AusweisScreen.start
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                title: Center(
                  child: Text(
                    AppLocalizations.of(context)!.idCard,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.headlineLarge,
                  ),
                ),
                // Add empty actions to balance the leading icon and keep title centered
                actions: const [
                  SizedBox(width: 56), // Same width as IconButton to balance the layout
                ],
              )
            : null,
        body: SafeArea(child: getBody(ausweis)),
      );
    });
  }
}
