import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

import 'face_capture_screen.dart';
//import '../services/local_storage_service.dart';
import '../services/face_detection_service.dart';
//import '../services/face_feature_service.dart';
import '../services/firestore_service.dart';
import '../services/facenet_service.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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

  List<double> averageEmbeddings(List<List<double>> embeddings) {
  final int length = embeddings.first.length;
  final avg = List<double>.filled(length, 0.0);

  for (final emb in embeddings) {
    for (int i = 0; i < length; i++) {
      avg[i] += emb[i];
    }
  }

  for (int i = 0; i < length; i++) {
    avg[i] /= embeddings.length;
  }

  return avg;
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
                    // 2.5 Face detection + feature extraction
                      final faceNetService = FaceNetService();
                      await faceNetService.loadModel();

                      final List<List<double>> allEmbeddings = [];


                      // Create FaceDetector ONCE
                      final detector = FaceDetector(
                        options: FaceDetectorOptions(
                          performanceMode: FaceDetectorMode.accurate,
                          enableLandmarks: false,
                        ),
                      );

                      for (final imagePath in images) {
                        // 1️⃣ Detect face
                        final inputImage = InputImage.fromFile(File(imagePath));
                        final faces = await detector.processImage(inputImage);

                        if (faces.isEmpty) {
                          detector.close();
                          throw Exception("Face not detected. Please re-register.");
                        }

                        final face = faces.first;
                        final box = face.boundingBox;

                        // 2️⃣ Load original image
                        final originalImage =
                            img.decodeImage(File(imagePath).readAsBytesSync());

                        if (originalImage == null) {
                          detector.close();
                          throw Exception("Failed to read image");
                        }

                        // 3️⃣ Safe crop
                        final x = box.left.toInt().clamp(0, originalImage.width - 1);
                        final y = box.top.toInt().clamp(0, originalImage.height - 1);

                        final w = box.width.toInt().clamp(1, originalImage.width - x);
                        final h = box.height.toInt().clamp(1, originalImage.height - y);

                        final croppedFace = img.copyCrop(
                          originalImage,
                          x: x,
                          y: y,
                          width: w,
                          height: h,
                        );

                        // 4️⃣ Generate FaceNet embedding
                        final embedding = faceNetService.getEmbedding(croppedFace);
                        allEmbeddings.add(embedding);

                      }

                      // Cleanup
                      detector.close();
                      faceNetService.dispose();
                      if (allEmbeddings.isEmpty) {
                        throw Exception("No valid face embeddings generated");
                      }

                      final averagedEmbedding = averageEmbeddings(allEmbeddings);


                    


                    // 3. Save images locally
                      final List<String> facePaths = List<String>.from(images);



                    // 4. Save student data in Firestore
                    final firestoreService = FirestoreService();
                    await firestoreService.saveStudent(
                      uid: uid,
                      name: nameController.text.trim(),
                      rollNo: rollController.text.trim(),
                      email: emailController.text.trim(),
                      faceUrls: facePaths,
                      embedding: averagedEmbedding, // local file paths

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
