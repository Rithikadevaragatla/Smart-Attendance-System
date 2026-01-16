# Smart Attendance System

## Overview
The Smart Attendance System is a mobile-based attendance solution designed to prevent proxy attendance using modern technologies such as Bluetooth Low Energy (BLE), Face Recognition, and Firebase.

The system is divided into two independent mobile applications:
- Student Application
- Teacher Application

Both applications communicate indirectly through a shared Firebase backend.

---

## Key Features
- Secure login using Firebase Authentication
- BLE-based session detection to ensure physical presence
- Face recognition-based student verification
- Real-time attendance recording
- Cloud-based data storage using Firebase

---

## Applications

### Student Application
- Student login and registration
- Face enrollment during registration
- Detects teacher’s BLE beacon
- Performs live face verification
- Submits attendance to Firebase

### Teacher Application
- Teacher login
- Creates attendance sessions
- Broadcasts BLE beacon with session ID
- Views real-time attendance reports

---

## Technologies Used
- Flutter (Mobile App Development)
- Firebase Authentication
- Firebase Firestore
- Firebase Storage
- Bluetooth Low Energy (BLE)
- TensorFlow Lite / MediaPipe (for face recognition)

---

## Team Collaboration
Both applications are developed in parallel by different team members and integrated through a common Firebase backend and predefined data contracts.

