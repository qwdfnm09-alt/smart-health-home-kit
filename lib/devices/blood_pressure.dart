import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import 'smart_device.dart';
import '../utils/logger.dart';


class BloodPressureMonitor extends SmartDevice {
  @override
  final String name = 'جهاز قياس الضغط (ADF-B180)';

  @override
  String get serviceUuid => '00001810-0000-1000-8000-00805f9b34fb';

  @override
  String get notifyCharUuid => '00002a35-0000-1000-8000-00805f9b34fb';

  @override
  String? get writeCharUuid => null;

  @override
  String get deviceName => 'ADF-B180';


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
    if (data.isEmpty || data.length < 4) return null;

    int systolic = data[1];
    int diastolic = data[3];

    double combinedValue = (systolic * 100 + diastolic).toDouble();

    final reading = HealthData(
      type: 'blood_pressure',
      value: combinedValue,
      timestamp: DateTime.now(),
    );


    AppLogger.logInfo('🩺 BP reading: $systolic/$diastolic mmHg');
    return reading;
  }
}

