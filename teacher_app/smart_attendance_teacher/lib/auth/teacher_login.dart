import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/admin_dashboard.dart';
import 'teacher_signup.dart';

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

  /* ---------------- LOGIN ---------------- */

  Future<void> _loginUser() async {

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Enter email and password.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {

      UserCredential credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) return;

      final adminDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (adminDoc.exists && adminDoc.data()?['role'] == 'admin') {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
        );

        return;
      }

      final teacherDoc = await FirebaseFirestore.instance
          .collection("teachers")
          .doc(email)
          .get();

      if (teacherDoc.exists) {

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherDashboard(),
          ),
        );

        return;
      }

      setState(() {
        _errorMessage = "You are not authorized to login.";
      });

    } on FirebaseAuthException catch (e) {

      setState(() {
        _errorMessage = e.message ?? "Login failed.";
      });

    } finally {

      setState(() {
        _isLoading = false;
      });
    }
  }

  /* ---------------- RESET PASSWORD ---------------- */

  Future<void> _resetPassword() async {

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email first")),
      );
      return;
    }

    try {

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to send reset email")),
      );
    }
  }

  /* ---------------- UI ---------------- */

  @override
  Widget build(BuildContext context) {

    final logoColor = const Color(0xFF2E1A8A);

    return Scaffold(

      appBar: AppBar(
        title: const Text("Faculty / Admin Login"),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              /// COLLEGE LOGO
              Image.asset(
                "assets/gcet_logo.png",
                width: MediaQuery.of(context).size.width * 0.25,
              ),

              const SizedBox(height: 10),

              /// COLLEGE NAME
              Text(
                "Geethanjali College of Engineering and Technology (Autonomous)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: logoColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              /// ACCREDITATION
              Text(
                "Accredited by NAAC with A+ Grade; B.Tech. CSE, EEE, ECE accredited by NBA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: logoColor,
                  fontSize: 12,
                ),
              ),

              /// ADDRESS
              Text(
                "Sy. No: 33 & 34, Cheeryal (V), Keesara (M), Medchal District, Telangana – 501301",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: logoColor,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 30),

              /// EMAIL
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              /// PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: const Text("Forgot Password?"),
                ),
              ),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _loginUser,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),

              const SizedBox(height: 10),

              TextButton(
                child: const Text("New Faculty? Create Account"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherSignupPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}