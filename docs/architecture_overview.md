# System Architecture Overview

## High-Level Architecture

The Smart Attendance System follows a distributed mobile architecture with a centralized cloud backend.

Student App ─┐
├── Firebase (Auth + Firestore + Storage)
Teacher App ─┘

---

## Student Application Flow
1. Student registers and enrolls face images
2. Student logs into the application
3. App scans for teacher’s BLE beacon
4. If beacon is detected, camera opens
5. Live face verification is performed
6. Attendance is submitted to Firebase

---

## Teacher Application Flow
1. Teacher logs into the application
2. Teacher creates an attendance session
3. BLE beacon broadcasts the session ID
4. Attendance session is closed after class
5. Attendance data is viewed from Firebase

---

## Communication Mechanism

| Component | Purpose |
|--------|--------|
| BLE | Ensures student is physically present |
| Firebase Auth | User authentication |
| Firestore | Attendance and session storage |
| Firebase Storage | Face image storage |

---

## Security Considerations
- Face images are stored securely in Firebase Storage
- Passwords are managed by Firebase Authentication
- Attendance is validated using both BLE and face recognition

---

## Scalability
- Supports multiple classes and sessions
- Cloud-based backend allows real-time updates
- Modular design enables future enhancements

