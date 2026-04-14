import 'package:hive/hive.dart';

part 'health_alert.g.dart';

@HiveType(typeId: 2)
class HealthAlert extends HiveObject {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final String type; // مثلاً "ضغط", "حرارة", "سكر"

  @HiveField(2)
  final DateTime timestamp;

  HealthAlert({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}
