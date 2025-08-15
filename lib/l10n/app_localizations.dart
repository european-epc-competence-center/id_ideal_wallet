import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @openSourceNote.
  ///
  /// In de, this message translates to:
  /// **'Open Source auf GitHub'**
  String get openSourceNote;

  /// No description provided for @forkedFromNote.
  ///
  /// In de, this message translates to:
  /// **'Ursprungsprojekt'**
  String get forkedFromNote;

  /// No description provided for @readIdCard.
  ///
  /// In de, this message translates to:
  /// **'Ausweisdaten auslesen'**
  String get readIdCard;

  /// No description provided for @about.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get about;

  /// No description provided for @idCard.
  ///
  /// In de, this message translates to:
  /// **'Ausweis'**
  String get idCard;

  /// No description provided for @home.
  ///
  /// In de, this message translates to:
  /// **'Startseite'**
  String get home;

  /// No description provided for @options.
  ///
  /// In de, this message translates to:
  /// **'Optionen'**
  String get options;

  /// No description provided for @lastPayments.
  ///
  /// In de, this message translates to:
  /// **'Letzte Zahlungen'**
  String get lastPayments;

  /// No description provided for @showMore.
  ///
  /// In de, this message translates to:
  /// **'Weitere Anzeigen'**
  String get showMore;

  /// No description provided for @noPayments.
  ///
  /// In de, this message translates to:
  /// **'Keine getätigten Zahlungen'**
  String get noPayments;

  /// No description provided for @scan.
  ///
  /// In de, this message translates to:
  /// **'Scannen'**
  String get scan;

  /// No description provided for @openWallet.
  ///
  /// In de, this message translates to:
  /// **'Wallet öffnen'**
  String get openWallet;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @verifyIdentity.
  ///
  /// In de, this message translates to:
  /// **'Bitte verifizieren Sie Ihre Identität'**
  String get verifyIdentity;

  /// No description provided for @localizedReason.
  ///
  /// In de, this message translates to:
  /// **'Zum Öffnen des Wallets ist Ihre Authentifizierung nötig'**
  String get localizedReason;

  /// No description provided for @sellCredentialTitle.
  ///
  /// In de, this message translates to:
  /// **'Nachweis verkaufen'**
  String get sellCredentialTitle;

  /// No description provided for @forSale.
  ///
  /// In de, this message translates to:
  /// **'zum Kauf anbieten'**
  String get forSale;

  /// No description provided for @forShow.
  ///
  /// In de, this message translates to:
  /// **'zum Vorzeigen anbieten'**
  String get forShow;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @deletionNote.
  ///
  /// In de, this message translates to:
  /// **'Sind Sie sicher, dass sie diesen Nachweis löschen möchten? Dieser Vorgang kann nicht rückgängig gemacht werden.'**
  String get deletionNote;

  /// No description provided for @deletionNoteApp.
  ///
  /// In de, this message translates to:
  /// **'Sind Sie sicher, dass sie diese Anwendung löschen möchten?'**
  String get deletionNoteApp;

  /// No description provided for @issuer.
  ///
  /// In de, this message translates to:
  /// **'Aussteller'**
  String get issuer;

  /// No description provided for @otherData.
  ///
  /// In de, this message translates to:
  /// **'Sonstige Daten'**
  String get otherData;

  /// No description provided for @personnelData.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Daten'**
  String get personnelData;

  /// No description provided for @invoice.
  ///
  /// In de, this message translates to:
  /// **'Rechnung'**
  String get invoice;

  /// No description provided for @invoiceNumber.
  ///
  /// In de, this message translates to:
  /// **'Rechnungsnummer'**
  String get invoiceNumber;

  /// No description provided for @selfIssued.
  ///
  /// In de, this message translates to:
  /// **'Selbstausgestellt'**
  String get selfIssued;

  /// No description provided for @verifiedBy.
  ///
  /// In de, this message translates to:
  /// **'verifiziert von: '**
  String get verifiedBy;

  /// No description provided for @verified.
  ///
  /// In de, this message translates to:
  /// **'verifiziert'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In de, this message translates to:
  /// **'nicht verfiziert'**
  String get notVerified;

  /// No description provided for @state.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get state;

  /// No description provided for @valid.
  ///
  /// In de, this message translates to:
  /// **'Gültig'**
  String get valid;

  /// No description provided for @expired.
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen'**
  String get expired;

  /// No description provided for @inactive.
  ///
  /// In de, this message translates to:
  /// **'Inaktiv'**
  String get inactive;

  /// No description provided for @revoked.
  ///
  /// In de, this message translates to:
  /// **'Zurückgezogen'**
  String get revoked;

  /// No description provided for @unknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get unknown;

  /// No description provided for @issuanceDate.
  ///
  /// In de, this message translates to:
  /// **'Ausstelldatum'**
  String get issuanceDate;

  /// No description provided for @expirationDate.
  ///
  /// In de, this message translates to:
  /// **'Ablaufdatum'**
  String get expirationDate;

  /// No description provided for @history.
  ///
  /// In de, this message translates to:
  /// **'Aktivitäten'**
  String get history;

  /// No description provided for @issued.
  ///
  /// In de, this message translates to:
  /// **'Ausgestellt'**
  String get issued;

  /// No description provided for @presented.
  ///
  /// In de, this message translates to:
  /// **'Vorgezeigt'**
  String get presented;

  /// No description provided for @presentedError.
  ///
  /// In de, this message translates to:
  /// **'Vorzeigen fehlgeschlagen'**
  String get presentedError;

  /// No description provided for @presentCredential.
  ///
  /// In de, this message translates to:
  /// **'Nachweis vorzeigen'**
  String get presentCredential;

  /// No description provided for @contextCredentialTitle.
  ///
  /// In de, this message translates to:
  /// **'Kontext hinzufügen'**
  String get contextCredentialTitle;

  /// No description provided for @create.
  ///
  /// In de, this message translates to:
  /// **'Anlegen'**
  String get create;

  /// No description provided for @credentialPageTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Nachweise'**
  String get credentialPageTitle;

  /// No description provided for @show.
  ///
  /// In de, this message translates to:
  /// **'Anzeigen'**
  String get show;

  /// No description provided for @preview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get preview;

  /// No description provided for @anonymousIssuer.
  ///
  /// In de, this message translates to:
  /// **'Anonymer Aussteller'**
  String get anonymousIssuer;

  /// No description provided for @anonymous.
  ///
  /// In de, this message translates to:
  /// **'anonym'**
  String get anonymous;

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @payments.
  ///
  /// In de, this message translates to:
  /// **'Zahlung{count, plural, =0{} other{en}}'**
  String payments(num count);

  /// No description provided for @paymentMethod.
  ///
  /// In de, this message translates to:
  /// **'Zahlungsmethode'**
  String get paymentMethod;

  /// No description provided for @noteShownCredentials.
  ///
  /// In de, this message translates to:
  /// **'Diese Nachweise wurden soeben vorgezeigt'**
  String get noteShownCredentials;

  /// No description provided for @noteOtherShowCredentials.
  ///
  /// In de, this message translates to:
  /// **'Ihr Gegenüber bietet Ihnen an, einen Nachweis mit folgenden Daten vorzuzeigen:'**
  String get noteOtherShowCredentials;

  /// No description provided for @request.
  ///
  /// In de, this message translates to:
  /// **'Anfragen'**
  String get request;

  /// No description provided for @requestTitle.
  ///
  /// In de, this message translates to:
  /// **'Anfrage'**
  String get requestTitle;

  /// No description provided for @ignore.
  ///
  /// In de, this message translates to:
  /// **'Ignorieren'**
  String get ignore;

  /// No description provided for @dataFor.
  ///
  /// In de, this message translates to:
  /// **'Die Daten werden übermittelt an:'**
  String get dataFor;

  /// No description provided for @reasonForRequest.
  ///
  /// In de, this message translates to:
  /// **'Grund der Anfrage'**
  String get reasonForRequest;

  /// No description provided for @selfIssueAllowed.
  ///
  /// In de, this message translates to:
  /// **'Der Anfragende erlaubt, Daten selbst einzutragen'**
  String get selfIssueAllowed;

  /// No description provided for @enterData.
  ///
  /// In de, this message translates to:
  /// **'Daten eintragen'**
  String get enterData;

  /// No description provided for @presentationSuccessful.
  ///
  /// In de, this message translates to:
  /// **'Nachweise erfolgreich vorgezeigt'**
  String get presentationSuccessful;

  /// No description provided for @presentationFailed.
  ///
  /// In de, this message translates to:
  /// **'Nachweise konnten nicht vorgezeigt werden'**
  String get presentationFailed;

  /// No description provided for @reject.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get reject;

  /// No description provided for @send.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get send;

  /// No description provided for @sendPresentation.
  ///
  /// In de, this message translates to:
  /// **'Nachweise senden'**
  String get sendPresentation;

  /// No description provided for @username.
  ///
  /// In de, this message translates to:
  /// **'Nutzername im gewählten Netzwerk'**
  String get username;

  /// No description provided for @mailAddress.
  ///
  /// In de, this message translates to:
  /// **'E-Mail Adresse'**
  String get mailAddress;

  /// No description provided for @selfIssuable.
  ///
  /// In de, this message translates to:
  /// **'Selbstausstellbare Nachweise'**
  String get selfIssuable;

  /// No description provided for @deviceInformation.
  ///
  /// In de, this message translates to:
  /// **'Geräteinformationen'**
  String get deviceInformation;

  /// No description provided for @stored.
  ///
  /// In de, this message translates to:
  /// **'Nachweis gespeichert'**
  String get stored;

  /// No description provided for @selfIssuance.
  ///
  /// In de, this message translates to:
  /// **'Selbstausstellung'**
  String get selfIssuance;

  /// No description provided for @noCredentialsTitle.
  ///
  /// In de, this message translates to:
  /// **'Fehlerhafte Anfrage'**
  String get noCredentialsTitle;

  /// No description provided for @noCredentialsNote.
  ///
  /// In de, this message translates to:
  /// **'Die Anfrage kann nicht verarbeitet werden. Entweder fehlt der erforderliche Nachweis in Ihrer Wallet, es werden nicht unterstützte Funktionen verlangt, oder es liegt ein Fehler bei der Erstellung vor.'**
  String get noCredentialsNote;

  /// No description provided for @paymentSuccessful.
  ///
  /// In de, this message translates to:
  /// **'Zahlung erfolgreich'**
  String get paymentSuccessful;

  /// No description provided for @paymentReceived.
  ///
  /// In de, this message translates to:
  /// **'Zahlung eingegangen'**
  String get paymentReceived;

  /// No description provided for @paymentFailed.
  ///
  /// In de, this message translates to:
  /// **'Zahlung fehlgeschlagen'**
  String get paymentFailed;

  /// No description provided for @paymentFailedNote.
  ///
  /// In de, this message translates to:
  /// **'Zahlung konnte nicht durchgeführt werden'**
  String get paymentFailedNote;

  /// No description provided for @noPaymentMethod.
  ///
  /// In de, this message translates to:
  /// **'Zahlung nicht möglich'**
  String get noPaymentMethod;

  /// No description provided for @requestPayment.
  ///
  /// In de, this message translates to:
  /// **'Zahlung anfordern'**
  String get requestPayment;

  /// No description provided for @noPaymentNote.
  ///
  /// In de, this message translates to:
  /// **'Keine passende Zahlungsmethode gefunden'**
  String get noPaymentNote;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In de, this message translates to:
  /// **'Lightning Account auswählen'**
  String get selectPaymentMethod;

  /// No description provided for @chargeMoney.
  ///
  /// In de, this message translates to:
  /// **'Aufladen'**
  String get chargeMoney;

  /// No description provided for @noPaymentMethodNote.
  ///
  /// In de, this message translates to:
  /// **'Sie besitzen kein Wallet. \nBitte legen Sie sich eines an und\nsorgen für ausreichend Deckung'**
  String get noPaymentMethodNote;

  /// No description provided for @credentialReceived.
  ///
  /// In de, this message translates to:
  /// **'Nachweis empfangen'**
  String get credentialReceived;

  /// No description provided for @amountSatoshi.
  ///
  /// In de, this message translates to:
  /// **'Betrag in Satoshi'**
  String get amountSatoshi;

  /// No description provided for @amountEuro.
  ///
  /// In de, this message translates to:
  /// **'Betrag in Euro'**
  String get amountEuro;

  /// No description provided for @pay.
  ///
  /// In de, this message translates to:
  /// **'Bezahlen'**
  String get pay;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @receive.
  ///
  /// In de, this message translates to:
  /// **'Empfangen'**
  String get receive;

  /// No description provided for @orderWithPayment.
  ///
  /// In de, this message translates to:
  /// **'Zahlungspflichtig bestellen'**
  String get orderWithPayment;

  /// No description provided for @credentialOffer.
  ///
  /// In de, this message translates to:
  /// **'Nachweis-Angebot'**
  String get credentialOffer;

  /// No description provided for @balance.
  ///
  /// In de, this message translates to:
  /// **'Kontostand'**
  String get balance;

  /// No description provided for @noteGetInformation.
  ///
  /// In de, this message translates to:
  /// **'möchte folgende Informationen von Dir'**
  String get noteGetInformation;

  /// No description provided for @notePresentationPurpose.
  ///
  /// In de, this message translates to:
  /// **'gibt an, die Daten für folgendes zu verwenden'**
  String get notePresentationPurpose;

  /// No description provided for @missingDataTitle.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Daten'**
  String get missingDataTitle;

  /// No description provided for @missingDataNote.
  ///
  /// In de, this message translates to:
  /// **'Der Anfragende bittet um eine Selbstauskunft. Bitte trage die geforderten Daten ein.'**
  String get missingDataNote;

  /// No description provided for @downloadFailed.
  ///
  /// In de, this message translates to:
  /// **'Download fehlgeschlagen'**
  String get downloadFailed;

  /// No description provided for @downloadFailedExplanation.
  ///
  /// In de, this message translates to:
  /// **'Die Anfrage des Gegenübers kann nicht herunterladen werden.'**
  String get downloadFailedExplanation;

  /// No description provided for @unexpectedMessage.
  ///
  /// In de, this message translates to:
  /// **'Unerwartete Nachricht'**
  String get unexpectedMessage;

  /// No description provided for @malformedMessage.
  ///
  /// In de, this message translates to:
  /// **'Fehlerhafte Nachricht'**
  String get malformedMessage;

  /// No description provided for @malformedOOBExplanation.
  ///
  /// In de, this message translates to:
  /// **'Die Nachricht kann nicht gelesen werden.\n Sie können versuchen, den QR-Code ein weiteres mal zu scannen. \n Sollte der Fehler bestehen bleiben, kontaktieren Sie den Support des Anfrage-Erstellers.'**
  String get malformedOOBExplanation;

  /// No description provided for @unknownMessageExplanation.
  ///
  /// In de, this message translates to:
  /// **'Diese Nachricht wird derzeit nicht unterstützt.\n Die Interaktion kann daher nicht fortgesetzt werden.'**
  String get unknownMessageExplanation;

  /// No description provided for @malformedEncryptedMessage.
  ///
  /// In de, this message translates to:
  /// **'Beim Entschlüsseln einer Nachricht ist ein Fehler aufgetreten.'**
  String get malformedEncryptedMessage;

  /// No description provided for @waiting.
  ///
  /// In de, this message translates to:
  /// **'Einen kleinen Moment bitte.'**
  String get waiting;

  /// No description provided for @waitingSendPresentation.
  ///
  /// In de, this message translates to:
  /// **'Ihre Antwort wird gesendet.'**
  String get waitingSendPresentation;

  /// No description provided for @waitingQrData.
  ///
  /// In de, this message translates to:
  /// **'Die Daten werden verarbeitet.'**
  String get waitingQrData;

  /// No description provided for @errorNotEnoughCredentials.
  ///
  /// In de, this message translates to:
  /// **'Sie können die Anfrage ihres Gegenübers nicht erfüllen, da Sie nicht die nötigen Nachweise besitzen bzw. ausgewählt haben.\nInformieren Sie sich, wie Sie die fehlenden Nachweise erlangen können oder wählen Sie die fehlenden aus.'**
  String get errorNotEnoughCredentials;

  /// No description provided for @attention.
  ///
  /// In de, this message translates to:
  /// **'Achtung'**
  String get attention;

  /// No description provided for @cancelWarning.
  ///
  /// In de, this message translates to:
  /// **'Zum Beenden \'Abbrechen\' verwenden'**
  String get cancelWarning;

  /// No description provided for @accept.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get accept;

  /// No description provided for @noteNoCredentials.
  ///
  /// In de, this message translates to:
  /// **'Keine Nachweise vorhanden'**
  String get noteNoCredentials;

  /// No description provided for @emptyCredentialTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen in Deiner\nEECC Wallet'**
  String get emptyCredentialTitle;

  /// No description provided for @emptyCredentialEidInfo.
  ///
  /// In de, this message translates to:
  /// **'Nutze Deinen elektronischen Personalausweis, um digitale Nachweise zu erstellen. Die Wallet liest Deine eID-Daten sicher über NFC aus.'**
  String get emptyCredentialEidInfo;

  /// No description provided for @emptyCredentialQrInfo.
  ///
  /// In de, this message translates to:
  /// **'Scanne QR-Codes, um neue Nachweise zu empfangen oder vorhandene Nachweise zu präsentieren.'**
  String get emptyCredentialQrInfo;

  /// No description provided for @allCredentials.
  ///
  /// In de, this message translates to:
  /// **'Alle Nachweise'**
  String get allCredentials;

  /// No description provided for @sendFailed.
  ///
  /// In de, this message translates to:
  /// **'Es gibt ein Problem'**
  String get sendFailed;

  /// No description provided for @sendFailedNote.
  ///
  /// In de, this message translates to:
  /// **'Der Vorgang kann nicht beendet werden. Bitte probieren Sie es erneut.'**
  String get sendFailedNote;

  /// No description provided for @wrongCredential.
  ///
  /// In de, this message translates to:
  /// **'Fehlerhafter Nachweis'**
  String get wrongCredential;

  /// No description provided for @wrongCredentialNote.
  ///
  /// In de, this message translates to:
  /// **'Dein Gegenüber hat einen Nachweis ausgestellt, der eine fehlerhafte Signatur trägt. \nTeilen Sie dies ihm mit.'**
  String get wrongCredentialNote;

  /// No description provided for @familyName.
  ///
  /// In de, this message translates to:
  /// **'Nachname'**
  String get familyName;

  /// No description provided for @givenName.
  ///
  /// In de, this message translates to:
  /// **'Vorname'**
  String get givenName;

  /// No description provided for @birthDate.
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum'**
  String get birthDate;

  /// No description provided for @countryName.
  ///
  /// In de, this message translates to:
  /// **'Staat'**
  String get countryName;

  /// No description provided for @stateOrProvinceName.
  ///
  /// In de, this message translates to:
  /// **'(Bundes)land'**
  String get stateOrProvinceName;

  /// No description provided for @localityName.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get localityName;

  /// No description provided for @organizationName.
  ///
  /// In de, this message translates to:
  /// **'Organisation'**
  String get organizationName;

  /// No description provided for @commonName.
  ///
  /// In de, this message translates to:
  /// **'Allgemeiner Name'**
  String get commonName;

  /// No description provided for @loadIssuerData.
  ///
  /// In de, this message translates to:
  /// **'Lade Informationen'**
  String get loadIssuerData;

  /// No description provided for @errorOpen.
  ///
  /// In de, this message translates to:
  /// **'Das Wallet kann nicht geöffnet werden.\nIst auf Ihrem Gerät ein Sicherheitsmechanismus (Pin, Passwort, Muster, Fingerabdruck,...) hinterlegt?\nWenn nicht, sichern Sie Ihr Gerät über Ihre Geräteeinstellungen.'**
  String get errorOpen;

  /// No description provided for @credential.
  ///
  /// In de, this message translates to:
  /// **'Nachweis'**
  String get credential;

  /// No description provided for @add.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get add;

  /// No description provided for @hashNotMatch.
  ///
  /// In de, this message translates to:
  /// **'Hash stimmt nicht überein'**
  String get hashNotMatch;

  /// No description provided for @hashNotMatchNote.
  ///
  /// In de, this message translates to:
  /// **'Dies kann ein Betrugsversuch sein,\n daher wird die Zahlung abgebrochen.'**
  String get hashNotMatchNote;

  /// No description provided for @otherValue.
  ///
  /// In de, this message translates to:
  /// **'Anderer Betrag'**
  String get otherValue;

  /// No description provided for @otherValueNote.
  ///
  /// In de, this message translates to:
  /// **'Der Betrag stimmt nicht mit dem von Ihnen angeforderten überein.\n Die Zahlung wird abgebrochen.'**
  String get otherValueNote;

  /// No description provided for @copy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get copy;

  /// No description provided for @copyNote.
  ///
  /// In de, this message translates to:
  /// **'Invoice wurde in die Zwischenablage kopiert.'**
  String get copyNote;

  /// No description provided for @enterAmount.
  ///
  /// In de, this message translates to:
  /// **'Betrag eingeben'**
  String get enterAmount;

  /// No description provided for @description.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get description;

  /// No description provided for @favorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favorites;

  /// No description provided for @amount.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get amount;

  /// No description provided for @termsOfService.
  ///
  /// In de, this message translates to:
  /// **'AGBs und Datenschutzbestimmungen'**
  String get termsOfService;

  /// No description provided for @termsOfServiceNote.
  ///
  /// In de, this message translates to:
  /// **'Ausgewählte Kontexte haben zusätzliche Nutzungsbedingungen. Bitte lesen Sie diese sorgfälltig durch und wählen die aus, denen Sie zustimmen. Kontexte, deren Nutzungsbedingungen Sie nicht zustimmen, werden nicht hinzugefügt.'**
  String get termsOfServiceNote;

  /// No description provided for @termsOfServiceButton.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen wie ausgewählt'**
  String get termsOfServiceButton;

  /// No description provided for @termsOfServiceNote1.
  ///
  /// In de, this message translates to:
  /// **'Ich habe die AGBs und Datenschutzbestimmungen unter '**
  String get termsOfServiceNote1;

  /// No description provided for @termsOfServiceNote2.
  ///
  /// In de, this message translates to:
  /// **' gelesen und akzeptiere diese.'**
  String get termsOfServiceNote2;

  /// No description provided for @pleaseAccept.
  ///
  /// In de, this message translates to:
  /// **'Bitte stimme unseren AGBs und Datenschutzbestimmungen zu.'**
  String get pleaseAccept;

  /// No description provided for @addNewApp.
  ///
  /// In de, this message translates to:
  /// **'Füge einen neuen Kontext hinzu'**
  String get addNewApp;

  /// No description provided for @invoiceLimit.
  ///
  /// In de, this message translates to:
  /// **'Aus Sicherheitsgründen darf dein Kontostand umgerechnet nicht mehr als 10€ betragen. Die Invoice überschreitet diesen Betrag.'**
  String get invoiceLimit;

  /// No description provided for @creationFailed.
  ///
  /// In de, this message translates to:
  /// **'Erstellen Fehlgeschlagen'**
  String get creationFailed;

  /// No description provided for @license.
  ///
  /// In de, this message translates to:
  /// **'Lizenzen'**
  String get license;

  /// No description provided for @welcome.
  ///
  /// In de, this message translates to:
  /// **'Willkommen in Deiner EECC Identity Wallet'**
  String get welcome;

  /// No description provided for @welcomeNote.
  ///
  /// In de, this message translates to:
  /// **'Bevor dir deine persönliche Wallet zur Verfügung steht, müssen noch ein paar Dinge geklärt werden.'**
  String get welcomeNote;

  /// No description provided for @technic.
  ///
  /// In de, this message translates to:
  /// **'Technische Vorraussetzungen'**
  String get technic;

  /// No description provided for @technicNoteOk.
  ///
  /// In de, this message translates to:
  /// **'Dein Smartphone ist mit Pin, Muster, Passwort oder Biometrie geschützt.'**
  String get technicNoteOk;

  /// No description provided for @technicNoteBad.
  ///
  /// In de, this message translates to:
  /// **'Dein Smartphone ist nicht mit Pin, Muster, Passwort oder Biometrie geschützt.'**
  String get technicNoteBad;

  /// No description provided for @noteGoToSettings.
  ///
  /// In de, this message translates to:
  /// **'Bitte schütze dein Gerät in den System-Einstellungen.'**
  String get noteGoToSettings;

  /// No description provided for @openSettings.
  ///
  /// In de, this message translates to:
  /// **'System-Einstellungen öffnen'**
  String get openSettings;

  /// No description provided for @recheck.
  ///
  /// In de, this message translates to:
  /// **'Erneut prüfen'**
  String get recheck;

  /// No description provided for @start.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get start;

  /// No description provided for @favoriteExplanation.
  ///
  /// In de, this message translates to:
  /// **'Füge einen Kontext zu deiner Favoriten-Liste hinzu, indem Du den Stern auf der Karte berührst.'**
  String get favoriteExplanation;

  /// No description provided for @addCardExplanation.
  ///
  /// In de, this message translates to:
  /// **'Füge eine Karte durch Scannen Ihres QR- oder Strichcodes hinzu'**
  String get addCardExplanation;

  /// No description provided for @importSuccess.
  ///
  /// In de, this message translates to:
  /// **'{passType} erfolgreich importiert'**
  String importSuccess(String passType);

  /// No description provided for @importFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get importFailed;

  /// No description provided for @saveError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Speichern'**
  String get saveError;

  /// No description provided for @saveErrorNote.
  ///
  /// In de, this message translates to:
  /// **'Speichern des Nachweises nicht möglich.\nBitte wiederhole den Vorgang.'**
  String get saveErrorNote;

  /// No description provided for @paymentInformation.
  ///
  /// In de, this message translates to:
  /// **'Zahlungsinformation'**
  String get paymentInformation;

  /// No description provided for @paymentInformationDetail.
  ///
  /// In de, this message translates to:
  /// **'Für die Weiterverarbeitung der Daten fallen folgende Kosten an: '**
  String get paymentInformationDetail;

  /// No description provided for @funding1.
  ///
  /// In de, this message translates to:
  /// **'Für das Freigeben Ihrer Daten werden Ihnen'**
  String get funding1;

  /// No description provided for @funding2.
  ///
  /// In de, this message translates to:
  /// **'gutgeschrieben'**
  String get funding2;

  /// No description provided for @oidcTan.
  ///
  /// In de, this message translates to:
  /// **'Vorgangsnummer'**
  String get oidcTan;

  /// No description provided for @oidcTanInfo.
  ///
  /// In de, this message translates to:
  /// **'Der Aussteller hat Ihnen für diesen Vorgang eine Vorgangsnummer übermittelt. Bitte tragen Sie diese hier ein.'**
  String get oidcTanInfo;

  /// No description provided for @noAppNote.
  ///
  /// In de, this message translates to:
  /// **'Sie haben noch keine Anwendungen hinzugefügt'**
  String get noAppNote;

  /// No description provided for @newAppTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Anwendungen'**
  String get newAppTitle;

  /// No description provided for @newAppNote.
  ///
  /// In de, this message translates to:
  /// **'Keine neuen Anwendungen verfügbar'**
  String get newAppNote;

  /// No description provided for @unknownQrCode.
  ///
  /// In de, this message translates to:
  /// **'Unbekannter Qr-Code'**
  String get unknownQrCode;

  /// No description provided for @unknownQrCodeNote.
  ///
  /// In de, this message translates to:
  /// **'Der gescannte Qr-Code enthalt Daten, die nicht verarbeitet werden können.'**
  String get unknownQrCodeNote;

  /// No description provided for @subscribe.
  ///
  /// In de, this message translates to:
  /// **'Abonieren'**
  String get subscribe;

  /// No description provided for @sendSatoshi.
  ///
  /// In de, this message translates to:
  /// **'Satoshi senden'**
  String get sendSatoshi;

  /// No description provided for @backgroundPresentation.
  ///
  /// In de, this message translates to:
  /// **'Hintergrundabfragen'**
  String get backgroundPresentation;

  /// No description provided for @backgroundPresentationNote.
  ///
  /// In de, this message translates to:
  /// **'Hiermit erlaube ich {otherParty}, diesen Nachweis zukünftig ohne meine explizite Zustimmung abzufragen'**
  String backgroundPresentationNote(String otherParty);

  /// No description provided for @finishProcess.
  ///
  /// In de, this message translates to:
  /// **'Prozess abgeschlossen'**
  String get finishProcess;

  /// No description provided for @finishProcessNote.
  ///
  /// In de, this message translates to:
  /// **'Dieser Nachweis wurde bereits an Sie ausgestellt'**
  String get finishProcessNote;

  /// No description provided for @authFailed.
  ///
  /// In de, this message translates to:
  /// **'Authentifizierung fehlgeschlagen'**
  String get authFailed;

  /// No description provided for @credentialDownloadFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Nachweis kann nicht heruntergeladen werden'**
  String get credentialDownloadFailed;

  /// No description provided for @issuanceInfoNotFound.
  ///
  /// In de, this message translates to:
  /// **'Wir haben leider nicht herausgefunden, wie Du Dir die fehlenden Nachweise besorgen kannst.'**
  String get issuanceInfoNotFound;

  /// No description provided for @issuanceInfoFound.
  ///
  /// In de, this message translates to:
  /// **'Hier kannst Du Dir die fehlenden Nachweise besorgen:'**
  String get issuanceInfoFound;

  /// No description provided for @hsmwEmployeeCard.
  ///
  /// In de, this message translates to:
  /// **'Mitarbeiterausweis (HSMW)'**
  String get hsmwEmployeeCard;

  /// No description provided for @hsmwStudentCard.
  ///
  /// In de, this message translates to:
  /// **'Studierendenausweis (HSMW)'**
  String get hsmwStudentCard;

  /// No description provided for @pictureProcess.
  ///
  /// In de, this message translates to:
  /// **'Ihr Bild wird erstellt'**
  String get pictureProcess;

  /// No description provided for @pictureProcessNote.
  ///
  /// In de, this message translates to:
  /// **'Bitte haben Sie einen Moment Geduld'**
  String get pictureProcessNote;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @restore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get restore;

  /// No description provided for @restoreMenu.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get restoreMenu;

  /// No description provided for @restoreQuestion.
  ///
  /// In de, this message translates to:
  /// **'Sind Sie sich sicher, dass Sie ein Backup einlesen wollen?'**
  String get restoreQuestion;

  /// No description provided for @restoreMnemonic.
  ///
  /// In de, this message translates to:
  /// **'Wortfolge eingeben'**
  String get restoreMnemonic;

  /// No description provided for @backup.
  ///
  /// In de, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupUpload.
  ///
  /// In de, this message translates to:
  /// **'Ihr Backup wird hochgeladen'**
  String get backupUpload;

  /// No description provided for @backupWriteDownPassword.
  ///
  /// In de, this message translates to:
  /// **'Bitte notieren Sie sich diese Wortfolge! Ohne diese Wörter kann ihr Backup nicht wiederhergestellt werden!'**
  String get backupWriteDownPassword;

  /// No description provided for @backupNotFound.
  ///
  /// In de, this message translates to:
  /// **'Kein passendes Backup gefunden! Falsche Wortfolge?'**
  String get backupNotFound;

  /// No description provided for @eidReadAndCreateCredentials.
  ///
  /// In de, this message translates to:
  /// **'eID auslesen & Nachweise erstellen'**
  String get eidReadAndCreateCredentials;

  /// No description provided for @eidDescription.
  ///
  /// In de, this message translates to:
  /// **'Wir lesen Deinen Personalausweis (eID) per NFC aus und erstellen daraus digitale Nachweise: einen Ausweis-Nachweis (ID Card) sowie – je nach tatsächlichem Alter – einen Altersnachweis 16+ oder 18+.'**
  String get eidDescription;

  /// No description provided for @youWillReceive.
  ///
  /// In de, this message translates to:
  /// **'Du erhältst'**
  String get youWillReceive;

  /// No description provided for @idCardCredential.
  ///
  /// In de, this message translates to:
  /// **'Personalausweis-Credential'**
  String get idCardCredential;

  /// No description provided for @ageVerification16Or18.
  ///
  /// In de, this message translates to:
  /// **'Altersnachweis 16+ oder 18+'**
  String get ageVerification16Or18;

  /// No description provided for @externalRequestDetected.
  ///
  /// In de, this message translates to:
  /// **'Externe Anfrage erkannt'**
  String get externalRequestDetected;

  /// No description provided for @startNowReadEid.
  ///
  /// In de, this message translates to:
  /// **'Jetzt starten – eID auslesen'**
  String get startNowReadEid;

  /// No description provided for @startNowAuthenticate.
  ///
  /// In de, this message translates to:
  /// **'Jetzt starten – authentifizieren'**
  String get startNowAuthenticate;

  /// No description provided for @authenticate.
  ///
  /// In de, this message translates to:
  /// **'Ausweisen'**
  String get authenticate;

  /// No description provided for @readIdCardData.
  ///
  /// In de, this message translates to:
  /// **'Ausweis lesen'**
  String get readIdCardData;

  /// No description provided for @insertCardInstruction.
  ///
  /// In de, this message translates to:
  /// **'Bitte halte deinen Ausweis an die NFC-Schnittstelle deines Gerätes. Diese befindet sich meistens an der Rückseite des Gerätes.'**
  String get insertCardInstruction;

  /// No description provided for @cancelProcess.
  ///
  /// In de, this message translates to:
  /// **'Vorgang Abbrechen'**
  String get cancelProcess;

  /// No description provided for @canEntry.
  ///
  /// In de, this message translates to:
  /// **'CAN-Eingabe'**
  String get canEntry;

  /// No description provided for @enterCanInstruction.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib die 6-stellige CAN von der Vorderseite deines Ausweises ein:'**
  String get enterCanInstruction;

  /// No description provided for @canMustBe6Digits.
  ///
  /// In de, this message translates to:
  /// **'Die CAN muss genau 6 Stellen haben'**
  String get canMustBe6Digits;

  /// No description provided for @pinEntry.
  ///
  /// In de, this message translates to:
  /// **'PIN-Eingabe'**
  String get pinEntry;

  /// No description provided for @enterPinInstruction.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deine 6-stellige Ausweis-PIN ein:'**
  String get enterPinInstruction;

  /// No description provided for @pinMustBe6Digits.
  ///
  /// In de, this message translates to:
  /// **'Die PIN muss genau 6 Stellen haben'**
  String get pinMustBe6Digits;

  /// No description provided for @idCardPin.
  ///
  /// In de, this message translates to:
  /// **'Ausweis-PIN'**
  String get idCardPin;

  /// No description provided for @remainingAttempts.
  ///
  /// In de, this message translates to:
  /// **'Verbleibende Versuche: {count}'**
  String remainingAttempts(int count);

  /// No description provided for @pinRetry2Warning.
  ///
  /// In de, this message translates to:
  /// **'Solltest Du auch bei diesem Versuch eine falsche PIN eingeben, muss vor dem letzten Versuch die CAN eingegeben werden. Das ist die 6-stellige Zahlenfolge auf der Vorderseite deines Ausweises.'**
  String get pinRetry2Warning;

  /// No description provided for @pinRetry1Warning.
  ///
  /// In de, this message translates to:
  /// **'Das ist dein letzter Versuch, eine korrekte PIN einzugeben. Sollte auch dieser fehlschlagen, wird die Online-Ausweis-Funktion gesperrt.'**
  String get pinRetry1Warning;

  /// No description provided for @fiveDigitPinInfo.
  ///
  /// In de, this message translates to:
  /// **'Du hast nur eine 5-stellige PIN? Dann brich den Vorgang bitte ab und nutze die Funktion \"PIN ändern\" der offiziellen Ausweis-App.'**
  String get fiveDigitPinInfo;

  /// No description provided for @pukEntry.
  ///
  /// In de, this message translates to:
  /// **'PUK-Eingabe'**
  String get pukEntry;

  /// No description provided for @enterPukInstruction.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib die 10-stellige PUK deines Ausweises ein:'**
  String get enterPukInstruction;

  /// No description provided for @pukMustBe10Digits.
  ///
  /// In de, this message translates to:
  /// **'Die PUK muss genau 10 Stellen haben'**
  String get pukMustBe10Digits;

  /// No description provided for @processFailed.
  ///
  /// In de, this message translates to:
  /// **'Vorgang fehlgeschlagen'**
  String get processFailed;

  /// No description provided for @idCardData.
  ///
  /// In de, this message translates to:
  /// **'Ausweisdaten'**
  String get idCardData;

  /// No description provided for @readingData.
  ///
  /// In de, this message translates to:
  /// **'Lese Daten'**
  String get readingData;

  /// No description provided for @saveAsCredential.
  ///
  /// In de, this message translates to:
  /// **'Als Nachweis speichern'**
  String get saveAsCredential;

  /// No description provided for @continueToPin.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Pin Eingabe'**
  String get continueToPin;

  /// No description provided for @loadingRequest.
  ///
  /// In de, this message translates to:
  /// **'Anfrage wird geladen'**
  String get loadingRequest;

  /// No description provided for @attributeAddress.
  ///
  /// In de, this message translates to:
  /// **'Adresse'**
  String get attributeAddress;

  /// No description provided for @attributeBirthName.
  ///
  /// In de, this message translates to:
  /// **'Geburtsname'**
  String get attributeBirthName;

  /// No description provided for @attributeFamilyName.
  ///
  /// In de, this message translates to:
  /// **'Familienname'**
  String get attributeFamilyName;

  /// No description provided for @attributeGivenNames.
  ///
  /// In de, this message translates to:
  /// **'Vorname(n)'**
  String get attributeGivenNames;

  /// No description provided for @attributePlaceOfBirth.
  ///
  /// In de, this message translates to:
  /// **'Geburtsort'**
  String get attributePlaceOfBirth;

  /// No description provided for @attributeDateOfBirth.
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum'**
  String get attributeDateOfBirth;

  /// No description provided for @attributeDoctoralDegree.
  ///
  /// In de, this message translates to:
  /// **'Doktortitel'**
  String get attributeDoctoralDegree;

  /// No description provided for @attributeArtisticName.
  ///
  /// In de, this message translates to:
  /// **'Künstlername'**
  String get attributeArtisticName;

  /// No description provided for @attributeValidUntil.
  ///
  /// In de, this message translates to:
  /// **'Ablaufdatum'**
  String get attributeValidUntil;

  /// No description provided for @attributeNationality.
  ///
  /// In de, this message translates to:
  /// **'Staatsangehörigkeit'**
  String get attributeNationality;

  /// No description provided for @attributeIssuingCountry.
  ///
  /// In de, this message translates to:
  /// **'Aussteller-Land'**
  String get attributeIssuingCountry;

  /// No description provided for @attributeDocumentType.
  ///
  /// In de, this message translates to:
  /// **'Dokumententyp'**
  String get attributeDocumentType;

  /// No description provided for @attributeResidencePermitI.
  ///
  /// In de, this message translates to:
  /// **'Aufenthaltserlaubnis 1'**
  String get attributeResidencePermitI;

  /// No description provided for @attributeResidencePermitII.
  ///
  /// In de, this message translates to:
  /// **'Aufenthaltserlaubnis 2'**
  String get attributeResidencePermitII;

  /// No description provided for @attributeCommunityID.
  ///
  /// In de, this message translates to:
  /// **'Wohnort-ID'**
  String get attributeCommunityID;

  /// No description provided for @attributeAddressVerification.
  ///
  /// In de, this message translates to:
  /// **'Adressverifikation'**
  String get attributeAddressVerification;

  /// No description provided for @attributeAgeVerification.
  ///
  /// In de, this message translates to:
  /// **'Altersverifikation'**
  String get attributeAgeVerification;

  /// No description provided for @requester.
  ///
  /// In de, this message translates to:
  /// **'Anfragender'**
  String get requester;

  /// No description provided for @certificateIssuer.
  ///
  /// In de, this message translates to:
  /// **'Aussteller des Berechtigungszertifikats'**
  String get certificateIssuer;

  /// No description provided for @validity.
  ///
  /// In de, this message translates to:
  /// **'Gültigkeit'**
  String get validity;

  /// No description provided for @reason.
  ///
  /// In de, this message translates to:
  /// **'Grund'**
  String get reason;

  /// No description provided for @providerInformation.
  ///
  /// In de, this message translates to:
  /// **'Anbieterinformationen'**
  String get providerInformation;

  /// No description provided for @requestedData.
  ///
  /// In de, this message translates to:
  /// **'Angefragte Daten'**
  String get requestedData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
