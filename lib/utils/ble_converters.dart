import '../models/health_data.dart';
import '../utils/constants.dart';


class BleConverters {
  // ---------------- Glucose ----------------
  static HealthData? toGlucoseHealth(Map<String, dynamic> m) {
    if (!m.containsKey("glucose")) return null;

    return HealthData(
      type: "glucose",
      value: (m["glucose"] ?? 0).toDouble(),
      unit: m["unit"] ?? "mg/dL",
      timestamp: DateTime.tryParse(m["timestamp"].toString()) ?? DateTime.now(),
      extra: {
        "glucose": (m["glucose"] ?? 0).toDouble(),
      },
    );
  }

  // ---------------- Thermometer ----------------
  static HealthData? toThermometerHealth(Map<String, dynamic> m) {
    if (!m.containsKey("temperature")) return null;

    return HealthData(
      type: DataTypes.temp,
      value: (m["temperature"] ?? 0).toDouble(),
      unit: m["unit"] ?? "°C",
      timestamp: DateTime.tryParse(m["timestamp"].toString()) ?? DateTime.now(),
      extra: {
        "temperature": (m["temperature"] ?? 0).toDouble(),
      },
    );
  }

  // ---------------- Blood Pressure ----------------
  static HealthData? toBloodPressureHealth(Map<String, dynamic> m) {
    if (!m.containsKey("systolic") || !m.containsKey("diastolic")) return null;

    return HealthData(
      type: DataTypes.bp,
      value: (m["systolic"] ?? 0).toDouble(), // نستخدم الـ sys كـ value
      unit: "mmHg",
      timestamp: DateTime.tryParse(m["timestamp"].toString()) ?? DateTime.now(),
      extra: {
        "systolic": (m["systolic"] ?? 0).toDouble(),
        "diastolic": (m["diastolic"] ?? 0).toDouble(),
        "pulse": (m["pulse"] ?? 0).toDouble(),
      },
    );
  }
}
