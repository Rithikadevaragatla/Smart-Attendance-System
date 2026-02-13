import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_attendance.dart';
import '../services/ble_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _activeSessionId;
  bool _isLoading = false;

  // 🔵 Start attendance session + BLE broadcast
  Future<void> _startSession() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1️⃣ Create session in Firestore
      final sessionRef =
          await FirebaseFirestore.instance.collection('sessions').add({
        'teacherId': user.uid,
        'startTime': Timestamp.now(),
        'isActive': true,
      });

      // 2️⃣ Start BLE advertising
      await BleService.startAdvertising(sessionRef.id);

      setState(() {
        _activeSessionId = sessionRef.id;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start session")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔴 End attendance session + STOP BLE
  Future<void> _endSession() async {
    if (_activeSessionId == null) return;

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_activeSessionId)
        .update({'isActive': false});

    await BleService.stopAdvertising();

    setState(() {
      _activeSessionId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 👋 Welcome
            Text(
              "Welcome, ${FirebaseAuth.instance.currentUser?.email}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 📦 Session Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _activeSessionId == null
                          ? "No Active Session"
                          : "Session Active",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _activeSessionId == null
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ),

                    if (_activeSessionId != null) ...[
                      const SizedBox(height: 10),

                      SelectableText(
                        "Session ID:\n$_activeSessionId",
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy Session ID"),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _activeSessionId!),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Session ID copied"),
                            ),
                          );
                        },
                      ),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ▶️ Start / ⛔ End Session Buttons
            if (_activeSessionId == null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Attendance Session"),
                onPressed: _isLoading ? null : _startSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text("End Session"),
                onPressed: _endSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                icon: const Icon(Icons.list),
                label: const Text("View Attendance"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewAttendancePage(
                        sessionId: _activeSessionId!,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
