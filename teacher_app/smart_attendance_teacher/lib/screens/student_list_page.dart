import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/teacher_login.dart';

class StudentListPage extends StatelessWidget {
  const StudentListPage({super.key});

  /* ---------------- ASSIGN DIALOG ---------------- */

  void _showAssignDialog(
      BuildContext context, String studentId, Map<String, dynamic> data) {

    String? department = data['department'];
    String? year = data['year']?.toString();
    String? section = data['section'];

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

                  /// DEPARTMENT
                  DropdownButtonFormField<String>(
                    value: department,
                    hint: const Text("Department"),
                    items: departments.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => department = value);
                    },
                  ),

                  const SizedBox(height: 10),

                  /// YEAR
                  DropdownButtonFormField<String>(
                    value: year,
                    hint: const Text("Year"),
                    items: years.map((y) {
                      return DropdownMenuItem(
                        value: y,
                        child: Text("Year $y"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => year = value);
                    },
                  ),

                  const SizedBox(height: 10),

                  /// SECTION
                  DropdownButtonFormField<String>(
                    value: section,
                    hint: const Text("Section"),
                    items: sections.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text("Section $s"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => section = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  /// PREVIEW
                  Text(
                    "${department ?? "Dept"} ${year ?? ""}${section ?? ""}",
                    style: const TextStyle(color: Colors.grey),
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
                        const SnackBar(
                            content: Text("Fill all fields")),
                      );
                      return;
                    }

                    try {
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
                        const SnackBar(
                            content: Text("Student updated")),
                      );

                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
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

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Students"),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {

              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const TeacherLoginPage(),
                ),
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

          return ListView.builder(

            itemCount: students.length,

            itemBuilder: (context, index) {

              final doc = students[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? "No Name";
              final rollNo = data['rollNo'] ?? "-";
              final dept = data['department'];
              final year = data['year'];
              final section = data['section'];

              final isAssigned =
                  dept != null && year != null && section != null;

              return Card(
                child: ListTile(

                  title: Text(name),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("Roll No: $rollNo"),

                      Text(
                        isAssigned
                            ? "Class: $dept $year$section"
                            : "⚠ Not Assigned",
                        style: TextStyle(
                          color:
                              isAssigned ? Colors.grey : Colors.red,
                        ),
                      ),
                    ],
                  ),

                  trailing: const Icon(Icons.edit),

                  onTap: () {
                    _showAssignDialog(context, doc.id, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}