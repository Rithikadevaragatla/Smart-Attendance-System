import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../services/permission_service.dart';


class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String studentName = "";
  String rollNo = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  print("LOGGED IN UID: $uid");

  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .get();

  print("DOCUMENT EXISTS: ${doc.exists}");
  print("DATA: ${doc.data()}");

  if (!doc.exists) {
    setState(() {
      loading = false;
    });
    return;
  }

  setState(() {
    studentName = doc['name'];
    rollNo = doc['rollNo'];
    loading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Dashboard"),
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Smart Attendance",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
              await FirebaseAuth.instance.signOut();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            ),
          ],
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔹 Student Info (DYNAMIC)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, $studentName",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Roll No: $rollNo"),
                        ],
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        try{
                          final hasPermission =
                              await PermissionService.requestBlePermissions();

                          if (!hasPermission) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Location permission required")),
                            );
                            return;
                          }

                          final bleService = BleService();
                          final sessionService = SessionService();

                          final sessionId = await bleService.scanForSessionId();

                          if (sessionId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No active class nearby")),
                            );
                            return;
                          }

                          final isActive =
                              await sessionService.isSessionActive(sessionId);

                          if (!isActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Session is no longer active")),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Session detected: $sessionId")),
                          );
                        }
                        catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      child: const Text("MARK ATTENDANCE"),
                    ),
                  ],
                ),

                const SizedBox(height: 25),


                  // 🔹 Today's Timetable
                  const Text(
                    "Today's Classes",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  _timetableCard("09:00 - 10:00", "DBMS"),
                  _timetableCard("10:00 - 11:00", "AI"),
                  _timetableCard("02:00 - 03:00", "CN"),

                  const SizedBox(height: 30),

                  // 🔹 Subject-wise Attendance
                  const Text(
                    "Attendance Overview",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  _attendanceCard("DBMS", 85),
                  _attendanceCard("AI", 92),
                  _attendanceCard("CN", 78),
                ],
              ),
            ),
    );
  }

  // ---------- Widgets ----------

  static Widget _timetableCard(String time, String subject) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(subject),
        subtitle: Text(time),
      ),
    );
  }

  static Widget _attendanceCard(String subject, int percent) {
    return Card(
      child: ListTile(
        title: Text(subject),
        subtitle: LinearProgressIndicator(
          value: percent / 100,
          minHeight: 8,
        ),
        trailing: Text("$percent%"),
      ),
    );
  }
}
