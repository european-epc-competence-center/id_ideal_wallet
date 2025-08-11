// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get openSourceNote => 'Open Source auf GitHub';

  @override
  String get forkedFromNote => 'Von diesem Projekt geforkt';

  @override
  String get readIdCard => 'Ausweisdaten auslesen';

  @override
  String get about => 'Über';

  @override
  String get idCard => 'Ausweis';

  @override
  String get home => 'Startseite';

  @override
  String get options => 'Optionen';

  @override
  String get lastPayments => 'Letzte Zahlungen';

  @override
  String get showMore => 'Weitere Anzeigen';

  @override
  String get noPayments => 'Keine getätigten Zahlungen';

  @override
  String get scan => 'Scannen';

  @override
  String get openWallet => 'Wallet öffnen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get verifyIdentity => 'Bitte verifizieren Sie Ihre Identität';

  @override
  String get localizedReason =>
      'Zum Öffnen des Wallets ist Ihre Authentifizierung nötig';

  @override
  String get sellCredentialTitle => 'Nachweis verkaufen';

  @override
  String get forSale => 'zum Kauf anbieten';

  @override
  String get forShow => 'zum Vorzeigen anbieten';

  @override
  String get delete => 'Löschen';

  @override
  String get deletionNote =>
      'Sind Sie sicher, dass sie diesen Nachweis löschen möchten? Dieser Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get deletionNoteApp =>
      'Sind Sie sicher, dass sie diese Anwendung löschen möchten?';

  @override
  String get issuer => 'Aussteller';

  @override
  String get otherData => 'Sonstige Daten';

  @override
  String get personnelData => 'Persönliche Daten';

  @override
  String get invoice => 'Rechnung';

  @override
  String get invoiceNumber => 'Rechnungsnummer';

  @override
  String get selfIssued => 'Selbstausgestellt';

  @override
  String get verifiedBy => 'verifiziert von: ';

  @override
  String get verified => 'verifiziert';

  @override
  String get notVerified => 'nicht verfiziert';

  @override
  String get state => 'Status';

  @override
  String get valid => 'Gültig';

  @override
  String get expired => 'Abgelaufen';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get revoked => 'Zurückgezogen';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get issuanceDate => 'Ausstelldatum';

  @override
  String get expirationDate => 'Ablaufdatum';

  @override
  String get history => 'Aktivitäten';

  @override
  String get issued => 'Ausgestellt';

  @override
  String get presented => 'Vorgezeigt';

  @override
  String get presentedError => 'Vorzeigen fehlgeschlagen';

  @override
  String get presentCredential => 'Nachweis vorzeigen';

  @override
  String get contextCredentialTitle => 'Kontext hinzufügen';

  @override
  String get create => 'Anlegen';

  @override
  String get credentialPageTitle => 'Meine Nachweise';

  @override
  String get show => 'Anzeigen';

  @override
  String get preview => 'Vorschau';

  @override
  String get anonymousIssuer => 'Anonymer Aussteller';

  @override
  String get anonymous => 'anonym';

  @override
  String get total => 'Gesamt';

  @override
  String payments(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en',
      zero: '',
    );
    return 'Zahlung$_temp0';
  }

  @override
  String get paymentMethod => 'Zahlungsmethode';

  @override
  String get noteShownCredentials => 'Diese Nachweise wurden soeben vorgezeigt';

  @override
  String get noteOtherShowCredentials =>
      'Ihr Gegenüber bietet Ihnen an, einen Nachweis mit folgenden Daten vorzuzeigen:';

  @override
  String get request => 'Anfragen';

  @override
  String get requestTitle => 'Anfrage';

  @override
  String get ignore => 'Ignorieren';

  @override
  String get dataFor => 'Die Daten werden übermittelt an:';

  @override
  String get reasonForRequest => 'Grund der Anfrage';

  @override
  String get selfIssueAllowed =>
      'Der Anfragende erlaubt, Daten selbst einzutragen';

  @override
  String get enterData => 'Daten eintragen';

  @override
  String get presentationSuccessful => 'Nachweise erfolgreich vorgezeigt';

  @override
  String get presentationFailed => 'Nachweise konnten nicht vorgezeigt werden';

  @override
  String get reject => 'Ablehnen';

  @override
  String get send => 'Senden';

  @override
  String get sendPresentation => 'Nachweise senden';

  @override
  String get username => 'Nutzername im gewählten Netzwerk';

  @override
  String get mailAddress => 'E-Mail Adresse';

  @override
  String get selfIssuable => 'Selbstausstellbare Nachweise';

  @override
  String get deviceInformation => 'Geräteinformationen';

  @override
  String get stored => 'Nachweis gespeichert';

  @override
  String get selfIssuance => 'Selbstausstellung';

  @override
  String get noCredentialsTitle => 'Fehlerhafte Anfrage';

  @override
  String get noCredentialsNote =>
      'Die Anfrage kann nicht verarbeitet werden. Entweder fehlt der erforderliche Nachweis in Ihrer Wallet, es werden nicht unterstützte Funktionen verlangt, oder es liegt ein Fehler bei der Erstellung vor.';

  @override
  String get paymentSuccessful => 'Zahlung erfolgreich';

  @override
  String get paymentReceived => 'Zahlung eingegangen';

  @override
  String get paymentFailed => 'Zahlung fehlgeschlagen';

  @override
  String get paymentFailedNote => 'Zahlung konnte nicht durchgeführt werden';

  @override
  String get noPaymentMethod => 'Zahlung nicht möglich';

  @override
  String get requestPayment => 'Zahlung anfordern';

  @override
  String get noPaymentNote => 'Keine passende Zahlungsmethode gefunden';

  @override
  String get selectPaymentMethod => 'Lightning Account auswählen';

  @override
  String get chargeMoney => 'Aufladen';

  @override
  String get noPaymentMethodNote =>
      'Sie besitzen kein Wallet. \nBitte legen Sie sich eines an und\nsorgen für ausreichend Deckung';

  @override
  String get credentialReceived => 'Nachweis empfangen';

  @override
  String get amountSatoshi => 'Betrag in Satoshi';

  @override
  String get amountEuro => 'Betrag in Euro';

  @override
  String get pay => 'Bezahlen';

  @override
  String get back => 'Zurück';

  @override
  String get receive => 'Empfangen';

  @override
  String get orderWithPayment => 'Zahlungspflichtig bestellen';

  @override
  String get credentialOffer => 'Nachweis-Angebot';

  @override
  String get balance => 'Kontostand';

  @override
  String get noteGetInformation => 'möchte folgende Informationen von Dir';

  @override
  String get notePresentationPurpose =>
      'gibt an, die Daten für folgendes zu verwenden';

  @override
  String get missingDataTitle => 'Fehlende Daten';

  @override
  String get missingDataNote =>
      'Der Anfragende bittet um eine Selbstauskunft. Bitte trage die geforderten Daten ein.';

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String get downloadFailedExplanation =>
      'Die Anfrage des Gegenübers kann nicht herunterladen werden.';

  @override
  String get unexpectedMessage => 'Unerwartete Nachricht';

  @override
  String get malformedMessage => 'Fehlerhafte Nachricht';

  @override
  String get malformedOOBExplanation =>
      'Die Nachricht kann nicht gelesen werden.\n Sie können versuchen, den QR-Code ein weiteres mal zu scannen. \n Sollte der Fehler bestehen bleiben, kontaktieren Sie den Support des Anfrage-Erstellers.';

  @override
  String get unknownMessageExplanation =>
      'Diese Nachricht wird derzeit nicht unterstützt.\n Die Interaktion kann daher nicht fortgesetzt werden.';

  @override
  String get malformedEncryptedMessage =>
      'Beim Entschlüsseln einer Nachricht ist ein Fehler aufgetreten.';

  @override
  String get waiting => 'Einen kleinen Moment bitte.';

  @override
  String get waitingSendPresentation => 'Ihre Antwort wird gesendet.';

  @override
  String get waitingQrData => 'Die Daten werden verarbeitet.';

  @override
  String get errorNotEnoughCredentials =>
      'Sie können die Anfrage ihres Gegenübers nicht erfüllen, da Sie nicht die nötigen Nachweise besitzen bzw. ausgewählt haben.\nInformieren Sie sich, wie Sie die fehlenden Nachweise erlangen können oder wählen Sie die fehlenden aus.';

  @override
  String get attention => 'Achtung';

  @override
  String get cancelWarning => 'Zum Beenden \'Abbrechen\' verwenden';

  @override
  String get accept => 'Annehmen';

  @override
  String get noteNoCredentials => 'Keine Nachweise vorhanden';

  @override
  String get emptyCredentialTitle => 'Willkommen in Ihrer\nEECC Wallet';

  @override
  String get emptyCredentialEidInfo =>
      'Nutzen Sie Ihren elektronischen Personalausweis, um digitale Nachweise zu erstellen. Die Wallet liest Ihre eID-Daten sicher über NFC aus.';

  @override
  String get emptyCredentialQrInfo =>
      'Scannen Sie QR-Codes, um neue Nachweise zu empfangen oder vorhandene Nachweise zu präsentieren.';

  @override
  String get allCredentials => 'Alle Nachweise';

  @override
  String get sendFailed => 'Es gibt ein Problem';

  @override
  String get sendFailedNote =>
      'Der Vorgang kann nicht beendet werden. Bitte probieren Sie es erneut.';

  @override
  String get wrongCredential => 'Fehlerhafter Nachweis';

  @override
  String get wrongCredentialNote =>
      'Dein Gegenüber hat einen Nachweis ausgestellt, der eine fehlerhafte Signatur trägt. \nTeilen Sie dies ihm mit.';

  @override
  String get familyName => 'Nachname';

  @override
  String get givenName => 'Vorname';

  @override
  String get birthDate => 'Geburtsdatum';

  @override
  String get countryName => 'Staat';

  @override
  String get stateOrProvinceName => '(Bundes)land';

  @override
  String get localityName => 'Stadt';

  @override
  String get organizationName => 'Organisation';

  @override
  String get commonName => 'Allgemeiner Name';

  @override
  String get loadIssuerData => 'Lade Informationen';

  @override
  String get errorOpen =>
      'Das Wallet kann nicht geöffnet werden.\nIst auf Ihrem Gerät ein Sicherheitsmechanismus (Pin, Passwort, Muster, Fingerabdruck,...) hinterlegt?\nWenn nicht, sichern Sie Ihr Gerät über Ihre Geräteeinstellungen.';

  @override
  String get credential => 'Nachweis';

  @override
  String get add => 'Hinzufügen';

  @override
  String get hashNotMatch => 'Hash stimmt nicht überein';

  @override
  String get hashNotMatchNote =>
      'Dies kann ein Betrugsversuch sein,\n daher wird die Zahlung abgebrochen.';

  @override
  String get otherValue => 'Anderer Betrag';

  @override
  String get otherValueNote =>
      'Der Betrag stimmt nicht mit dem von Ihnen angeforderten überein.\n Die Zahlung wird abgebrochen.';

  @override
  String get copy => 'Kopieren';

  @override
  String get copyNote => 'Invoice wurde in die Zwischenablage kopiert.';

  @override
  String get enterAmount => 'Betrag eingeben';

  @override
  String get description => 'Beschreibung';

  @override
  String get favorites => 'Favoriten';

  @override
  String get amount => 'Betrag';

  @override
  String get termsOfService => 'AGBs und Datenschutzbestimmungen';

  @override
  String get termsOfServiceNote =>
      'Ausgewählte Kontexte haben zusätzliche Nutzungsbedingungen. Bitte lesen Sie diese sorgfälltig durch und wählen die aus, denen Sie zustimmen. Kontexte, deren Nutzungsbedingungen Sie nicht zustimmen, werden nicht hinzugefügt.';

  @override
  String get termsOfServiceButton => 'Hinzufügen wie ausgewählt';

  @override
  String get termsOfServiceNote1 =>
      'Ich habe die AGBs und Datenschutzbestimmungen unter ';

  @override
  String get termsOfServiceNote2 => ' gelesen und akzeptiere diese.';

  @override
  String get pleaseAccept =>
      'Bitte stimme unseren AGBs und Datenschutzbestimmungen zu.';

  @override
  String get addNewApp => 'Füge einen neuen Kontext hinzu';

  @override
  String get invoiceLimit =>
      'Aus Sicherheitsgründen darf dein Kontostand umgerechnet nicht mehr als 10€ betragen. Die Invoice überschreitet diesen Betrag.';

  @override
  String get creationFailed => 'Erstellen Fehlgeschlagen';

  @override
  String get license => 'Lizenzen';

  @override
  String get welcome => 'Willkommen in Ihrer EECC Identity Wallet';

  @override
  String get welcomeNote =>
      'Bevor dir deine persönliche Wallet zur Verfügung steht, müssen noch ein paar Dinge geklärt werden.';

  @override
  String get technic => 'Technische Vorraussetzungen';

  @override
  String get technicNoteOk =>
      'Dein Smartphone ist mit Pin, Muster, Passwort oder Biometrie geschützt.';

  @override
  String get technicNoteBad =>
      'Dein Smartphone ist nicht mit Pin, Muster, Passwort oder Biometrie geschützt.';

  @override
  String get noteGoToSettings =>
      'Bitte schütze dein Gerät in den System-Einstellungen.';

  @override
  String get openSettings => 'System-Einstellungen öffnen';

  @override
  String get recheck => 'Erneut prüfen';

  @override
  String get start => 'Los geht\'s';

  @override
  String get favoriteExplanation =>
      'Füge einen Kontext zu deiner Favoriten-Liste hinzu, indem Du den Stern auf der Karte berührst.';

  @override
  String get addCardExplanation =>
      'Füge eine Karte durch Scannen Ihres QR- oder Strichcodes hinzu';

  @override
  String importSuccess(String passType) {
    return '$passType erfolgreich importiert';
  }

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get saveError => 'Fehler beim Speichern';

  @override
  String get saveErrorNote =>
      'Speichern des Nachweises nicht möglich.\nBitte wiederhole den Vorgang.';

  @override
  String get paymentInformation => 'Zahlungsinformation';

  @override
  String get paymentInformationDetail =>
      'Für die Weiterverarbeitung der Daten fallen folgende Kosten an: ';

  @override
  String get funding1 => 'Für das Freigeben Ihrer Daten werden Ihnen';

  @override
  String get funding2 => 'gutgeschrieben';

  @override
  String get oidcTan => 'Vorgangsnummer';

  @override
  String get oidcTanInfo =>
      'Der Aussteller hat Ihnen für diesen Vorgang eine Vorgangsnummer übermittelt. Bitte tragen Sie diese hier ein.';

  @override
  String get noAppNote => 'Sie haben noch keine Anwendungen hinzugefügt';

  @override
  String get newAppTitle => 'Neue Anwendungen';

  @override
  String get newAppNote => 'Keine neuen Anwendungen verfügbar';

  @override
  String get unknownQrCode => 'Unbekannter Qr-Code';

  @override
  String get unknownQrCodeNote =>
      'Der gescannte Qr-Code enthalt Daten, die nicht verarbeitet werden können.';

  @override
  String get subscribe => 'Abonieren';

  @override
  String get sendSatoshi => 'Satoshi senden';

  @override
  String get backgroundPresentation => 'Hintergrundabfragen';

  @override
  String backgroundPresentationNote(String otherParty) {
    return 'Hiermit erlaube ich $otherParty, diesen Nachweis zukünftig ohne meine explizite Zustimmung abzufragen';
  }

  @override
  String get finishProcess => 'Prozess abgeschlossen';

  @override
  String get finishProcessNote =>
      'Dieser Nachweis wurde bereits an Sie ausgestellt';

  @override
  String get authFailed => 'Authentifizierung fehlgeschlagen';

  @override
  String get credentialDownloadFailed =>
      'Der Nachweis kann nicht heruntergeladen werden';

  @override
  String get issuanceInfoNotFound =>
      'Wir haben leider nicht herausgefunden, wie Du Dir die fehlenden Nachweise besorgen kannst.';

  @override
  String get issuanceInfoFound =>
      'Hier kannst Du Dir die fehlenden Nachweise besorgen:';

  @override
  String get hsmwEmployeeCard => 'Mitarbeiterausweis (HSMW)';

  @override
  String get hsmwStudentCard => 'Studierendenausweis (HSMW)';

  @override
  String get pictureProcess => 'Ihr Bild wird erstellt';

  @override
  String get pictureProcessNote => 'Bitte haben Sie einen Moment Geduld';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get restoreMenu => 'Wiederherstellen';

  @override
  String get restoreQuestion =>
      'Sind Sie sich sicher, dass Sie ein Backup einlesen wollen?';

  @override
  String get restoreMnemonic => 'Wortfolge eingeben';

  @override
  String get backup => 'Backup';

  @override
  String get backupUpload => 'Ihr Backup wird hochgeladen';

  @override
  String get backupWriteDownPassword =>
      'Bitte notieren Sie sich diese Wortfolge! Ohne diese Wörter kann ihr Backup nicht wiederhergestellt werden!';

  @override
  String get backupNotFound =>
      'Kein passendes Backup gefunden! Falsche Wortfolge?';

  @override
  String get eidReadAndCreateCredentials =>
      'eID auslesen & Nachweise erstellen';

  @override
  String get eidDescription =>
      'Wir lesen Ihren Personalausweis (eID) per NFC aus und erstellen daraus digitale Nachweise: einen Ausweis-Nachweis (ID Card) sowie – je nach tatsächlichem Alter – einen Altersnachweis 16+ oder 18+.';

  @override
  String get youWillReceive => 'Sie erhalten';

  @override
  String get idCardCredential => 'ID Card Credential';

  @override
  String get ageVerification16Or18 => 'Altersnachweis 16+ oder 18+';

  @override
  String get externalRequestDetected => 'Externe Anfrage erkannt';

  @override
  String get startNowReadEid => 'Jetzt starten – eID auslesen';

  @override
  String get startNowAuthenticate => 'Jetzt starten – authentifizieren';

  @override
  String get authenticate => 'Ausweisen';

  @override
  String get readIdCardData => 'Ausweis lesen';

  @override
  String get insertCardInstruction =>
      'Bitte halte deinen Ausweis an die NFC-Schnittstelle deines Gerätes. Diese befindet sich meistens an der Rückseite des Gerätes.';

  @override
  String get cancelProcess => 'Vorgang Abbrechen';

  @override
  String get canEntry => 'CAN-Eingabe';

  @override
  String get enterCanInstruction =>
      'Bitte gib die 6-stellige CAN von der Vorderseite deines Ausweises ein:';

  @override
  String get canMustBe6Digits => 'Die CAN muss genau 6 Stellen haben';

  @override
  String get pinEntry => 'PIN-Eingabe';

  @override
  String get enterPinInstruction =>
      'Bitte gib deine 6-stellige Ausweis-PIN ein:';

  @override
  String get pinMustBe6Digits => 'Die PIN muss genau 6 Stellen haben';

  @override
  String get idCardPin => 'Ausweis-PIN';

  @override
  String remainingAttempts(int count) {
    return 'Verbleibende Versuche: $count';
  }

  @override
  String get pinRetry2Warning =>
      'Solltest Du auch bei diesem Versuch eine falsche PIN eingeben, muss vor dem letzten Versuch die CAN eingegeben werden. Das ist die 6-stellige Zahlenfolge auf der Vorderseite deines Ausweises.';

  @override
  String get pinRetry1Warning =>
      'Das ist dein letzter Versuch, eine korrekte PIN einzugeben. Sollte auch dieser fehlschlagen, wird die Online-Ausweis-Funktion gesperrt.';

  @override
  String get fiveDigitPinInfo =>
      'Du hast nur eine 5-stellige PIN? Dann brich den Vorgang bitte ab und nutze die Funktion \"PIN ändern\" der offiziellen Ausweis-App.';

  @override
  String get pukEntry => 'PUK-Eingabe';

  @override
  String get enterPukInstruction =>
      'Bitte gib die 10-stellige PUK deines Ausweises ein:';

  @override
  String get pukMustBe10Digits => 'Die PUK muss genau 10 Stellen haben';

  @override
  String get processFailed => 'Vorgang fehlgeschlagen';

  @override
  String get idCardData => 'Ausweisdaten';

  @override
  String get readingData => 'Lese Daten';

  @override
  String get saveAsCredential => 'Als Nachweis speichern';

  @override
  String get continueToPin => 'Weiter zur Pin Eingabe';

  @override
  String get loadingRequest => 'Anfrage wird geladen';

  @override
  String get attributeAddress => 'Adresse';

  @override
  String get attributeBirthName => 'Geburtsname';

  @override
  String get attributeFamilyName => 'Familienname';

  @override
  String get attributeGivenNames => 'Vorname(n)';

  @override
  String get attributePlaceOfBirth => 'Geburtsort';

  @override
  String get attributeDateOfBirth => 'Geburtsdatum';

  @override
  String get attributeDoctoralDegree => 'Doktortitel';

  @override
  String get attributeArtisticName => 'Künstlername';

  @override
  String get attributeValidUntil => 'Ablaufdatum';

  @override
  String get attributeNationality => 'Staatsangehörigkeit';

  @override
  String get attributeIssuingCountry => 'Aussteller-Land';

  @override
  String get attributeDocumentType => 'Dokumententyp';

  @override
  String get attributeResidencePermitI => 'Aufenthaltserlaubnis 1';

  @override
  String get attributeResidencePermitII => 'Aufenthaltserlaubnis 2';

  @override
  String get attributeCommunityID => 'Wohnort-ID';

  @override
  String get attributeAddressVerification => 'Adressverifikation';

  @override
  String get attributeAgeVerification => 'Altersverifikation';

  @override
  String get requester => 'Anfragender';

  @override
  String get certificateIssuer => 'Aussteller des Berechtigungszertifikats';

  @override
  String get validity => 'Gültigkeit';

  @override
  String get reason => 'Grund';

  @override
  String get providerInformation => 'Anbieterinformationen';

  @override
  String get requestedData => 'Angefragte Daten';
}
