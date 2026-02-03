import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableLandmarks: false,
    ),
  );

  Future<bool> hasFace(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final faces = await _detector.processImage(inputImage);

    return faces.isNotEmpty;
  }

  void dispose() {
    _detector.close();
  }
}
