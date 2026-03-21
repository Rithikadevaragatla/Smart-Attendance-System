import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/excel_service.dart';

class ViewAttendancePage extends StatefulWidget {
  final String sessionId;

  const ViewAttendancePage({super.key, required this.sessionId});

  @override
  State<ViewAttendancePage> createState() => _ViewAttendancePageState();
}

class _ViewAttendancePageState extends State<ViewAttendancePage> {

  bool isDownloading = false;

  DateTime? selectedDate;
  DateTime? selectedMonth;

  /* ---------------- SESSION REPORT ---------------- */

  Future<void> downloadSessionReport() async {

    setState(() => isDownloading = true);

    await ExcelService.generateSessionReport(
      sessionId: widget.sessionId,
    );

    if (!mounted) return;

    setState(() => isDownloading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session report downloaded")),
    );
  }

  /* ---------------- ABSENTEES REPORT ---------------- */

  Future<void> downloadAbsenteesReport() async {

    setState(() => isDownloading = true);

    await ExcelService.generateAbsenteesReport(
      sessionId: widget.sessionId,
    );

    if (!mounted) return;

    setState(() => isDownloading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Absentees report downloaded")),
    );
  }

  /* ---------------- DAY REPORT ---------------- */

  Future<void> downloadDayReport() async {

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date first")),
      );
      return;
    }

    setState(() => isDownloading = true);

    await ExcelService.generateDayReport(
      date: selectedDate!,
    );

    if (!mounted) return;

    setState(() => isDownloading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Day report downloaded")),
    );
  }

  /* ---------------- MONTH REPORT ---------------- */

  Future<void> downloadMonthReport() async {

    if (selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a month first")),
      );
      return;
    }

    setState(() => isDownloading = true);

    await ExcelService.generateMonthReport(
      month: selectedMonth!,
    );

    if (!mounted) return;

    setState(() => isDownloading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Month report downloaded")),
    );
  }

  /* ---------------- PICK DATE ---------------- */

  Future<void> pickDate() async {

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  /* ---------------- PICK MONTH ---------------- */

  Future<void> pickMonth() async {

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: "Select Month",
    );

    if (date != null) {
      setState(() {
        selectedMonth = DateTime(date.year, date.month);
      });
    }
  }

  /* ---------------- REPORT BUTTON ---------------- */

  Widget reportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {

    return InkWell(

      borderRadius: BorderRadius.circular(12),

      onTap: isDownloading ? null : onTap,

      child: Container(

        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),

        padding: const EdgeInsets.all(12),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(icon, color: color),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Attendance Records"),
      ),

      body: Column(
        children: [

          /* ---------------- REPORT DASHBOARD ---------------- */

          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [

                  const Text(
                    "Download Reports",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  GridView.count(

                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),

                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.4,

                    children: [

                      reportButton(
                        icon: Icons.picture_as_pdf,
                        label: "Session Report",
                        color: Colors.blue,
                        onTap: downloadSessionReport,
                      ),

                      reportButton(
                        icon: Icons.person_off,
                        label: "Absentees Report",
                        color: Colors.red,
                        onTap: downloadAbsenteesReport,
                      ),

                      reportButton(
                        icon: Icons.calendar_today,
                        label: "Select Day",
                        color: Colors.orange,
                        onTap: pickDate,
                      ),

                      reportButton(
                        icon: Icons.download,
                        label: "Day Report",
                        color: Colors.green,
                        onTap: downloadDayReport,
                      ),

                      reportButton(
                        icon: Icons.calendar_month,
                        label: "Select Month",
                        color: Colors.deepPurple,
                        onTap: pickMonth,
                      ),

                      reportButton(
                        icon: Icons.file_download,
                        label: "Month Report",
                        color: Colors.teal,
                        onTap: downloadMonthReport,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /* ---------------- SESSION DETAILS ---------------- */

          FutureBuilder<DocumentSnapshot>(

            future: FirebaseFirestore.instance
                .collection('sessions')
                .doc(widget.sessionId)
                .get(),

            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final data =
                  snapshot.data!.data() as Map<String, dynamic>;

              final subject = data['subject'] ?? "--";
              final faculty = data['facultyName'] ?? "--";

              return Card(

                margin: const EdgeInsets.symmetric(horizontal: 16),

                elevation: 3,

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [

                      const Text(
                        "Session Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          const Icon(Icons.book, size: 18),
                          const SizedBox(width: 6),

                          Text("Subject : $subject"),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 6),

                          Text("Faculty : $faculty"),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          /* ---------------- ATTENDANCE LIST ---------------- */

          Expanded(

            child: StreamBuilder<QuerySnapshot>(

              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .doc(widget.sessionId)
                  .collection('attendance')
                  .orderBy('timestamp')
                  .snapshots(),

              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {

                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {

                  return const Center(
                    child: Text(
                      "No attendance records yet",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ListView.builder(

                  padding: const EdgeInsets.symmetric(horizontal: 12),

                  itemCount: docs.length,

                  itemBuilder: (context, index) {

                    final data =
                        docs[index].data() as Map<String, dynamic>;

                    final Timestamp? ts = data['timestamp'];

                    final timeString = ts != null
                        ? ts
                            .toDate()
                            .toLocal()
                            .toString()
                            .substring(11, 19)
                        : "--";

                    return Card(

                      elevation: 2,

                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),

                      child: ListTile(

                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),

                        title: Text(
                          data['name'] ?? "Unknown",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          "Roll No : ${data['rollNo'] ?? "--"}",
                        ),

                        trailing: Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}