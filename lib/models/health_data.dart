import 'package:hive/hive.dart';
import 'glucose_reading.dart'; // استورد الموديل الجديد

part 'health_data.g.dart';

@HiveType(typeId: 0)
class HealthData extends HiveObject {
  @HiveField(0)
  final String type; // "bp", "glucose", "temp"

  @HiveField(1)
  final double value;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String unit;

  @HiveField(4)
  final String source;

  HealthData({
    required this.type,
    required this.value,
    required this.timestamp,
    this.unit = "",
    this.source = "",
  });

  /// ✅ Factory لتحويل GlucoseReading -> HealthData
  factory HealthData.fromGlucose(GlucoseReading g) {
    return HealthData(
      type: "glucose",
      value: g.value.toDouble(),
      timestamp: g.datetime,
      unit: g.unit,
      source: g.source,
    );
  }
}
