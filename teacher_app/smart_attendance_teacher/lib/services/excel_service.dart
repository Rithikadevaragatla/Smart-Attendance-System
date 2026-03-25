import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelService {

  /* ---------------- SESSION REPORT ---------------- */

  static Future<void> generateSessionReport({
    required String sessionId,
  }) async {

    final firestore = FirebaseFirestore.instance;

    final sessionDoc =
        await firestore.collection('sessions').doc(sessionId).get();

    final sessionData = sessionDoc.data()!;

    final subject = sessionData['subject'];
    final faculty = sessionData['facultyName'];
    final DateTime date = (sessionData['date'] as Timestamp).toDate();

    final department = sessionData['department'] ?? "";
    final year = sessionData['year'] ?? 0;
    final section = sessionData['section'] ?? "";

    final attendanceSnapshot = await firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('attendance')
        .get();

    final attendanceDocs = attendanceSnapshot.docs;

    final studentsSnapshot = await firestore
        .collection('students')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    final totalStudents = studentsSnapshot.docs.length;
    final present = attendanceDocs.length;
    final absent = totalStudents - present;

    await _buildExcel(
      fileName: "Session_Report",
      subject: subject,
      faculty: faculty,
      date: date,
      attendanceDocs: attendanceDocs,
      totalStudents: totalStudents,
      present: present,
      absent: absent,
      department: department,
      year: year.toString(),
      section: section,
    );
  }

  /* ---------------- ABSENTEES REPORT ---------------- */

  static Future<void> generateAbsenteesReport({
    required String sessionId,
  }) async {

    final firestore = FirebaseFirestore.instance;

    final sessionDoc =
        await firestore.collection('sessions').doc(sessionId).get();

    final sessionData = sessionDoc.data()!;

    final subject = sessionData['subject'];
    final faculty = sessionData['facultyName'];
    final DateTime date = (sessionData['date'] as Timestamp).toDate();

    final department = sessionData['department'] ?? "";
    final year = sessionData['year'] ?? 0;
    final section = sessionData['section'] ?? "";

    final attendanceSnapshot = await firestore
        .collection('sessions')
        .doc(sessionId)
        .collection('attendance')
        .get();

    final presentRollNos = attendanceSnapshot.docs
        .map((doc) => doc['rollNo'])
        .toSet();

    final studentsSnapshot = await firestore
        .collection('students')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    final absentees = studentsSnapshot.docs.where((student) {
      final data = student.data();
      return !presentRollNos.contains(data['rollNo']);
    }).toList();

    final totalStudents = studentsSnapshot.docs.length;
    final present = presentRollNos.length;
    final absent = absentees.length;

    await _buildExcel(
      fileName: "Absentees_Report",
      subject: subject,
      faculty: faculty,
      date: date,
      attendanceDocs: absentees,
      totalStudents: totalStudents,
      present: present,
      absent: absent,
      isAbsentees: true,
      department: department,
      year: year.toString(),
      section: section,
    );
  }

  /* ---------------- DAY REPORT (FIXED) ---------------- */

  static Future<void> generateDayReport({
    required DateTime date,
    required String department,
    required int year,
    required String section,
  }) async {

    final firestore = FirebaseFirestore.instance;

    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final sessionsSnapshot = await firestore
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    List<QueryDocumentSnapshot> attendanceDocs = [];

    for (var session in sessionsSnapshot.docs) {
      final snapshot = await firestore
          .collection('sessions')
          .doc(session.id)
          .collection('attendance')
          .get();

      attendanceDocs.addAll(snapshot.docs);
    }

    final studentsSnapshot = await firestore
        .collection('students')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    final totalStudents = studentsSnapshot.docs.length;
    final present = attendanceDocs.length;
    final absent = totalStudents - present;

    await _buildExcel(
      fileName: "Day_Report",
      subject: "Multiple Subjects",
      faculty: "Multiple Faculty",
      date: date,
      attendanceDocs: attendanceDocs,
      totalStudents: totalStudents,
      present: present,
      absent: absent,
      department: department,
      year: year.toString(),
      section: section,
    );
  }

  /* ---------------- MONTH REPORT (FIXED) ---------------- */

  static Future<void> generateMonthReport({
    required DateTime month,
    required String department,
    required int year,
    required String section,
  }) async {

    final firestore = FirebaseFirestore.instance;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59);

    final sessionsSnapshot = await firestore
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    List<QueryDocumentSnapshot> attendanceDocs = [];

    for (var session in sessionsSnapshot.docs) {
      final snapshot = await firestore
          .collection('sessions')
          .doc(session.id)
          .collection('attendance')
          .get();

      attendanceDocs.addAll(snapshot.docs);
    }

    final studentsSnapshot = await firestore
        .collection('students')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year)
        .where('section', isEqualTo: section)
        .get();

    final totalStudents = studentsSnapshot.docs.length;
    final present = attendanceDocs.length;
    final absent = totalStudents - present;

    await _buildExcel(
      fileName: "Month_Report",
      subject: "Multiple Subjects",
      faculty: "Multiple Faculty",
      date: month,
      attendanceDocs: attendanceDocs,
      totalStudents: totalStudents,
      present: present,
      absent: absent,
      department: department,
      year: year.toString(),
      section: section,
    );
  }

  /* ---------------- COMMON EXCEL BUILDER ---------------- */

  static Future<void> _buildExcel({
    required String fileName,
    required String subject,
    required String faculty,
    required DateTime date,
    required List attendanceDocs,
    required int totalStudents,
    required int present,
    required int absent,
    required String department,
    required String year,
    required String section,
    bool isAbsentees = false,
  }) async {

    final excel = Excel.createExcel();
    final sheet = excel['Attendance'];

    sheet.appendRow([
      "GEETHANJALI COLLEGE OF ENGINEERING AND TECHNOLOGY"
    ]);

    sheet.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("C1"));

    sheet.appendRow([
      isAbsentees ? "Absentees Report" : "Attendance Report"
    ]);

    sheet.merge(CellIndex.indexByString("A2"), CellIndex.indexByString("C2"));

    sheet.appendRow([]);

    sheet.appendRow(["Faculty", faculty]);
    sheet.appendRow(["Subject", subject]);
    sheet.appendRow(["Department", department]);
    sheet.appendRow(["Year", year]);
    sheet.appendRow(["Section", section]);

    sheet.appendRow([
      "Date",
      "${date.day}-${date.month}-${date.year}"
    ]);

    sheet.appendRow([]);

    sheet.appendRow(["Total Students", totalStudents]);
    sheet.appendRow(["Present", present]);
    sheet.appendRow(["Absent", absent]);

    sheet.appendRow([]);

    if (isAbsentees) {
      sheet.appendRow(["Roll No", "Student Name"]);
    } else {
      sheet.appendRow(["Roll No", "Student Name", "Time"]);
    }

    for (var doc in attendanceDocs) {

      final data = doc.data();

      if (isAbsentees) {

        sheet.appendRow([
          data['rollNo'] ?? "",
          data['name'] ?? "",
        ]);

      } else {

        final Timestamp? ts = data['timestamp'];

        final timeString = ts != null
            ? ts.toDate().toLocal().toString().substring(11, 19)
            : "--";

        sheet.appendRow([
          data['rollNo'] ?? "",
          data['name'] ?? "",
          timeString,
        ]);
      }
    }

    sheet.setColWidth(0, 18);
    sheet.setColWidth(1, 30);
    sheet.setColWidth(2, 18);

    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        "${directory.path}/${fileName}_${date.day}-${date.month}-${date.year}.xlsx";

    final fileBytes = excel.save();

    if (fileBytes != null) {
      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await OpenFilex.open(file.path);
    }
  }
}