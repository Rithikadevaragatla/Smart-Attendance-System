import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'subject_details_page.dart';
import 'profile_page.dart';
import 'courses_page.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../services/permission_service.dart';
import 'face_attendance_capture.dart';
import '../services/face_detection_service.dart';
//import '../services/face_feature_service.dart';
import '../services/facenet_service.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';




class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String studentName = "";
  String rollNo = "";
  String? studentDept;
  int? studentYear;
  String? studentSection;
  bool loading = true;
  double overallPercentage = 0;
  bool isLowAttendance = false;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
   // calculateOverallAttendance();
  }
  Future<void> calculateOverallAttendance() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 1️⃣ Get all sessions
  final sessionsSnapshot = await FirebaseFirestore.instance
    .collection('sessions')
    .where('department', isEqualTo: studentDept)
    .where('year', isEqualTo: studentYear)
    .where('section', isEqualTo: studentSection)
    .get();

  // 2️⃣ Get student attendance
  final attendanceSnapshot = await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .collection('attendance')
      .get();

  int totalSessions = sessionsSnapshot.docs.length;
  int present = attendanceSnapshot.docs.length;

if (totalSessions == 0) {
  setState(() {
    overallPercentage = 0;
    isLowAttendance = true;
  });
  return;
}
  double percent = (present / totalSessions) * 100;

  setState(() {
    overallPercentage = percent;
    isLowAttendance = percent < 75;
  });
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

  studentDept = doc['department'];
studentYear = int.tryParse(doc['year'].toString());
studentSection = doc['section'];
  loading = false;
  });
  await calculateOverallAttendance();
}
double calculateDistance(List<double> e1, List<double> e2) {
  double sum = 0.0;
  for (int i = 0; i < e1.length; i++) {
    sum += (e1[i] - e2[i]) * (e1[i] - e2[i]);
  }
  return sum;
}
   List<double> normalize(List<double> embedding) {
                              double sum = 0.0;
                              for (var v in embedding) {
                                sum += v * v;
                              }

                              double magnitude = sqrt(sum);

                              return embedding.map((e) => e / magnitude).toList();
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
              leading: const Icon(Icons.book),
              title: const Text("Courses"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoursesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Roll No: $rollNo"),
                          const SizedBox(height: 6),
                            Text(
                              "Attendance: ${overallPercentage.toStringAsFixed(1)}%",
                              style: const TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                            ),

                            Text(
                              isLowAttendance
                                  ? "Your attendance is low"
                                  : "Your attendance is good",
                              style: TextStyle(
                                color: isLowAttendance ? Colors.red : Colors.green,
                                fontSize: 18, fontWeight: FontWeight.w500,
                              ),
                            ),
                                                    ],
                      ),
                    ),

                    
                      ElevatedButton(
                      onPressed: () async {
                        try {
                          // 1️⃣ Permissions
                          final hasPermission =
                              await PermissionService.requestBlePermissions();

                          if (!hasPermission) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Location permission required")),
                            );
                            return;
                          }

                          // 2️⃣ BLE scan
                                                 
                          final bleService = BleService();
                          final sessionService = SessionService();

                          final sessionData = await bleService.scanForSession();

                          if (sessionData == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No active class nearby")),
                            );
                            return;
                          }

                          // Extract data
                          String sessionId = sessionData["sessionId"]!;
                          String subject = sessionData["subject"]!;
                          String dept = sessionData["department"]!;
                          int year = int.tryParse(sessionData["year"]!) ?? -1;
                          String section = sessionData["section"]!;
                          // Edge case
                          if (studentDept == null || studentYear == null || studentSection == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Contact admin. Class not assigned")),
                            );
                            return;
                          }

                          // FILTER
                          if (dept.trim().toUpperCase() != studentDept!.trim().toUpperCase() ||
                              year != studentYear ||
                              section.trim().toUpperCase() != studentSection!.trim().toUpperCase()) {

                            print("Different class session ignored");

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("This session is not for your class")),
                            );

                            return;
                          }

                          print("Correct class session detected");
                          // 3️⃣ Validate session
                          final isActive =
                              await sessionService.isSessionActive(sessionId);

                          if (!isActive) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Session is no longer active")),
                            );
                            return;
                          }

                          // 4️⃣ Open camera
                          final imagePath = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FaceAttendanceCapture(),
                            ),
                          );

                          if (imagePath == null) return;

                          // 5️⃣ Face detection
                          final faceDetectionService = FaceDetectionService();
                          final hasFace =
                              await faceDetectionService.hasFace(imagePath);
                          faceDetectionService.dispose();

                          if (!hasFace) {
                            showDialog(
                              context: context,
                              builder: (_) => const AlertDialog(
                                title: Text("Face Not Detected"),
                                content: Text("Please keep your face clearly visible."),
                              ),
                            );
                            return;
                          }

                          // 6️⃣ Extract live features
                          // Extract embedding using SAME model as registration
                                  final faceNetService = FaceNetService();
                                  await faceNetService.loadModel();

                                  // Load image
                                  final originalImage =
                                      img.decodeImage(File(imagePath).readAsBytesSync());

                                  if (originalImage == null) {
                                    throw Exception("Image error");
                                  }

// You must crop face using SAME bounding box logic
                              final inputImage = InputImage.fromFile(File(imagePath));

                                  final detector = FaceDetector(
                                    options: FaceDetectorOptions(
                                      performanceMode: FaceDetectorMode.accurate,
                                    ),
                                  );

                                  final List<Face> faces = await detector.processImage(inputImage);

                                  if (faces.isEmpty) {
                                    detector.close();
                                    throw Exception("Face not detected during cropping");
                                  }

                                  final Rect box = faces.first.boundingBox;

                                  detector.close();


                              

                              final x = box.left.toInt().clamp(0, originalImage.width - 1);
                              final y = box.top.toInt().clamp(0, originalImage.height - 1);
                              final w = box.width.toInt().clamp(1, originalImage.width - x);
                              final h = box.height.toInt().clamp(1, originalImage.height - y);

                              final croppedFace = img.copyCrop(
                                originalImage,
                                x: x,
                                y: y,
                                width: w,
                                height: h,
                              );

                              final liveFeatures =
                                  faceNetService.getEmbedding(croppedFace);

                              faceNetService.dispose();


                          

                        
           // 7️⃣ Fetch stored embeddings
// 7️⃣ Fetch stored embedding
final uid = FirebaseAuth.instance.currentUser!.uid;
final doc = await FirebaseFirestore.instance
    .collection('students')
    .doc(uid)
    .get();

final List<double> storedEmbedding =
    List<double>.from(doc['embedding']);

// Normalize both
final normalizedLive = normalize(liveFeatures);
final normalizedStored = normalize(storedEmbedding);

// Calculate distance
final distance =
    calculateDistance(normalizedLive, normalizedStored);

print("FINAL DISTANCE = $distance");



  if (distance < 0.8) {

  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 🔍 CHECK FIRST (ADD THIS)
  final existing = await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .collection('attendance')
      .doc(sessionId)
      .get();

  if (existing.exists) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("Already Marked"),
        content: Text("You have already marked attendance for this class."),
      ),
    );
    return;
  }

  // ✅ THEN SAVE (your existing code)

  await FirebaseFirestore.instance
      .collection('sessions')
      .doc(sessionId)
      .collection('attendance')
      .doc(uid)
      .set({
    'name': studentName,
    'rollNo': rollNo,
    'timestamp': Timestamp.now(),
  });

  await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .collection('attendance')
      .doc(sessionId)
      .set({
    'subject': subject,
    'date': Timestamp.now(),
    'status': 'Present',
  });

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Attendance Marked"),
      content: Text(
        "Name: $studentName\nRoll No: $rollNo",
      ),
    ),
  );
}
 else {

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Face Mismatch"),
      content: Text(
        "Attendance not marked.\nDistance: ${distance.toStringAsFixed(2)}",
      ),
    ),
  );
}



                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      },
                      child: const Text("MARK ATTENDANCE"),
                    ),
                  ],
                ),
                

                  // 🔹 Today's Timetable
                  const Text(
                    "Today's Classes",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _timetableCard(context, "09:00 - 10:00", "DBMS"),
                  _timetableCard(context, "09:00 - 10:00", "AI"),
                  _timetableCard(context, "09:00 - 10:00", "CN"),
                  

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

  static Widget _timetableCard(
    BuildContext context, String time, String subject) {
  return Card(
    child: ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(subject),
      subtitle: Text(time),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubjectDetailsPage(
              subjectName: subject,
              subjectCode: "CS301",
              faculty: "Dr.S.Radha",
              time: time,
              room: "213",
            ),
          ),
        );
      },
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
