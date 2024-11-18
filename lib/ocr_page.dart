import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  _OcrPageState createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  List<String> _recognizedTextLines = [];
  bool _isOcr = false;
  Timer? _timer; //Timer类
  final halfSecond = const Duration(milliseconds: 500);

  final textRecognizer = TextRecognizer();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _captureAndRecognizeText() async {
    if (!_isCameraInitialized) return;

    final image = await _cameraController.takePicture();
    final inputImage = InputImage.fromFilePath(image.path);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    setState(() {
      _recognizedTextLines = recognizedText.text.split('\n');
    });
  }

  void _toggleRecognition() {
    if (_isOcr) {
      // 停止定时识别
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(halfSecond, (timer) {
        _captureAndRecognizeText();
      });
    }

    setState(() {
      _isOcr = !_isOcr;
    });
  }

  void _shotRecognition() {
    if (_isOcr) {
      // 停止定时识别
      _timer?.cancel();
      _captureAndRecognizeText();
      setState(() {
        _isOcr = !_isOcr;
      });
    } else {
      _captureAndRecognizeText();
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("文字识别")),
      body: Column(
        children: [
          if (_isCameraInitialized)
            AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _toggleRecognition,
            child: Text(_isOcr ? "停止" : "开始文字识别"),
          ),
          ElevatedButton(
            onPressed: _shotRecognition,
            child: Text(_isOcr ? "停止并拍照识别" : "拍照识别"),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _recognizedTextLines.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 8.0),
                  child: Text(
                    _recognizedTextLines[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
