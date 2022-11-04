import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/didcomm.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:json_path/json_path.dart';
import 'package:json_schema2/json_schema2.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

class QrRender extends StatelessWidget {
  final VerifiableCredential credential;

  const QrRender({Key? key, required this.credential}) : super(key: key);

  Future<String> _proposePresentation() async {
    var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
        listen: false);
    var idField = InputDescriptorField(
        path: [JsonPath(r'$.id'), JsonPath(r'$.credentialSubject.id')],
        filter: JsonSchema.createSchema({
          'type': 'string',
          'pattern': credential.id ?? credential.credentialSubject['id']
        }));
    var type = credential.type.firstWhere(
        (element) => element != 'VerifiableCredential',
        orElse: () => '');
    var typeField = InputDescriptorField(
        path: [JsonPath(r'$.type')],
        filter: JsonSchema.createSchema({
          'type': 'array',
          'contains': {'type': 'string', 'pattern': type}
        }));
    var newConnDid = await wallet.newConnectionDid();
    var message = ProposePresentation(
        from: newConnDid,
        replyUrl: '$relay/buffer/$newConnDid',
        presentationDefinition: [
          PresentationDefinition(inputDescriptors: [
            InputDescriptor(
                constraints:
                    InputDescriptorConstraints(fields: [idField, typeField]))
          ])
        ]);
    print(message);

    var bufferId = Uuid().v4();
    await post(Uri.parse('$relay/buffer/$bufferId'), body: message.toString());

    wallet.storeConversation(message, newConnDid);

    var oob = OutOfBandMessage(from: newConnDid, attachments: [
      Attachment(
          data:
              AttachmentData(links: ['$relay/get/$bufferId'], hash: 'gfzuwqi'))
    ]);
    var url = oob.toUrl('http', 'ver', '');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential anbieten'),
      ),
      body: Center(
        child: FutureBuilder(
          future: _proposePresentation(),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return QrImage(data: snapshot.data!);
            } else if (snapshot.hasError) {
              return Text('Da ging was schief: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
