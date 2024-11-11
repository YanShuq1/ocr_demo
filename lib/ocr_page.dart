import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrPage extends StatefulWidget {
  @override
  _OcrPageState createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  List<String> _recognizedTextLines = [];

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

    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    setState(() {
      _recognizedTextLines = recognizedText.text.split('\n');
    });
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
      appBar: AppBar(title: Text("文字识别")),
      body: Column(
        children: [
          if (_isCameraInitialized)
            AspectRatio(
              aspectRatio: _cameraController.value.aspectRatio,
              child: CameraPreview(_cameraController),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _captureAndRecognizeText,
            child: Text("拍照并识别文字"),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _recognizedTextLines.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                  child: Text(
                    _recognizedTextLines[index],
                    style: TextStyle(fontSize: 16),
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
