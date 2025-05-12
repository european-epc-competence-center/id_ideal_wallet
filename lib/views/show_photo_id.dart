import 'dart:convert';

import 'package:flutter/material.dart';

class ShowPhotoId extends StatelessWidget {
  final String front, back;

  const ShowPhotoId({super.key, required this.front, required this.back});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Text('Vorderseite'),
          SizedBox(
            height: 5,
          ),
          Image.memory(base64Decode(front.split(',').last)),
          SizedBox(
            height: 20,
          ),
          Text('Rückseite'),
          SizedBox(
            height: 5,
          ),
          Image.memory(base64Decode(back.split(',').last)),
        ],
      ),
    );
  }
}
