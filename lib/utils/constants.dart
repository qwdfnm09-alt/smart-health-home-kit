import 'package:flutter/material.dart';
import 'device_type.dart';

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

class DataTypes {
  static const String bp = "bloodPressure";
  static const String glucose = "glucose";
  static const String temp = "temp";
}



class DeviceConstants {
  // نربط الاسم الظاهر لكل جهاز بالنوع
  static const Map<String, DeviceType> deviceNameToType = {
    "BPM": DeviceType.bloodPressure,       // جهاز الضغط
    "Samico GL": DeviceType.glucose,         // جهاز السكر
    "TEMP": DeviceType.thermometer,       // جهاز الحرارة
  };
}




class Constants {
  static const String appWebsiteUrl = 'https://smarthealth-eg.framer.website/';
  static const String supportEmail = 'https://docs.google.com/forms/d/e/1FAIpQLSdNAejGDWOW_hFHh2rUyzHLiXQKwp6P0uVJ0gqRxK281sRksA/viewform';
  static const String appName = 'Smart Health Kit';
  static const String tmedDoctorPhone = '2001203939070';


  /// ✅ حدود التنبيهات (متوافقة مع Helper)
  ///  لباقي الأنواع (سكر، حرارة)
  static const Map<String, Map<String, double>> alertThresholds = {
    DataTypes.glucose: {"min": 70.0, "max": 200.0},
    DataTypes.temp: {"min": 36.0, "max": 37.5},
    'pulse': {"min": 60.0, "max": 100.0},
  };
  // حدود الضغط (مبنية كـ خريطة بمفتاح واحد DataTypes.bp)
  static const Map<String, Map<String, Map<String, double>>> bpThresholds = {
    DataTypes.bp: {
      "bp_systolic": {"min": 90.0, "max": 140.0},
      "bp_diastolic": {"min": 60.0, "max": 90.0},
    }
  };

}
