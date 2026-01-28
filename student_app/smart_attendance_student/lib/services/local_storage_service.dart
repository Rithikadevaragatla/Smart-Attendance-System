import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {

  /// Save captured face images locally
  Future<List<String>> saveFaceImages(List<File> images) async {
    final Directory appDir = await getApplicationDocumentsDirectory();

    List<String> savedPaths = [];

    for (int i = 0; i < images.length; i++) {
      final String newPath =
          path.join(appDir.path, 'face_$i.jpg');

      final File savedImage = await images[i].copy(newPath);
      savedPaths.add(savedImage.path);
    }

    return savedPaths; // local file paths
  }
}
