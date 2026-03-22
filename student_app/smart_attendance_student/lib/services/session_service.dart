import 'package:cloud_firestore/cloud_firestore.dart';

class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isSessionActive(String sessionId) async {
    
    final doc =
        await _db.collection('sessions').doc(sessionId).get();

    if (!doc.exists) return false;

    return doc.data()?['isActive'] == true;
  }
  Future<bool> validateSession({
    required String sessionId,
    required String studentClass,
    required String studentSection,
  }) async {
    final doc =
        await _db.collection('sessions').doc(sessionId).get();

    if (!doc.exists) return false;

    final data = doc.data();

    return data?['isActive'] == true &&
           data?['class'] == studentClass &&
           data?['section'] == studentSection;
  }
}
