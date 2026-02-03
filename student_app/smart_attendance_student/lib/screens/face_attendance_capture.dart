import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class FaceAttendanceCapture extends StatefulWidget {
  const FaceAttendanceCapture({super.key});

  @override
  State<FaceAttendanceCapture> createState() => _FaceAttendanceCaptureState();
}

class _FaceAttendanceCaptureState extends State<FaceAttendanceCapture> {
  late CameraController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    // FRONT camera
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();

    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capture Face")),
      body: _initialized
          ? CameraPreview(_controller)
          : const Center(child: CircularProgressIndicator()),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera),
        onPressed: () async {
          final image = await _controller.takePicture();

          // For now just return the image path
          Navigator.pop(context, image.path);
        },
      ),
    );
  }
}
