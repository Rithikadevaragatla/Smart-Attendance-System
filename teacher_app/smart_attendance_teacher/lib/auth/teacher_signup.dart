import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherSignupPage extends StatefulWidget {
  const TeacherSignupPage({super.key});

  @override
  State<TeacherSignupPage> createState() => _TeacherSignupPageState();
}

class _TeacherSignupPageState extends State<TeacherSignupPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String errorMessage = "";
  bool loading = false;

  Future<void> createAccount() async {

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Enter email and password.";
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = "Password must be at least 6 characters.";
      });
      return;
    }

    try {

      if (!mounted) return;
      setState(() {
        loading = true;
        errorMessage = "";
      });

      /* CHECK IF ADMIN ADDED THIS TEACHER */

      final teacherDoc = await FirebaseFirestore.instance
          .collection("teachers")
          .doc(email)
          .get();

      if (!teacherDoc.exists) {

        if (!mounted) return;

        setState(() {
          errorMessage = "This email is not registered by admin.";
          loading = false;
        });

        return;
      }

      /* CREATE FIREBASE AUTH ACCOUNT */

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      /* SIGN OUT AFTER SIGNUP (VERY IMPORTANT) */

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully. Please login."),
        ),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {

      if (!mounted) return;

      setState(() {
        errorMessage = e.message ?? "Signup failed.";
      });

    } finally {

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Faculty Signup"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.person_add,
              size: 70,
              color: Colors.indigo,
            ),

            const SizedBox(height: 20),

            const Text(
              "Create Faculty Account",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Faculty Email",
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

            const SizedBox(height: 10),

            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: loading ? null : createAccount,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}