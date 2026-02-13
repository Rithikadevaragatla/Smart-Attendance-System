import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import 'face_capture_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Mark Attendance"),
          onPressed: () async {

            final bleService = BleService();
            final sessionService = SessionService();

            // 1️⃣ Scan BLE
            final sessionId = await bleService.scanForSessionId();

            if (sessionId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No active class nearby")),
              );
              return;
            }

            // 2️⃣ Validate session in Firestore
            final isActive =
                await sessionService.isSessionActive(sessionId);

            if (!isActive) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Session is no longer active")),
              );
              return;
            }

            // ✅ BLE + Firestore passed
            print("Valid session detected: $sessionId");

            // NEXT STEP (later)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FaceCaptureScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
