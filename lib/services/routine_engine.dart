import '../models/user_profile.dart';
import '../models/health_data.dart';
import '../models/routine_task.dart';
import '../utils/constants.dart';

class RoutineEngine {
  /// 🧠 الدالة الرئيسية لتوليد الروتين
  static List<RoutineTask> generateRoutine(UserProfile user, List<HealthData> history) {
    List<RoutineTask> routine = [];
    final now = DateTime.now();
    
    // فلترة التاريخ لآخر 3 أيام فقط للتحليل الذكي والتركيز على الحالة الحالية
    final recentHistory = history.where((h) => 
      h.timestamp.isAfter(now.subtract(const Duration(days: 3)))
    ).toList();

    // 1️⃣ مهام الترطيب (أساسية للجميع)
    _addHydrationTasks(routine);

    // 2️⃣ مهام النشاط البدني (تعتمد على العمر)
    _addExerciseTasks(routine, user);

    // 3️⃣ مهام المراقبة الذكية (تعتمد على الفجوات في البيانات أو القراءات المقلقة)
    _addMonitoringTasks(routine, user, recentHistory);

    // 4️⃣ مهام التغذية (تعتمد على نمط الشخصية)
    _addNutritionTasks(routine, user);

    // 5️⃣ مهام الصحة النفسية والنوم
    _addMentalHealthTasks(routine);

    return routine;
  }

  // 💧 وظائف شرب الماء
  static void _addHydrationTasks(List<RoutineTask> routine) {
    routine.add(RoutineTask(
      title: "كوب الماء الصباحي",
      description: "اشرب كوباً كبيراً من الماء فور الاستيقاظ لتنشيط أعضاء جسمك.",
      time: "07:00 AM",
      category: "Nutrition",
    ));
    
    routine.add(RoutineTask(
      title: "كوب ماء قبل النوم",
      description: "يساعد في تجنب الجفاف وتحسين جودة النوم.",
      time: "10:00 PM",
      category: "Nutrition",
    ));
  }

  // 🏃 وظائف التمارين الرياضية
  static void _addExerciseTasks(List<RoutineTask> routine, UserProfile user) {
    if (user.age < 50) {
      routine.add(RoutineTask(
        title: "تمرين نشط (Cardio)",
        description: "مشي سريع أو جري خفيف لمدة 20 دقيقة لتقوية عضلة القلب.",
        time: "05:00 PM",
        category: "Exercise",
      ));
    } else {
      routine.add(RoutineTask(
        title: "تمارين إطالة وليونة",
        description: "تمارين خفيفة لتحسين مرونة المفاصل وتجنب التيبس.",
        time: "08:30 AM",
        category: "Exercise",
      ));
    }
  }

  // 🩺 وظائف المراقبة الطبية الذكية
  static void _addMonitoringTasks(List<RoutineTask> routine, UserProfile user, List<HealthData> recentHistory) {
    // 🔍 ذكاء مراقبة الضغط:
    // لو مفيش قراءات في آخر 3 أيام، أو آخر قراءة كانت عالية (> 135)
    bool needsBPCheck = recentHistory.where((h) => h.type == DataTypes.bp).isEmpty ||
                        recentHistory.any((h) => h.type == DataTypes.bp && (h.systolic ?? 0) > 135);
    
    if (needsBPCheck) {
      routine.add(RoutineTask(
        title: "فحص ضغط الدم",
        description: "متابعة الضغط ضرورية اليوم لضمان استقرار حالتك الصحية.",
        time: "09:00 AM",
        category: "Monitoring",
      ));
    }

    // 🔍 ذكاء مراقبة السكري:
    if (user.conditions.any((c) => c.toLowerCase().contains("diabetes") || c.contains("سكري"))) {
      routine.add(RoutineTask(
        title: "قياس السكر الصائم",
        description: "تأكد من مستوى السكر في الدم قبل تناول وجبة الإفطار.",
        time: "07:15 AM",
        category: "Monitoring",
      ));
    }
  }

  // 🥗 وظائف التغذية المتخصصة
  static void _addNutritionTasks(List<RoutineTask> routine, UserProfile user) {
    if (user.personality == PersonalityType.strict) {
      routine.add(RoutineTask(
        title: "تحضير وجبة صحية متكاملة",
        description: "احرص على توازن البروتين والألياف وتقليل الكربوهيدرات.",
        time: "02:00 PM",
        category: "Nutrition",
      ));
    } else {
      routine.add(RoutineTask(
        title: "وجبة خفيفة من الفواكه",
        description: "استبدل السكريات الصناعية بقطعة فاكهة موسمية.",
        time: "04:00 PM",
        category: "Nutrition",
      ));
    }
  }

  // 🧘 وظائف الصحة النفسية
  static void _addMentalHealthTasks(List<RoutineTask> routine) {
    routine.add(RoutineTask(
      title: "تخلص من المشتتات الرقمية",
      description: "اترك هاتفك قبل النوم بـ 30 دقيقة لتحسين هرمون النوم (الميلاتونين).",
      time: "10:30 PM",
      category: "Mental Health",
    ));
    
    routine.add(RoutineTask(
      title: "تمرين تنفس عميق",
      description: "5 دقائق من التنفس العميق كفيلة بتقليل مستويات التوتر.",
      time: "09:00 PM",
      category: "Mental Health",
    ));
  }
}
