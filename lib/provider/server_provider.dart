import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String localhost = "ec2-18-199-147-148.eu-central-1.compute.amazonaws.com";//"http://10.0.2.2";
const String apiKey = 'supersecretapikey123';

// ######### Backup functions #############

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

// ########### Keyshare functions ##############

Future<String?> postKeyshareSend(String fromUserId, String targetUserId, String keyshare) async {
  var url = Uri.parse("http://${localhost}:3000/key-share/send");
  // fromUserId, toUserId, keyShare

  try {
    // Prepare the request body
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'fromUserId': fromUserId, // TODO: Fetch userID from somewhere, maybe hash the pub key or something
        'toUserId': targetUserId, // The user ID from the input field
        'keyShare': keyshare,     // Replace with the actual key share
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      String requestId = responseData['keyShareId'];
      return requestId;
    } else {
      print('Failed to send key share request: ${response.body}');
      return null;
    }
  } catch (error) {
    print('Error sending key share request: $error');
    return null;
  }
}

Future<bool> postKeyshareAccept(AcceptRejectType request) async {
  var url = Uri.parse("http://${localhost}:3000/key-share/accept");

  try {
    // Prepare the request body
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(request),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to send key share request: ${response.body}');
      return false;
    }
  } catch (error) {
    print('Error sending key share request: $error');
    return false;
  }
}

Future<bool> postKeyShareReject(AcceptRejectType request) async {
  var url = Uri.parse("http://${localhost}:3000/key-share/reject");

  try {
    // Prepare the request body
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(request),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to send key share request: ${response.body}');
      return false;
    }
  } catch (error) {
    print('Error sending key share request: $error');
    return false;
  }
}

// TODO: fix to correct datatype
Future<String> getKeyShareRequest(String toUserId) async {
  var url = Uri.parse("http://${localhost}:3000/key-share/received/$toUserId");

  // Send GET request to fetch the file
  var response = await http.get(url);

  try {
    // Check if the request was successful
    if (response.statusCode == 200) {
      // maybe return proper type
      return response.body;
    } else {
      throw('Failed to fetch key-share requests. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw('Error fetching key-share: $e');
  }
}
/**
 * _id        66faaf10089e5fc3db824e1e
 * fromUserId 1234
 * toUserId   1234
 * keyShare   5678
 * status     pending
 * createAt   2024-09-30T14:00:48.680Z
 * updateAt   2024-09-30T14:00:48.682Z
 */

class AcceptRejectType {
  String requestId;
  String toUserId;
  String fromUserId;
  String keyShare;
  String status;
  String createdAt;
  String updatedAt;

  // Constructor
  AcceptRejectType({required this.requestId, required this.toUserId, required this.fromUserId, required this.keyShare, required this.status, required this.createdAt, required this.updatedAt});

  // Method to convert the object to JSON (encoding)
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'toUserId': toUserId,
    };
  }

  // Method to create an object from JSON (decoding)
  factory AcceptRejectType.fromJson(Map<String, dynamic> json) {
    AcceptRejectType act = AcceptRejectType(
      requestId: json['_id'],
      toUserId: json['toUserId'],
      fromUserId: json['fromUserId'],
      keyShare: json['keyShare'],
      status: json['status'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
    return act;
  }
}