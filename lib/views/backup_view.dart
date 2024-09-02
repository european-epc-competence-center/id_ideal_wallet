import 'dart:io';

import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hive/hive.dart';
import 'package:dart_ssi/src/wallet/hive_model.dart';

void showConfirmationDialog(BuildContext context, void Function(BuildContext) onConfirmed) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you want to perform this action?'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirmed(context);
            },
          ),
        ],
      );
    },
  );
}

// Function to perform backup
Future<void> performBackup(BuildContext context) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);
  var boxes = wallet.wallet.getBoxes();

  // Filter out null boxes
  Map<String, Box<dynamic>> nonNullableBoxes = Map.fromEntries(
    boxes.entries
        .where((entry) => entry.value != null)
        .map((entry) => MapEntry(entry.key, entry.value!)),
  );

  var encodedBoxes = encodeBoxes(nonNullableBoxes);
  // Send boxes somewhere, e.g., save to file, upload to cloud storage, etc.
  Share.shareXFiles([XFile.fromData(utf8.encode(encodedBoxes), mimeType: 'text/plain')], fileNameOverrides: ['hidy_backup.json']);
}

// Function to apply backup
Future<void> applyBackup(BuildContext context) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);
  String encodedBoxes = ""; // Retrieve this string from wherever you stored it

  final XFile? file = await openFile(acceptedTypeGroups: [
                const XTypeGroup(
                  label: 'all files',
                  extensions: [], // Empty list of extensions to allow all files
                ),
              ]);
  if (file == null) {
    // Operation was canceled by the user.
    return;
  }
  encodedBoxes = await file!.readAsString();

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

