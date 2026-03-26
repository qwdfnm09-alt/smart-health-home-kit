import 'package:hive/hive.dart';

part 'health_advice.g.dart';

enum AdviceCategory { food, activity, measurement, lifestyle, warning }
enum AdvicePriority { low, medium, high }
enum AdviceRisk {
  normal,    // طبيعي
  caution,   // محتاج متابعة
  danger,    // خطر حقيقي
}

@HiveType(typeId: 10)
class HealthAdvice {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final AdviceCategory category;

  @HiveField(4)
  final AdvicePriority priority;

  @HiveField(5)
  final DateTime measurementTime; // ✅ وقت القياس

  @HiveField(6)
  final AdviceRisk risk;

  @HiveField(7)
  final String type;


  HealthAdvice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.measurementTime,
    required this.risk,
    required this.type, // ✅ الجديد
  });
}