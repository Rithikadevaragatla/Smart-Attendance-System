import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewAttendancePage extends StatelessWidget {
  final String sessionId;

  const ViewAttendancePage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Records"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .collection('attendance')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ Error
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Unable to load attendance records.",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // 📭 Empty
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No attendance records yet",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Waiting for students to mark attendance",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ✅ Attendance List
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
                  docs[index].data() as Map<String, dynamic>;

              final Timestamp? ts = data['timestamp'];
              final timeString = ts != null
                  ? ts.toDate().toLocal().toString().substring(11, 19)
                  : "--";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    data['name'] ?? "Unknown",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Roll No: ${data['rollNo'] ?? '--'}",
                  ),
                  trailing: Text(
                    timeString,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
