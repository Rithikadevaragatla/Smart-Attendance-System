import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<String>> uploadFaceImages(List<File> images) async {
    final uid = _auth.currentUser!.uid;
    List<String> downloadUrls = [];

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
