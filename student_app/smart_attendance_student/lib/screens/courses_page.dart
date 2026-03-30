import 'package:flutter/material.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Courses")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            courseCard("DBMS", "CS301"),
            courseCard("CN", "CS302"),
            courseCard("SE", "CS303"),

            const SizedBox(height: 20),

            const Text("Labs", style: TextStyle(fontSize: 16)),

            courseCard("DBMS Lab", "CS301"),
            courseCard("CN Lab", "CS302"),
            courseCard("SE Lab", "CS303"),
          ],
        ),
      ),
    );
  }

  Widget courseCard(String name, String code) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text("Subject Code: $code"),
      ),
    );
  }
}