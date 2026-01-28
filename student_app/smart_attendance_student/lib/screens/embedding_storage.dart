import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class EmbeddingStorage {

  Future<void> saveEmbeddings(List<List<double>> embeddings) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/face_embeddings.json');

    final jsonData = jsonEncode({
      'embeddings': embeddings,
    });

    await file.writeAsString(jsonData);
  }

  Future<List<List<double>>> loadEmbeddings() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/face_embeddings.json');

    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    return (decoded['embeddings'] as List)
        .map<List<double>>(
            (e) => List<double>.from(e))
        .toList();
  }
}
