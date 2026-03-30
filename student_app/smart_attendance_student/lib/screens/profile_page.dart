import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String rollNo = "";
  String email = "";
  String dept = "";
  String year = "";
  String section = "";

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();

    setState(() {
      name = doc['name'] ?? "";
      rollNo = doc['rollNo'] ?? "";
      email = doc['email'] ?? "";
      dept = doc['department'] ?? "";
      year = doc['year'].toString();
      section = doc['section'] ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // 🔹 Profile Icon
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 15),

            // 🔹 Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            // 🔹 Email
            Text(
              email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // 🔹 Details List (Aligned)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileRow("Roll No", rollNo),
                profileRow("Department", dept),
                profileRow("Year", year),
                profileRow("Section", section),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Clean aligned row
  Widget profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120, // alignment control
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}