import 'package:hive/hive.dart';
import 'package:smart_health_home_kit/models/blood_pressure_reading.dart';
import 'package:smart_health_home_kit/models/glucose_reading.dart';
import 'package:smart_health_home_kit/models/thermometer_reading.dart';
import '../utils/constants.dart';


part 'health_data.g.dart';

@HiveType(typeId: 0)
class HealthData extends HiveObject {
  @HiveField(0)
  final String type; // "bp", "glucose", "temp"

  @HiveField(1)
  final double value; // main value (sys for bp, glucose value, temperature)

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String unit;

  @HiveField(4)
  final String source;

  // ---------------- Specific Fields ----------------
  @HiveField(5)
  final int? systolic;

  @HiveField(6)
  final int? diastolic;

  @HiveField(7)
  final int? pulse;

  @HiveField(8)
  final double? temperature;

  @HiveField(9)
  final int? glucose;

  @HiveField(10)
  Map<String, dynamic>? extra;


  HealthData({
    required this.type,
    required this.value,
    required this.timestamp,
    this.unit = "",
    this.source = "",
    this.systolic,
    this.diastolic,
    this.pulse,
    this.temperature,
    this.glucose,
    this.extra,   // ✅ أضفناها
  });


  HealthData copyWith({
    String? type,
    double? value,
    String? unit,
    DateTime? timestamp,
    String? source,
    int? systolic,
    int? diastolic,
    int? pulse,
    double? temperature,
    int? glucose,
    Map<String, dynamic>? extra,
  }) {
    return HealthData(
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      temperature: temperature ?? this.temperature,
      glucose: glucose ?? this.glucose,
      extra: extra ?? this.extra,
    );
  }


  // ---------------- Factories ----------------

  /// ✅ GlucoseReading -> HealthData
  factory HealthData.fromGlucose(GlucoseReading g) {
    return HealthData(
      type: "glucose",
      value: g.glucose.toDouble(),
      glucose: g.glucose,
      timestamp: g.datetime,
      unit: "mg/dL",
      source: g.source,

    );
  }

  factory HealthData.fromThermometer(ThermometerReading t) {
    return HealthData(
      type: "temp",
      value: t.temperature,
      temperature: t.temperature,
      timestamp: t.datetime,
      unit: "°C",
      source: t.source,

    );
  }


  /// ✅ BloodPressureReading -> HealthData
  factory HealthData.fromBloodPressure(BloodPressureReading bp) {
    return HealthData(
      type: DataTypes.bp,
      value: bp.systolic.toDouble(),
      timestamp: bp.datetime,
      unit: "mmHg",
      source: bp.source,
      systolic: bp.systolic,
      diastolic: bp.diastolic,
      pulse: bp.pulse,
    );
  }

  /// Factory مباشر للـ Glucose من القيم
  factory HealthData.fromGlucoseValues({
    required int glucose,
    required DateTime datetime,
    String source = "glucose",
  }) {
    return HealthData(
      type: "glucose",
      value: glucose.toDouble(),
      glucose: glucose,
      timestamp: datetime,
      unit: "mg/dL",
      source: source,
    );
  }

  /// Factory مباشر للـ Thermometer من القيم
  factory HealthData.fromThermometerValues({
    required double temperature,
    required DateTime datetime,
    String source = "thermometer",
  }) {
    return HealthData(
      type: "temp",
      value: temperature,
      temperature: temperature,
      timestamp: datetime,
      unit: "°C",
      source: source,
    );
  }

  /// Factory مباشر للـ Blood Pressure من القيم
  factory HealthData.fromBloodPressureValues({
    required int systolic,
    required int diastolic,
    required int pulse,
    required DateTime datetime,
    String source = "bloodPressure",
  }) {
    return HealthData(
      type: DataTypes.bp,
      value: systolic.toDouble(),
      timestamp: datetime,
      unit: "mmHg",
      source: source,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
    );
  }


}
