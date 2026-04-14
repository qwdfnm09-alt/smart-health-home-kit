import 'package:hive/hive.dart';

part 'routine_task.g.dart';

 @HiveType(typeId: 15)
 class RoutineTask extends HiveObject {
    @HiveField(0)
    final String title;

     @HiveField(1)
     final String description;

    @HiveField(2)
     final String time;

     @HiveField(3)
     bool isCompleted;

     @HiveField(4)
     final String category;

     @HiveField(5)
     final String type; // manual, ai

   RoutineTask({
      required this.title,
      required this.description,
      required this.time,
      this.isCompleted = false,
      required this.category,
      this.type = 'manual', // قيمة افتراضية تضمن عمل الـ Adapter مع البيانات القديمة
    });
   }