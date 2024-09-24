import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String localhost = "http://10.0.2.2";
const String apiKey = 'supersecretapikey123';

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