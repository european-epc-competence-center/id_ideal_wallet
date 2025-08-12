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
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Compact hero section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.indigo.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100, width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.contactless,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.eidReadAndCreateCredentials,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.eidDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // What you will receive (bigger, stacked)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, size: 20, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.youWillReceive,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade100),
                      color: Colors.blue.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, size: 24, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.idCardCredential,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade100),
                      color: Colors.green.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 24, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.ageVerification16Or18,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            
            if (ausweis.tcTokenUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.externalRequestDetected,
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Compact CTA button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.indigo.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ausweis.startProgress(ausweis.tcTokenUrl);
                },
                icon: const Icon(Icons.nfc, size: 20),
                label: Text(
                  ausweis.selfInfo 
                    ? AppLocalizations.of(context)!.startNowReadEid
                    : AppLocalizations.of(context)!.startNowAuthenticate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
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
