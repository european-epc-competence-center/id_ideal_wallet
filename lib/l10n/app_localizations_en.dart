// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get openSourceNote => 'Open Source on GitHub';

  @override
  String get forkedFromNote => 'Upstream project';

  @override
  String get readIdCard => 'Extract ID Card data';

  @override
  String get about => 'About';

  @override
  String get idCard => 'ID Card';

  @override
  String get home => 'Home';

  @override
  String get options => 'Options';

  @override
  String get lastPayments => 'Last Payments';

  @override
  String get showMore => 'show more';

  @override
  String get noPayments => 'no payments';

  @override
  String get scan => 'Scan';

  @override
  String get openWallet => 'Open wallet';

  @override
  String get cancel => 'cancel';

  @override
  String get ok => 'OK';

  @override
  String get verifyIdentity => 'Please verify your identity';

  @override
  String get localizedReason =>
      'Your authentication is required to open the wallet';

  @override
  String get sellCredentialTitle => 'Sell credential';

  @override
  String get forSale => 'offer for sale';

  @override
  String get forShow => 'offer for presentation';

  @override
  String get delete => 'delete';

  @override
  String get deletionNote =>
      'Are you sure you want to delete this credential? This operation cannot be undone.';

  @override
  String get deletionNoteApp =>
      'Are you sure you want to delete this application?';

  @override
  String get issuer => 'Issuer';

  @override
  String get otherData => 'Other data';

  @override
  String get personnelData => 'Personal data';

  @override
  String get invoice => 'Invoice';

  @override
  String get invoiceNumber => 'invoice number';

  @override
  String get selfIssued => 'self-issued';

  @override
  String get verifiedBy => 'verified by: ';

  @override
  String get verified => 'verified';

  @override
  String get notVerified => 'not verified';

  @override
  String get state => 'state';

  @override
  String get valid => 'valid';

  @override
  String get expired => 'expired';

  @override
  String get inactive => 'inactive';

  @override
  String get revoked => 'revoked';

  @override
  String get unknown => 'unknown';

  @override
  String get issuanceDate => 'issuance date';

  @override
  String get expirationDate => 'expiration date';

  @override
  String get history => 'Activity';

  @override
  String get issued => 'issued';

  @override
  String get presented => 'presented';

  @override
  String get presentedError => 'presentation failed';

  @override
  String get presentCredential => 'present credential';

  @override
  String get contextCredentialTitle => 'Add context';

  @override
  String get create => 'create';

  @override
  String get credentialPageTitle => 'My credentials';

  @override
  String get show => 'show';

  @override
  String get preview => 'Preview';

  @override
  String get anonymousIssuer => 'anonymous issuer';

  @override
  String get anonymous => 'anonymous';

  @override
  String get total => 'total';

  @override
  String payments(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      zero: '',
    );
    return 'Payment$_temp0';
  }

  @override
  String get paymentMethod => 'payment method';

  @override
  String get noteShownCredentials => 'These credentials were just presented';

  @override
  String get noteOtherShowCredentials =>
      'Your counterpart offers to show you a credential with the following data:';

  @override
  String get request => 'request';

  @override
  String get requestTitle => 'Request';

  @override
  String get ignore => 'ignore';

  @override
  String get dataFor => 'The data are transmitted to:';

  @override
  String get reasonForRequest => 'reason for request';

  @override
  String get selfIssueAllowed =>
      'The requester allows to enter data by yourself';

  @override
  String get enterData => 'enter your data';

  @override
  String get presentationSuccessful => 'Credentials successfully presented';

  @override
  String get presentationFailed => 'Credentials could not be presented';

  @override
  String get reject => 'Reject';

  @override
  String get send => 'send';

  @override
  String get sendPresentation => 'send credentials';

  @override
  String get username => 'User name in the selected network';

  @override
  String get mailAddress => 'e-mail addresse';

  @override
  String get selfIssuable => 'Self-issuable credentials';

  @override
  String get deviceInformation => 'device information';

  @override
  String get stored => 'credential saved';

  @override
  String get selfIssuance => 'Self-Issuance';

  @override
  String get noCredentialsTitle => 'Incorrect request';

  @override
  String get noCredentialsNote =>
      'You have just received a request that cannot be processed. Either functions are requested that your application does not currently support or your counterpart made a mistake when creating it.';

  @override
  String get paymentSuccessful => 'payment successful';

  @override
  String get paymentReceived => 'Payment received';

  @override
  String get paymentFailed => 'payment failed';

  @override
  String get paymentFailedNote => 'Payment could not be performed';

  @override
  String get noPaymentMethod => 'payment not possible';

  @override
  String get requestPayment => 'request payment';

  @override
  String get noPaymentNote => 'No suitable payment method found';

  @override
  String get selectPaymentMethod => 'Select Lightning Account';

  @override
  String get chargeMoney => 'charge money';

  @override
  String get noPaymentMethodNote =>
      'You do not have a wallet for payment. \nPlease create one.';

  @override
  String get credentialReceived => 'Credential received';

  @override
  String get amountSatoshi => 'amount in Satoshi';

  @override
  String get amountEuro => 'amount in Euro';

  @override
  String get pay => 'pay';

  @override
  String get back => 'back';

  @override
  String get receive => 'receive';

  @override
  String get orderWithPayment => 'Order with obligation to pay';

  @override
  String get credentialOffer => 'Credential Offer';

  @override
  String get balance => 'Balance';

  @override
  String get noteGetInformation => 'like to have the following information';

  @override
  String get notePresentationPurpose => 'specifies to use the data for';

  @override
  String get missingDataTitle => 'Missing data';

  @override
  String get missingDataNote =>
      'The requester asks you to tell a little more about yourself. Please fill in the requested data.';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get downloadFailedExplanation =>
      'The request of the counterpart can not be downloaded.';

  @override
  String get unexpectedMessage => 'Unexpected message';

  @override
  String get malformedMessage => 'Incorrect message';

  @override
  String get malformedOOBExplanation =>
      'The message cannot be read.\n You can try to scan the QR code one more time. \n If the error persists, contact the support of the request creator.';

  @override
  String get unknownMessageExplanation =>
      'This message is currently not supported.\n Therefore, the interaction cannot be continued.';

  @override
  String get malformedEncryptedMessage =>
      'An error occurred while decrypting a message.';

  @override
  String get waiting => 'Just a moment, please.';

  @override
  String get waitingSendPresentation => 'Your answer is sent.';

  @override
  String get waitingQrData => 'The data is being processed.';

  @override
  String get errorNotEnoughCredentials =>
      'You cannot fulfill the request of your counterpart because you do not have the necessary credentials (selected).\nFind out how you can obtain the missing credentials or select the missing ones.';

  @override
  String get attention => 'Attention';

  @override
  String get cancelWarning => 'Please use \'Cancel\' to close';

  @override
  String get accept => 'Accept';

  @override
  String get noteNoCredentials => 'No Credentials';

  @override
  String get emptyCredentialTitle => 'Welcome to your\nEECC Wallet';

  @override
  String get emptyCredentialEidInfo =>
      'Use your electronic ID card to create digital credentials. The wallet securely reads your eID data via NFC.';

  @override
  String get emptyCredentialQrInfo =>
      'Scan QR codes to receive new credentials or present existing credentials.';

  @override
  String get allCredentials => 'All Credentials';

  @override
  String get sendFailed => 'Sending failed';

  @override
  String get sendFailedNote =>
      'Sending a message failed or the message could not be processed by the other side';

  @override
  String get wrongCredential => 'Incorrect Credential';

  @override
  String get wrongCredentialNote =>
      'Your counterpart has issued a credential that bears an incorrect signature.\nInform him about this.';

  @override
  String get familyName => 'surname';

  @override
  String get givenName => 'given name';

  @override
  String get birthDate => 'birth date';

  @override
  String get countryName => 'country';

  @override
  String get stateOrProvinceName => 'state/province';

  @override
  String get localityName => 'locality';

  @override
  String get organizationName => 'organization';

  @override
  String get commonName => 'common name';

  @override
  String get loadIssuerData => 'Load information';

  @override
  String get errorOpen =>
      'The wallet cannot be opened.\nIs a security mechanism (pin, password, pattern, fingerprint,...) stored on your device?\nIf not, secure your device via your device settings.';

  @override
  String get credential => 'Credential';

  @override
  String get add => 'Add';

  @override
  String get hashNotMatch => 'Hash does not match';

  @override
  String get hashNotMatchNote =>
      'This may be an attempt to scam you,\ntherefore the payment will be canceled';

  @override
  String get otherValue => 'Other Amount';

  @override
  String get otherValueNote =>
      'The amount does not match the one you requested.\nThe payment is canceled.';

  @override
  String get copy => 'Copy';

  @override
  String get copyNote => 'Invoice copied to clipboard';

  @override
  String get enterAmount => 'Enter Amount';

  @override
  String get description => 'Description';

  @override
  String get favorites => 'Favorites';

  @override
  String get amount => 'Amount';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceNote =>
      'Selected contexts have additional terms of use. Please read them carefully and select the ones you agree with. Contexts whose terms of use you do not agree with will not be added.';

  @override
  String get termsOfServiceButton => 'Add as selected';

  @override
  String get termsOfServiceNote1 =>
      'I have read and accept the terms and conditions and privacy policy at ';

  @override
  String get termsOfServiceNote2 => '.';

  @override
  String get pleaseAccept =>
      'Please accept our terms and conditions and privacy policy';

  @override
  String get addNewApp => 'Add a new context';

  @override
  String get invoiceLimit =>
      'For security reasons, your account balance must not exceed the equivalent of 10€. The invoice exceeds this amount.';

  @override
  String get creationFailed => 'Creation failed';

  @override
  String get license => 'Licenses';

  @override
  String get welcome => 'Welcome to your EECC Identity Wallet';

  @override
  String get welcomeNote =>
      'Before your personal wallet is available to you, a few things need to be cleared up.';

  @override
  String get technic => 'Technical Requirements';

  @override
  String get technicNoteOk =>
      'Your smartphone is protected with pin, pattern, password or biometrics.';

  @override
  String get technicNoteBad =>
      'Your smartphone is not protected with pin, pattern, password or biometrics.';

  @override
  String get noteGoToSettings =>
      'Please protect your device in the system settings.';

  @override
  String get openSettings => 'Open System-Settings';

  @override
  String get recheck => 'Check again';

  @override
  String get start => 'Let\'s start';

  @override
  String get favoriteExplanation =>
      'Add a context to your favorites list by touching the star on the map.';

  @override
  String get addCardExplanation => 'Add a card by scanning its QR or barcode';

  @override
  String importSuccess(String passType) {
    return '$passType successfully imported';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String get saveError => 'Error saving';

  @override
  String get saveErrorNote =>
      'Unable to save the credential.\nPlease retry the operation.';

  @override
  String get paymentInformation => 'Payment information';

  @override
  String get paymentInformationDetail =>
      'The following costs are incurred for the further processing of the data: ';

  @override
  String get funding1 => 'You will be credited with ';

  @override
  String get funding2 => 'for releasing your data';

  @override
  String get oidcTan => 'Transaction number';

  @override
  String get oidcTanInfo =>
      'The issuer has sent you a transaction number for this transaction. Please enter it here.';

  @override
  String get noAppNote => 'You haven\'t added any applications yet';

  @override
  String get newAppTitle => 'New applications';

  @override
  String get newAppNote => 'No new applications available';

  @override
  String get unknownQrCode => 'Unknown Qr-Code';

  @override
  String get unknownQrCodeNote =>
      'The scanned Qr code contains data that cannot be processed.';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get sendSatoshi => 'send Satoshi';

  @override
  String get backgroundPresentation => 'Background-Presentation';

  @override
  String backgroundPresentationNote(String otherParty) {
    return 'I hereby authorize $otherParty to request these credentials in the future without my explicit consent.';
  }

  @override
  String get finishProcess => 'Process completed';

  @override
  String get finishProcessNote =>
      'The credential has already been issued to you';

  @override
  String get authFailed => 'Authentication failed';

  @override
  String get credentialDownloadFailed => 'The credential cannot be downloaded';

  @override
  String get issuanceInfoNotFound =>
      'Unfortunately, we have not found out how you can obtain the missing credentials.';

  @override
  String get issuanceInfoFound =>
      'You can obtain the missing credentials here:';

  @override
  String get hsmwEmployeeCard => 'Employee-Card (HSMW)';

  @override
  String get hsmwStudentCard => 'Student-Card (HSMW)';

  @override
  String get pictureProcess => 'Your picture is created';

  @override
  String get pictureProcessNote => 'Please wait a moment';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get restore => 'Restore';

  @override
  String get restoreMenu => 'Restore Backup';

  @override
  String get restoreQuestion => 'Are you sure you want to load a Backup?';

  @override
  String get restoreMnemonic => 'Enter your Secret Words';

  @override
  String get backup => 'backup';

  @override
  String get backupUpload => 'Your backup is beeing uploaded';

  @override
  String get backupWriteDownPassword =>
      'Please note down this list of words! Without these words you wont be able to restore from Backup!';

  @override
  String get backupNotFound => 'Backup not found! Wrong Password?';

  @override
  String get eidReadAndCreateCredentials => 'Read eID & Create Credentials';

  @override
  String get eidDescription =>
      'We read your ID card (eID) via NFC and create digital credentials: an ID card credential and - depending on your actual age - an age verification 16+ or 18+.';

  @override
  String get youWillReceive => 'You will receive';

  @override
  String get idCardCredential => 'ID Card Credential';

  @override
  String get ageVerification16Or18 => 'Age Verification 16+ or 18+';

  @override
  String get externalRequestDetected => 'External request detected';

  @override
  String get startNowReadEid => 'Start now – Read eID';

  @override
  String get startNowAuthenticate => 'Start now – Authenticate';

  @override
  String get authenticate => 'Authenticate';

  @override
  String get readIdCardData => 'Read ID card data';

  @override
  String get insertCardInstruction =>
      'Please hold your ID card to the NFC interface of your device. This is usually located on the back of the device.';

  @override
  String get cancelProcess => 'Cancel Process';

  @override
  String get canEntry => 'CAN Entry';

  @override
  String get enterCanInstruction =>
      'Please enter the 6-digit CAN from the front of your ID card:';

  @override
  String get canMustBe6Digits => 'The CAN must be exactly 6 digits';

  @override
  String get pinEntry => 'PIN Entry';

  @override
  String get enterPinInstruction => 'Please enter your 6-digit ID card PIN:';

  @override
  String get pinMustBe6Digits => 'The PIN must be exactly 6 digits';

  @override
  String get idCardPin => 'ID Card PIN';

  @override
  String remainingAttempts(int count) {
    return 'Remaining attempts: $count';
  }

  @override
  String get pinRetry2Warning =>
      'If you enter an incorrect PIN on this attempt as well, the CAN must be entered before the last attempt. This is the 6-digit number sequence on the front of your ID card.';

  @override
  String get pinRetry1Warning =>
      'This is your last attempt to enter a correct PIN. If this also fails, the online ID card function will be blocked.';

  @override
  String get fiveDigitPinInfo =>
      'Do you only have a 5-digit PIN? Then please cancel the process and use the \"Change PIN\" function in the official ID card app.';

  @override
  String get pukEntry => 'PUK Entry';

  @override
  String get enterPukInstruction =>
      'Please enter the 10-digit PUK of your ID card:';

  @override
  String get pukMustBe10Digits => 'The PUK must be exactly 10 digits';

  @override
  String get processFailed => 'Process Failed';

  @override
  String get idCardData => 'ID Card Data';

  @override
  String get readingData => 'Reading data';

  @override
  String get saveAsCredential => 'Save as Credential';

  @override
  String get continueToPin => 'Continue to PIN entry';

  @override
  String get loadingRequest => 'Loading request';

  @override
  String get attributeAddress => 'Address';

  @override
  String get attributeBirthName => 'Birth Name';

  @override
  String get attributeFamilyName => 'Family Name';

  @override
  String get attributeGivenNames => 'Given Name(s)';

  @override
  String get attributePlaceOfBirth => 'Place of Birth';

  @override
  String get attributeDateOfBirth => 'Date of Birth';

  @override
  String get attributeDoctoralDegree => 'Doctoral Degree';

  @override
  String get attributeArtisticName => 'Artistic Name';

  @override
  String get attributeValidUntil => 'Valid Until';

  @override
  String get attributeNationality => 'Nationality';

  @override
  String get attributeIssuingCountry => 'Issuing Country';

  @override
  String get attributeDocumentType => 'Document Type';

  @override
  String get attributeResidencePermitI => 'Residence Permit I';

  @override
  String get attributeResidencePermitII => 'Residence Permit II';

  @override
  String get attributeCommunityID => 'Community ID';

  @override
  String get attributeAddressVerification => 'Address Verification';

  @override
  String get attributeAgeVerification => 'Age Verification';

  @override
  String get requester => 'Requester';

  @override
  String get certificateIssuer => 'Certificate Issuer';

  @override
  String get validity => 'Validity';

  @override
  String get reason => 'Reason';

  @override
  String get providerInformation => 'Provider Information';

  @override
  String get requestedData => 'Requested Data';

  @override
  String get oidMetadataError => 'Metadata Error';

  @override
  String get oidMetadataErrorNote =>
      'The issuer metadata could not be retrieved.';
}
