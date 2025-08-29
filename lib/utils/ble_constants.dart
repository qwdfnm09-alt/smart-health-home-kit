// lib/utils/ble_constants.dart
class BleConstants {
  // ========= Glucose (Samico GL) =========
  static const String glucoseService = "0000fff0-0000-1000-8000-00805f9b34fb";
  static const String glucoseWriteChar = "0000fff1-0000-1000-8000-00805f9b34fb";
  static const String glucoseNotifyChar = "0000fff4-0000-1000-8000-00805f9b34fb";

  // ========= Thermometer (Health Thermometer Service) =========
  static const String thermoService = "00001809-0000-1000-8000-00805f9b34fb";
  static const String thermoTempMeasurementChar = "00002a1c-0000-1000-8000-00805f9b34fb"; // Temperature Measurement
  // Read
  static const String intermediateTemperatureChar = "00002a1e-0000-1000-8000-00805f9b34fb"; // Notify
  static const String measurementIntervalChar = "00002a21-0000-1000-8000-00805f9b34fb"; // Read/Write/Indicate



  // ========= Blood Pressure (B180) =========
  static const String bpmService = "0000fff0-0000-1000-8000-00805f9b34fb";
  static const String bpmNotifyChar = "0000fff4-0000-1000-8000-00805f9b34fb";
  static const String bpmWriteChar = "0000fff3-0000-1000-8000-00805f9b34fb";

  // ------- اختياري: aliases عشان ما يحصلش لخبطة أسماء -------
  static const String bloodPressureService = bpmService;
  static const String bloodPressureNotifyChar = bpmNotifyChar;
  static const String bloodPressureWriteChar = bpmWriteChar;
}

