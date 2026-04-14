import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../models/health_advice.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class AdviceEngine {
  /// 🧠 الدالة الرئيسية لجلب النصائح الذكية
  static List<HealthAdvice> getAdvice({
    required HealthData data,
    required UserProfile profile,
    List<HealthData> history = const [], // أضفنا التاريخ للتحليل المستقبلي
  }) {
    AppLogger.logInfo("🧠 AdviceEngine: Processing '${data.type}' for ${profile.name}");
    List<HealthAdvice> adviceList = [];

    switch (data.type) {
      case DataTypes.glucose:
        adviceList.addAll(_glucoseAdvice(data, profile, history));
        break;
      case DataTypes.temp:
        adviceList.addAll(_tempAdvice(data, profile));
        break;
      case DataTypes.bp:
        adviceList.addAll(_bpAdvice(data, profile, history));
        break;
    }

    return adviceList;
  }

  // ---------------- 🩸 Glucose (Diabetes Intelligence) ----------------
  static List<HealthAdvice> _glucoseAdvice(HealthData data, UserProfile profile, List<HealthData> history) {
    List<HealthAdvice> list = [];
    final value = data.value;
    final isDiabetic = profile.conditions.any((c) => c.toLowerCase().contains("diabetes") || c.contains("سكري"));

    // 🚨 حالة الطوارئ (Hyperglycemia Crisis)
    if (value > 300) {
      list.add(_buildAdvice(
        id: 'gl_emergency_${data.timestamp.millisecondsSinceEpoch}',
        title: '⚠️ تحذير: مستوى سكر حرج',
        description: "مستوى السكر مرتفع جدًا بشكل خطر. اشرب الكثير من الماء فورًا، وتجنب أي نشاط بدني عنيف، واتصل بطبيبك أو توجه لأقرب طوارئ إذا شعرت بغثيان أو ضيق تنفس.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    } 
    // 📉 حالة هبوط السكر (Hypoglycemia)
    else if (value < 70) {
      list.add(_buildAdvice(
        id: 'gl_low_${data.timestamp.millisecondsSinceEpoch}',
        title: '📉 تنبيه: هبوط السكر',
        description: _tone(profile,
          strict: "تناول 15 جرامًا من السكريات السريعة (نصف كوب عصير) فورًا وأعد القياس بعد 15 دقيقة. لا تهمل هذا التنبيه.",
          balanced: "سكرك منخفض. تناول قطعة حلوى أو عصير وانتظر قليلاً، ثم تناول وجبة خفيفة.",
          relaxed: "سكرك واطي شوية، خد حاجة مسكرة بسرعة وريح جسمك.",
        ),
        category: AdviceCategory.food,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    }
    // ✅ المستوى الطبيعي أو المرتفع قليلاً
    else {
      // إذا كان مريض سكر، نكون أكثر حذراً (140 كحد أقصى بدل 180)
      double threshold = isDiabetic ? 140 : 180;
      bool isHigh = value > threshold;

      String desc = isHigh 
          ? (isDiabetic ? "مستوى السكر مرتفع بالنسبة لمريض سكر. تأكد من جرعة الدواء والمشي قليلاً." : "مستوى السكر مرتفع قليلاً. حاول المشي وشرب الماء.")
          : "مستوى السكر ممتاز ومستقر. استمر في اتباع نظامك الغذائي الحالي.";
      
      list.add(_buildAdvice(
        id: 'gl_normal_${data.timestamp.millisecondsSinceEpoch}',
        title: isHigh ? 'ارتفاع يحتاج متابعة' : 'مستوى سكر مستقر',
        description: _tone(profile,
          strict: "التزم بالحمية الغذائية بدقة. $desc",
          balanced: "نتائج جيدة بشكل عام. $desc",
          relaxed: "كله تمام، خلي بالك بس من الأكل الجاي. $desc",
        ),
        category: isHigh ? AdviceCategory.activity : AdviceCategory.lifestyle,
        priority: isHigh ? AdvicePriority.medium : AdvicePriority.low,
        risk: isHigh ? AdviceRisk.caution : AdviceRisk.normal,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    }
    return list;
  }

  // ---------------- 🌡️ Temperature Intelligence ----------------
  static List<HealthAdvice> _tempAdvice(HealthData data, UserProfile profile) {
    List<HealthAdvice> list = [];
    final temp = data.value;

    if (temp >= 38.5) {
      list.add(_buildAdvice(
        id: 'temp_high_${data.timestamp.millisecondsSinceEpoch}',
        title: '🌡️ تنبيه: حمى مرتفعة',
        description: "حرارتك مرتفعة. استخدم كمدات ماء فاتر (ليس باردًا)، واشرب الكثير من السوائل، وإذا لم تنخفض الحرارة خلال ساعات، استشر الطبيب.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.temp,
      ));
    } else if (temp <= 35.5) {
      list.add(_buildAdvice(
        id: 'temp_low_${data.timestamp.millisecondsSinceEpoch}',
        title: '❄️ تنبيه: انخفاض حرارة',
        description: "درجة حرارة جسمك منخفضة. ارتدِ ملابس دافئة واشرب مشروبًا ساخنًا. لو استمر الانخفاض مع شعور بالرجفة، يرجى استشارة مختص.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.medium,
        risk: AdviceRisk.caution,
        measurementTime: data.timestamp,
        type: DataTypes.temp,
      ));
    } else {
      list.add(_buildAdvice(
        id: 'temp_ok_${data.timestamp.millisecondsSinceEpoch}',
        title: 'حرارة طبيعية',
        description: "حرارة جسمك مثالية (36.5 - 37.2). حافظ على روتينك اليومي.",
        category: AdviceCategory.lifestyle,
        priority: AdvicePriority.low,
        risk: AdviceRisk.normal,
        measurementTime: data.timestamp,
        type: DataTypes.temp,
      ));
    }
    return list;
  }

  // ---------------- 💓 Blood Pressure Intelligence ----------------
  static List<HealthAdvice> _bpAdvice(HealthData data, UserProfile profile, List<HealthData> history) {
    List<HealthAdvice> list = [];
    final sys = data.systolic ?? 0;
    final dia = data.diastolic ?? 0;

    // 🚨 أزمة ضغط (Hypertensive Crisis)
    if (sys >= 180 || dia >= 120) {
      list.add(_buildAdvice(
        id: 'bp_crisis_${data.timestamp.millisecondsSinceEpoch}',
        title: '🛑 حالة طارئة: ضغط حرج',
        description: "ضغط الدم وصل لمستوى حرج جدًا. اجلس بهدوء، تنفس ببطء، ولا تحاول بذل أي مجهود. إذا شعرت بألم في الصدر أو صداع شديد، توجه للطوارئ فورًا.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    } 
    // 📈 ضغط مرتفع (Hypertension)
    else if (sys >= 140 || dia >= 90) {
      String advice = "ضغطك مرتفع قليلاً. حاول تقليل الملح في الطعام، وتجنب التوتر والكافيين، وراقب القياس مرة أخرى بعد ساعة من الراحة.";
      if (profile.age > 65) advice += " (بالنسبة لعمرك، هذا الارتفاع يحتاج لمتابعة دقيقة مع طبيبك).";

      list.add(_buildAdvice(
        id: 'bp_high_${data.timestamp.millisecondsSinceEpoch}',
        title: '📈 ضغط مرتفع',
        description: _tone(profile,
          strict: "يجب الالتزام بتقليل الصوديوم فورًا والمتابعة. $advice",
          balanced: "حاول الاسترخاء وتقليل الأملاح. $advice",
          relaxed: "خفف الملح شوية في أكلك النهاردة وارتاح. $advice",
        ),
        category: AdviceCategory.warning,
        priority: AdvicePriority.medium,
        risk: AdviceRisk.caution,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    }
    // ✅ ضغط طبيعي
    else {
      list.add(_buildAdvice(
        id: 'bp_ok_${data.timestamp.millisecondsSinceEpoch}',
        title: 'ضغط دم مثالي',
        description: "ضغطك في النطاق الصحي (120/80). استمر في ممارسة الرياضة الخفيفة والحفاظ على وزن صحي.",
        category: AdviceCategory.lifestyle,
        priority: AdvicePriority.low,
        risk: AdviceRisk.normal,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    }
    return list;
  }

  // ---------------- 🛠️ Helper Methods ----------------

  static String _tone(UserProfile profile, {required String strict, required String balanced, required String relaxed}) {
    switch (profile.personality) {
      case PersonalityType.strict: return strict;
      case PersonalityType.relaxed: return relaxed;
      case PersonalityType.balanced: return balanced;
    }
  }

  static HealthAdvice _buildAdvice({
    required String id,
    required String title,
    required String description,
    required AdviceCategory category,
    required AdvicePriority priority,
    required DateTime measurementTime,
    required AdviceRisk risk,
    required String type,
  }) {
    return HealthAdvice(
      id: id, title: title, description: description,
      category: category, priority: priority,
      measurementTime: measurementTime, risk: risk, type: type,
    );
  }
}
