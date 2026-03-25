import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/teacher_login.dart';
import 'student_analytics_page.dart';

class StudentListPage extends StatelessWidget {
  const StudentListPage({super.key});

  /* ---------------- ASSIGN DIALOG ---------------- */

  void _showAssignDialog(
      BuildContext context, String studentId, Map<String, dynamic> data) {

    // ✅ FIX: convert empty values → null
    String? department =
        (data['department'] == null || data['department'].toString().trim().isEmpty)
            ? null
            : data['department'];

    String? year =
        (data['year'] == null || data['year'].toString().trim().isEmpty)
            ? null
            : data['year'].toString();

    String? section =
        (data['section'] == null || data['section'].toString().trim().isEmpty)
            ? null
            : data['section'];

    List<String> departments = ["CSE", "ECE", "EEE"];
    List<String> years = ["1", "2", "3", "4"];
    List<String> sections = ["A", "B", "C"];

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {

            return AlertDialog(
              title: const Text("Assign Class"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// ✅ FIXED DROPDOWN
                  DropdownButtonFormField<String>(
                    value: departments.contains(department) ? department : null,
                    hint: const Text("Department"),
                    items: departments
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setStateDialog(() => department = value),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: years.contains(year) ? year : null,
                    hint: const Text("Year"),
                    items: years
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text("Year $y"),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setStateDialog(() => year = value),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: sections.contains(section) ? section : null,
                    hint: const Text("Section"),
                    items: sections
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text("Section $s"),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setStateDialog(() => section = value),
                  ),
                ],
              ),

              actions: [

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {

                    if (department == null ||
                        year == null ||
                        section == null) {

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fill all fields")),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('students')
                        .doc(studentId)
                        .set({
                      "department": department,
                      "year": int.parse(year!),
                      "section": section,
                    }, SetOptions(merge: true));

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Assigned Successfully")),
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /* ---------------- STAT CARD ---------------- */

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          )
        ],
      ),
    );
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text("Student Management"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,

        actions: [

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const TeacherLoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          /// 🔴 UNASSIGNED STUDENTS
          final unassigned = students.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            bool isEmptyField(dynamic value) {
              return value == null || value.toString().trim().isEmpty;
            }

            return isEmptyField(data['department']) ||
                  isEmptyField(data['year']) ||
                  isEmptyField(data['section']);
          }).toList();

          return SingleChildScrollView(

            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 SUMMARY
                Row(
                  children: [

                    Expanded(
                      child: _statCard(
                        "Students",
                        students.length.toString(),
                        Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _statCard(
                        "Unassigned",
                        unassigned.length.toString(),
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 🔴 UNASSIGNED LIST
                const Text(
                  "Unassigned Students",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                if (unassigned.isEmpty)

                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("All students are assigned 🎉"),
                    ),
                  )

                else

                  ...unassigned.map((doc) {

                    final data = doc.data() as Map<String, dynamic>;

                    final name = data['name'] ?? "No Name";
                    final rollNo = data['rollNo'] ?? "-";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),

                      child: ListTile(

                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),

                        title: Text(name),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text("Roll No: $rollNo"),

                            const Text(
                              "⚠ Class Not Assigned",
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),

                        trailing: ElevatedButton(
                          child: const Text("Assign"),
                          onPressed: () {
                            _showAssignDialog(context, doc.id, data);
                          },
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 30),

                /// 📊 ANALYTICS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 10,
                      )
                    ],
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Student Analytics",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "View attendance insights",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const StudentAnalyticsPage(),
                            ),
                          );
                        },
                        child: const Text("Open"),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}