import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth/teacher_login.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const TeacherApp());
}

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Attendance System",
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const TeacherLoginPage();
        }

        final user = snapshot.data!;
        final email = user.email;

        return FutureBuilder(
          future: Future.wait([
            FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get(),
            FirebaseFirestore.instance
                .collection("teachers")
                .doc(email)
                .get(),
          ]),
          builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {

            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final adminDoc = snapshot.data![0];
            final teacherDoc = snapshot.data![1];

            // ADMIN LOGIN
            if (adminDoc.exists &&
                (adminDoc.data() as Map<String, dynamic>)['role'] == 'admin') {
              return const AdminDashboard();
            }

            // TEACHER LOGIN
            if (teacherDoc.exists) {
              return const TeacherDashboard();
            }

            // ROLE NOT FOUND
            return const Scaffold(
              body: Center(
                child: Text("Role not configured"),
              ),
            );
          },
        );
      },
    );
  }
}