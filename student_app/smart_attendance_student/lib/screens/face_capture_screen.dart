import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  int step = 0; // 0-front, 1-left, 2-right
  List<String> capturedImages = [];

  final instructions = [
    'Capture FRONT face',
    'Capture LEFT side face',
    'Capture RIGHT side face'
  ];

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();

  // Select FRONT camera
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );

  _controller = CameraController(
    frontCamera,
    ResolutionPreset.medium,
    enableAudio: false,
  );

  _initializeControllerFuture = _controller.initialize();
  setState(() {});
  }

  Future<void> _takePicture() async {
    await _initializeControllerFuture;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
    '${directory.path}/face_${step}_${DateTime.now().millisecondsSinceEpoch}.jpg';


    final image = await _controller.takePicture();
    final savedImage = await File(image.path).copy(imagePath);

    capturedImages.add(savedImage.path);

    if (step < 2) {
      setState(() => step++);
    } else {
      Navigator.pop(context, capturedImages);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Enrollment')),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(child: CameraPreview(_controller)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    instructions[step],
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _takePicture,
                  child: Text('Capture'),
                ),
                SizedBox(height: 10),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
