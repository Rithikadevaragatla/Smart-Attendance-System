import 'package:cloud_firestore/cloud_firestore.dart';

class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> isSessionActive(String sessionId) async {
    final doc =
        await _db.collection('sessions').doc(sessionId).get();

    if (!doc.exists) return false;

    return doc.data()?['isActive'] == true;
  }
}
