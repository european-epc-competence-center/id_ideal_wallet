import 'dart:io';

import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hive/hive.dart';
import 'package:dart_ssi/src/wallet/hive_model.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';
import 'package:cryptography/cryptography.dart';

class BackupWidget extends StatefulWidget {
  @override
  _BackupWidgetState createState() => _BackupWidgetState();
}

class _BackupWidgetState extends State<BackupWidget> {
  final _passwordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  void _onBackupPressed() {
    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    final password = _passwordController.text;
    final repeatPassword = _repeatPasswordController.text;

    if (password.isEmpty || repeatPassword.isEmpty) {
      _showMessage('Please fill in both password fields.');
      return;
    }

    if (password != repeatPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    // Proceed with backup using the password
    performBackup(context, password);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please enter your password to secure the backup.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _repeatPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Repeat Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _onBackupPressed,
                child: Text('Backup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showConfirmationDialog(BuildContext context, void Function(BuildContext) onConfirmed) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing by tapping outside
    builder: (BuildContext context2) {
      return AlertDialog(
        title: Text('Backup'),
        content: Text('Sind Sie sicher das Sie ein Backup einlesen wollen?'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context2).pop();
            },
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () {
              Navigator.of(context2).pop();
              onConfirmed(context);
            },
          ),
        ],
      );
    },
  );
}

  Future<String?> _askForPassword(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Return null if canceled
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(passwordController.text); // Return the password
              },
            ),
          ],
        );
      },
    );
  }

// Function to perform backup
Future<void> performBackup(BuildContext context, String password) async {
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

  // Send boxes somewhere, e.g., save to file, upload to cloud storage, etc.
  Share.shareXFiles([XFile.fromData(utf8.encode(encryptedData), mimeType: 'text/plain')], fileNameOverrides: ['hidy_backup.enc']);
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
  
  var encryptedData = await file!.readAsString();
  
  var password = await _askForPassword(context);

  // Decrypt the data using the password
  final encryptionService = EncryptionService();
  encodedBoxes = await encryptionService.decryptData(password!, encryptedData);

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

// #############  password encryption  #####################

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  encrypt.Key? _key;
  Uint8List? _salt;

  EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  Future<void> init(String password) async {
    _salt = _generateSalt(16); // Generate a random 16-byte salt
    _key = encrypt.Key(await _deriveKeyFromPassword(password, _salt!, 10000, 32));
  }

  String encryptData(String plainText) {
    if (_key == null || _salt == null) {
      throw Exception('Encryption key is not initialized.');
    }

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final saltBase64 = base64UrlEncode(_salt!);
    final ivBase64 = iv.base64;
    final encryptedBase64 = encrypted.base64;

    return '$saltBase64:$ivBase64:$encryptedBase64'; // Prepend salt, IV, and encrypted text
  }

  Future<String> decryptData(String password, String encryptedData) async {
    final parts = encryptedData.split(':');
    if (parts.length != 3) {
      throw Exception('Invalid encrypted data format.');
    }

    final salt = base64Url.decode(parts[0]);
    final iv = encrypt.IV.fromBase64(parts[1]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[2]);

    // Derive the key using the extracted salt
    final key = encrypt.Key(await _deriveKeyFromPassword(password, salt, 10000, 32));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  Uint8List _generateSalt(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  Future<Uint8List> _deriveKeyFromPassword(String password, Uint8List salt, int iterations, int length) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: length * 8,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    return Uint8List.fromList(await secretKey.extractBytes());
  }
}