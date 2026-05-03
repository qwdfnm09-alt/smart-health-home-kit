# 🏥 Smart Health Home Kit

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com)

A comprehensive, modular Flutter application designed for **real-time health monitoring** and **smart medical device integration** via Bluetooth Low Energy (BLE).

---

## 🌟 Key Features

### 📡 Medical Device Integration (BLE)
Seamlessly connect and sync data from various medical devices:
- 🩸 **Glucose Meter**: Track blood sugar levels accurately.
- 🩺 **Blood Pressure Monitor**: Monitor systolic, diastolic, and pulse.
- 🌡️ **Thermometer**: Record and track body temperature trends.
- *Built on a scalable architecture allowing for easy device expansion.*

### 📊 Data Visualization & Insights
- Interactive charts showing health trends over time (using `fl_chart`).
- Historical data tracking for the active user profile.
- Smart analysis of readings to detect abnormal values.

### 🧠 AI-Powered Health Advice
- Intelligent health advisor that provides personalized recommendations.
- Daily routine generator based on health status and user personality.
- Smart alerts and notifications for critical health readings.

### 📄 Professional Medical Reports
- Generate detailed PDF reports of health data.
- Perfect for sharing with doctors or keeping personal medical records.

### 👤 User Profile
- Single active profile with personalized health history and settings.
- Local-first storage using **Hive** for speed and privacy.

---

## 🏗️ Architecture & Tech Stack

This project follows a **Modular Architecture** for maximum scalability and maintainability:

- **Frontend:** [Flutter](https://flutter.dev) (Dart)
- **Local Database:** [Hive](https://pub.dev/packages/hive) (NoSQL, high performance)
- **BLE Communication:** [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)
- **PDF Generation:** [pdf](https://pub.dev/packages/pdf)
- **State Management:** Provider / Clean Logic Separation
- **Backend (Optional):** Firebase Integration

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- A physical device with Bluetooth (for BLE features)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/qwdfnm09-alt/smart-health-home-kit.git
   ```
2. Navigate to the project directory:
   ```bash
   cd smart-health-home-kit
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## 📁 Project Structure
```text
lib/
├── devices/    # Hardware device logic (BLE)
├── services/   # Core engines (BLE, Storage, PDF, Alerts)
├── models/     # Data entities and adapters
├── screens/    # UI Layer
├── utils/      # Helpers and constants
└── l10n/       # Localization (AR/EN support)
```

---

## 🌍 Localization
The app supports both **Arabic** and **English** out of the box, with a focus on RTL layout compatibility.

---

## 🛡️ Privacy & Security
- Health data and profile data are stored **locally** on the device by default.
- Encrypted local storage is used for app data.
- AI requests may send user-selected text or images to Google Gemini.
- Technical crash reports may be sent to Firebase Crashlytics to improve stability.
- PDF and WhatsApp sharing happen only when initiated by the user.

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
