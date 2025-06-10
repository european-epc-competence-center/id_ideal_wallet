import 'dart:io';

import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/camera_view.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';

class CameraView extends StatefulWidget {
  final String type;

  const CameraView({super.key, required this.type});

  @override
  CamaraViewState createState() => CamaraViewState();
}

class CamaraViewState extends State<CameraView> {
  String? front, back;

  Future<void> storeData() async {
    if (front == null) {
      showScaffoldMessenger(context, 'Keine Vorderseite');
      return;
    }
    if (back == null) {
      showScaffoldMessenger(context, 'Keine Rückseite');
      return;
    }
    Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false)
        .addPhotoId(widget.type, front!, back!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.frontside),
            GestureDetector(
              onTap: () async {
                front = await navigateClassic(AndroidCameraWidget());
                setState(() {});
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: front != null
                      ? Image.file(
                          File(front!),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(AppLocalizations.of(context)!.backside),
            GestureDetector(
              onTap: () async {
                back = await navigateClassic(AndroidCameraWidget());
                setState(() {});
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: back != null
                      ? Image.file(
                          File(back!),
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: storeData,
        label: Text(AppLocalizations.of(context)!.finish),
        icon: Icon(Icons.check),
      ),
    );
  }
}
