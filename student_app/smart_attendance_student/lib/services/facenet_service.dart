import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceNetService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    if (_interpreter != null) return;

    // 1️⃣ Get app directory
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/mobilefacenet.tflite';

    // 2️⃣ Copy model from assets if not exists
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      final byteData =
          await rootBundle.load('assets/models/mobilefacenet.tflite');
      await modelFile.writeAsBytes(byteData.buffer.asUint8List());
    }

    // 3️⃣ Load model from FILE (not asset)
    _interpreter = await Interpreter.fromFile(modelFile);
  }

  List<double> getEmbedding(img.Image faceImage) {
    if (_interpreter == null) {
      throw Exception('FaceNet model not loaded');
    }

    final input = _imageToFloat32(faceImage);
    final output = List.filled(128, 0.0).reshape([1, 128]);

    _interpreter!.run(input, output);

    return List<double>.from(output[0]);
  }

  List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    final resized = img.copyResize(image, width: 112, height: 112);

    return [
      List.generate(112, (y) {
        return List.generate(112, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r - 128) / 128,
            (pixel.g - 128) / 128,
            (pixel.b - 128) / 128,
          ];
        });
      })
    ];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
