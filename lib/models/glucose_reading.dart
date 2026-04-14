// lib/models/glucose_reading.dart
class GlucoseReading {
  final int glucose; // mg/dL (raw)
  final String unit; // "mg/dL" أو "mmol/L"
  final DateTime datetime; // وقت القياس من الجهاز (أو الوقت الحالي لو مش موجود)
  final String source; // device type / name
  final Map<String, dynamic>? raw; // optional raw map for debugging

  GlucoseReading({
    required this.glucose,
    required this.unit,
    required this.datetime,
    required this.source,
    this.raw,
  });

  factory GlucoseReading.fromMap(Map<String, dynamic> map) {
    // مرونة في قراءة الحقول (value/glucose; unit/units; datetime/datetime)
    final dynamic maybeValue = map['value'] ?? map['glucose'] ?? map['glucoseValue'];
    final int value = (maybeValue is int) ? maybeValue : int.tryParse('${maybeValue ?? 0}') ?? 0;

    final String unit = (map['unit'] ?? map['units'] ?? 'mg/dL') as String;

    DateTime datetime;
    final dtStr = map['datetime'] ?? map['datetime_iso'] ?? map['datetimeString'];
    if (dtStr is String) {
      datetime = DateTime.tryParse(dtStr) ?? DateTime.now();
    } else {
      datetime = DateTime.now();
    }

    final source = (map['device'] ?? map['source'] ?? 'glucose').toString();

    return GlucoseReading(
      glucose: value,
      unit: unit,
      datetime: datetime,
      source: source,
      raw: Map<String, dynamic>.from(map),
    );
  }

  /// convenience: return mmol/L approx (if unit in mg/dL)
  double get mmolL {
    if (unit.toLowerCase().contains('mg')) {
      return glucose.toDouble() / 18.0;
    }
    // assume already mmol/L
    return glucose.toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'value': glucose,
      'unit': unit,
      'datetime': datetime.toIso8601String(),
      'source': source,
    };
  }
}
