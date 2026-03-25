import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/l10n/app_localizations.dart';
import 'package:id_ideal_wallet/provider/encryption_provider.dart';
import 'package:id_ideal_wallet/provider/server_provider.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:restart/restart.dart';

const String localhost =
    "http://78.47.219.104:3000"; //"http://ec2-18-199-147-148.eu-central-1.compute.amazonaws.com:3000";//"http://10.0.2.2";
const String apiKey = 'supersecretapikey123';

// Function to perform backup
Future<void> performBackup(BuildContext context, String memonic) async {
  final encryptionService = EncryptionService();

  Uint8List password =
      utf8.encode(encryptionService.getPasswordFromMemonic(memonic));

  var wallet = Provider.of<WalletProvider>(context, listen: false);
  final exported = await wallet.wallet.export();
  final encodedData = jsonEncode(exported);

  // Encrypt wallet data
  final encryptedData = encryptionService.encryptData(encodedData, password);

  // Save the file locally first
  File file =
      await saveFileLocally(sha256.convert(password).toString(), encryptedData);

  String apiUrl = '$localhost/data';
  String textData = sha256.convert(password).toString();

  await sendStringAndFile(apiUrl, apiKey, textData, file);
}

// Function to apply backup
Future<void> applyBackup(BuildContext context, String memonic) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);

  final encryptionService = EncryptionService();

  String password = encryptionService.getPasswordFromMemonic(memonic);
  String encryptedData;

  try {
    encryptedData =
        await fetchFileInMemory(sha256.convert(utf8.encode(password)).toString());
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.backupNotFound)));
    return;
  }

  final decodedData = await encryptionService.decryptData(password, encryptedData);
  final imported = (jsonDecode(decodedData) as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));

  await wallet.wallet.import(imported);

  restart();
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
