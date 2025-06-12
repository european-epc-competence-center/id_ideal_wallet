import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/views/credential_page.dart';
import 'package:iso_mdoc/iso_mdoc.dart';
import 'package:sd_jwt/sd_jwt.dart';

class ShowFilterResult extends StatefulWidget {
  final FilterResult result;
  final List<bool>? selected;
  final List<Widget>? additionalChildren;
  final void Function()? afterCheck;

  const ShowFilterResult(
      {super.key,
      required this.result,
      this.selected,
      this.additionalChildren,
      this.afterCheck});

  @override
  ShowFilterResultState createState() => ShowFilterResultState();
}

class ShowFilterResultState extends State<ShowFilterResult> {
  List<String> types = [];
  List<List<Widget>> content = [];

  @override
  void initState() {
    super.initState();
  }

  void getData() {
    for (var m in widget.result.isoMdocCredentials ?? <IssuerSignedObject>[]) {
      var mso = MobileSecurityObject.fromCbor(m.issuerAuth.payload);
      Map<String, dynamic> subject = {};
      for (var k in m.items.keys) {
        //namespaces
        var items = m.items[k];
        for (var i in items!) {
          subject[i.dataElementIdentifier] = i.dataElementValue;
        }
      }
      types.add(mso.docType);
      content.add(buildCredSubject(subject));
    }

    for (var w in widget.result.credentials ?? <VerifiableCredential>[]) {
      types.add(getTypeToShow(w.type));
      content.add(buildCredSubject(
          (w.credentialSubject as Map).cast<String, dynamic>()));
    }

    for (var s in widget.result.sdJwtCredentials ?? <SdJws>[]) {
      var sd = s.toSdJwt();
      Map<String, dynamic> subject = sd.additionalClaims ?? {};
      var type = subject.remove('vct');
      types.add(type);
      content.add(buildCredSubject(subject));
    }
  }

  @override
  Widget build(BuildContext context) {
    getData();
    return ExpansionTile(
      initiallyExpanded: true,
      leading: widget.selected != null
          ? Text(
              '${widget.selected!.fold<int>(0, (p, e) => e ? p + 1 : p)}/${widget.result.submissionRequirement?.min ?? widget.result.submissionRequirement?.count ?? 1}',
              style: Theme.of(context).primaryTextTheme.bodyMedium!,
            )
          : null,
      title: Text(widget.result.submissionRequirement?.name ??
          widget.result.presentationDefinitionId),
      children: [
        if (widget.additionalChildren != null) ...widget.additionalChildren!,
        ...List.generate(
          content.length,
          (i) => ExpansionTile(
            title: Text(types[i]),
            leading: widget.selected != null
                ? Checkbox(
                    value: widget.selected![i],
                    onChanged: (bool? newValue) {
                      setState(() {
                        if (newValue != null) {
                          widget.selected![i] = newValue;
                        }
                        if (widget.afterCheck != null) {
                          widget.afterCheck!.call();
                        }
                      });
                    })
                : null,
            children: content[i],
          ),
        ),
      ],
    );
  }
}
