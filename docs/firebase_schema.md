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

