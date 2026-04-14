import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';

/// 🧠 Abstract base class for all smart health devices
abstract class SmartDevice {
  /// 📛 اسم الجهاز الظاهر للمستخدم
  String get name;

  /// 🔌 مرجع جهاز البلوتوث
  BluetoothDevice? device;

  /// ✅ هل الجهاز متصل؟
  bool get isConnected => device != null;

  /// 🔗 UUID الخاص بالخدمة الرئيسية
  String get serviceUuid;

  /// 📨 UUID الخاص بقراءة البيانات (Notify)
  String get notifyCharUuid;

  /// ✍️ UUID للكتابة (لو الجهاز يحتاج كتابة)
  String? get writeCharUuid;

  String get deviceName; // ← أضف ده هنا

  /// 🔌 الاتصال بالجهاز
  Future<void> connect(BluetoothDevice device);

  /// 🔌 فصل الاتصال بالجهاز
  Future<void> disconnect();

  /// 📊 تحليل البيانات القادمة من BLE وإرجاع قراءة صحية
  HealthData? handleData(List<int> data);
}

