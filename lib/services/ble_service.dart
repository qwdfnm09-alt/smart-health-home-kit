import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/logger.dart';
import '../utils/data_parser.dart';
import '../utils/ble_constants.dart';
import '../utils/device_type.dart';

class BleService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<Map<String, dynamic>> _onParsedDataController =
  StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onParsedData => _onParsedDataController.stream;
  final List<StreamSubscription> _subscriptions = [];
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  DeviceType _inferDeviceType({
    required String serviceUuid,
    required String notifyCharUuid,
  }) {
    final s = serviceUuid.toLowerCase();
    final c = notifyCharUuid.toLowerCase();

    if (s == BleConstants.glucoseService.toLowerCase() &&
        c == BleConstants.glucoseNotifyChar.toLowerCase()) {
      return DeviceType.glucose;
    }
    if (s == BleConstants.thermoService.toLowerCase() &&
        c == BleConstants.thermoTempMeasurementChar.toLowerCase()) {
      return DeviceType.thermometer;
    }
    if (s == BleConstants.bpmService.toLowerCase() &&
        c == BleConstants.bpmNotifyChar.toLowerCase()) {
      return DeviceType.bloodPressure;
    }
    return DeviceType.unknown;
  }

  void _updateConnectionState(bool state) => _connectionStateController.add(state);

  void dispose() {
    _onParsedDataController.close();
    _connectionStateController.close();
    _scanSubscription?.cancel();
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // 🔍 Scan & connect
  void scanAndConnectTo({
    required String targetName,
    serviceUuid = BleConstants.bloodPressureService,
    notifyCharUuid = BleConstants.bloodPressureNotifyChar,
    String? writeCharUuid,
    DeviceType? deviceType,
    required void Function(Uint8List data) onData,
    VoidCallback? onError,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      AppLogger.logInfo("🔎 Starting scan for $targetName...");
      bool deviceFound = false;

      await FlutterBluePlus.startScan(timeout: timeout);

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          final device = result.device;
          AppLogger.logInfo("📶 Found device: ${device.platformName}");

          if (device.platformName == targetName) {
            deviceFound = true;
            await FlutterBluePlus.stopScan();
            await _scanSubscription?.cancel();
            _scanSubscription = null;

            try {
              await connectToDevice(
                device,
                serviceUuid: serviceUuid,
                notifyCharUuid: notifyCharUuid,
                writeCharUuid: writeCharUuid,
                deviceType: deviceType,
                onError: onError,
              );
            } catch (e) {
              AppLogger.logInfo("❌ فشل الاتصال بالجهاز: $e");
              onError?.call();
            }
          }
        }

        if (!deviceFound) {
          await FlutterBluePlus.stopScan();
          AppLogger.logInfo("❌ Timeout scan: لم يتم العثور على الجهاز $targetName");
          onError?.call();
        }
      });
    } catch (e) {
      AppLogger.logInfo("❌ خطأ أثناء عملية المسح: $e");
      onError?.call();
    }
  }



  // 🔍 Scan for devices
  Stream<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 5)}) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }



  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    AppLogger.logInfo("❌ لم يتم العثور على الجهاز بعد انتهاء المسح");
  }


  // 🔌 Connect to device
  Future<void> connectToDevice(
      BluetoothDevice device, {
        serviceUuid = BleConstants.bloodPressureService,
        notifyCharUuid = BleConstants.bloodPressureNotifyChar,
        String? writeCharUuid,
        VoidCallback? onError,
        DeviceType? deviceType,
      }) async {
    // Cleanup previous subscriptions to avoid duplicate listens
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    try {
      _connectedDevice = device;
      AppLogger.logInfo("🔌 Connecting to device: ${device.platformName}...");

      final effectiveType = deviceType ??
          _inferDeviceType(serviceUuid: serviceUuid, notifyCharUuid: notifyCharUuid);

      await device.connect(autoConnect: false).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception("⏱ Timeout: الاتصال بالجهاز استغرق وقتاً طويلاً");
        },
      );

      List<BluetoothService> services = await device.discoverServices();
      AppLogger.logInfo("✅ Services discovered: ${services.length}");

      // Print services & characteristics
      for (BluetoothService service in services) {
        AppLogger.logInfo('🔹 Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          AppLogger.logInfo(
              '   ↳ Characteristic UUID: ${characteristic.uuid}, read=${characteristic.properties.read}, write=${characteristic.properties.write}, notify=${characteristic.properties.notify}');
        }
      }

      _updateConnectionState(true);

      // Assign notify & write characteristics
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() != serviceUuid.toLowerCase()) continue;

        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString().toLowerCase() == notifyCharUuid.toLowerCase()) {
            _notifyCharacteristic = c;
            await c.setNotifyValue(true);

            // Single listen with timeout
            final sub = c.lastValueStream.timeout(
              const Duration(seconds: 10),
              onTimeout: (sink) {
                AppLogger.logInfo("⚠ Timeout: لم تصل بيانات من characteristic ${c.uuid}");
                sink.add([]); // empty to prevent freeze
              },
            ).listen((rawData) {
              if (rawData.isEmpty) return;
              final parsed = DataParser.parse(Uint8List.fromList(rawData), deviceType: effectiveType);
              _onParsedDataController.add(parsed);
              AppLogger.logInfo("📊 Parsed Data: $parsed");
            });

            _subscriptions.add(sub);
          }

          if (writeCharUuid != null && c.uuid.toString().toLowerCase() == writeCharUuid.toLowerCase()) {
            _writeCharacteristic = c;
          }

          if (effectiveType == DeviceType.glucose && _writeCharacteristic != null) {
            try {
              await _sendGlucoseHandshake(_writeCharacteristic);
            } catch (e) {
              AppLogger.logInfo("❌ Glucose handshake failed: $e");
              onError?.call();
            }
          }
        }
      }

      AppLogger.logInfo("🔹 Notify characteristic found: ${_notifyCharacteristic != null}");
      AppLogger.logInfo("🔹 Write characteristic found: ${_writeCharacteristic != null}");

      if (_notifyCharacteristic == null) throw Exception("❗ Notify characteristic not found");
    } catch (e) {
      AppLogger.logInfo("❌ فشل الاتصال أو العثور على characteristic: $e");
      onError?.call();
    }
  }

  // ✍ Write data
  Future<void> writeData(List<int> data) async {
    AppLogger.logInfo("✍ Writing data: $data");
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(data);
      AppLogger.logInfo("✅ Write successful");
    } else {
      AppLogger.logInfo("❗ Write characteristic not available");
      throw Exception("❗ Write characteristic not available");
    }
  }

  // 📤 Read data
  Future<List<int>> readData({
    required BluetoothDevice device,
    required String serviceUuid,
    required String characteristicUuid,
  }) async {
    AppLogger.logInfo(
        "📖 Reading from device: ${device.platformName}, service: $serviceUuid, characteristic: $characteristicUuid");

    final services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
            final value = await characteristic.read();
            AppLogger.logInfo("✅ Read successful: $value");
            return value;
          }
        }
      }
    }
    AppLogger.logInfo("❌ Characteristic not found");
    throw Exception('Characteristic not found');
  }

  // 🔌 Disconnect
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      AppLogger.logInfo("🔌 Disconnecting from device: ${_connectedDevice!.platformName}");
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _notifyCharacteristic = null;
      _writeCharacteristic = null;
    }

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    _updateConnectionState(false);
  }

  Future<void> reconnect({
    required String serviceUuid,
    required String notifyCharUuid,
    String? writeCharUuid,
    VoidCallback? onError,
  }) async {
    if (_connectedDevice == null) {
      AppLogger.logInfo("⚠ لا يوجد جهاز متصل لإعادة الاتصال");
      onError?.call();
      return;
    }

    try {
      AppLogger.logInfo("🔄 إعادة الاتصال بالجهاز: ${_connectedDevice!.platformName}");
      await connectToDevice(
        _connectedDevice!,
        serviceUuid: serviceUuid,
        notifyCharUuid: notifyCharUuid,
        writeCharUuid: writeCharUuid,
        onError: onError,
      );
    } catch (e) {
      AppLogger.logInfo("❌ فشل إعادة الاتصال: $e");
      onError?.call();
    }
  }

  // 🔑 Glucose handshake
  Future<void> _sendGlucoseHandshake(BluetoothCharacteristic? writeChar) async {
    if (writeChar == null) return;
    final now = DateTime.now();
    final bytes = Uint8List(10);
    bytes[0] = 0x5A;
    bytes[1] = 0x0A;
    bytes[2] = 0x00;
    bytes[3] = now.year % 100;
    bytes[4] = now.month;
    bytes[5] = now.day;
    bytes[6] = now.hour;
    bytes[7] = now.minute;
    bytes[8] = now.second;

    int sum = bytes.sublist(0, 9).reduce((a, b) => a + b) + 2;
    bytes[9] = sum & 0xFF;

    for (int i = 0; i < bytes.length; i++) {
      AppLogger.logInfo("🔑 Glucose handshake byte[$i]: ${bytes[i]}");
    }

    AppLogger.logInfo("🔑 Sending glucose handshake...");
    await writeChar.write(bytes, withoutResponse: false);
    AppLogger.logInfo("✅ Glucose handshake sent");
  }

  // 🛠 Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
}
