// lib/utils/ble_converters.dart
import '../models/glucose_reading.dart';


class BleConverters {
  static GlucoseReading toGlucose(Map<String, dynamic> m) => GlucoseReading.fromMap(m);

// ستكمل الباقي لاحقًا:
// static BloodPressureReading toBp(Map<String, dynamic> m) => BloodPressureReading.fromMap(m);
// static TemperatureReading toTemp(Map<String, dynamic> m) => TemperatureReading.fromMap(m);
}
