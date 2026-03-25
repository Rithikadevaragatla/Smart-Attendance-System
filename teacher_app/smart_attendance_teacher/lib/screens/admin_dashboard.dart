import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/teacher_login.dart';
import 'student_list_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  List<String> subjects = [];
  //List<String> selectedSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  /* ---------------- LOGOUT ---------------- */

  Future<void> _logout() async {

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TeacherLoginPage()),
      (route) => false,
    );
  }

  /* ---------------- PROFILE MENU ---------------- */

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
                child: Icon(Icons.admin_panel_settings,
                    size: 30, color: Colors.green),
              ),

              const SizedBox(height: 12),

              const Text(
                "Admin",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
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

  /* ---------------- LOAD SUBJECTS ---------------- */

  Future<void> _loadSubjects() async {

    final snapshot =
        await FirebaseFirestore.instance.collection("subjects").get();

    setState(() {
      subjects =
        snapshot.docs.map((doc) => (doc["name"] as String).trim()).toList();
    });
  }

  /* ---------------- DASHBOARD STAT CARDS ---------------- */

  Widget statCard(IconData icon, String title, int count, Color color) {

    return Container(
      padding: const EdgeInsets.all(18),

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

          Icon(icon, color: color, size: 30),

          const SizedBox(height: 8),

          Text(
            count.toString(),
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold),
          ),

          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          )
        ],
      ),
    );
  }

  Widget studentCount() {

    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore.instance
          .collection("students")
          .snapshots(),

      builder: (context, snapshot) {

        int total = snapshot.data?.docs.length ?? 0;

        return statCard(Icons.people, "Students", total, Colors.blue);
      },
    );
  }

  Widget facultyCount() {

    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore.instance
          .collection("teachers")
          .snapshots(),

      builder: (context, snapshot) {

        int total = snapshot.data?.docs.length ?? 0;

        return statCard(Icons.person, "Faculty", total, Colors.green);
      },
    );
  }

  Widget subjectCount() {

    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore.instance
          .collection("subjects")
          .snapshots(),

      builder: (context, snapshot) {

        int total = snapshot.data?.docs.length ?? 0;

        return statCard(Icons.book, "Subjects", total, Colors.orange);
      },
    );
  }

  Widget sessionCount() {

    return StreamBuilder<QuerySnapshot>(

      stream: FirebaseFirestore.instance
          .collection("sessions")
          .snapshots(),

      builder: (context, snapshot) {

        int total = snapshot.data?.docs.length ?? 0;

        return statCard(Icons.event, "Sessions", total, Colors.purple);
      },
    );
  }

  
  /* ---------------- ADD SUBJECT ---------------- */

  void _showAddSubjectDialog(BuildContext context) {

    final nameController = TextEditingController();
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: "Subject Name"),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: semesterController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Semester"),
              ),
            ],
          ),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              child: const Text("Add"),
              onPressed: () async {

                if (nameController.text.isEmpty ||
                    semesterController.text.isEmpty) return;

                await FirebaseFirestore.instance
                    .collection("subjects")
                    .add({
                  "name": nameController.text.trim(),
                  "semester":
                      int.parse(semesterController.text.trim()),
                  "createdAt": Timestamp.now(),
                });

                Navigator.pop(context);

                _loadSubjects();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Subject added successfully"),
                  ),
                );
              },
            )
          ],
        );
      },
    );
  }

  Future<void> _deleteSubject(String id) async {
    await FirebaseFirestore.instance
        .collection("subjects")
        .doc(id)
        .delete();
  }

  /* ---------------- ADD FACULTY ---------------- */

 void _showAddFacultyDialog(BuildContext context) {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final deptController = TextEditingController();

  List<String> dialogSelectedSubjects = [];


  showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {

          return AlertDialog(
            title: const Text("Add Faculty"),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// NAME
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Faculty Name",
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// EMAIL
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// DEPARTMENT
                  TextField(
                    controller: deptController,
                    decoration: const InputDecoration(
                      labelText: "Department",
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// SUBJECTS
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Assign Subjects",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subjects.map((subject) {
                      return CheckboxListTile(
                        value: dialogSelectedSubjects.contains(subject),
                        title: Text(subject),
                        onChanged: (value) {
                          setStateDialog(() {
                            if (value == true) {
                              dialogSelectedSubjects.add(subject);
                            } else {
                              dialogSelectedSubjects.remove(subject);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),



                  const SizedBox(height: 15),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Preview:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: dialogSelectedSubjects.map((subject) {
                       return Text(
                          "• $subject",
                          style: const TextStyle(color: Colors.grey),
                        );
                       }).toList(),
                    ),
                ],
              ),
            ),

            actions: [

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                child: const Text("Create"),
                onPressed: () async {

                  final email = emailController.text.trim();

                  if (nameController.text.isEmpty ||
                      email.isEmpty ||
                      deptController.text.isEmpty ||
                      dialogSelectedSubjects.isEmpty) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill all fields"),
                      ),
                    );
                    return;
                  }
                  // 🔥 Remove duplicates (safety)
                  List<String> subjectsList = dialogSelectedSubjects
                    .map((s) => s.toUpperCase())
                    .toSet()
                    .toList();
                  /// CHECK IF EXISTS
                  final doc = await FirebaseFirestore.instance
                      .collection("teachers")
                      .doc(email)
                      .get();

                  if (doc.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Faculty already exists"),
                      ),
                    );
                    return;
                  }

                 

                  /// 🔥 SAVE TO FIRESTORE
                  await FirebaseFirestore.instance
                      .collection("teachers")
                      .doc(email)
                      .set({

                    "name": nameController.text.trim(),
                    "email": email,
                    "department": deptController.text.trim(),
                    "subjects": subjectsList,
                    //"assignments": assignments,
                    "role": "faculty",
                    "createdAt": Timestamp.now(),

                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Faculty added successfully"),
                    ),
                  );
                },
              )
            ],
          );
        },
      );
    },
  );
}
  Future<void> _deleteFaculty(String id) async {

    await FirebaseFirestore.instance
        .collection("teachers")
        .doc(id)
        .delete();
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.person, color: Colors.green),
            ),
            onPressed: showProfileMenu,
          )
        ],
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Expanded(child: studentCount()),
                const SizedBox(width: 10),
                Expanded(child: facultyCount()),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: subjectCount()),
                const SizedBox(width: 10),
                Expanded(child: sessionCount()),
              ],
            ),

            const SizedBox(height: 30),

            
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Manage Students"),
              style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentListPage(),
                  ),
                );
              },
            ),
          ),

            const SizedBox(height: 20),

            const SizedBox(height: 30),

            const Divider(),

            /* SUBJECTS */

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                const Text(
                  "Subjects",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                  onPressed: () => _showAddSubjectDialog(context),
                )
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 200,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("subjects")
                    .orderBy("createdAt")
                    .snapshots(),

                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {

                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      return Card(
                        child: ListTile(

                          leading: const Icon(Icons.book),

                          title: Text(data["name"]),

                          subtitle:
                              Text("Semester ${data["semester"]}"),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () =>
                                _deleteSubject(docs[index].id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /* FACULTY */

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                const Text(
                  "Faculty",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add"),
                  onPressed: () => _showAddFacultyDialog(context),
                )
              ],
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("teachers")
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(

                        leading: const Icon(Icons.person),

                        title: Text(data["name"] ?? ""),

                        subtitle: Text(data["email"] ?? ""),

                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () =>
                              _deleteFaculty(docs[index].id),
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}