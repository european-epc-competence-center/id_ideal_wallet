import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_ssi/credentials.dart';
import 'package:dart_ssi/wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:id_ideal_wallet/functions/didcomm_message_handler.dart';
import 'package:id_ideal_wallet/functions/util.dart';
import 'package:id_ideal_wallet/provider/encryption_provider.dart';
import 'package:id_ideal_wallet/provider/server_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

const String localhost =
    "http://78.47.219.104:3000"; //"http://ec2-18-199-147-148.eu-central-1.compute.amazonaws.com:3000";//"http://10.0.2.2";
const String apiKey = 'supersecretapikey123';

Future<(Map<String, Map<String, dynamic>>, String)> getBackupableData() async {
  var wallet =
      Provider.of<WalletProvider>(navigatorKey.currentContext!, listen: false);
  var walletData = await wallet.wallet.export();
  var osKeyStoreDids = wallet.getDidsInOsKeyStore();
  String notInBackup = '';
  logger.d(walletData['credentials']?.length);
  for (var d in osKeyStoreDids ?? <String>[]) {
    logger.d(d);
    var c = walletData['credentials']?.remove(d);
    if (c != null) {
      logger.d(c);
      notInBackup += getTypeToShow(VerifiableCredential.fromJson(
              Credential.fromJson(c).verifiableCredential)
          .type);
      notInBackup += ', ';
    }
  }
  logger.d(walletData['credentials']?.length);
  return (walletData, notInBackup);
}

// Function to perform backup in background task
Future<bool> performBackup(Map<String, dynamic> input) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(input['token']);
  logger.d('backup start');
  final encryptionService = EncryptionService();
  Map<String, Map<String, dynamic>> data = input['data'];
  String memonic = input['mnemonic'];
  logger.d(memonic);
  logger.d(data['credentials']?.length);
  Uint8List password =
      utf8.encode(encryptionService.getPasswordFromMemonic(memonic));

  var encodedBoxes = jsonEncode(data);

  // Encrypt boxes
  final encryptedData = encryptionService.encryptData(encodedBoxes, password);

  // Save the file locally first
  File file =
      await saveFileLocally(sha256.convert(password).toString(), encryptedData);
  logger.d('local file saved');

  String apiUrl =
      '$localhost/data'; // Replace with your server URL      // Replace with your API key
  String textData = sha256.convert(password).toString();

  await sendStringAndFile(apiUrl, apiKey, textData, file);

  return true;
}

Future<Map<String, Map<String, dynamic>>?> loadAndDecryptBackup(
    String mnemonic) async {
  final encryptionService = EncryptionService();

  String password = encryptionService.getPasswordFromMemonic(mnemonic);
  String encryptedData;

  try {
    encryptedData = await fetchFileInMemory(
        sha256.convert(utf8.encode(password)).toString());

    // Decrypt the data using the password
    String encodedBoxes =
        await encryptionService.decryptData(password, encryptedData);

    var walletData = (jsonDecode(encodedBoxes) as Map).map((k, v) => MapEntry(
        k as String, (v as Map).map((k1, v1) => MapEntry(k1 as String, v1))));
    return walletData;
  } catch (e) {
    // if we catch here we did not get a 200

    return null;
  }
}

// Function to apply backup
Future<void> applyBackup(BuildContext context, String mnemonic) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);

  var walletData = await compute(loadAndDecryptBackup, mnemonic);
  if (walletData == null) {
    showErrorMessage(
      AppLocalizations.of(navigatorKey.currentContext!)!.backupRestoreError,
      AppLocalizations.of(navigatorKey.currentContext!)!.backupRestoreErrorNote,
    );
    return;
  }

  var cKeys = wallet.wallet.getAllCredentials().keys;
  for (var k in cKeys) {
    await wallet.wallet.deleteCredential(k);
  }
  logger.d(wallet.wallet.getAllCredentials().length);

  await wallet.wallet.import(walletData);

  await wallet.restart();
}

// Function to encode boxes
String encodeBoxes(Map<String, Box<dynamic>> boxes) {
  Map<String, Map<dynamic, dynamic>> encodedBoxes = {};

  boxes.forEach((key, box) {
    encodedBoxes[key] = box.toMap().map((k, v) {
      if (v is Credential) {
        return MapEntry(k, v.toJson());
      } else if (v is Connection) {
        return MapEntry(k, v.toJson());
      } else if (v is DidcommConversation) {
        return MapEntry(k, v.toJson());
      } else {
        return MapEntry(k, v); // For basic types (int, String, etc.)
      }
    });
  });

  return jsonEncode(encodedBoxes);
}

// Function to decode and set boxes
Future<void> decodeAndSetBoxes(
    String encodedData, Map<String, Box<dynamic>> boxes) async {
  Map<String, dynamic> decodedData = jsonDecode(encodedData);

  for (var entry in decodedData.entries) {
    String boxKey = entry.key;
    Map<dynamic, dynamic> boxData = entry.value;

    if (boxes.containsKey(boxKey)) {
      Box<dynamic> box = boxes[boxKey]!;
      await box.clear(); // Clear existing data in the box

      for (var dataEntry in boxData.entries) {
        dynamic key = dataEntry.key;
        dynamic value = dataEntry.value;
        /**
            The boxes are handled by the dart_ssi library. To see the boxes types with their keys
            check dart_ssi/lib/src/wallet/wallet_store.dart -> openBoxes()
         */
        if (boxKey == 'credentialBox' || boxKey == "issuingHistory") {
          box.put(key, Credential.fromJson(value));
        } else if (boxKey == 'connection') {
          box.put(key, Connection.fromJson(value));
        } else if (boxKey == 'didcommConversations') {
          box.put(key, DidcommConversation.fromJson(value));
        } else {
          if (boxKey == 'keyBox' && key == 'seed') {
            box.put(key, Uint8List.fromList((value as List).cast<int>()));
          } else {
            box.put(key, value); // For basic types (int, String, etc.)
          }
        }
      }
    }
  }
}

// Function to save the file on disk
Future<File> saveFileLocally(String fileName, String encryptedData) async {
  // Get the directory where to save the file (temporary directory in this case)
  final directory = await getTemporaryDirectory();

  // Create the file path
  final filePath = '${directory.path}/$fileName';

  // Create the file
  File file = File(filePath);

  // Write the encrypted data to the file
  return file.writeAsString(encryptedData);
}
