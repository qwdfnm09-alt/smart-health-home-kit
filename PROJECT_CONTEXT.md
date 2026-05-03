# Smart Health Kit App

## 📌 Project Overview
This is a Flutter-based Smart Health Monitoring system that connects to medical devices via BLE and provides real-time health tracking for users.

The system is designed to be modular, scalable, and production-ready.

---

## 🏗️ Architecture
The project follows a modular architecture:

- devices/ → Hardware device implementations (BLE medical devices)
- services/ → Core logic (BLE, Storage, PDF, Alerts)
- models/ → Data models (HealthData, UserProfile, etc.)
- screens/ → UI screens
- utils/ → Helpers, constants, logger

---

## 📡 Core Features

### 1. BLE Integration
- Connect to medical devices via Bluetooth Low Energy
- Supported devices:
    - Glucose Meter
    - Blood Pressure Monitor
    - Thermometer
- Each device has its own class under /devices

---

### 2. Data Storage
- Local storage using Hive
- Stores:
    - User profile
    - Health readings
    - History for the active profile

---

### 3. Data Visualization
- Charts using fl_chart
- Shows trends for:
    - Blood pressure
    - Glucose levels
    - Temperature

---

### 4. PDF Reports
- Generates medical reports for doctors
- Includes:
    - User info
    - Latest readings
    - Health summary

---

### 5. Alerts System
- Detects abnormal values
- Uses predefined thresholds
- Sends in-app alerts

---

## 👤 User System
- Single active user profile
- The profile includes:
    - Age, gender, and conditions
    - Personal health history

---

## 🧠 Smart Features (Planned)
- Rule-based health advice system
- Daily routine generator
- Personality-based recommendations (strict / balanced / relaxed)

---

## 🔐 Data & Security
- Encrypted local storage for Hive data
- Local-first storage for health records
- AI requests may send user-selected text or images to Google Gemini
- Technical crash reports may be sent to Firebase Crashlytics

---

## 📱 Target Devices
- Android (primary)
- iOS (future support)

---

## ⚙️ Development Rules
- Keep code modular
- No logic inside UI screens
- Each BLE device must extend SmartDevice class
- BLE service must handle all communication
- Avoid duplicate logic

---

## 🚀 How Codex should use this file
Always read this file first before making changes to understand:
- Project structure
- Architecture rules
- Device system
- Feature scope
