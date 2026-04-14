import 'dart:typed_data';
import 'dart:math';
import 'package:smart_health_home_kit/utils/device_type.dart';
import '../utils/logger.dart';
import '../models/health_data.dart';

class DataParser {
  static Map<String, dynamic> parse(
      Uint8List data, {
        DeviceType? deviceType,
      }) {
    final result = {
      "type": deviceType ?? DeviceType.unknown,
      "raw": data,
      "timestamp": DateTime.now().toIso8601String(),
    };

    switch (deviceType) {
      case DeviceType.bloodPressure:
        final bpData = _parseBloodPressure(data);
        if (bpData != null) {
          return {
            "type": DeviceType.bloodPressure,
            "healthData": bpData,
            "systolic": bpData.systolic,
            "diastolic": bpData.diastolic,
            "pulse": bpData.pulse,
            "raw": data,
            "timestamp": bpData.timestamp.toIso8601String(),
          };
        }
        break;


      case DeviceType.glucose:
        final glucoseData = _parseGlucose(data.toList());
        if (glucoseData != null) {
          result.addAll({
            "glucose": glucoseData.value,
            "unit": glucoseData.unit,
          });
        }
        break;

      case DeviceType.thermometer:
        final tempData = _parseThermometer(data.toList());
        if (tempData != null) {
          result.addAll({
            "temperature": tempData["temperature"],
            "unit": tempData["unit"],
          });
        }
        break;

      default:
        AppLogger.logInfo("⚠️ Unknown device type, raw saved only.");
    }

    return result;
  }


  // ------------------ Parsers ------------------

  static HealthData? _parseBloodPressure(Uint8List data) {
    if (data.length == 12) {
      int systolic = data[2] | (data[3] << 8);
      int diastolic = data[4] | (data[5] << 8);
      int pulse = data[8] | (data[9] << 8);

      AppLogger.logInfo("🩺 BP Parsed → SYS=$systolic, DIA=$diastolic, PULSE=$pulse");

      return HealthData.fromBloodPressureValues(
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        datetime: DateTime.now(),
        source: "bloodPressure",
      );
    }
    return null;
  }


  static HealthData? _parseGlucose(List<int> rawData) {
    if (rawData.isEmpty || rawData[0] != 0x55) return null;

    // Example parsing for Samico GL
    if (rawData.length >= 12 && rawData[2] == 0x03) {
      int glucose = rawData[9] | (rawData[10] << 8);

      return HealthData(
        type: "glucose",
        value: glucose.toDouble(),
        unit: "mg/dL",
        timestamp: DateTime.now(),
      );
    }
    return null;
  }

  static Map<String, dynamic>? _parseThermometer(List<int> data) {
    if (data.length < 5) return null;

    int flags = data[0];
    int mantissa = (data[1] | (data[2] << 8) | (data[3] << 16));
    int exponent = data[4];
    if (exponent > 127) exponent -= 256; // signed int8

    if (mantissa & 0x800000 != 0) {
      mantissa = mantissa - 0x1000000; // signed 24-bit
    }

    num rawValue = mantissa * pow(10, exponent);
    double value = rawValue.toDouble();


    AppLogger.logInfo("🌡 Flags: $flags, Mantissa: $mantissa, Exponent: $exponent, Temp: $value");


    return {
      "temperature": value,
      "unit": (flags & 0x01) == 0 ? "°C" : "°F",
      "type": DeviceType.thermometer,
    };
  }


}









