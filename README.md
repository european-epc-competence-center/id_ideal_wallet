# id_ideal_wallet

**Flutter 3.10.x**

- after last update it is possible that the wallet is only buildable with at least this
  flutter-version (because of some problems with pdf package)

**Last update added Internationalization**
If building the app won't work out of box, run:

```
flutter gen-l10n
```

to generate needed translation files

## The wallet

Wallet Application supporting W3C Verifiable Credentials and recent didcomm protocols
to issue credentials to the wallet and request them from the wallet.

This app is in an early stage of development and for now only recommended to use for demonstration
purpose.

This branch supports http as transport protocol for didcomm messages.

## App-Link

- `https://wallet.bccm.dev`
- App is able to scan codes pointing to a
  webview: `https://wallet.bccm.dev/webview?url=https://maps.google.com&title=Karte`, where url
  parameter is mandatory and title optional
- if the url for the webview contains fragment and query it MUST be percent-encoded
- the wallet will add a wallet id to the url if requested. To request this id, add the
  query-parameter `wid=` (without value) to your url.
- the wallet can also understand links with ligthning-invoices or
  lnurls : `https://wallet.bccm.dev/invoice?invoice=<lightning invoice>`
  or `https://wallet.bccm.dev/invoice?lnurl=<lnurl>`

**Important Notes**

- because the wallet store potential sensitive data the smartphone you run it on must offer an
  enrolled authentication mechanism (password, pin, pattern, fingerprint, face)
- the implemented transport layer for didcomm messages here is http. Because a mobile phone can't be
  reached by http requests directly a relay-service is needed. I've provided
  a [simple one on Github](https://github.com/b2cm/simple_didcomm_relay).
- the wallet expects the relay service to run at `http://localhost:8888`
- to access the relay running on your PC from the mobile device the wallet is running on,
  use `adb reverse` command:
  ```
  adb reverse tcp:8888 tcp:8888
  ```
- Documentation  (Flow charts) explaining how the wallet react on specific didcomm messages can be
  found in doc folder
- the wallet was not tested on iOS
- the wallet relies heavily on a special header in didcomm messages. This header is
  called `reply_to`. It specifies the service endpoint to which the response to a message should be
  sent back.
- running the wallet works like running every other flutter app using `flutter run`
  after `flutter pub get`
- samples services to test the wallet can be found
  in [this](https://github.com/b2cm/didcomm_examples) repository

## App Links in iOS (universal links)

1. Add "FlutterDeepLinkingEnabled": YES (boolean) to the Info.plist
2. In Singing & Capabilities, add applinks:wallet.bccm.dev to the domains
3. Create a file <https://wallet.bccm.dev/.well-known/apple-app-site-association> (must be https),
   with this content:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "9MY7ZZP3KS.eu.hidy.app",
        "paths": [
          "*"
        ]
      }
    ]
  }
}
```

(the weird code before the identifier is the team id, which can be found in the development team
apple ID)

4. Make sure that the file is delivered as content-type: application/json (it has no extension, so
   configure the web server accordingly)
5. Write the app-internal code to handle routing