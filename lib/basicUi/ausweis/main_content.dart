import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/basicUi/standard/footer_buttons.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:provider/provider.dart';

Map<String, String> translationAttributes = {
  'Address': AppLocalizations.of(navigatorKey.currentContext!)!.address,
  'BirthName': AppLocalizations.of(navigatorKey.currentContext!)!.birthName,
  'FamilyName': AppLocalizations.of(navigatorKey.currentContext!)!.familyName,
  'GivenNames': AppLocalizations.of(navigatorKey.currentContext!)!.givenName,
  'PlaceOfBirth': AppLocalizations.of(navigatorKey.currentContext!)!.birthPlace,
  'DateOfBirth': AppLocalizations.of(navigatorKey.currentContext!)!.birthDate,
  'DoctoralDegree':
      AppLocalizations.of(navigatorKey.currentContext!)!.doctoralDegree,
  'ArtisticName':
      AppLocalizations.of(navigatorKey.currentContext!)!.artisticName,
  'ValidUntil':
      AppLocalizations.of(navigatorKey.currentContext!)!.expirationDate,
  'Nationality': AppLocalizations.of(navigatorKey.currentContext!)!.nationality,
  'IssuingCountry':
      AppLocalizations.of(navigatorKey.currentContext!)!.issuingCountry,
  'DocumentType':
      AppLocalizations.of(navigatorKey.currentContext!)!.documentType,
  'ResidencePermitI':
      AppLocalizations.of(navigatorKey.currentContext!)!.residencePermit1,
  'ResidencePermitII':
      AppLocalizations.of(navigatorKey.currentContext!)!.residencePermit2,
  'CommunityID': AppLocalizations.of(navigatorKey.currentContext!)!.communityId,
  'AddressVerification':
      AppLocalizations.of(navigatorKey.currentContext!)!.addressVerification,
  'AgeVerification':
      AppLocalizations.of(navigatorKey.currentContext!)!.ageVerification
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
            title: Text(AppLocalizations.of(context)!.provider),
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
                              title:
                                  Text(AppLocalizations.of(context)!.provider),
                              subtitle: Text(
                                  '${ausweis.requesterCert!.subjectName}\n${ausweis.requesterCert!.subjectUrl}'),
                            ),
                            ListTile(
                              title: Text(AppLocalizations.of(context)!
                                  .certificateIssuer),
                              subtitle: Text(
                                  '${ausweis.requesterCert!.issuerName}\n${ausweis.requesterCert!.issuerUrl}'),
                            ),
                            ListTile(
                              title:
                                  Text(AppLocalizations.of(context)!.validity),
                              subtitle: Text(
                                  '${ausweis.requesterCert!.effectiveDate.day.toString().padLeft(2, '0')}.${ausweis.requesterCert!.effectiveDate.month.toString().padLeft(2, '0')}.${ausweis.requesterCert!.effectiveDate.year} - ${ausweis.requesterCert!.expirationDate.day.toString().padLeft(2, '0')}.${ausweis.requesterCert!.expirationDate.month.toString().padLeft(2, '0')}.${ausweis.requesterCert!.expirationDate.year}'),
                            ),
                            if (ausweis.requesterCert!.purpose.isNotEmpty)
                              ListTile(
                                title:
                                    Text(AppLocalizations.of(context)!.reason),
                                subtitle: Text(ausweis.requesterCert!.purpose),
                              ),
                            ListTile(
                              title: Text(
                                  AppLocalizations.of(context)!.providerInfo),
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
          child: ExpansionTile(
              title: Text(AppLocalizations.of(context)!.providerInfo),
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ausweis.requestedAttributes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      visualDensity:
                          const VisualDensity(horizontal: 0, vertical: -4),
                      subtitle: Text(translationAttributes[
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
                AppLocalizations.of(context)!.identify,
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
                    semanticsLabel: AppLocalizations.of(context)!.loadRequest,
                    semanticsValue: AppLocalizations.of(context)!.loadRequest,
                  ),
                ),
            ])),
        persistentFooterButtons: ausweis.requestedAttributes.isNotEmpty &&
                ausweis.requesterCert != null
            ? [
                FooterButtons(
                  positiveText: AppLocalizations.of(context)!.continueWithPin,
                  positiveFunction: () =>
                      Provider.of<AusweisProvider>(context, listen: false)
                          .accept(),
                  negativeFunction: () =>
                      Provider.of<AusweisProvider>(context, listen: false)
                          .cancel(),
                ),
              ]
            : [],
      );
    });
  }
}
