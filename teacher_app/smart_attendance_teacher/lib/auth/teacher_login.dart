import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/teacher_dashboard.dart';

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";

  Future<void> _loginTeacher() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // 1️⃣ Authenticate teacher
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) return;

      // 2️⃣ Reference to teachers collection
      final teacherRef =
          FirebaseFirestore.instance.collection('teachers').doc(user.uid);

      // 3️⃣ Check if teacher document exists
      final teacherSnapshot = await teacherRef.get();

      if (!teacherSnapshot.exists) {
        // 4️⃣ Create teacher profile (first login only)
        await teacherRef.set({
          'name': 'Teacher Name', // Can be updated later
          'employeeId': 'EMP-${user.uid.substring(0, 6)}',
          'email': user.email,
          'createdAt': Timestamp.now(),
        });
      }

      // 5️⃣ Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherDashboard(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Login failed";
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : _loginTeacher,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
