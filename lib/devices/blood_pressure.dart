import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import 'smart_device.dart';
import '../utils/logger.dart';
import '../models/blood_pressure_reading.dart';



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
    int pulse = data.length > 5 ? data[5] : 0;

    final bpReading = BloodPressureReading(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      datetime: DateTime.now(),
      source: "ADF-B180",
    );

    final reading = HealthData.fromBloodPressure(bpReading);
    AppLogger.logInfo(
      '🩺 BP: ${bpReading.systolic}/${bpReading.diastolic} mmHg (Pulse: ${bpReading.pulse})',
    );
    return reading;

  }

}
