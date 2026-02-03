import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceFeatureService {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: false,
    ),
  );

  /// Extracts simple facial feature vector using landmarks
  Future<List<double>?> extractFeatures(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final faces = await _detector.processImage(inputImage);

    if (faces.isEmpty) return null;

    final face = faces.first;
    final boundingBox = face.boundingBox;

    final features = <double>[];

    void addPoint(FaceLandmarkType type) {
  final landmark = face.landmarks[type];
  if (landmark != null) {
    final normalizedX =
        (landmark.position.x - boundingBox.left) / boundingBox.width;
    final normalizedY =
        (landmark.position.y - boundingBox.top) / boundingBox.height;

    features.add(normalizedX);
    features.add(normalizedY);
  }
}


    addPoint(FaceLandmarkType.leftEye);
    addPoint(FaceLandmarkType.rightEye);
    addPoint(FaceLandmarkType.noseBase);
    addPoint(FaceLandmarkType.leftMouth);
    addPoint(FaceLandmarkType.rightMouth);

    if (features.isEmpty) return null;
    return features;
  }

  /// Euclidean distance between two face vectors
  static double compare(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  void dispose() {
    _detector.close();
  }
}
