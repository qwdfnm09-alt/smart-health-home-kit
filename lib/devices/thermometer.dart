import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import 'smart_device.dart';
import '../utils/logger.dart';

class Thermometer extends SmartDevice {
  @override
  final String name = 'جهاز قياس الحرارة (ADF-B33A)';

  @override
  String get serviceUuid => '00001809-0000-1000-8000-00805f9b34fb';

  @override
  String get notifyCharUuid => '00002a1c-0000-1000-8000-00805f9b34fb';

  @override
  String? get writeCharUuid => null;

  @override
  String get deviceName => 'ADF-B33A';


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

    double tempValue = data[1] + data[2] / 100;

    final reading = HealthData(
      type: 'temperature',
      value: tempValue,
      timestamp: DateTime.now(),
    );

    AppLogger.logInfo('🌡️ Temperature reading: $tempValue °C');
    return reading;
  }
}

