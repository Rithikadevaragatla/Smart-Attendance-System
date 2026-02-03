import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceNetService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'models/mobilefacenet.tflite',
    );
  }

  List<double> getEmbedding(img.Image faceImage) {
    final input = _imageToByteList(faceImage, 112);
    final output = List.filled(128, 0.0).reshape([1, 128]);

    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  Uint8List _imageToByteList(img.Image image, int size) {
    final resized = img.copyResize(image, width: size, height: size);
    final bytes = Float32List(1 * size * size * 3);
    int index = 0;

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final pixel = resized.getPixel(x, y);
        bytes[index++] = (img.getRed(pixel) - 128) / 128;
        bytes[index++] = (img.getGreen(pixel) - 128) / 128;
        bytes[index++] = (img.getBlue(pixel) - 128) / 128;
      }
    }
    return bytes.buffer.asUint8List();
  }

  void dispose() {
    _interpreter.close();
  }
}
