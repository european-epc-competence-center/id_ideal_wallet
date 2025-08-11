import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/basicUi/standard/footer_buttons.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:provider/provider.dart';

import 'package:id_ideal_wallet/l10n/app_localizations.dart';

Map<String, String> getTranslationAttributes(BuildContext context) => {
  'Address': AppLocalizations.of(context)!.attributeAddress,
  'BirthName': AppLocalizations.of(context)!.attributeBirthName,
  'FamilyName': AppLocalizations.of(context)!.attributeFamilyName,
  'GivenNames': AppLocalizations.of(context)!.attributeGivenNames,
  'PlaceOfBirth': AppLocalizations.of(context)!.attributePlaceOfBirth,
  'DateOfBirth': AppLocalizations.of(context)!.attributeDateOfBirth,
  'DoctoralDegree': AppLocalizations.of(context)!.attributeDoctoralDegree,
  'ArtisticName': AppLocalizations.of(context)!.attributeArtisticName,
  'ValidUntil': AppLocalizations.of(context)!.attributeValidUntil,
  'Nationality': AppLocalizations.of(context)!.attributeNationality,
  'IssuingCountry': AppLocalizations.of(context)!.attributeIssuingCountry,
  'DocumentType': AppLocalizations.of(context)!.attributeDocumentType,
  'ResidencePermitI': AppLocalizations.of(context)!.attributeResidencePermitI,
  'ResidencePermitII': AppLocalizations.of(context)!.attributeResidencePermitII,
  'CommunityID': AppLocalizations.of(context)!.attributeCommunityID,
  'AddressVerification': AppLocalizations.of(context)!.attributeAddressVerification,
  'AgeVerification': AppLocalizations.of(context)!.attributeAgeVerification
};

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  List<Widget> buildContent(AusweisProvider ausweis, BuildContext context) {
    return [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Card(
              child: ListTile(
            subtitle: Text(
              ausweis.requesterCert!.subjectName,
            ),
            title: Text(AppLocalizations.of(context)!.requester),
            onTap: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 30),
                      child: Scaffold(
                        body: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.requester),
                              subtitle: Text(
                                  '${ausweis.requesterCert!.subjectName}\n${ausweis.requesterCert!.subjectUrl}'),
                            ),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.certificateIssuer),
                              subtitle: Text(
                                  '${ausweis.requesterCert!.issuerName}\n${ausweis.requesterCert!.issuerUrl}'),
                            ),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.validity),
                              subtitle: Text(
                                  '${ausweis.requesterCert!.effectiveDate.day.toString().padLeft(2, '0')}.${ausweis.requesterCert!.effectiveDate.month.toString().padLeft(2, '0')}.${ausweis.requesterCert!.effectiveDate.year} - ${ausweis.requesterCert!.expirationDate.day.toString().padLeft(2, '0')}.${ausweis.requesterCert!.expirationDate.month.toString().padLeft(2, '0')}.${ausweis.requesterCert!.expirationDate.year}'),
                            ),
                            if (ausweis.requesterCert!.purpose.isNotEmpty)
                              ListTile(
                                title: Text(AppLocalizations.of(context)!.reason),
                                subtitle: Text(ausweis.requesterCert!.purpose),
                              ),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!.providerInformation),
                              subtitle:
                                  Text(ausweis.requesterCert!.termsOfUsage),
                            )
                          ],
                        ),
                        persistentFooterButtons: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Ok'))
                        ],
                      ));
                }),
          ))),
      const SizedBox(
        height: 10,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Card(
          child:
              ExpansionTile(title: Text('${AppLocalizations.of(context)!.requestedData}:'), children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ausweis.requestedAttributes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  subtitle: Text(getTranslationAttributes(context)[
                          ausweis.requestedAttributes[index]] ??
                      ausweis.requestedAttributes[index]),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            )
          ]),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AusweisProvider>(builder: (context, ausweis, child) {
      return Scaffold(
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
              Text(
                AppLocalizations.of(context)!.authenticate,
                style: Theme.of(context).primaryTextTheme.headlineLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              if (ausweis.requestedAttributes.isNotEmpty &&
                  ausweis.requesterCert != null)
                ...buildContent(ausweis, context)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LinearProgressIndicator(
                    value: ausweis.statusProgress,
                    minHeight: 7,
                    semanticsLabel: AppLocalizations.of(context)!.loadingRequest,
                    semanticsValue: AppLocalizations.of(context)!.loadingRequest,
                  ),
                ),
            ])),
        persistentFooterButtons: ausweis.requestedAttributes.isNotEmpty &&
                ausweis.requesterCert != null
            ? [
                FooterButtons(
                  positiveText: AppLocalizations.of(context)!.continueToPin,
                  positiveFunction: () =>
                      Provider.of<AusweisProvider>(context, listen: false)
                          .accept(),
                  negativeFunction: () =>
                      Provider.of<AusweisProvider>(context, listen: false)
                          .cancel(context),
                ),
              ]
            : [],
      );
    });
  }
}
