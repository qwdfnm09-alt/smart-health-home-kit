import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import 'smart_device.dart';
import '../utils/logger.dart';
import '../models/glucose_reading.dart';

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
    if (data.isEmpty || data.length < 3) return null;

    int glucoseValue = data[1] + (data[2] << 8);

    final gReading = GlucoseReading(
      glucose: glucoseValue,
      datetime: DateTime.now(),
      source: "ADF-B27",
      raw: {"data": data},
      unit: 'mg/dL',
    );

    final reading = HealthData.fromGlucose(gReading);
    AppLogger.logInfo('🩸 Glucose: ${gReading.glucose} ${reading.unit}');
    return reading;
  }
}
