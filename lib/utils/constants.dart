import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0D47A1);
  static const secondary = Color(0xFF1976D2);
  static const background = Color(0xFFF5F5F5);
  static const alertHigh = Colors.redAccent;
  static const alertLow = Colors.orangeAccent;
}

class DeviceTypes {
  static const glucose = 'glucose';
  static const bloodPressure = 'blood_pressure';
  static const temperature = 'temperature'; //統一 بدل thermometer
}

class AppStrings {
  static const appName = 'Smart Health Kit';
  static const developer = 'Developed by Elsayed said';
}

class Constants {
  static const String appWebsiteUrl = 'https://yourwebsite.com';
  static const String supportEmail = 'support@yourapp.com';
  static const String appName = 'Smart Health Kit';

  /// ✅ حدود التنبيهات (متوافقة مع Helper)
  static const Map<String, Map<String, double>> alertThresholds = {
    DeviceTypes.glucose: {
      'min': 70,
      'max': 180,
    },
    DeviceTypes.temperature: {
      'min': 36.0,
      'max': 37.5,
    },
    'blood_pressure_systolic': {
      'min': 90,// أقل من كده يعتبر انخفاض ضغط
      'max': 120,// أعلى من كده يعتبر ارتفاع ضغط
    },
    'blood_pressure_diastolic': {
      'min': 60,// أقل من كده يعتبر انخفاض
      'max': 80,// أعلى من كده يعتبر ارتفاع
    },
  };


}
