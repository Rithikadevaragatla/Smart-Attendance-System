import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'view_attendance.dart';
import '../services/ble_service.dart';
import '../auth/teacher_login.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String? _activeSessionId;
  bool _isLoading = false;

  //String? selectedSubject;
  String facultyName = "Faculty";

  List<String> subjects = [];
  String? selectedSubject;

  String selectedYear = "3";
  String selectedSection = "A";

  List<String> years = ["1", "2", "3", "4"];
  List<String> sections = ["A", "B", "C", "D", "E", "F", "G"];
  String? department;

  Timer? _timer;
  Duration sessionDuration = Duration.zero;
  Timestamp? startTimestamp;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /* LOAD TEACHER DATA */

  Future<void> _loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(user.email)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      final data = doc.data()!;
      subjects = List<String>.from(data['subjects'] ?? []);

      setState(() {
        facultyName = data['name'] ?? "Faculty";
        department = data['department'];

        if (subjects.isNotEmpty) {
          selectedSubject = subjects.first;
        }
      });
    }
  }

  /* SUBJECT DROPDOWN */

  /* TIMER */

  void startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (startTimestamp == null) return;

      final start = startTimestamp!.toDate();
      final now = DateTime.now();

      setState(() {
        sessionDuration = now.difference(start);
      });
    });
  }

  String formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');

    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));

    return "$h:$m:$s";
  }

  /* START SESSION */

  Future<void> _startSession() async {
    if (_isLoading || selectedSubject == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = Timestamp.now();

      final sessionRef = await FirebaseFirestore.instance
          .collection('sessions')
          .add({
            'teacherId': user.uid,
            'teacherEmail': user.email,
            'facultyName': facultyName,
            'subject': selectedSubject,
            'department': department ?? "",
            'year': int.parse(selectedYear),
            'section': selectedSection,
            'date': now,
            'startTime': now,
            'isActive': true,
          });

      String payload =
          "${sessionRef.id}|$selectedSubject|${department ?? ""}|$selectedYear|$selectedSection";
      await BleService.startAdvertising(payload);

      startTimestamp = now;
      startTimer();

      if (!mounted) return;

      setState(() {
        _activeSessionId = sessionRef.id;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to start session")));
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /* END SESSION */

  Future<void> _endSession() async {
    if (_activeSessionId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(_activeSessionId)
          .update({'isActive': false});

      await BleService.stopAdvertising();

      _timer?.cancel();

      if (!mounted) return;

      setState(() {
        _activeSessionId = null;
        sessionDuration = Duration.zero;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to end session")));
    }
  }

  /* LOGOUT */

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLoginPage()),
      (route) => false,
    );
  }

  /* PROFILE MENU */

  void showProfileMenu() {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.person, size: 30, color: Colors.green),
              ),

              const SizedBox(height: 12),

              Text(
                facultyName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                user?.email ?? "",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout"),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /* LIVE ATTENDANCE + PROGRESS */

  Widget attendanceWidget() {
    if (_activeSessionId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(_activeSessionId)
          .collection('attendance')
          .snapshots(),

      builder: (context, snapshot) {
        int present = snapshot.data?.docs.length ?? 0;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('students')
              .where('department', isEqualTo: department ?? "")
              .where('year', isEqualTo: int.parse(selectedYear))
              .where('section', isEqualTo: selectedSection)
              .get(),

          builder: (context, studentSnap) {
            int total = studentSnap.data?.docs.length ?? 0;

            double progress = total == 0 ? 0 : present / total;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Class Attendance : $present / $total",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* SESSION CARD */

  Widget sessionCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 140),

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        gradient: LinearGradient(
          colors: _activeSessionId == null
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
        ),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 10),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeSessionId == null ? "No Active Session" : "Session Running",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_activeSessionId != null) ...[
            const SizedBox(height: 10),

            Text(
              selectedSubject == null
                  ? "Class : -"
                  : "Class : $selectedSubject - ${department ?? ""} $selectedYear$selectedSection",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 6),

            Text(
              "Duration : ${formatDuration(sessionDuration)}",
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(height: 10),

            attendanceWidget(),
          ],
        ],
      ),
    );
  }

  /* STAT CARD */

  Widget statCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 26),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /* STUDENT COUNTER */

  Widget studentCounter() {
    if (selectedSubject == null) {
      return statCard(Icons.people, "Students", "0", Colors.blue);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('department', isEqualTo: department ?? "")
          .where('year', isEqualTo: int.parse(selectedYear))
          .where('section', isEqualTo: selectedSection)
          .snapshots(),
      builder: (context, snapshot) {
        int totalStudents = snapshot.data?.docs.length ?? 0;

        return statCard(
          Icons.people,
          "Students",
          totalStudents.toString(),
          Colors.blue,
        );
      },
    );
  }

  /* SESSION COUNTER */

  Widget sessionCounter() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('teacherEmail', isEqualTo: user?.email)
          .snapshots(),

      builder: (context, snapshot) {
        int totalSessions = snapshot.data?.docs.length ?? 0;

        return statCard(
          Icons.event,
          "Sessions",
          totalSessions.toString(),
          Colors.green,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Teacher Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, color: Colors.green),
            ),
            onPressed: showProfileMenu,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "Welcome back 👋",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            Text(
              facultyName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text("Select Class", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 8),

            /// SUBJECT DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSubject,
                  isExpanded: true,
                  hint: const Text("Select Subject"),
                  items: subjects.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// YEAR DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedYear,
                  isExpanded: true,
                  items: years.map((y) {
                    return DropdownMenuItem(value: y, child: Text("Year $y"));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// SECTION DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSection,
                  isExpanded: true,
                  items: sections.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text("Section $s"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSection = value!;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: sessionCounter()),

                const SizedBox(width: 12),

                Expanded(child: studentCounter()),
              ],
            ),

            const SizedBox(height: 25),

            sessionCard(),

            const SizedBox(height: 30),

            if (_activeSessionId == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  icon: const Icon(Icons.play_arrow),

                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Start Attendance Session",
                          style: TextStyle(fontSize: 16),
                        ),

                  onPressed:
                      _isLoading || subjects.isEmpty || selectedSubject == null
                      ? null
                      : _startSession,
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: [
                  actionTile(
                    Icons.stop_circle,
                    "End Session",
                    Colors.red,
                    _endSession,
                  ),

                  actionTile(
                    Icons.list_alt,
                    "View Attendance",
                    Colors.blue,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ViewAttendancePage(sessionId: _activeSessionId!),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget actionTile(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(16),

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(height: 10),

            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
