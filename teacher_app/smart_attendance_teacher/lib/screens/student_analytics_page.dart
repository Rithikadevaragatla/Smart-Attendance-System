import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class StudentAnalyticsPage extends StatefulWidget {
  const StudentAnalyticsPage({super.key});

  @override
  State<StudentAnalyticsPage> createState() =>
      _StudentAnalyticsPageState();
}

class _StudentAnalyticsPageState extends State<StudentAnalyticsPage> {
  String? selectedDept;
  String? selectedYear;
  String? selectedSection;

  List<Map<String, dynamic>> students = [];
  bool isLoading = false;

  final List<String> departments = [
    "CSE",
    "AIML",
    "DS",
    "IOT",
    "ECE",
    "EEE",
    "MECH"
  ];
  final List<String> years = ["1", "2", "3", "4"];
  final List<String> sections = ["A", "B", "C", "D", "E", "F", "G"];

  /* ---------------- FETCH STUDENTS ---------------- */

  Future<void> fetchStudents() async {
    if (selectedDept == null ||
        selectedYear == null ||
        selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select all filters")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      students = [];
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("students")
          .where("department", isEqualTo: selectedDept)
          .where("year", isEqualTo: int.parse(selectedYear!))
          .where("section", isEqualTo: selectedSection)
          .get();

      print("Students fetched: ${snapshot.docs.length}");

      if (snapshot.docs.isEmpty) {
        setState(() {
          students = [];
          isLoading = false;
        });
        return;
      }

      // 🔥 PARALLEL PROCESSING (IMPORTANT FIX)
      List<Future<Map<String, dynamic>>> futures =
          snapshot.docs.map((doc) async {
        double attendance = await calculateAttendance(doc.id);

        return {
          "id": doc.id,
          "name": doc["name"] ?? "No Name",
          "rollNo": doc["rollNo"] ?? "",
          "attendance": attendance,
          "emailController": TextEditingController(),
        };
      }).toList();

      final results = await Future.wait(futures);

      setState(() {
        students = results;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching students: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  /* ---------------- CALCULATE ATTENDANCE ---------------- */

  Future<double> calculateAttendance(String studentId) async {
    try {
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection("sessions")
          .orderBy("date", descending: true)
          .limit(60)
          .get();

      int total = sessionsSnapshot.docs.length;
      int present = 0;

      // 🔥 Still async but optimized enough
      for (var session in sessionsSnapshot.docs) {
        final att = await FirebaseFirestore.instance
            .collection("sessions")
            .doc(session.id)
            .collection("attendance")
            .doc(studentId)
            .get();

        if (att.exists) present++;
      }

      if (total == 0) return 0;

      return (present / total) * 100;
    } catch (e) {
      print("Attendance error: $e");
      return 0;
    }
  }

  /* ---------------- SEND EMAIL ---------------- */

  Future<void> sendEmail(
      String studentName,
      double attendance,
      String parentEmail,
      ) async {

    if (parentEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter parent email")),
      );
      return;
    }

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': 'service_7qzwifa', // ✅ your ID
          'template_id': 'template_o52m1fl', // 🔴 replace if needed
          'user_id': 'DeEWpuLTg8KA0cWVr', // 🔴 replace if needed
          'template_params': {
            'student_name': studentName,
            'attendance': attendance.toStringAsFixed(1),
            'parent_email': parentEmail,
          }
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Email sent to $parentEmail ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed ❌ ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error ❌ $e")),
      );
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Analytics"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            /* -------- FILTERS -------- */

            Row(
              children: [

                Expanded(
                  child: DropdownButtonFormField<String>(
                    hint: const Text("Dept"),
                    value: departments.contains(selectedDept)
                        ? selectedDept
                        : null,
                    items: departments
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedDept = val);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    hint: const Text("Year"),
                    value: years.contains(selectedYear)
                        ? selectedYear
                        : null,
                    items: years
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedYear = val);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    hint: const Text("Section"),
                    value: sections.contains(selectedSection)
                        ? selectedSection
                        : null,
                    items: sections
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedSection = val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: fetchStudents,
                child: const Text("Load Students"),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            /* -------- STUDENT LIST -------- */

            Expanded(
              child: (!isLoading && students.isEmpty)
                  ? const Center(
                child: Text("No students found"),
              )
                  : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {

                  final s = students[index];
                  bool low = s["attendance"] < 75;

                  final controller =
                  s["emailController"]
                  as TextEditingController;

                  return Card(
                    elevation: 4,
                    margin:
                    const EdgeInsets.only(bottom: 12),

                    color: low
                        ? Colors.red.withOpacity(0.08)
                        : Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(14),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          Text(
                            s["name"],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold),
                          ),

                          const SizedBox(height: 4),

                          Text("Roll: ${s["rollNo"]}"),

                          const SizedBox(height: 6),

                          Text(
                            "Attendance: ${s["attendance"].toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: low
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),

                          if (low) ...[
                            const SizedBox(height: 10),

                            TextField(
                              controller: controller,
                              decoration:
                              const InputDecoration(
                                labelText:
                                "Parent Email",
                                border:
                                OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    sendEmail(
                                      s["name"],
                                      s["attendance"],
                                      controller.text
                                          .trim(),
                                    ),
                                child: const Text(
                                    "Send Alert"),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}