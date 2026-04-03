# 🚀 SmartMark – Smart Attendance System

## 📌 Overview
**SmartMark** is an intelligent, mobile-based attendance system that eliminates proxy attendance using a hybrid approach of **BLE proximity detection + Facial Recognition + Cloud Analytics**.

The system ensures that a student is **physically present AND identity-verified**, making attendance secure, automated, and reliable.

---

## 🎯 Problem Solved
Traditional attendance systems are:
- ❌ Time-consuming  
- ❌ Prone to proxy attendance  
- ❌ Dependent on hardware (RFID/Biometrics)  
- ❌ Lack real-time insights  

👉 **SmartMark solves all these with a fully automated, secure solution.**

---

## 💡 Key Features

### 🔐 Secure Authentication
- Firebase Authentication for students & teachers

### 📡 BLE-Based Presence Detection
- Teacher broadcasts BLE signal  
- Detects nearby student devices automatically  

### 📸 Face Recognition Verification
- Validates student identity  
- Prevents proxy attendance  

### ⚡ Real-Time Attendance Tracking
- Instant marking of attendance  
- Live session updates  

### 📊 Smart Analytics Dashboard
- View attendance insights  
- Calculate attendance percentage  

### 📄 Excel Report Generation
- Day-wise & range-based reports  
- Downloadable attendance sheets  

### 🚨 Low Attendance Alert System
- Detects students below threshold  
- Sends automated email alerts to parents  

---

## 📱 Applications

### 👨‍🏫 Teacher Application
- Start/End attendance sessions  
- Broadcast BLE signals  
- View attendance analytics  
- Generate reports (Excel)  
- Send alerts for low attendance  

---

### 👩‍🎓 Student Application
- Register & login securely  
- Face enrollment during onboarding  
- Detect BLE session automatically  
- Perform face verification  
- Submit attendance  

---

## 🏗️ System Architecture

```mermaid
flowchart TD
    A[Teacher App] --> B[BLE Communication]
    B --> C[Student App]
    C --> D[Face Recognition]
    D --> E[Firebase Backend]
    E --> F[Analytics & Reports]
    F --> G[Low Attendance Alerts]

---

## ⚙️ Technologies Used

| Category | Technology |
|----------|------------|
| Mobile Development | Flutter |
| Backend | Firebase Firestore |
| Authentication | Firebase Auth |
| Storage | Firebase Storage |
| Communication | Bluetooth Low Energy (BLE) |
| AI/ML | TensorFlow Lite / MediaPipe |
| Reporting | Excel (Dart Package) |
| Notifications | EmailJS |

---

## 🔥 Unique Selling Points (USP)

- ✅ Dual Verification (BLE + Face Recognition)  
- ✅ Fully Automated Attendance System  
- ✅ No Extra Hardware Required  
- ✅ Real-Time Analytics & Insights  
- ✅ Parent Notification System  
- ✅ Scalable Cloud-Based Architecture  

---

## 👥 Team Collaboration
This project was developed collaboratively with:
- Separate **Student & Teacher apps**
- Integrated via a **shared Firebase backend**
- Structured using **modular architecture**

---

## 🚀 Future Enhancements
- 📍 GPS-based validation for location accuracy  
- 📊 Advanced AI analytics & predictions  
- 📱 Push notifications integration  
- 🧠 Liveness detection for face recognition  
- 🌐 Web dashboard for admin  

---

## 🏁 Conclusion
SmartMark transforms traditional attendance into a **secure, intelligent, and automated system**, ensuring accuracy, efficiency, and transparency in educational institutions.
