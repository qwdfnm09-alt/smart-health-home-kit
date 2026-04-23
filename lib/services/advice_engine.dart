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
    List<HealthData> history = const [],
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

  // ---------------- 🩸 Glucose ----------------
  static List<HealthAdvice> _glucoseAdvice(HealthData data, UserProfile profile, List<HealthData> history) {
    List<HealthAdvice> list = [];
    // التأكد من جلب القيمة الصحيحة
    final double glucoseValue = (data.glucose?.toDouble()) ?? data.value;
    final range = Constants.alertThresholds[DataTypes.glucose]!;

    if (glucoseValue > 300) {
      list.add(_buildAdvice(
        id: 'gl_emergency_${data.timestamp.millisecondsSinceEpoch}',
        title: '⚠️ تحذير: سكر حرج',
        description: "مستوى السكر مرتفع جداً ($glucoseValue). اتصل بطبيبك فوراً.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    } else if (glucoseValue > range["max"]!) {
      list.add(_buildAdvice(
        id: 'gl_high_${data.timestamp.millisecondsSinceEpoch}',
        title: '📈 سكر مرتفع',
        description: "سكرك ($glucoseValue) أعلى من المعدل. قلل السكريات وامشِ قليلاً.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.medium,
        risk: AdviceRisk.caution,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    } else if (glucoseValue < range["min"]!) {
      list.add(_buildAdvice(
        id: 'gl_low_${data.timestamp.millisecondsSinceEpoch}',
        title: '📉 هبوط سكر',
        description: "سكرك منخفض ($glucoseValue). تناول عصير أو عسل فوراً.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    } else {
      list.add(_buildAdvice(
        id: 'gl_ok_${data.timestamp.millisecondsSinceEpoch}',
        title: 'مستوى سكر مستقر',
        description: "سكرك ($glucoseValue) في النطاق الطبيعي. حافظ على نظامك.",
        category: AdviceCategory.lifestyle,
        priority: AdvicePriority.low,
        risk: AdviceRisk.normal,
        measurementTime: data.timestamp,
        type: DataTypes.glucose,
      ));
    }
    return list;
  }

  // ---------------- 🌡️ Temperature ----------------
  static List<HealthAdvice> _tempAdvice(HealthData data, UserProfile profile) {
    List<HealthAdvice> list = [];
    // التعديل الجوهري: استخدام الحقل المخصص أولاً
    final double tempValue = data.temperature ?? data.value;
    final range = Constants.alertThresholds[DataTypes.temp]!;

    if (tempValue >= 38.5) {
      list.add(_buildAdvice(
        id: 'temp_high_v_${data.timestamp.millisecondsSinceEpoch}',
        title: '🌡️ تنبيه: حمى مرتفعة',
        description: "حرارتك مرتفعة جداً ($tempValue). استخدم كمدات واستشر طبيب.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.temp,
      ));
    } else if (tempValue > range["max"]!) {
      list.add(_buildAdvice(
        id: 'temp_caution_${data.timestamp.millisecondsSinceEpoch}',
        title: '🌡️ ارتفاع طفيف في الحرارة',
        description: "حرارتك ($tempValue) أعلى من المعدل الطبيعي. اشرب سوائل وراقبها.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.medium,
        risk: AdviceRisk.caution,
        measurementTime: data.timestamp,
        type: DataTypes.temp,
      ));
    } else if (tempValue < range["min"]!) {
      list.add(_buildAdvice(
        id: 'temp_low_${data.timestamp.millisecondsSinceEpoch}',
        title: '❄️ تنبيه: انخفاض حرارة',
        description: "حرارة جسمك منخفضة ($tempValue). تدفأ جيداً.",
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
        description: "حرارة جسمك ($tempValue) مثالية.",
        category: AdviceCategory.lifestyle,
        priority: AdvicePriority.low,
        risk: AdviceRisk.normal,
        measurementTime: data.timestamp,
        type: DataTypes.temp,
      ));
    }
    return list;
  }

  // ---------------- 💓 Blood Pressure ----------------
  static List<HealthAdvice> _bpAdvice(HealthData data, UserProfile profile, List<HealthData> history) {
    List<HealthAdvice> list = [];
    final int sys = data.systolic ?? data.value.toInt();
    final int dia = data.diastolic ?? 0;
    
    final bpRange = Constants.bpThresholds[DataTypes.bp]!["bp_systolic"]!;
    final diaRange = Constants.bpThresholds[DataTypes.bp]!["bp_diastolic"]!;

    if (sys >= 180 || dia >= 120) {
      list.add(_buildAdvice(
        id: 'bp_crisis_${data.timestamp.millisecondsSinceEpoch}',
        title: '🛑 حالة طارئة: ضغط حرج',
        description: "ضغطك في مستوى خطر ($sys/$dia). اطلب مساعدة طبية فوراً.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.high,
        risk: AdviceRisk.danger,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    } else if (sys > bpRange["max"]! || dia > diaRange["max"]!) {
      list.add(_buildAdvice(
        id: 'bp_high_${data.timestamp.millisecondsSinceEpoch}',
        title: '📈 ضغط مرتفع',
        description: "ضغطك مرتفع ($sys/$dia). قلل الأملاح وارتح قليلاً.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.medium,
        risk: AdviceRisk.caution,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    } else if ((sys < bpRange["min"]! && sys > 0) || (dia < diaRange["min"]! && dia > 0)) {
      list.add(_buildAdvice(
        id: 'bp_low_${data.timestamp.millisecondsSinceEpoch}',
        title: '📉 ضغط منخفض',
        description: "ضغطك منخفض ($sys/$dia). اشرب سوائل كافية.",
        category: AdviceCategory.warning,
        priority: AdvicePriority.medium,
        risk: AdviceRisk.caution,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    } else {
      list.add(_buildAdvice(
        id: 'bp_ok_${data.timestamp.millisecondsSinceEpoch}',
        title: 'ضغط دم مثالي',
        description: "ضغطك ($sys/$dia) في النطاق الصحي.",
        category: AdviceCategory.lifestyle,
        priority: AdvicePriority.low,
        risk: AdviceRisk.normal,
        measurementTime: data.timestamp,
        type: DataTypes.bp,
      ));
    }
    return list;
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
