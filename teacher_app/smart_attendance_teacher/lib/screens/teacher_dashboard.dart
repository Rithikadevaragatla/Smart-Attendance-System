import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_attendance.dart';
import '../services/ble_service.dart'; // 🔵 ADD THIS

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
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1️⃣ Create session in Firestore
      DocumentReference sessionRef =
          await FirebaseFirestore.instance.collection('sessions').add({
        'teacherId': user.uid,
        'startTime': Timestamp.now(),
        'isActive': true,
      });

      // 2️⃣ START BLE advertising with sessionId
      await BleService.startAdvertising(sessionRef.id);

      setState(() {
        _activeSessionId = sessionRef.id;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start session: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔴 End attendance session + STOP BLE
  Future<void> _endSession() async {
    if (_activeSessionId == null) return;

    // 1️⃣ Update Firestore
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(_activeSessionId)
        .update({'isActive': false});

    // 2️⃣ STOP BLE advertising
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 No active session
              if (_activeSessionId == null) ...[
                ElevatedButton(
                  onPressed: _isLoading ? null : _startSession,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Start Attendance Session"),
                ),
              ]

              // 🔹 Active session
              else ...[
                const Text(
                  "Session Active",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                SelectableText(
                  "Session ID:\n$_activeSessionId",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _endSession,
                  child: const Text("End Session"),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAttendancePage(
                          sessionId: _activeSessionId!,
                        ),
                      ),
                    );
                  },
                  child: const Text("View Attendance"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
