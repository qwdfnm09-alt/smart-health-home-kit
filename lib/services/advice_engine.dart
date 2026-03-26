import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../models/health_advice.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class AdviceEngine {
  static List<HealthAdvice> getAdvice({
    required HealthData data,
    required UserProfile profile,
  }) {
    AppLogger.logInfo("🔥 ENTER AdviceEngine, type = '${data.type}'");
    List<HealthAdvice> adviceList = [];
    switch (data.type) {
      case DataTypes.glucose:
        adviceList.addAll(_glucoseAdvice(data, profile));
        break;
      case DataTypes.temp:
        adviceList.addAll(_tempAdvice(data, profile));
        break;
      case DataTypes.bp:
        adviceList.addAll(_bpAdvice(data, profile));
        break;
    }

    return adviceList;
  }

  // ---------------- Glucose ----------------
  static List<HealthAdvice> _glucoseAdvice(HealthData data, UserProfile profile) {
    List<HealthAdvice> list = [];
    final min = Constants.alertThresholds[DataTypes.glucose]!['min']!;
    final max = Constants.alertThresholds[DataTypes.glucose]!['max']!;
    final value = data.value;

    if (value < min) {
      list.add(
          _buildAdvice(
        id: 'glucose_low_${data.timestamp.millisecondsSinceEpoch}',
        title: 'مستوى السكر منخفض',
        description: _tone(
          profile,
          strict: 'انخفاض السكر خطر. تناول مصدر سكر فورًا وأعد القياس خلال 15 دقيقة.',
          balanced: 'السكر منخفض، تناول وجبة خفيفة وأعد القياس قريبًا.',
          relaxed: 'السكر واطي شوية، كل حاجة مسكرة بسيطة واطمّن.',
        ),
        category: AdviceCategory.food,
        priority: _glucosePriority(value),
            risk: _glucoseRisk(value),
        measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.glucose, // أو bp أو temp

      ));
    } else if (value > 250)  {
      // خطر حقيقي
      list.add(
          _buildAdvice(
            id: 'glucose_high_${data.timestamp.millisecondsSinceEpoch}',
            title: 'مستوى السكر مرتفع جدا',
            description: _tone(
              profile,
              strict: 'يجب تقليل السكريات فورًا والمشي 15 دقيقة بعد الأكل.',
              balanced: 'حاول تقليل السكريات السريعة والمشي قليلًا بعد الوجبة.',
              relaxed: 'خفّف الحلويات النهارده ومشية خفيفة هتبقى كويسة.',
            ),
            category: AdviceCategory.food,
            priority: _glucosePriority(value),
            risk: _glucoseRisk(value),
            measurementTime: data.timestamp, //
            type: DataTypes.glucose,// ✅ الوقت الصحيح لكل نصيحة
          ));
    } else if (value > max)  {
      // ارتفاع متوسط
      list.add(
          _buildAdvice(
            id: 'glucose_high_${data.timestamp.millisecondsSinceEpoch}',
            title: 'مستوى السكر مرتفع',
            description: _tone(
              profile,
              strict: 'يجب تقليل السكريات فورًا والمشي 15 دقيقة بعد الأكل.',
              balanced: 'حاول تقليل السكريات السريعة والمشي قليلًا بعد الوجبة.',
              relaxed: 'خفّف الحلويات النهارده ومشية خفيفة هتبقى كويسة.',
            ),
            category: AdviceCategory.food,
            priority: _glucosePriority(value),
            risk: _glucoseRisk(value),
            measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.glucose,
          ));
    } else {
      list.add(
          _buildAdvice(
        id: 'glucose_normal_${data.timestamp.millisecondsSinceEpoch}',
        title: 'مستوى السكر طبيعي',
        description: _tone(
          profile,
          strict: 'السكر في المعدل الطبيعي. استمر على نظامك والتزم بمواعيد القياس.',
          balanced: 'مستوى السكر طبيعي، كمل على نفس النظام.',
          relaxed: 'تمام 👍 السكر مظبوط، كمل زي ما إنت.',
        ),
        category: AdviceCategory.lifestyle,
        priority: _glucosePriority(value),
            risk: _glucoseRisk(value),
        measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.glucose,
      ));
    }
    return list;
  }
  static AdvicePriority _glucosePriority(double value) {
    if (value < 70) return AdvicePriority.high;   // هبوط خطر
    if (value > 250) return AdvicePriority.high;  // ارتفاع خطر
    if (value > 180) return AdvicePriority.medium;
    return AdvicePriority.low;
  }
  static AdviceRisk _glucoseRisk(double value) {
    if (value < 70) return AdviceRisk.danger;
    if (value > 250) return AdviceRisk.danger;
    if (value > 180) return AdviceRisk.caution;
    return AdviceRisk.normal;
  }



  // ---------------- Temperature ----------------
  static List<HealthAdvice> _tempAdvice(HealthData data, UserProfile profile) {
    List<HealthAdvice> list = [];
    final min = Constants.alertThresholds[DataTypes.temp]!['min']!;
    final max = Constants.alertThresholds[DataTypes.temp]!['max']!;
    final value = data.value;

    if (value < min) {
      list.add(
          _buildAdvice(
        id:'temp_low_${data.timestamp.millisecondsSinceEpoch}',
        title: 'درجة الحرارة منخفضة',
        description: _tone(
          profile,
          strict: 'درجة الحرارة منخفضة. حافظ على التدفئة وراقب الأعراض.',
          balanced: 'حاول تدفي نفسك وراقب الحرارة.',
          relaxed: 'إدفى شوية وخليك متابع الحرارة.',
        ),
        category: AdviceCategory.warning,
        priority: _tempPriority(value),
        risk: _tempRisk(value),

        measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.temp,
      ));
    } else if (value > max) {
      list.add(
          _buildAdvice(
        id: 'temp_high_${data.timestamp.millisecondsSinceEpoch}',
        title: 'حمى خفيفة',
        description: _tone(
          profile,
          strict: 'لو استمرت الحرارة أكتر من 24 ساعة يجب استشارة طبيب.',
          balanced: 'راقب الحرارة واشرب سوائل ولو استمرت تابع مع طبيب.',
          relaxed: 'اشرب مية كتير وارتاح شوية، ولو طولت تابعها.',
        ),
        category: AdviceCategory.warning,
        priority: _tempPriority(value),
        risk: _tempRisk(value),
        measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.temp,
      ));
    } else {
      list.add(
          _buildAdvice(
        id: 'temp_normal_${data.timestamp.millisecondsSinceEpoch}',
        title: 'درجة الحرارة طبيعية',
        description: _tone(
          profile,
          strict: 'درجة الحرارة طبيعية. استمر على روتينك المعتاد.',
          balanced: 'حرارتك طبيعية، مفيش قلق.',
          relaxed: 'كله تمام 👍 حرارتك مظبوطة.',
        ),
        category: AdviceCategory.lifestyle,
        priority: _tempPriority(value),
        risk: _tempRisk(value),
        measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.temp,
      ));
    }
    return list;
  }
  static AdvicePriority _tempPriority(double value) {
    if (value >= 39.5) return AdvicePriority.high;
    if (value >= 38) return AdvicePriority.medium;
    if (value < 34) return AdvicePriority.high;
    if (value < 35) return AdvicePriority.medium;
    return AdvicePriority.low;
  }
  static AdviceRisk _tempRisk(double value) {
    if (value >= 39.5) return AdviceRisk.danger;
    if (value >= 38) return AdviceRisk.caution;
    if (value < 34) return AdviceRisk.danger;
    if (value < 35) return AdviceRisk.caution;
    return AdviceRisk.normal;
  }


  // ---------------- Blood Pressure ----------------
  static List<HealthAdvice> _bpAdvice(HealthData data, UserProfile profile) {
    List<HealthAdvice> list = [];
    final sys = data.systolic ?? 0;
    final dia = data.diastolic ?? 0;
    final sysMax = Constants.bpThresholds[DataTypes.bp]!['bp_systolic']!['max']!;
    final sysMin = Constants.bpThresholds[DataTypes.bp]!['bp_systolic']!['min']!;
    final diaMax = Constants.bpThresholds[DataTypes.bp]!['bp_diastolic']!['max']!;
    final diaMin = Constants.bpThresholds[DataTypes.bp]!['bp_diastolic']!['min']!;

    if (sys < sysMin || dia < diaMin) {
      list.add(
          _buildAdvice(
        id: 'bp_low_${data.timestamp.millisecondsSinceEpoch}',
        title: 'ضغط الدم منخفض',
        description: _tone(
          profile,
          strict: 'ضغط الدم منخفض. لو في دوخة أو تعب راجع طبيب فورًا.',
          balanced: 'ضغطك منخفض، حاول تشرب سوائل وراقب الأعراض.',
          relaxed: 'ضغطك واطي شوية، خليك مرتاح واطمّن.',
        ),
        category: AdviceCategory.warning,
        priority: _bpPriority(sys, dia),
        risk: _bpRisk(sys, dia),
        measurementTime: data.timestamp, // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.bp,
      ));
    } else if (sys > sysMax || dia > diaMax) {
      list.add(
          _buildAdvice(
        id: 'bp_high_${data.timestamp.millisecondsSinceEpoch}',
        title: 'ضغط الدم مرتفع',
        description: _tone(
          profile,
          strict: 'ضغطك مرتفع. قلل الملح فورًا وراجع طبيب لو القيم تكررت.',
          balanced: 'قلل الملح وحاول تمشي يوميًا وراقب القياسات.',
          relaxed: 'خفّف الملح شوية ومشية كل يوم هتفرق.',
        ),
        category: AdviceCategory.warning,
        priority: _bpPriority(sys, dia),
        risk: _bpRisk(sys, dia),
        measurementTime:data.timestamp , // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.bp,
      ));
    } else {
      list.add(
          _buildAdvice(
        id: 'bp_normal_${data.timestamp.millisecondsSinceEpoch}',
        title: 'ضغط الدم طبيعي',
        description: _tone(
          profile,
          strict: 'ضغط الدم طبيعي. التزم بقياسات منتظمة ونمط حياة صحي.',
          balanced: 'ضغطك مظبوط، استمر على نفس النظام.',
          relaxed: 'تمام 👍 الضغط مظبوط.',
        ),
        category: AdviceCategory.lifestyle,
        priority: _bpPriority(sys, dia),
        risk: _bpRisk(sys, dia),
        measurementTime:data.timestamp, // ✅ هنا صح // ✅ الوقت الصحيح لكل نصيحة
            type: DataTypes.bp,

      ));
    }

    return list;
  }
  static AdvicePriority _bpPriority(int sys, int dia) {
    if (sys >= 180 || dia >= 120) {
      return AdvicePriority.high; // أزمة ضغط
    }
    if (sys >= 160 || dia >= 100) {
      return AdvicePriority.high;
    }
    if (sys >= 140 || dia >= 90) {
      return AdvicePriority.medium;
    }
    return AdvicePriority.low;
  }

  static AdviceRisk _bpRisk(int sys, int dia) {
    if (sys >= 180 || dia >= 120) return AdviceRisk.danger;
    if (sys >= 160 || dia >= 100) return AdviceRisk.danger;
    if (sys >= 140 || dia >= 90) return AdviceRisk.caution;
    return AdviceRisk.normal;
  }


  static String _tone(UserProfile profile,
      {required String strict,
        required String balanced,
        required String relaxed}) {
    switch (profile.personality) {
      case PersonalityType.strict:
        return strict;
      case PersonalityType.relaxed:
        return relaxed;
      case PersonalityType.balanced:
        return balanced;
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
    required String type, // ✅ الجديد

  }) {
    return HealthAdvice(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      measurementTime: measurementTime,
      risk: risk,
      type: type, // ✅ مهم جدًا




    );
  }
}
