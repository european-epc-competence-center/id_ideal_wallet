import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/styled_scaffold_title.dart';
import 'package:id_ideal_wallet/views/ausweis_view.dart';

class AusweisStart extends StatefulWidget {
  const AusweisStart({super.key});

  @override
  AusweisStartState createState() => AusweisStartState();
}

class AusweisStartState extends State<AusweisStart> {
  void navigate() {
    Navigator.of(context).push(Platform.isIOS
        ? CupertinoPageRoute(builder: (context) => const AusweisView())
        : MaterialPageRoute(builder: (context) => const AusweisView()));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigate();
    });

  @override
  Widget build(BuildContext context) {
    return StyledScaffoldTitle(
      title: AppLocalizations.of(context)!.idCard,
      child: Column(
        children: [
          ListTile(
              title: Text(AppLocalizations.of(context)!.readIdCard),
              onTap: () => navigate())
        ],
      ),
    );
  }
}
