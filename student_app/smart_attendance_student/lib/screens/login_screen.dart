import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';
//import 'student_home_screen.dart';
import 'student_dashboard.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {

  final logoColor = const Color(0xFF2E1A8A); // similar to logo shade

  return Scaffold(
    appBar: AppBar(
      title: const Text('Student Login'),
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
                fontFamily: "Sans-serif",
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
                fontFamily: "Sans-serif",
              ),
            ),

            /// ADDRESS
            Text(
              "Sy. No: 33 & 34, Cheeryal (V), Keesara (M), Medchal District, Telangana – 501301",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: logoColor,
                fontSize: 12,
                fontFamily: "Sans-serif",
              ),
            ),

            const SizedBox(height: 30),

            /// EMAIL FIELD
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            /// PASSWORD FIELD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Login'),
                onPressed: () async {
                  try {
                    final userCredential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentDashboard(),
                      ),
                    );

                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                );
              },
              child: const Text('New user? Register'),
            ),
          ],
        ),
      ),
    ),
  );
}
}