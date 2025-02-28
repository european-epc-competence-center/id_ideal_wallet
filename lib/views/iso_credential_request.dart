import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/provider/mdoc_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class IsoCredentialRequest extends StatefulWidget {
  const IsoCredentialRequest({super.key});

  @override
  IsoCredentialRequestState createState() => IsoCredentialRequestState();
}

class IsoCredentialRequestState extends State<IsoCredentialRequest> {
  @override
  void initState() {
    super.initState();
    //Provider.of<MdocProvider>(context, listen: false).startBle();
  }

  @override
  void dispose() {
    Provider.of<MdocProvider>(navigatorKey.currentContext!, listen: false)
        .stopAdvertising(true);
    super.dispose();
  }

  Widget getText(MdocProvider mdoc) {
    if (mdoc.transmissionState == BleMdocTransmissionState.uninitialized) {
      return Text(AppLocalizations.of(context)!.bleTransmissionStart);
    } else if (mdoc.transmissionState == BleMdocTransmissionState.advertising) {
      return mdoc.qrData.isEmpty
          ? Text(AppLocalizations.of(context)!.bleTransmissionPrepare)
          : QrImageView(data: mdoc.qrData);
    } else if (mdoc.transmissionState == BleMdocTransmissionState.connected) {
      return Text(AppLocalizations.of(context)!.bleTransmissionConnected);
    } else if (mdoc.transmissionState == BleMdocTransmissionState.send) {
      return Text(AppLocalizations.of(context)!.bleTransmissionSend);
    } else if (mdoc.transmissionState ==
        BleMdocTransmissionState.disconnected) {
      return Text(AppLocalizations.of(context)!.bleTransmissionFinished);
    } else {
      return Text('Keine Ahnung was grad los ist');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Consumer<MdocProvider>(builder: (context, mdoc, child) {
            if (mdoc.transmissionState ==
                BleMdocTransmissionState.uninitialized) {
              mdoc.startBle();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                mdoc.bleState == BluetoothLowEnergyState.poweredOn
                    ? getText(mdoc)
                    : Text(AppLocalizations.of(context)!.bleOff),
                const SizedBox(
                  height: 10,
                ),
                if (mdoc.transmissionState ==
                    BleMdocTransmissionState.disconnected)
                  ElevatedButton(
                      onPressed: () {
                        mdoc.restartBle();
                      },
                      child: Text(AppLocalizations.of(context)!.bleButton))
              ],
            );
          }),
        ),
      ),
    );
  }
}
