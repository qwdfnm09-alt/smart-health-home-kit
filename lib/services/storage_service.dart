import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../models/health_alert.dart';
import 'package:flutter/material.dart'; // ✅ ده بيحتوي على كلاس Locale
import '../utils/constants.dart';
import '../utils/logger.dart';
import 'advice_engine.dart';
import '../models/health_advice.dart';
import '../models/personality_type_adapter.dart';
import '../models/adapters/advice_category_adapter.dart';
import '../models/adapters/advice_priority_adapter.dart';
import '../models/adapters/advice_risk_adapter.dart';
import 'alert_service.dart';
import '../models/routine_task.dart';


class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // 🔹 Save flag
  Future<void> setSetupCompleted(bool value) async {
    var box = Hive.box('app_settings');
    await box.put('setupCompleted', value);
  }

// 🔹 Read flag
  Future<bool> isSetupCompleted() async {
    var box = Hive.box('app_settings');
    return box.get('setupCompleted', defaultValue: false);
  }


  Box<HealthData>? _bpDataBox;
  Box<HealthData>? _glucoseDataBox;
  Box<HealthData>? _tempDataBox;
  Box<HealthData>? _healthDataBox;
  Box<UserProfile>? _userProfileBox;
  Box<HealthAlert>? _alertBox;
  Box<RoutineTask>? _routineBox;
  final _secureStorage = const FlutterSecureStorage();

  static const _bpBoxName = 'bp_data';
  static const _glucoseBoxName = 'glucose_data';
  static const _tempBoxName = 'temp_data'; // ✅ ده الاسم الموحد
  static const _encryptionKeyName = 'hive_encryption_key';
  static const _encryptionEnabledKey = 'encryption_enabled';

  Box<HealthData> get healthDataBox => Hive.box<HealthData>('health_data');
  Box<RoutineTask> get routineBox => Hive.box<RoutineTask>('routine_tasks');


  Future<void> init() async {
    try {
      // 🆕 تهيئة Hive
      await Hive.initFlutter();
      
      // فتح صندوق الإعدادات الأساسي أولاً (إعدادات عامة غير مشفرة)
      await Hive.openBox('app_settings');

      // 1️⃣ تسجيل جميع الـ Adapters قبل فتح أي صناديق
      _registerAdapters();

      // 2️⃣ تجهيز التشفير (إجباري الآن للبيانات الصحية والبروفايل)
      List<int> key;
      try {
        String? storedKey = await _secureStorage.read(key: _encryptionKeyName);
        if (storedKey == null || storedKey.isEmpty) {
          key = Hive.generateSecureKey();
          await _secureStorage.write(key: _encryptionKeyName, value: key.join(','));
        } else {
          key = storedKey.split(',').map((e) => int.parse(e)).toList();
        }
      } catch (e) {
        AppLogger.logError("❌ Encryption Key Error: $e");
        key = Hive.generateSecureKey();
      }

      final cipher = HiveAesCipher(key);

      // 3️⃣ فتح الصناديق بتشفير AES
      await _openAllBoxes(cipher);
      
      AppLogger.logInfo("✅ Storage Service Initialized with AES Encryption");
    } catch (e, st) {
      AppLogger.logError("🚨 Fatal error during Storage init: $e\n$st");
      rethrow; 
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HealthDataAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HealthAlertAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PersonalityTypeAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(HealthAdviceAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(AdviceCategoryAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(AdvicePriorityAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(AdviceRiskAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(RoutineTaskAdapter());
  }

  Future<void> _openAllBoxes(HiveCipher? cipher) async {
    _bpDataBox = await Hive.openBox<HealthData>(_bpBoxName, encryptionCipher: cipher);
    _glucoseDataBox = await Hive.openBox<HealthData>(_glucoseBoxName, encryptionCipher: cipher);
    _tempDataBox = await Hive.openBox<HealthData>(_tempBoxName, encryptionCipher: cipher);
    _healthDataBox = await Hive.openBox<HealthData>('health_data', encryptionCipher: cipher);
    _userProfileBox = await Hive.openBox<UserProfile>('user_profile', encryptionCipher: cipher);
    _alertBox = await Hive.openBox<HealthAlert>('alerts', encryptionCipher: cipher);
    _routineBox = await Hive.openBox<RoutineTask>('routine_tasks', encryptionCipher: cipher);

    await Hive.openBox<HealthAdvice>('adviceBox', encryptionCipher: cipher);
    await Hive.openBox('remindLaterBox', encryptionCipher: cipher);
  }


  // -------- Encryption --------
  Future<void> setEncryptionEnabled(bool enabled) async {
    await _secureStorage.write(key: _encryptionEnabledKey, value: enabled ? 'true' : 'false');
  }

  Future<bool> isEncryptionEnabled() async {
    try {
      final value = await _secureStorage.read(key: _encryptionEnabledKey);
      return value == 'true';
    } catch (e) {
      AppLogger.logError("❌ Failed to read encryption flag: $e");
      return false;
    }
  }


  // -------- Health Data --------
  Future<void> saveHealthData(HealthData data) async {
    try {
      // نسخة للـ health_data العام
      final clone1 = data.copyWith(
        value: data.value,
        unit: data.unit,
        extra: data.extra,
      );
      await _healthDataBox?.add(clone1);

      // نسخة تانية للـ نوع الجهاز
      final clone2 = data.copyWith(
        value: data.value,
        unit: data.unit,
        extra: data.extra,
      );
      await addHealthData(clone2);
      // 🔔 هنا الحل
      await AlertService.checkAndGenerateAlert(data);


      AppLogger.logInfo("✅ HealthData stored with → value: ${clone2.value}, extra: ${clone2.extra}");
    } catch (e) {
      AppLogger.logError("❌ Error saving HealthData: $e");
    }
  }


  Future<void> addHealthData(HealthData data) async {
    try {


      switch (data.type) {
        case DataTypes.bp:
          if (_bpDataBox?.isOpen ?? false) {
            await _bpDataBox?.add(data.copyWith());
            await _bpDataBox?.put('latest', data.copyWith() );
            AppLogger.logInfo("💾 Saved BP data: ${data.toString()}");
          }
          break;
        case DataTypes.glucose:
          if (_glucoseDataBox?.isOpen ?? false) {
            await _glucoseDataBox?.add(data.copyWith());
            await _glucoseDataBox?.put('latest', data.copyWith() ); // لو glucose
            AppLogger.logInfo("💾 Saved Glucose data: ${data .toString()}");
          }
          break;
        case DataTypes.temp:
          if (_tempDataBox?.isOpen ?? false) {
            await _tempDataBox?.add(data.copyWith());
            await _tempDataBox?.put('latest', data.copyWith()); // لو temp
            AppLogger.logInfo("💾 Saved Temp data: ${data.toString()}");
          }
          break;
        default:
          AppLogger.logInfo(
              "⚠️ Unknown type: ${data.type}, saved in health_data only");
      }
    }
    catch (e) {
      AppLogger.logError("❌ Error adding HealthData: $e");
    }
  }


  List<HealthData> getAllHealthData() {
    final all = _healthDataBox?.values.toList() ?? [];
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }


  List<HealthData> getAllByType(String type) {
    List<HealthData> all = [];
    switch (type) {
      case DataTypes.bp:
        all = _bpDataBox?.values.toList() ?? [];
        break;
      case DataTypes.glucose:
        all = _glucoseDataBox?.values.toList() ?? [];
        break;
      case DataTypes.temp:
        all = _tempDataBox?.values.toList() ?? [];
        break;
    }
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }



  HealthData? getLatestByType(String type) {
    switch (type) {
      case DataTypes.bp:
        return _bpDataBox?.get('latest');
      case DataTypes.glucose:
        return _glucoseDataBox?.get('latest');
      case DataTypes.temp:
        return _tempDataBox?.get('latest');
      default:
        return null;
    }
  }


  Stream<BoxEvent>? healthDataStream() {
    if (_healthDataBox != null && _healthDataBox!.isOpen) {
      return _healthDataBox!.watch();
    }
    return null;
  }


  // -------- Advice --------
  Future<List<HealthAdvice>> saveHealthDataWithAdvice(HealthData data) async {
    AppLogger.logInfo("🧠 saveHealthDataWithAdvice CALLED");
    // 1️⃣ احفظ القياس
    await saveHealthData(data);

    // 2️⃣ هات البروفايل
    final profile = getUserProfile();
    AppLogger.logInfo("🔥 profile = $profile");

    if (profile == null) {
      AppLogger.logError("❌ UserProfile is NULL → advice skipped");
      return [];
    }


    // 3️⃣ استخدم AdviceEngine
    final adviceList = AdviceEngine.getAdvice(data: data, profile: profile);
    AppLogger.logInfo("🧠 Advice generated = ${adviceList.length}");

    // 4️⃣ احفظ نصائح اليوم في Hive لو حابب
    await saveHealthAdvice(adviceList);
    return adviceList;
  }

// 🔹 وظيفة حفظ نصائح منفصلة (ممكن تستخدم في أي وقت)
  Future<void> saveHealthAdvice(List<HealthAdvice> adviceList) async {
    final box = Hive.box<HealthAdvice>('adviceBox');
    for (var advice in adviceList) {
      await box.put(advice.id, advice);
    }
  }

  // -------- User Profile --------
  Future<void> saveUserProfile(UserProfile profile) async {
    try{
    await _userProfileBox?.put('profile', profile);
  }
  catch (e) {
      AppLogger.logError("❌ Error saving UserProfile: $e");
    }
  }

  UserProfile? getUserProfile() {
    return _userProfileBox?.get('profile');
  }

  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try{
    await _userProfileBox?.put('profile', updatedProfile);
  }catch (e) {
      AppLogger.logError("❌ Error updating UserProfile: $e");
    }
  }


  Stream<BoxEvent> userProfileStream() {
    return _userProfileBox!.watch();
  }

  // -------- Alerts --------
  Future<void> addAlert(HealthAlert alert) async {
    try{
    await _alertBox?.add(alert);
  }catch (e) {
      AppLogger.logError("❌ Error adding HealthAlert: $e");
    }
  }

  List<HealthAlert> getAllAlerts() {
    return _alertBox?.values.toList() ?? [];
  }

  Stream<BoxEvent> alertStream() {
    return _alertBox!.watch();
  }

  Future<void> deleteAlert(int key) async {
    try {
      await _alertBox?.delete(key);
    } catch (e) {
      AppLogger.logError("❌ Error deleting HealthAlert: $e");
    }
  }

  // -------- Daily Routine --------
  Future<void> saveDailyRoutine(List<RoutineTask> tasks) async {
    try {
      await _routineBox?.clear();
      await _routineBox?.addAll(tasks);
      AppLogger.logInfo("📅 Daily routine saved with ${tasks.length} tasks");
    } catch (e) {
      AppLogger.logError("❌ Error saving Daily Routine: $e");
    }
  }

  List<RoutineTask> getDailyRoutine() {
    return _routineBox?.values.toList() ?? [];
  }

  Future<void> updateRoutineTask(int index, bool isCompleted) async {
    try {
      final task = _routineBox?.getAt(index);
      if (task != null) {
        task.isCompleted = isCompleted;
        await task.save();
      }
    } catch (e) {
      AppLogger.logError("❌ Error updating RoutineTask: $e");
    }
  }


  // -------- First Time Check --------
  Future<void> markProfileCompleted() async {
    await _secureStorage.write(key: 'profile_completed', value: 'true');
  }

  Future<bool> isProfileCompleted() async {
    final value = await _secureStorage.read(key: 'profile_completed');
    return value == 'true';
  }

  // -------- Locale --------
  Future<void> saveLocale(String languageCode) async {
    await _secureStorage.write(key: 'locale', value: languageCode);
  }

  Future<Locale> getSavedLocale() async {
    final code = await _secureStorage.read(key: 'locale');
    if (code == null || code.isEmpty) return const Locale('ar');
    return Locale(code);
  }

  // -------- Reset --------
  Future<void> resetAllData() async {
    await _healthDataBox?.clear();
    await _userProfileBox?.clear();
    await _alertBox?.clear();
    await _bpDataBox?.clear();
    await _glucoseDataBox?.clear();
    await _tempDataBox?.clear();

    // ✅ نمسح الإعدادات من الـ secure storage
    await _secureStorage.delete(key: 'locale');
    await _secureStorage.delete(key: 'theme');
    await _secureStorage.delete(key: 'profile_completed');
    await _secureStorage.delete(key: _encryptionEnabledKey);
    await _secureStorage.delete(key: _encryptionKeyName); // 🆕 أهم حاجة

    // 🆕 نقفل كل الـ Boxes بعد الـ clear
    await close();
  }

  // -------- close --------
  //مفيد لو عايز Restart للـ Hive من غير ما تعيد تشغيل الأبلكيشن
  Future<void> close() async {
    await _bpDataBox?.close();
    await _glucoseDataBox?.close();
    await _tempDataBox?.close();
    await _healthDataBox?.close();
    await _userProfileBox?.close();
    await _alertBox?.close();
    await _routineBox?.close();

    if (Hive.isBoxOpen('adviceBox')) {
      await Hive.box<HealthAdvice>('adviceBox').close();
    }
    if (Hive.isBoxOpen('remindLaterBox')) {
      await Hive.box('remindLaterBox').close();
    }
  }

}
