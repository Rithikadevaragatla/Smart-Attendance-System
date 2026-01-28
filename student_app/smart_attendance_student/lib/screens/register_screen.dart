import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'face_capture_screen.dart';
import '../services/local_storage_service.dart';

import '../services/firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController rollController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    rollController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            TextField(
              controller: rollController,
              decoration: InputDecoration(
                labelText: 'Roll Number (used as password)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // 1. Create Firebase Auth user
                    final credential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: rollController.text.trim(),
                    );

                    final uid = credential.user!.uid;

                    // 2. Capture face images
                    final images = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FaceCaptureScreen(),
                      ),
                    );

                    if (images == null || images.isEmpty) {
                      throw Exception("Face capture cancelled");
                    }

                    // 3. Save images locally
                      final localStorageService = LocalStorageService();
                      final facePaths =
                          await localStorageService.saveFaceImages(images);


                    // 4. Save student data in Firestore
                    final firestoreService = FirestoreService();
                    await firestoreService.saveStudent(
                      uid: uid,
                      name: nameController.text.trim(),
                      rollNo: rollController.text.trim(),
                      email: emailController.text.trim(),
                      faceUrls: facePaths, // local file paths

                    );

                    // 5. Success
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Registration successful"),
                      ),
                    );

                    Navigator.pop(context); // back to login
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                      ),
                    );
                  }
                },
                child: Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
