import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:id_ideal_wallet/constants/navigation_pages.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/navigation_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/ausweis_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:id_ideal_wallet/views/backup_view.dart';
import 'package:id_ideal_wallet/functions/backup_functions.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    var wallet = Provider.of<WalletProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.options,
          style: Theme.of(context).primaryTextTheme.headlineLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 10, right: 10, top: 0),
          child: Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.termsOfService),
                subtitle: Text(wallet.tosUrl),
                onTap: () {
                  launchUrl(Uri.parse(wallet.tosUrl),
                      mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.license),
                onTap: () => navigateClassic(LicensePage(
                  applicationName: 'EECC Identity Wallet',
                  applicationVersion: versionNumber,
                  applicationIcon: Image.asset(
                    'assets/icons/app_icon-playstore.png',
                    height: 100,
                  ),
                )),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.about),
                subtitle: const Text('https://id.eecc.de'), // wallet.aboutUrl
                onTap: () {
                  launchUrl(Uri.parse('https://id.eecc.de'),
                      mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.newAppTitle),
                onTap: () => Provider.of<NavigationProvider>(context, listen: false)
                    .changePage([NavigationPage.searchNewAbo]),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.backup),
                onTap: () => Navigator.of(navigatorKey.currentContext!).push(
                    MaterialPageRoute(builder: (context) => BackupWidget())),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.restoreMenu),
                onTap: () => showConfirmationDialog(context, applyBackup)
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.openSourceNote), // Neu test
                subtitle: const Text('https://github.com/european-epc-competence-center/id_ideal_wallet'),
                onTap: () {
                  launchUrl(Uri.parse('https://github.com/european-epc-competence-center/id_ideal_wallet'),
                      mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.forkedFromNote), // Neu test
                subtitle: const Text('https://github.com/b2cm/id_ideal_wallet'),
                onTap: () {
                  launchUrl(Uri.parse('https://github.com/b2cm/id_ideal_wallet'),
                      mode: LaunchMode.externalApplication);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}