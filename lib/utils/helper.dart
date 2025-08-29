import 'package:intl/intl.dart';
import '../models/health_data.dart';



class Helper {
  // تنسيق التاريخ والوقت
  static String formatDate(DateTime date, {String? locale}) {
    return DateFormat('yyyy-MM-dd – HH:mm', locale).format(date);
  }

  static List<HealthData> getOutOfRangeReadings(
      List<HealthData> readings,
      Map<String, Map<String, double>> thresholds,
      ) {
    return readings.where(
          (d) => isOutOfRangeByType(d.type, d.value, thresholds),
    ).toList();
  }

  static String getOutOfRangeMessage(String type, double value, DateTime date) {
    return "• ${formatValueByType(type, value)} (${formatDate(date)}) خارج النطاق";
  }


  // التحقق من إذا كانت القيمة خارج النطاق
  static bool isValueOutOfRange(double value, double min, double max) {
    return value < min || value > max;
  }

  // تنسيق ضغط الدم كسلسلة نصية
  static String formatBloodPressure(int systolic, int diastolic) {
    return "$systolic/$diastolic mmHg";
  }

  // تقسيم قيمة ضغط الدم المخزنة (مثلاً 12080 → 120/80)
  static Map<String, int> parseBloodPressure(double value) {
    final intValue = value.toInt();
    if (intValue < 100) { // قيمة مش صحيحة
      return {'systolic': 0, 'diastolic': 0};
    }
    return {
      'systolic': intValue ~/ 100,
      'diastolic': intValue % 100,
    };
  }

  // تنسيق قيمة السكر
  static String formatGlucose(double value) {
    return "${value.toStringAsFixed(1)} mg/dL";
  }

  // تنسيق درجة الحرارة
  static String formatTemperature(double value) {
    return "${value.toStringAsFixed(1)} °C";
  }

  // تنسيق القيمة حسب النوع
  static String formatValueByType(String? type, double? value) {
    if (type == null || value == null) return "-";

    switch (type) {
      case 'blood_pressure':
        final bp = parseBloodPressure(value);
        return formatBloodPressure(bp['systolic']!, bp['diastolic']!);
      case 'glucose':
        return formatGlucose(value);
      case 'temperature':
        return formatTemperature(value);
      default:
        return value.toString();
    }
  }


  // التحقق من النطاق حسب النوع
  static bool isOutOfRangeByType(
      String type,
      double value,
      Map<String, Map<String, double>> thresholds,
      ) {
    if (type == 'blood_pressure') {
      if (!thresholds.containsKey('blood_pressure_systolic') ||
          !thresholds.containsKey('blood_pressure_diastolic')) {
        return false;
      }

      final bp = parseBloodPressure(value);
      final systolic = bp['systolic']!;
      final diastolic = bp['diastolic']!;

      final sys = thresholds['blood_pressure_systolic']!;
      final dia = thresholds['blood_pressure_diastolic']!;

      return isValueOutOfRange(systolic.toDouble(), sys['min']!, sys['max']!) ||
          isValueOutOfRange(diastolic.toDouble(), dia['min']!, dia['max']!);
    }

    if (!thresholds.containsKey(type)) return false;

    final min = thresholds[type]!['min']!;
    final max = thresholds[type]!['max']!;
    return isValueOutOfRange(value, min, max);
  }
  static bool isNormalBP(HealthData d) {
    final v = d.value as Map;
    return v['sys'] >= 90 && v['sys'] <= 120 && v['dia'] >= 60 && v['dia'] <= 80;
  }

  static bool isHighBP(HealthData d) {
    final v = d.value as Map;
    return v['sys'] > 130 || v['dia'] > 90;
  }

  static bool isLowBP(HealthData d) {
    final v = d.value as Map;
    return v['sys'] < 90 || v['dia'] < 60;
  }

  static bool isNormalTemp(HealthData d) {
    if (d.type != 'temperature') return false;
    final value = (d.value as num).toDouble();
    return value >= 36.1 && value <= 37.5; // النطاق الطبيعي
  }

  static bool isHighTemp(HealthData d) {
    if (d.type != 'temperature') return false;
    final value = (d.value as num).toDouble();
    return value > 37.5;
  }

  static bool isLowTemp(HealthData d) {
    if (d.type != 'temperature') return false;
    final value = (d.value as num).toDouble();
    return value < 36.1;
  }

  static String formatTemp(num value) {
    return "${value.toStringAsFixed(1)} °C";
  }


}
