import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/styled_scaffold_title.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/ausweis_view.dart';
import 'package:provider/provider.dart';

class AusweisStart extends StatefulWidget {
  const AusweisStart({super.key});

  @override
  AusweisStartState createState() => AusweisStartState();
}

class AusweisStartState extends State<AusweisStart> {
  @override
  Widget build(BuildContext context) {
    var wallet = Provider.of<WalletProvider>(context, listen: false);
    return StyledScaffoldTitle(
      title: 'ID card',
      child: Column(
        children: [
          ListTile(
            title: Text('Read ID card'),
            onTap: () => Navigator.of(navigatorKey.currentContext!).push(
                Platform.isIOS
                    ? CupertinoPageRoute(
                    builder: (context) => const AusweisView())
                    : MaterialPageRoute(
                    builder: (context) => const AusweisView())),
          )
        ],
      ),
    );
  }
}