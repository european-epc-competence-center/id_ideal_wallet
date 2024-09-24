import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:dart_ssi/src/wallet/hive_model.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:id_ideal_wallet/provider/encryption_provider.dart';
import 'package:id_ideal_wallet/provider/server_provider.dart';

const String localhost = "http://10.0.2.2";
const String apiKey = 'supersecretapikey123'; 
const String backupFileName = 'hidy_backup.enc';
const String symbolsForPasswordGeneration = 'ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_=+[]{};:,.<>?';

// Function to perform backup
Future<void> performBackup(BuildContext context, Uint8List password) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);
  var boxes = wallet.wallet.getBoxes();

  // Filter out null boxes
  Map<String, Box<dynamic>> nonNullableBoxes = Map.fromEntries(
    boxes.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value!)),
  );

  var encodedBoxes = encodeBoxes(nonNullableBoxes);
  
  final encryptionService = EncryptionService();

  // Initialize with a password
  await encryptionService.init(password);

  // Encrypt boxes
  final encryptedData = encryptionService.encryptData(encodedBoxes);

  

  // Save the file locally first
  File file = await saveFileLocally(backupFileName, encryptedData);

  String apiUrl = '${localhost}/data'; // Replace with your server URL      // Replace with your API key
  String textData = sha256.convert(password).toString();

  await sendStringAndFile(apiUrl, apiKey, textData, file);
}

// Function to apply backup
Future<void> applyBackup(BuildContext context, String password) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);

  String encryptedData;

  try{
    encryptedData = await fetchFileInMemory(sha256.convert(utf8.encode(password!)).toString());
  } catch(e) { // if we catch here we did not get a 200
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Backup not found! Wrong Password?")));
    return;
  }

  // Decrypt the data using the password
  final encryptionService = EncryptionService();
  String encodedBoxes = await encryptionService.decryptData(password!, encryptedData);

  Map<String, Box<dynamic>> boxes = wallet.wallet.getBoxes().cast<String, Box<dynamic>>();

  // Decode and restore boxes
  await decodeAndSetBoxes(encodedBoxes, boxes);

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
Future<void> decodeAndSetBoxes(String encodedData, Map<String, Box<dynamic>> boxes) async {
  Map<String, dynamic> decodedData = jsonDecode(encodedData);

  for (var entry in decodedData.entries) {
    var box = boxes[entry.key];
    if (box != null) {
      entry.value.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          if (entry.key == 'credentialBox') {
            box.put(k, Credential.fromJson(v));
          } else if (entry.key == 'connectionBox') {
            box.put(k, Connection.fromJson(v));
          } else if (entry.key == 'didcommConversationsBox') {
            box.put(k, DidcommConversation.fromJson(v));
          } else if (entry.key == 'issuingHistoryBox') {
            box.put(k, Credential.fromJson(v));
          }
        } else {
          box.put(k, v); // For basic types (int, String, etc.)
        }
      });
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