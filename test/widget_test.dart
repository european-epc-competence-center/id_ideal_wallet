// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:id_ideal_wallet/views/presentation_request.dart';

import 'example_credentials.dart';

void main() {
  testWidgets('test presentation request widget for selecting credentials',
      (WidgetTester tester) async {
    await tester.pumpWidget(Localizations(
        locale: Locale('de'),
        delegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: PresentationRequestDialog(
            results: [
              FilterResult(
                  matchingDescriptorIds: [],
                  presentationDefinitionId: 'abc',
                  fulfilled: true,
                  isoMdocCredentials: [msoVc1],
                  sdJwtCredentials: [sdJwt2]),
            ],
            otherEndpoint: 'google.com',
            definition: PresentationDefinition(inputDescriptors: []))));

    var finder = find.bySemanticsLabel('org.iso.18013.5.1.mDL');
    expect(finder, findsOneWidget);
    var findMdocCred = find.text('org.iso.18013.5.1.mDL');
    expect(findMdocCred, findsOneWidget);
    var findSdJwt = find.text('TestVc2');
    expect(findSdJwt, findsOneWidget);
  });
}
