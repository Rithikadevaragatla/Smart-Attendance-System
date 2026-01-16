import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveStudentData({
    required String uid,
    required String name,
    required String rollNo,
    required String email,
    required List<String> faceUrls,
  }) async {
    await _db.collection('students').doc(uid).set({
      'name': name,
      'rollNo': rollNo,
      'email': email,
      'faceImages': faceUrls,
      'createdAt': Timestamp.now(),
    });
  }
}
