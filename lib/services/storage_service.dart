import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../models/health_alert.dart';
import 'package:flutter/material.dart'; // ✅ ده بيحتوي على كلاس Locale

class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  Box<HealthData>? _healthDataBox;


  Box<UserProfile>? _userProfileBox;
  Box<HealthAlert>? _alertBox;
  final _secureStorage = const FlutterSecureStorage();

  Box<HealthData> get healthDataBox {
    if (_healthDataBox == null) {
      throw Exception("healthDataBox has not been initialized. Call init() first.");
    }
    return _healthDataBox!;
  }




  static const _encryptionKeyName = 'hive_encryption_key';
  static const _encryptionEnabledKey = 'encryption_enabled';  // مفتاح جديد لتخزين حالة التشفير

  Future<void> init() async {
    await Hive.initFlutter();

    // التأكد من تسجيل الـ Adapters مرة واحدة فقط
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HealthDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HealthAlertAdapter());
    }

    final key = await _getEncryptionKey();

    _healthDataBox = await Hive.openBox<HealthData>(
      'health_data',
      encryptionCipher: HiveAesCipher(key),
    );

    _userProfileBox = await Hive.openBox<UserProfile>(
      'user_profile',
      encryptionCipher: HiveAesCipher(key),
    );

    _alertBox = await Hive.openBox<HealthAlert>(
      'alerts',
      encryptionCipher: HiveAesCipher(key),
    );
  }


  Future<List<int>> _getEncryptionKey() async {
    String? storedKey = await _secureStorage.read(key: _encryptionKeyName);

    if (storedKey == null) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: key.join(','),
      );
      return key;
    } else {
      return storedKey.split(',').map((e) => int.parse(e)).toList();
    }
  }


  // -------- Encryption Enabled --------
  Future<void> setEncryptionEnabled(bool enabled) async {
    await _secureStorage.write(key: _encryptionEnabledKey, value: enabled ? 'true' : 'false');
  }

  Future<bool> isEncryptionEnabled() async {
    final value = await _secureStorage.read(key: _encryptionEnabledKey);
    if (value == null) return false; // القيمة الافتراضية: التشفير غير مفعل
    return value == 'true';
  }

  // -------- Health Data --------
  Future<void> addHealthData(HealthData data) async {
    await _healthDataBox?.add(data);
  }

  List<HealthData> getAllHealthData() {
    return _healthDataBox?.values.toList() ?? [];
  }

  Stream<BoxEvent> healthDataStream() {
    return _healthDataBox!.watch();
  }

  // -------- User Profile --------
  Future<void> saveUserProfile(UserProfile profile) async {
    await _userProfileBox?.put('profile', profile);
  }

  UserProfile? getUserProfile() {
    return _userProfileBox?.get('profile');
  }

  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    await _userProfileBox?.put('profile', updatedProfile);
  }

  Stream<BoxEvent> userProfileStream() {
    return _userProfileBox!.watch();
  }

  // -------- Alerts --------
  Future<void> addAlert(HealthAlert alert) async {
    await _alertBox?.add(alert);
  }

  List<HealthAlert> getAllAlerts() {
    return _alertBox?.values.toList() ?? [];
  }

  Stream<BoxEvent> alertStream() {
    return _alertBox!.watch();
  }
  // -------- First Time Check --------
  Future<void> markProfileCompleted() async {
    await _secureStorage.write(key: 'profile_completed', value: 'true');
  }

  Future<bool> isProfileCompleted() async {
    final value = await _secureStorage.read(key: 'profile_completed');
    return value == 'true';
  }
  // -------- Locale (Language) --------
  Future<void> saveLocale(String languageCode) async {
    await _secureStorage.write(key: 'locale', value: languageCode);
  }

  Future<Locale> getSavedLocale() async {
    final code = await _secureStorage.read(key: 'locale');
    if (code == null || code.isEmpty) return const Locale('ar'); // اللغة الافتراضية
    return Locale(code);
  }
  // -------- Reset All Data --------
  Future<void> resetAllData() async {
    await _healthDataBox?.clear();
    await _userProfileBox?.clear();
    await _alertBox?.clear();

    await _secureStorage.delete(key: 'locale');
    await _secureStorage.delete(key: 'theme');
    await _secureStorage.delete(key: 'profile_completed');
    await _secureStorage.delete(key: _encryptionEnabledKey); // حذف حالة التشفير عند إعادة التعيين
  }
}
