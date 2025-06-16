import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';

class ShowPhotoId extends StatelessWidget {
  final String front, back;

  const ShowPhotoId({super.key, required this.front, required this.back});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Text(AppLocalizations.of(context)!.frontside),
          SizedBox(
            height: 5,
          ),
          Image.memory(base64Decode(front.split(',').last)),
          SizedBox(
            height: 20,
          ),
          Text(AppLocalizations.of(context)!.backside),
          SizedBox(
            height: 5,
          ),
          Image.memory(base64Decode(back.split(',').last)),
        ],
      ),
    );
  }
}
