import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:id_ideal_wallet/constants/server_address.dart';
import 'package:image/image.dart' as img;

class AndroidCameraWidget extends StatefulWidget {
  const AndroidCameraWidget({super.key});

  @override
  State<AndroidCameraWidget> createState() => _AndroidCameraWidgetState();
}

class _AndroidCameraWidgetState extends State<AndroidCameraWidget> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isRearCameraSelected = true;
  String? _capturedImagePath;
  double overlayWidth = 0, overlayHeight = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      logger.d('Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    final newCamera = _isRearCameraSelected ? _cameras[1] : _cameras[0];
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
    });

    _cameraController = CameraController(newCamera, ResolutionPreset.high);
    await _cameraController!.initialize();
    setState(() {});
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) {
      logger.d('Camera not initialized');
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
      });
      var newPath = await _cropToRectangle(_capturedImagePath!);
      logger.d(newPath);
      Navigator.of(navigatorKey.currentContext!).pop(newPath);
    } catch (e) {
      logger.d('Error capturing image: $e');
    }
  }

  Future<String> _cropToRectangle(String imagePath) async {
    // Load the image as bytes
    final bytes = await File(imagePath).readAsBytes();
    final originalImage = img.decodeImage(Uint8List.fromList(bytes))!;

    // Calculate cropping area in terms of the image's resolution
    final double previewWidth = _cameraController!.value.previewSize!.height;
    final double previewHeight = _cameraController!.value.previewSize!.width;

    var overlayFactor = previewWidth / (overlayWidth / 0.9);
    overlayWidth = overlayWidth * overlayFactor;
    overlayHeight = overlayHeight * overlayFactor;

    logger.d('overlay: $overlayWidth * $overlayHeight');
    logger.d('preview: $previewWidth * $previewHeight');
    logger.d('image: ${originalImage.width} * ${originalImage.height}');

    // Get scaling factors between the preview and the overlay
    final double widthScale = originalImage.width / previewWidth;
    final double heightScale = originalImage.height / previewHeight;

    // Calculate the rectangle's position and size in the image
    final double left = (previewWidth - overlayWidth) / 2 * widthScale;
    final double top = (previewHeight - overlayHeight) / 2 * heightScale;
    final int cropWidth = (overlayWidth * widthScale).toInt();
    final int cropHeight = (overlayHeight * heightScale).toInt();

    // Crop the image
    final croppedImage = img.copyCrop(
      originalImage,
      x: left.toInt(),
      y: top.toInt(),
      width: cropWidth,
      height: cropHeight,
    );

    logger.d('cropped: ${croppedImage.width} * ${croppedImage.height}');

    // Save the cropped image to a new file
    final croppedFile = File(imagePath)
      ..writeAsBytesSync(img.encodeJpg(croppedImage));

    return croppedFile.path;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              Center(
                child: CircularProgressIndicator(),
              ),
            Center(
              child: Container(
                width: overlayWidth = MediaQuery.of(context).size.width * 0.9,
                height: overlayHeight =
                    MediaQuery.of(context).size.width * 0.9 / 1.586,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Top bar with controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  if (_isInitialized)
                    IconButton(
                      onPressed: () async {
                        final currentFlashMode =
                            _cameraController!.value.flashMode;
                        final nextFlashMode =
                            FlashModeHelper.getNextFlashMode(currentFlashMode);

                        await _cameraController!.setFlashMode(nextFlashMode);
                        setState(() {});
                      },
                      icon: Icon(
                          FlashModeHelper.getIcon(
                              _cameraController!.value.flashMode),
                          color: Colors.white),
                    ),
                ],
              ),
            ),
            // Bottom bar with controls
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_capturedImagePath != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Image.file(
                        File(_capturedImagePath!),
                        height: 100,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlashModeHelper {
  static final List<FlashMode> _flashModes = [
    FlashMode.off,
    FlashMode.auto,
    FlashMode.always,
    FlashMode.torch,
  ];

  static IconData getIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  static FlashMode getNextFlashMode(FlashMode currentFlashMode) {
    final currentIndex = _flashModes.indexOf(currentFlashMode);
    final nextIndex = (currentIndex + 1) % _flashModes.length;
    return _flashModes[nextIndex];
  }
}
