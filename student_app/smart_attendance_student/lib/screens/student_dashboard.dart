import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
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

                          final sessionId = await bleService.scanForSessionId();

                          if (sessionId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No active class nearby")),
                            );
                            return;
                          }

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

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Attendance Marked"),
      content: Text(
        "Name: $studentName\nRoll No: $rollNo",
      ),
    ),
  );

} else {

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
