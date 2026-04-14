import 'package:intl/intl.dart';
import 'package:smart_health_home_kit/utils/logger.dart';
import '../models/health_data.dart';
import '../utils/constants.dart';

class Helper {
  // تنسيق التاريخ والوقت
  static String formatDate(DateTime date, {String? locale}) {
    return DateFormat('yyyy-MM-dd – HH:mm', locale).format(date);
  }


  static String formatDisplayText(HealthData data) {
    final t = data.type.toLowerCase();

    // BP
    if (t == DataTypes.bp || t == 'bp' || t == 'bloodpressure' || t == 'blood_pressure' || t == 'bloodpressure') {
      final sys = data.extra?['systolic'] ?? data.systolic ?? "-" ;
      final dia = data.extra?['diastolic'] ?? data.diastolic ?? '-';
      final pulse = data.extra?['pulse'] ?? data.pulse ?? '-';
      return "BP: $sys/$dia mmHg | Pulse: $pulse bpm";
    }

    // Glucose
    if (t == DataTypes.glucose || t == 'glucose' || t == 'gl') {
      final val = data.extra?['glucose'] ?? data.glucose ?? data.value;
      return "Glucose: $val mg/dL";
    }

    // Temp
    if (t == DataTypes.temp || t == 'temp' || t == 'thermometer' || t == 'temperature') {
      final val = data.extra?['temperature'] ?? data.temperature ?? data.value;
      return "Temp: $val °C";
    }

    // fallback generic
    return "${data.type} - ${data.value}";
  }

  static bool isBloodPressureAbnormal(HealthData data) {
    // قراءة القيود من Constants.bpThresholds
    final bpMap = Constants.bpThresholds[DataTypes.bp];
    if (bpMap == null) return false;

    final sysRange = bpMap['bp_systolic'];
    final diaRange = bpMap['bp_diastolic'];
    if (sysRange == null || diaRange == null) return false;

    final sys = data.systolic ?? 0;   // لو null نخلي قيمة بعيدة
    final dia = data.diastolic ?? 0;

    final bool systolicOut = sys < (sysRange['min'] ?? double.negativeInfinity) ||
        sys > (sysRange['max'] ?? double.infinity);
    final bool diastolicOut = dia < (diaRange['min'] ?? double.negativeInfinity) ||
        dia > (diaRange['max'] ?? double.infinity);

    AppLogger.logInfo("Helper.isBloodPressureAbnormal -> sys=$sys, dia=$dia, sysRange=$sysRange, diaRange=$diaRange, result=${systolicOut||diastolicOut}");
    return systolicOut || diastolicOut;
  }

  static bool isGlucoseAbnormal(HealthData data) {
    final range = Constants.alertThresholds[DataTypes.glucose];
    if (range == null) return false;
    final val = (data.glucose ?? data.value).toDouble();
    return val < (range['min'] ?? double.negativeInfinity) || val > (range['max'] ?? double.infinity);
  }

  static bool isTemperatureAbnormal(HealthData data) {
    final range = Constants.alertThresholds[DataTypes.temp];
    if (range == null) return false;
    final val = (data.temperature ?? data.value).toDouble();
    return val < (range['min'] ?? double.negativeInfinity) || val > (range['max'] ?? double.infinity);
  }






  static int getSystolic(double value) => (value ~/ 1000);

  static int getDiastolic(double value) => ((value % 1000) ~/ 10);

  static int getPulse(double value) => (value % 10).toInt();





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
      case DataTypes.bp:
        final bp = parseBloodPressure(value);
        return formatBloodPressure(bp['systolic']!, bp['diastolic']!);
      case DataTypes.glucose:
        return formatGlucose(value);
      case DataTypes.temp:
        return formatTemperature(value);
      default:
        return value.toString();
    }
  }



  // التحقق من النطاق حسب النوع
  static bool isOutOfRangeByType(
      String type,
      double value,
      Map<String, dynamic> thresholds, {
        HealthData? data,
      }) {
    if (type == DataTypes.bp) {
      if (data == null) return false;

      final bpRanges = thresholds[DataTypes.bp];
      if (bpRanges == null) return false;

      final sysRange = bpRanges['bp_systolic'] ;
      final diaRange = bpRanges['bp_diastolic'];

      final sys = data.systolic ?? 0;
      final dia = data.diastolic ?? 0;

      final systolicOut =
          sys < (sysRange['min'] ?? 0) || sys > (sysRange['max'] ?? double.infinity);

      final diastolicOut =
          dia < (diaRange['min'] ?? 0) || dia > (diaRange['max'] ?? double.infinity);

      AppLogger.logInfo("SYS=${data.systolic}, DIA=${data.diastolic}, sysRange=$sysRange, diaRange=$diaRange, result=${systolicOut || diastolicOut}");

      return systolicOut || diastolicOut;
    }

    // باقي الأنواع (سكر، حرارة)
    if (!thresholds.containsKey(type)) return false;

    final range = thresholds[type] as Map<String, double>;
    final min = range['min'] ?? 0;
    final max = range['max'] ?? double.infinity;

    return value < min || value > max;


  }



  static bool isNormalBP(HealthData d) {
    final sys = d.systolic ?? 0;
    final dia = d.diastolic ?? 0;
    return sys >= 90 && sys <= 120 && dia >= 60 && dia <= 80;
  }

  static bool isHighBP(HealthData d) {
    final sys = d.systolic ?? 0;
    final dia = d.diastolic ?? 0;
    return sys > 130 || dia > 90;
  }

  static bool isLowBP(HealthData d) {
    final sys = d.systolic ?? 0;
    final dia = d.diastolic ?? 0;
    return sys < 90 || dia < 60;
  }


  static bool isNormalTemp(HealthData d) {
    if (d.type != DataTypes.temp) return false;
    final value = (d.value as num).toDouble();
    return value >= 36.1 && value <= 37.5; // النطاق الطبيعي
  }

  static bool isHighTemp(HealthData d) {
    if (d.type != DataTypes.temp) return false;
    final value = (d.value as num).toDouble();
    return value > 37.5;
  }

  static bool isLowTemp(HealthData d) {
    if (d.type != DataTypes.temp) return false;
    final value = (d.value as num).toDouble();
    return value < 36.1;
  }

  static String formatTemp(num value) {
    return "${value.toStringAsFixed(1)} °C";
  }


}
