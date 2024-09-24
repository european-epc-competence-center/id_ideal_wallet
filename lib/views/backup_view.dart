import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:id_ideal_wallet/provider/encryption_provider.dart';
import 'package:id_ideal_wallet/functions/backup_functions.dart';


class BackupWidget extends StatefulWidget {
  @override
  _BackupWidgetState createState() => _BackupWidgetState();
}

class _BackupWidgetState extends State<BackupWidget> {

  late Uint8List _generatePassword;

  @override
  void initState() {
    super.initState();
    _generatePassword = EncryptionService().generatePassword(16); // Initialize in initState
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

void showConfirmationDialog(BuildContext context, void Function(BuildContext, String) onConfirmed) {
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
              askForPassword(context).then((pwd)=>{onConfirmed(context, pwd!)});
            },
          ),
        ],
      );
    },
  );
}

Future<String?> askForPassword(BuildContext context) async {
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
