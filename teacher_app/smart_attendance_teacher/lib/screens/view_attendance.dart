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
            .collection('attendance')
            .where('sessionId', isEqualTo: sessionId)
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading attendance"),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Empty state (IMPORTANT)
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No attendance records yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Attendance list
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text("Student ID: ${data['studentId']}"),
                subtitle: Text(
                  "Status: ${data['status']}\n"
                  "Time: ${data['timestamp'].toDate()}",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
