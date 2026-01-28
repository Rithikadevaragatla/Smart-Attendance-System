import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/teacher_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA7xaykYQkDNasfCcTcRbY-3Rc54wMHWD8",
      authDomain: "smartattendancesystem-a6bd5.firebaseapp.com",
      projectId: "smartattendancesystem-a6bd5",
      storageBucket: "smartattendancesystem-a6bd5.firebasestorage.app",
      messagingSenderId: "463144931073",
      appId: "1:463144931073:web:85bb46b3218ba91c70d500",
    ),
  );

  runApp(const TeacherApp());
}

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Attendance - Teacher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const TeacherLoginPage(),
    );
  }
}
