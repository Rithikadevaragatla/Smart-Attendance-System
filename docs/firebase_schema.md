# Firebase Database Schema

This document describes the structure of the Firebase backend used by the Smart Attendance System.

---

## Firebase Services Used
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

---

## Authentication
Firebase Authentication is used to manage user login and registration using Email and Password.

Passwords are securely handled by Firebase and are never stored manually in Firestore.

---

## Firestore Collections

### 1. students
Stores registered student information.
students (collection)
└── studentId (document)
├── name: String
├── rollNo: String
├── email: String
├── faceImages: List<String>
├── createdAt: Timestamp

---

### 2. teachers
Stores teacher information.
eachers (collection)
└── teacherId (document)
├── name: String
├── employeeId: String
├── email: String
├── createdAt: Timestamp


---

### 3. sessions
Stores active attendance sessions created by teachers.

sessions (collection)
└── sessionId (document)
├── teacherId: String
├── startTime: Timestamp
├── isActive: Boolean

---

### 4. attendance
Stores attendance records submitted by students.

attendance (collection)
└── recordId (document)
├── studentId: String
├── sessionId: String
├── timestamp: Timestamp
├── status: String (Present / Late / Absent)

---

## Firebase Storage Structure

storage
└── students
└── studentId
├── face_front.jpg
├── face_left.jpg
└── face_right.jpg


Face images are uploaded only during student registration and are used for face recognition during attendance verification.

