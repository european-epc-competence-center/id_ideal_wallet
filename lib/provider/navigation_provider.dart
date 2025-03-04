import 'dart:async';

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/constants/navigation_pages.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/didcomm_message_handler.dart';
import 'package:id_ideal_wallet/functions/oidc_handler.dart';
import 'package:id_ideal_wallet/functions/payment_utils.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/ausweis_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:id_ideal_wallet/views/ausweis_view.dart';
import 'package:id_ideal_wallet/views/web_view.dart';
import 'package:provider/provider.dart';

class NavigationProvider extends ChangeNotifier {
  NavigationPage activeIndex = NavigationPage.abo;
  List<NavigationPage> pageStack = [];
  String webViewUrl = 'https://hidy.app';
  String? redirectWebViewUrl;
  VerifiableCredential? credential;
  bool canPop = true;
  bool showWelcome;
  String? bufferedLink;

  static const platform = MethodChannel('app.channel.deeplink');
  static const stream = EventChannel('app.channel.deeplink/events');

  NavigationProvider(this.showWelcome) {
    getInitialUri().then((l) => handleLink(l));
    stream.receiveBroadcastStream().listen((link) => handleLink(link));
    logger.d('listen link stream');
  }

  void finishOnboard() {
    showWelcome = false;
    if (bufferedLink != null) {
      handleLink(bufferedLink!);
      bufferedLink = null;
    }
    notifyListeners();
  }

  void finishOpen() {
    if (bufferedLink != null) {
      handleLink(bufferedLink!);
      bufferedLink = null;
    }
  }

  void changePage(List<NavigationPage> newIndex,
      {String? webViewUrl,
      VerifiableCredential? credential,
      bool track = true}) {
    if (newIndex.first != activeIndex ||
        newIndex.first == NavigationPage.webView) {
      canPop = false;
      logger.d('Before: $activeIndex /${this.webViewUrl}');
      activeIndex = newIndex.first;
      while (pageStack.isNotEmpty && newIndex.contains(pageStack.last)) {
        pageStack.removeLast();
      }
      if (track) {
        pageStack.add(newIndex.first);
      }
      if (webViewUrl != null) {
        this.webViewUrl = webViewUrl;
      }
      if (credential != null) {
        this.credential = credential;
      }
      logger.d('After: $activeIndex /${this.webViewUrl}');
      notifyListeners();
    }
  }

  void setWebViewUrl(String newUrl) {
    webViewUrl = newUrl;
  }

  Future<dynamic> getInitialUri() async {
    try {
      final initialUri = await platform.invokeMethod('getInitialLink');
      if (initialUri != null) {
        return initialUri;
      }
    } on PlatformException catch (e) {
      logger.d('Failed to Invoke Link from Android: ${e.message}.');
      return "Failed to Invoke: '${e.message}'.";
    }
  }

  void handleLink(String link) {
    logger.i(link);
    if (showWelcome) {
      logger.d('Buffer link');
      bufferedLink = link;
      return;
    }
    if (!(Provider.of<WalletProvider>(navigatorKey.currentContext!,
            listen: false)
        .isOpen())) {
      logger.d('wallet not open, buffer');
      bufferedLink = link;
      return;
    }
    // Handle Custom Schemes
    if (link.startsWith('lightning:')) {
      handleLink(link.replaceAll('lightning:', ''));
    } else if (link.startsWith('LNURL') || link.startsWith('lnurl')) {
      handleLnurl(link);
    } else if (link.startsWith('lnbc') || link.startsWith('LNBC')) {
      logger.d('LN-Invoice found');
      payInvoiceInteraction(
        link,
      );
    } else if (link.startsWith('eudi-openid4ci://authorize')) {
      handleRedirect(link);
    } else if (link.startsWith('openid-credential-offer') ||
        link.startsWith('eudi-openid4vci')) {
      handleOfferOidc(link);
    } else if (link.startsWith('openid-presentation-request') ||
        link.startsWith('eudi-openid4vp') ||
        link.startsWith('openid4vp')) {
      handlePresentationRequestOidc(link);
    } else if (link.startsWith('eid')) {
      logger.d(link);
      var asUri = Uri.parse(link);
      var tcTokenUrl = asUri.queryParameters['tcTokenURL'] ??
          asUri.queryParameters['tcTokenUrl'];
      logger.d(tcTokenUrl);
      navigateClassic(const AusweisView());
      Provider.of<AusweisProvider>(navigatorKey.currentContext!, listen: false)
          .startProgress(tcTokenUrl);
    }
    // Handle own App Link
    else if (link.startsWith('https://wallet.bccm.dev')) {
      var asUri = Uri.parse(link);
      // Known Query Parameter
      if (link.contains('credential_offer')) {
        handleOfferOidc(link);
      } else if (link.contains('ooburl=')) {
        handleOobUrl(link);
      } else if (link.contains('oobid=')) {
        handleOobId(link);
      } else if (link.contains('_oob=')) {
        handleDidcommMessage(link);
      }
      // Known Path Parameters
      else if (asUri.path == '/' || asUri.path.isEmpty) {
        // only open hidy
        logger.d('only open');
      } else if (link.contains('/webview')) {
        var asUri = Uri.parse(link);
        var uriToCall = Uri.parse(asUri.queryParameters['url']!);
        var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
            listen: false);
        // changePage([NavigationPage.credential], track: false);
        Timer(
            const Duration(milliseconds: 10),
            () => navigateClassic(WebViewWindow(
                initialUrl: uriToCall
                    .toString()
                    .replaceAll('wid=', 'wid=${wallet.lndwId}'),
                title: '')));
      } else if (link.contains('redirect')) {
        handleRedirect(link);
      } else if (link.contains('/invoice')) {
        var uri = Uri.parse(link);
        var invoice = uri.queryParameters['invoice'];
        if (invoice != null) {
          payInvoiceInteraction(
            invoice,
          );
        } else if (uri.queryParameters.containsKey('lnurl')) {
          handleLnurl(uri.queryParameters['lnurl']!);
        }
      } else {
        showErrorMessage(
            AppLocalizations.of(navigatorKey.currentContext!)!.unknownQrCode,
            AppLocalizations.of(navigatorKey.currentContext!)!
                .unknownQrCodeNote);
      }
    } else if (link.contains("No initial link has been stored yet")) {
      return;
    } else {
      showErrorMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.unknownQrCode,
          AppLocalizations.of(navigatorKey.currentContext!)!.unknownQrCodeNote);
    }
  }

  void goBack() {
    if (pageStack.isNotEmpty) {
      pageStack.removeLast();
    }
    if (pageStack.isEmpty) {
      if (activeIndex == NavigationPage.abo) {
        Navigator.of(navigatorKey.currentContext!).pop();
      } else {
        canPop = true;
        activeIndex = NavigationPage.abo;
      }
    } else {
      activeIndex = pageStack.last;
    }
    notifyListeners();
  }
}
