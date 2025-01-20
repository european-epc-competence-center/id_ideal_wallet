import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:id_ideal_wallet/functions/backup_functions.dart';
import 'package:id_ideal_wallet/provider/encryption_provider.dart';

class BackupWidget extends StatefulWidget {
  @override
  _BackupWidgetState createState() => _BackupWidgetState();
}

class _BackupWidgetState extends State<BackupWidget> {
  late String _generateMemonic;

  @override
  void initState() {
    super.initState();
    _generateMemonic =
        EncryptionService().createMemonic(); // Initialize in initState
  }

  void _onBackupPressed() {
    // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    // Proceed with backup using the password
    performBackup(context, _generateMemonic);

    _showMessage(AppLocalizations.of(context)!.backupUpload);
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.backup)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.backupWriteDownPassword,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Text(
              _generateMemonic,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: ElevatedButton(
                onPressed: _onBackupPressed,
                child: Text(AppLocalizations.of(context)!.backup),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showConfirmationDialog(
    BuildContext context, void Function(BuildContext, String) onConfirmed) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevents dismissing by tapping outside
    builder: (BuildContext context2) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.backup),
        content: Text(AppLocalizations.of(context)!.restoreQuestion),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.no),
            onPressed: () {
              Navigator.of(context2).pop();
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.yes),
            onPressed: () {
              Navigator.of(context2).pop();
              askForMnemonic(context)
                  .then((mnemonic) => {onConfirmed(context, mnemonic!)});
            },
          ),
        ],
      );
    },
  );
}

Future<String?> askForMnemonic(BuildContext context) async {
  List<TextEditingController> controllers =
      List.generate(12, (_) => TextEditingController());

  return showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreMnemonic),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              12,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: TextField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    labelText: 'Word ${index + 1}',
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () {
              Navigator.of(context).pop(null); // Return null if canceled
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.ok),
            onPressed: () {
              // Combine all entered words into a single space-separated string
              String mnemonic = controllers
                  .map((controller) => controller.text.trim())
                  .join(' ');
              Navigator.of(context).pop(mnemonic); // Return the mnemonic string
            },
          ),
        ],
      );
    },
  );
}
