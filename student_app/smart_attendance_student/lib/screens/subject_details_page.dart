import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SubjectDetailsPage extends StatefulWidget {
  final String subjectName;
  final String subjectCode;
  final String faculty;
  final String time;
  final String room;

  const SubjectDetailsPage({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.faculty,
    required this.time,
    required this.room,
  });

  @override
  State<SubjectDetailsPage> createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  DateTime selectedMonth = DateTime.now();

  List<Map<String, dynamic>> records = [];
  int attended = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  // ✅ FETCH DATA
Future<void> fetchAttendance() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // 1️⃣ Get sessions for THIS class only
  final sessionsSnapshot = await FirebaseFirestore.instance
      .collection('sessions')
      .where('subject', isEqualTo: widget.subjectName)
      .get();

  // 2️⃣ Get student attendance
  final attendanceSnapshot = await FirebaseFirestore.instance
      .collection('students')
      .doc(uid)
      .collection('attendance')
      .get();

  final attendedSessionIds =
      attendanceSnapshot.docs.map((doc) => doc.id).toSet();

  // 3️⃣ Build records
  records = sessionsSnapshot.docs.map((session) {
    Timestamp date = session['date'];

    return {
      "date": date,
      "status": attendedSessionIds.contains(session.id)
          ? "Present"
          : "Absent",
    };
  }).toList();
 

  // 4️⃣ Filter by month
  records = records.where((e) {
    DateTime date = (e['date'] as Timestamp).toDate();

    return date.year == selectedMonth.year &&
           date.month == selectedMonth.month;
  }).toList();
   records.sort((a, b) {
  DateTime dateA = (a['date'] as Timestamp).toDate();
  DateTime dateB = (b['date'] as Timestamp).toDate();

  return dateB.compareTo(dateA); // 🔥 latest first
});

  // 5️⃣ Count
  total = records.length;
  attended =
      records.where((e) => e['status'] == 'Present').length;

  setState(() {});
}
  // ✅ MONTH PICKER
   void pickMonth() async {
  int year = selectedMonth.year;
  int month = selectedMonth.month;

  await showDialog(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Select Month"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ✅ Year Dropdown
                DropdownButton<int>(
                  value: year,
                  items: List.generate(10, (i) {
                    int y = 2022 + i;
                    return DropdownMenuItem(
                      value: y,
                      child: Text("$y"),
                    );
                  }),
                  onChanged: (v) {
                    setStateDialog(() {
                      year = v!;
                    });
                  },
                ),

                // ✅ Month Dropdown
                DropdownButton<int>(
                  value: month,
                  items: List.generate(12, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(
                        DateFormat.MMM().format(DateTime(0, i + 1)),
                      ),
                    );
                  }),
                  onChanged: (v) {
                    setStateDialog(() {
                      month = v!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(year, month);
                  });
                  Navigator.pop(context);
                  fetchAttendance();
                },
                child: const Text("OK"),
              )
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    String monthName =
        DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 Subject Info
            Text("Subject: ${widget.subjectName}"),
            Text("Code: ${widget.subjectCode}"),
            Text("Faculty: ${widget.faculty}"),
            Text("Time: ${widget.time}"),
            Text("Room: ${widget.room}"),

            const SizedBox(height: 20),

            // 🔹 Month Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(monthName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: pickMonth,
                )
              ],
            ),

            const SizedBox(height: 10),

            // 🔹 Monthly Count
            Text("$monthName - $attended/$total classes attended"),

            const SizedBox(height: 20),

            // 🔹 Day-wise List
            Expanded(
              child: ListView.builder(
                itemCount: records.length,
                itemBuilder: (_, i) {
                  final data = records[i];
                  DateTime date =
                      (data['date'] as Timestamp).toDate();

                  return Card(
                    child: ListTile(
                      title: Text(
                          DateFormat('dd MMM').format(date)),
                      trailing: Text(
                        data['status'],
                        style: TextStyle(
                          color: data['status'] == 'Present'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}