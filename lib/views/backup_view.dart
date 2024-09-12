import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/provider/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:dart_ssi/src/wallet/hive_model.dart';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const String localhost = "http://10.0.2.2";
const String apiKey = 'supersecretapikey123'; 
const String backupFileName = 'hidy_backup.enc';
const String symbolsForPasswordGeneration = 'ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()-_=+[]{};:,.<>?';

class BackupWidget extends StatefulWidget {
  @override
  _BackupWidgetState createState() => _BackupWidgetState();
}

class _BackupWidgetState extends State<BackupWidget> {

  late Uint8List _generatePassword;

  @override
  void initState() {
    super.initState();
    _generatePassword = EncryptionService()._generatePassword(16); // Initialize in initState
  }

  void _onBackupPressed() {
    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    // Proceed with backup using the password
    performBackup(context, _generatePassword);
    
    _showMessage("Your backup will be uploaded...");
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please write down this password in order to retrieve your backup later! Without this password restoring will not be available!',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Text(
              utf8.decode(_generatePassword),
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _onBackupPressed,
                child: const Text('Backup'),
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
Future<void> applyBackup(BuildContext context) async {
  var wallet = Provider.of<WalletProvider>(context, listen: false);
  
  var password = await _askForPassword(context);

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

// #############  password encryption  #####################

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  encrypt.Key? _key;

  EncryptionService._internal();

  factory EncryptionService() {
    return _instance;
  }

  Future<void> init(Uint8List password) async {
    _key = encrypt.Key(password); //encrypt.Key(await _deriveKeyFromPassword(password, _salt!, 10000, 32));
  }

  String encryptData(String plainText) {
    if (_key == null) {
      throw Exception('Encryption key is not initialized.');
    }

    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final ivBase64 = iv.base64;
    final encryptedBase64 = encrypted.base64;

    return '$ivBase64:$encryptedBase64'; // Prepend salt, IV, and encrypted text
  }

  Future<String> decryptData(String password, String encryptedData) async {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format.');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    // Derive the key using the extracted salt
    final key = encrypt.Key(Uint8List.fromList(utf8.encode(password)));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  Uint8List _generatePassword(int length) {
  final rand = Random.secure();
  var password = List.generate(length, (index) => symbolsForPasswordGeneration[rand.nextInt(symbolsForPasswordGeneration.length)]).join();
  return Uint8List.fromList(utf8.encode(password));
}
}

Future<void> sendStringAndFile(String apiUrl, String apiKey, String textData, File file) async {
  try {
    // Create the Multipart request
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Add API key in headers
    request.headers['x-api-key'] = apiKey;

    // Add text data as a field
    request.fields['text'] = textData;

    // Add the file as a MultipartFile
    var fileStream = http.ByteStream(file.openRead());
    var length = await file.length();
    var filename = file.path.split('/').last;

    var multipartFile = http.MultipartFile(
      'file',  // This is the key the Node.js server expects for the file
      fileStream,
      length,
      filename: filename,
    );

    request.files.add(multipartFile);

    // Send the request
    var response = await request.send();

    // Handle the response
    if (response.statusCode == 200) {
      print('File and data uploaded successfully');
      var responseData = await http.Response.fromStream(response);
      print('Response: ${responseData.body}');
    } else {
      print('Failed to upload. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error uploading file: $e');
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

Future<String> fetchFileInMemory(String fileId) async {
  String apiUrl = '${localhost}/data/$fileId';  // Replace with your server URL


    // Send GET request to fetch the file
    var response = await http.get(Uri.parse(apiUrl));
  try {
    // Check if the request was successful
    if (response.statusCode == 200) {
      // File is fetched, you can read the content here
      return utf8.decode(response.bodyBytes);
    } else {
      throw('Failed to fetch file. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw('Error fetching file: $e');
  }
}