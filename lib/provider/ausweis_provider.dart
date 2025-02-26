import 'dart:convert';
import 'dart:io';

import 'package:dart_ssi/credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/ausweis_message.dart';
import 'package:id_ideal_wallet/functions/didcomm_message_handler.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';

import '../basicUi/ausweis/main_content.dart';

enum AusweisScreen {
  enterPin,
  main,
  insertCard,
  start,
  finish,
  enterCan,
  enterPuk,
  error
}

typedef CustomTypeHandler = void Function(dynamic data);

class AusweisProvider extends ChangeNotifier {
  static const method = MethodChannel('app.channel.method');
  static const stream = EventChannel('app.channel.event');

  AusweisScreen screen = AusweisScreen.start;
  List<String> requestedAttributes = [];
  CertificateMessage? requesterCert;
  double? statusProgress;
  bool start = false;
  bool pinEntered = false;
  Map<String, dynamic>? readData;
  int pinRetry = 3;
  String errorDescription = '';
  String errorMessage = '';
  String? tcTokenUrl;
  bool selfInfo = true;
  bool connected = false;
  bool pause = false;

  late final Map<Type, CustomTypeHandler> typeHandlers;

  AusweisProvider() {
    typeHandlers = {
      InsertCardMessage: handleInsertCardMessage,
      PauseMessage: handlePauseMessage,
      EnterPinMessage: handleEnterPinMessage,
      AccessRightsMessage: handleAccessRightsMessage,
      CertificateMessage: handleCertificateMessage,
      AuthMessage: handleAuthMessage,
      StatusMessage: handleStatusMessage,
      ReaderMessage: handleReaderMessage,
      DisconnectMessage: handleDisconnectMessage,
      EnterCanMessage: handleEnterCanMessage,
      EnterPukMessage: handleEnterPukMessage
    };
  }

  void reset([bool notify = true]) {
    screen = AusweisScreen.start;
    requestedAttributes = [];
    requesterCert = null;
    start = false;
    pinEntered = false;
    readData = null;
    statusProgress = null;
    pinRetry = 3;
    errorDescription = '';
    errorMessage = '';
    selfInfo = true;
    pause = false;
    disconnectSdk();
    if (notify) notifyListeners();
  }

  void startListening() {
    stream.receiveBroadcastStream().listen((data) => handleData(data));
    logger.d('listen data stream');
  }

  void startProgress([String? tcTokenUrl]) {
    connectSdk();
    this.tcTokenUrl = tcTokenUrl;
    screen = AusweisScreen.main;
    start = true;
    notifyListeners();
  }

  void storeAsCredential() async {
    try {
      var wallet = Provider.of<WalletProvider>(navigatorKey.currentContext!,
          listen: false);
      var did = await wallet.newCredentialDid();
      readData!['id'] = did;
      var vc = VerifiableCredential(
          id: did,
          context: [credentialsV1Iri, schemaOrgIri],
          type: ['VerifiableCredential', 'Personalausweis'],
          credentialSubject: readData,
          issuer: did,
          issuanceDate: DateTime.now());
      var signed = await signCredential(wallet.wallet, vc);
      var storedCred = wallet.getCredential(did);
      if (storedCred != null) {
        wallet.storeCredential(signed, storedCred.hdPath);
      } else {
        throw Exception('Das sollte nicht passieren');
      }

      showSuccessMessage(
          AppLocalizations.of(navigatorKey.currentContext!)!.credentialReceived,
          'Personalausweis');
    } catch (e) {
      showErrorMessage('Speichern fehlgeschlagen', e.toString());
    }
    reset();
  }

  void handleData(String data) async {
    logger.d('data received: $data');

    var message = AusweisMessage.fromJson(data);

    CustomTypeHandler? handler = typeHandlers[message.runtimeType];
    if (handler != null) {
      handler(message);
    } else {
      logger.d("No handler for ${data.runtimeType}");
    }
  }

  void connectSdk() {
    try {
      method.invokeMethod('connectSdk');
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
      connected = false;
      return;
    }
    connected = true;
  }

  void disconnectSdk() {
    try {
      method.invokeMethod('disconnectSdk');
    } on PlatformException catch (e) {
      logger.d('Failed to disconnect from sdk: ${e.message}.');
      return;
    }
    connected = false;
  }

  void getInfo() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'GET_INFO'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void getStatus() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'GET_STATUS'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void checkApiLevel() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'GET_API_LEVEL'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void setApiLevel(int newLevel) {
    try {
      method.invokeMethod('sendCommand',
          jsonEncode({'cmd': 'SET_API_LEVEL', 'level': newLevel}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void getReader(String readerName) {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({'cmd': 'GET_READER', 'name': readerName}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void getReaderList() {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({'cmd': 'GET_READER_LIST'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void runAuth(
      {required String tcTokenUrl,
      bool developerMode = false,
      bool handleInterrupt = false,
      bool status = true,
      String? sessionStartedMessage,
      String? sessionFailedMessage,
      String? sessionSucceedMessage,
      String? sessionInProgressMessage}) {
    Map<String, dynamic> cmd = {
      'cmd': 'RUN_AUTH',
      "tcTokenURL": tcTokenUrl,
      "developerMode": developerMode,
      "handleInterrupt": handleInterrupt,
      'status': status
    };
    if (Platform.isIOS) {
      Map<String, String> messages = {};
      if (sessionStartedMessage != null) {
        messages['sessionStarted'] = sessionStartedMessage;
      }
      if (sessionFailedMessage != null) {
        messages['sessionFailed'] = sessionFailedMessage;
      }
      if (sessionSucceedMessage != null) {
        messages['sessionSucceeded'] = sessionSucceedMessage;
      }
      if (sessionInProgressMessage != null) {
        messages['sessionInProgress'] = sessionInProgressMessage;
      }
      cmd['messages'] = messages;
    }
    try {
      method.invokeMethod('sendCommand', jsonEncode(cmd));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void runChangePin(
      {bool handleInterrupt = false,
      bool status = true,
      String? sessionStartedMessage,
      String? sessionFailedMessage,
      String? sessionSucceedMessage,
      String? sessionInProgressMessage}) {
    Map<String, dynamic> cmd = {
      'cmd': 'RUN_CHANGE_PIN',
      "handleInterrupt": handleInterrupt,
      'status': status
    };
    if (Platform.isIOS) {
      Map<String, String> messages = {};
      if (sessionStartedMessage != null) {
        messages['sessionStarted'] = sessionStartedMessage;
      }
      if (sessionFailedMessage != null) {
        messages['sessionFailed'] = sessionFailedMessage;
      }
      if (sessionSucceedMessage != null) {
        messages['sessionSucceeded'] = sessionSucceedMessage;
      }
      if (sessionInProgressMessage != null) {
        messages['sessionInProgress'] = sessionInProgressMessage;
      }
      cmd['messages'] = messages;
    }
    try {
      method.invokeMethod('sendCommand', jsonEncode(cmd));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void runDemoAuth() {
    runAuth(
        // tcTokenUrl:
        //     'https://test.governikus-eid.de/AusweisAuskunft/WebServiceRequesterServlet',
        tcTokenUrl:
            'https://www.autentapp.de/AusweisAuskunft/WebServiceRequesterServlet',
        developerMode: false);
  }

  void getAccessRights() {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({'cmd': 'GET_ACCESS_RIGHTS'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void setAccessRights(List<String> accessRights) {
    try {
      method.invokeMethod('sendCommand',
          jsonEncode({'cmd': 'SET_ACCESS_RIGHTS', 'chat': accessRights}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void setCard(
      {required String readerName,
      List<Map<String, dynamic>>? files,
      List<Map<String, dynamic>>? keys}) {
    Map<String, dynamic> cmd = {'cmd': 'SET_CARD', 'name': readerName};

    if (files != null || keys != null) {
      Map<String, dynamic> sim = {};
      if (files != null) {
        sim['files'] = files;
      }
      if (keys != null) {
        sim['keys'] = keys;
      }
      cmd['simulator'] = sim;
    }
    try {
      method.invokeMethod('sendCommand', jsonEncode(cmd));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void getCertificate() {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({'cmd': 'GET_CERTIFICATE'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void cancel() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'CANCEL'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void accept() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'ACCEPT'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void interrupt() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'INTERRUPT'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void sendContinue() {
    try {
      method.invokeMethod('sendCommand', jsonEncode({'cmd': 'CONTINUE'}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void setPin(String pin) {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({"cmd": "SET_PIN", "value": pin}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
    pinEntered = true;
    screen = AusweisScreen.finish;
  }

  void setNewPin(String pin) {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({"cmd": "SET_NEW_PIN", "value": pin}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
  }

  void setCan(String can) {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({"cmd": "SET_CAN", "value": can}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
    screen = AusweisScreen.finish;
  }

  void setPuk(String puk) {
    try {
      method.invokeMethod(
          'sendCommand', jsonEncode({"cmd": "SET_PUK", "value": puk}));
    } on PlatformException catch (e) {
      logger.d('Failed to connect to sdk: ${e.message}.');
    }
    screen = AusweisScreen.finish;
  }

  void handleInsertCardMessage(dynamic message) {
    if (message is InsertCardMessage) {
      if (screen != AusweisScreen.enterPin &&
          screen != AusweisScreen.enterCan &&
          screen != AusweisScreen.enterPuk) {
        screen = AusweisScreen.insertCard;
      }
    } else {
      logger.d("Incorrect type for handleInsertCardMessage");
    }
    notifyListeners();
  }

  void handlePauseMessage(dynamic message) {
    if (message is PauseMessage) {
      screen = AusweisScreen.insertCard;
      pause = true;
      logger.d('set pause: $pause');
    } else {
      logger.d("Incorrect type for handlePauseMessage");
    }
    notifyListeners();
  }

  void handleEnterPinMessage(dynamic message) {
    if (message is EnterPinMessage) {
      screen = AusweisScreen.enterPin;
      pinRetry = message.reader?.cardRetryCounter ?? 3;
      pinEntered = false;
    } else {
      logger.d("Incorrect type for handleEnterPinMessage");
    }
    notifyListeners();
  }

  void handleAccessRightsMessage(dynamic message) {
    if (message is AccessRightsMessage) {
      requestedAttributes = message.effectiveRights;
      if (requesterCert == null) {
        getCertificate();
      }
    } else {
      logger.d("Incorrect type for handleAccessRightsMessage");
    }
    notifyListeners();
  }

  void handleCertificateMessage(dynamic message) {
    if (message is CertificateMessage) {
      requesterCert = message;
    } else {
      logger.d("Incorrect type for handleCertificateMessage");
    }
    notifyListeners();
  }

  Map<String, String> idCardTranslations = {
    'DocumentType': 'Dokumententyp:',
    'IssuingState': 'Ausstellender Staat:',
    'DateOfExpiry': 'Ablaufdatum:',
    'GivenNames': 'Vorname:',
    'FamilyNames': 'Nachname:',
    'ArtisticName': 'Künstlername:',
    'AcademicTitle': 'Akademischer Titel:',
    'PlaceOfBirth': 'Geburtsort:',
    'Nationality': 'Staatsangehörigkeit:',
    'BirthName': 'Geburtsname:',
    'PlaceOfResidence': 'Adresse:',
    'DateOfBirth': 'Geburtsdatum:',
    'ResidencePermitI': 'Aufenthaltserlaubnis 1:'
  };

  void handleAuthMessage(dynamic message) async {
    if (message is AuthMessage) {
      if (message.major ==
          'http://www.bsi.bund.de/ecard/api/1.1/resultmajor#ok') {
        if (selfInfo) {
          var response = await get(Uri.parse(message.url!),
              headers: {'Accept': 'application/json'});
          if (response.statusCode == 200) {
            readData = {};
            String utf8body = utf8.decode(response.bodyBytes);
            var jsonResponse = jsonDecode(utf8body);
            var personalData = jsonResponse['PersonalData'];
            personalData.forEach((key, value) {
              String translatedKey = idCardTranslations[key] ?? key;
              if (key == 'PlaceOfBirth' && value is Map) {
                readData![translatedKey] = value['FreetextPlace'];
              } else if (key == 'PlaceOfResidence' && value is Map) {
                var structuredPlace = value['StructuredPlace'];
                if (structuredPlace is Map) {
                  readData![translatedKey] =
                      'Land: ${structuredPlace['Country']}, '
                          'Stadt: ${structuredPlace['ZipCode']} ${structuredPlace['City']}, Straße: ${structuredPlace['Street'].replaceAll('ẞ', 'ß')}';
                  logger.d('Street: ${structuredPlace['Street']}');
                }
              } else if (value is Map) {
                value.forEach((subKey, subValue) {
                  readData!['$translatedKey.$subKey'] = subValue;
                });
              } else {
                if (key == 'DateOfBirth' || key == 'DateOfExpiry') {
                  value = value.split("+")[0];
                  DateTime parsedDate = DateTime.parse(value);
                  String formattedDate =
                      DateFormat('dd.MM.yyyy').format(parsedDate);
                  readData![translatedKey] = formattedDate;
                } else {
                  readData![translatedKey] = value;
                }
              }
            });
            logger.d(readData);

            screen = AusweisScreen.finish;
            requestedAttributes = [];
            requesterCert = null;
            disconnectSdk();
          }
        } else {
          launchUrl(Uri.parse(message.url!),
              mode: LaunchMode.externalApplication);
          logger.d('launched');
          Navigator.pop(navigatorKey.currentContext!);
          logger.d('page changed?');
          reset(false);
        }
      } else if (message.major ==
              'http://www.bsi.bund.de/ecard/api/1.1/resultmajor#error' &&
          message.minor ==
              'http://www.bsi.bund.de/ecard/api/1.1/resultminor/sal#cancellationByUser') {
        if (message.reason == 'User_Cancelled') {
          reset();
        } else {
          errorDescription =
              message.description ?? 'Es ist ein Fehler aufgetreten';
          errorMessage =
              message.message ?? 'Es liegt keine Beschreibung des Fehlers vor';
          screen = AusweisScreen.error;
        }
      }
    } else {
      logger.d("Incorrect type for handleAuthMessage");
    }
    notifyListeners();
  }

  void handleStatusMessage(dynamic message) {
    if (message is StatusMessage) {
      if (pinEntered) {
        screen = AusweisScreen.finish;
      } else {
        screen = AusweisScreen.main;
      }
      statusProgress =
          message.progress == null ? null : message.progress! / 100;
      logger.d(statusProgress);
    } else {
      logger.d("Incorrect type for handleStatusMessage");
    }
    notifyListeners();
  }

  void handleReaderMessage(dynamic message) {
    if (message is ReaderMessage) {
      if (start) {
        if (tcTokenUrl == null) {
          runDemoAuth();
        } else {
          runAuth(tcTokenUrl: tcTokenUrl!);
          selfInfo = false;
        }
        start = false;
      }

      if (message.cardRetryCounter != null) {
        pinRetry = 3;
      }

      logger.d(pause);

      if (pause) {
        if (message.cardRetryCounter != null &&
            message.cardDeactivated != null &&
            message.cardInoperative != null) {
          sendContinue();
          if (pinEntered) {
            screen = AusweisScreen.finish;
          } else {
            screen = AusweisScreen.main;
          }
          pause = false;
        }
      }
    } else {
      logger.d("Incorrect type for handleReaderMessage");
    }
    notifyListeners();
  }

  void handleDisconnectMessage(dynamic message) {
    if (message is DisconnectMessage) {
      logger.d('Successfully disconnected');
    } else {
      logger.d("Incorrect type for handleDisconnectMessage");
    }
    notifyListeners();
  }

  void handleEnterCanMessage(dynamic message) {
    if (message is EnterCanMessage) {
      screen = AusweisScreen.enterCan;
    } else {
      logger.d("Incorrect type for handleEnterCanMessage");
    }
    notifyListeners();
  }

  void handleEnterPukMessage(dynamic message) {
    if (message is EnterPukMessage) {
      screen = AusweisScreen.enterPuk;
    } else {
      logger.d("Incorrect type for handleEnterPukMessage");
    }
    notifyListeners();
  }
}
