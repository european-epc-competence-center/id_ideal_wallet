import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/styled_scaffold_title.dart';
import 'package:id_ideal_wallet/constants/navigation_pages.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/navigation_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/camera_view.dart';
import 'package:id_ideal_wallet/views/show_photo_id.dart';
import 'package:provider/provider.dart';

class IdentityOverview extends StatefulWidget {
  const IdentityOverview({super.key});

  @override
  IdentityOverviewState createState() => IdentityOverviewState();
}

class IdentityOverviewState extends State<IdentityOverview> {
  @override
  Widget build(BuildContext context) {
    return StyledScaffoldTitle(
      title: 'Meine Daten',
      child: Consumer<WalletProvider>(builder: (context, wallet, child) {
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (wallet.accountVcs.isNotEmpty)
                ...wallet.accountVcs.values.map((e) => ListTile(
                      title: Text(e.credentialSubject['webview']),
                    )),
              SizedBox(
                height: 5,
              ),
              SizedBox(
                height: 5,
              ),
              ElevatedButton(
                  onPressed: () =>
                      Provider.of<NavigationProvider>(context, listen: false)
                          .changePage([NavigationPage.credential]),
                  child: Text('Alle Credentials')),
              SizedBox(
                height: 5,
              ),
              ElevatedButton(
                  onPressed: () =>
                      Provider.of<WalletProvider>(context, listen: false)
                          .generatePseudonym('https://hidy.app/oiwsandbox'),
                  child: Text('Account für HsmwSandbox')),
              SizedBox(
                height: 5,
              ),
              ElevatedButton(
                  onPressed: () =>
                      Provider.of<NavigationProvider>(context, listen: false)
                          .changePage([NavigationPage.email]),
                  child: Text('E-Mail')),
              SizedBox(
                height: 5,
              ),
              wallet.getDriverLicensePhoto() == null
                  ? ElevatedButton(
                      onPressed: () => navigateClassic(CameraView(
                            type: 'driverLicensePhoto',
                          )),
                      child: Text('Führerschein-Foto hinzufügen'))
                  : ElevatedButton(
                      onPressed: () {
                        var vc = wallet.getDriverLicensePhoto();
                        navigateClassic(ShowPhotoId(
                            front: vc!.credentialSubject['front'],
                            back: vc.credentialSubject['back']));
                      },
                      child: Text('Führerschein anzeigen')),
              SizedBox(
                height: 5,
              ),
              wallet.getIdCardPhoto() == null
                  ? ElevatedButton(
                      onPressed: () => navigateClassic(CameraView(
                            type: 'idCardPhoto',
                          )),
                      child: Text('Ausweis-Foto hinzufügen'))
                  : ElevatedButton(
                      onPressed: () {
                        var vc = wallet.getIdCardPhoto();
                        navigateClassic(ShowPhotoId(
                            front: vc!.credentialSubject['front'],
                            back: vc.credentialSubject['back']));
                      },
                      child: Text('Ausweis anzeigen'))
            ],
          ),
        );
      }),
    );
  }
}
