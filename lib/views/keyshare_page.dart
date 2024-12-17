import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/provider/encryption_provider.dart';
import 'package:id_ideal_wallet/provider/server_provider.dart';
import 'dart:convert';
import 'dart:math';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class KeyShareWidget extends StatefulWidget {
  @override
  _KeyShareWidgetState createState() => _KeyShareWidgetState();
}

class _KeyShareWidgetState extends State<KeyShareWidget> {
  final TextEditingController _userIdController = TextEditingController();
  List<String> _sentRequests = []; // List of userIds to whom key requests were sent
  List<String> _receivedRequests = []; // List of userIds who sent key requests
  List<String> _acceptedRequests = []; // List of Requests whe Accepted
  
  String secret = "";
  List<String> keyShares = [];

  String userId = "";

  @override
  void initState() {
    super.initState();
    // generate secret
    secret = List.generate(32, (index) => Random().nextInt(256)).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    // generate keyshares
    keyShares = EncryptionService().getKeyShare(secret, 1, 2);

    userId = secret.substring(0,5);
    OneSignal.login(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Key Sharing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TextField for entering user ID
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            Text(userId),
            SizedBox(height: 10),
            
            // Button for sending a key share request
            ElevatedButton(
              onPressed: () {
                if (_userIdController.text.isNotEmpty) {
                  setState(() {
                    _sentRequests.add(_userIdController.text);
                    // TODO: fetch keyshare

                    // call the POST API to send the request
                    postKeyshareSend(userId, _userIdController.text, keyShares[1]);
                    _userIdController.clear(); // Clear input field after sending
                  });
                }
              },
              child: Text('Send Key Share Request'),
            ),
            ElevatedButton(
              onPressed: () async {
                var requests = await getKeyShareRequest(userId);
                setState((){
                  _receivedRequests.add(requests);
                });
              },
              child: Text("Get Key Share Requests"),
            ),

            SizedBox(height: 20),

            // List of sent requests
            Text('Sent Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _sentRequests.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_sentRequests[index]),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // List of received requests with Accept/Reject buttons
            Text('Open Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedRequests.length,
                itemBuilder: (context, index) {
                  String request = _receivedRequests[index];
                  return ListTile(
                    title: Text(request),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            // Accept the request
                            setState(() {
                              // TODO: remove the icons
                              if(request != "[]"){
                              List<dynamic> jsonList = jsonDecode(request);
                              AcceptRejectType req = AcceptRejectType.fromJson(jsonList[0]);
                              postKeyshareAccept(req);
                              _acceptedRequests.add(request);
                              _receivedRequests.removeAt(index);
                              }
                              // TODO: store keyshare securly
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            // Reject the request
                            setState(() {
                              _receivedRequests.removeAt(index);
                              // TODO: remove the icons
                              List<dynamic> jsonList = jsonDecode(request);
                              if(jsonList.isNotEmpty){
                                AcceptRejectType req = AcceptRejectType.fromJson(jsonList[0]);
                                postKeyShareReject(req);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // List of Accepted requests
            Text('Accepted Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _acceptedRequests.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_acceptedRequests[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
