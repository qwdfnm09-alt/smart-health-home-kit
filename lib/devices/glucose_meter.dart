import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import 'smart_device.dart';
import '../utils/logger.dart';

class GlucoseMeter extends SmartDevice {
  @override
  final String name = 'جهاز قياس السكر (ADF-B27)';

  @override
  String get serviceUuid => '00001808-0000-1000-8000-00805f9b34fb';

  @override
  String get notifyCharUuid => '00002a18-0000-1000-8000-00805f9b34fb';

  @override
  String? get writeCharUuid => null;

  @override
  String get deviceName => 'ADF-B27'; // ← اسم الجهاز الحقيقي على البلوتوث


  @override
  Future<void> connect(BluetoothDevice device) async {
    this.device = device;
    await device.connect();
  }

  @override
  Future<void> disconnect() async {
    await device?.disconnect();
    device = null;
  }

  @override
  HealthData? handleData(List<int> data) {
    if (data.isEmpty) return null;

    int glucoseValue = data[1] + (data[2] << 8);

    final reading = HealthData(
      type: 'glucose',
      value: glucoseValue.toDouble(),
      timestamp: DateTime.now(),
    );

    AppLogger.logInfo('🩸 Glucose reading: ${reading.value} mg/dL');
    return reading;
  }
}


