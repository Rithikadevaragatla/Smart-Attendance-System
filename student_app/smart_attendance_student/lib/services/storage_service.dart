import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Future<List<String>> uploadFaceImages(List<File> images) async {
    List<String> downloadUrls = [];
    final uid = _auth.currentUser!.uid;

    for (int i = 0; i < images.length; i++) {
      final ref = _storage
          .ref()
          .child('students/$uid/face_$i.jpg');

      await ref.putFile(images[i]);
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }
}
