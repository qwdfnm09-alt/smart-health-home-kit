import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';
import '../utils/ble_constants.dart';
import '../utils/data_parser.dart';
import '../utils/device_type.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';






class BleService {
  String _streamDeviceName(DeviceType type) {
    switch (type) {
      case DeviceType.bloodPressure:
        return 'blood_pressure';
      case DeviceType.glucose:
        return 'glucose';
      case DeviceType.thermometer:
        return 'thermometer';
      case DeviceType.unknown:
        return 'unknown';
    }
  }

  DeviceType _detectDeviceType(String deviceName) {
    return DeviceConstants.deviceNameToType[deviceName] ?? DeviceType.unknown;
  }



  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<Map<String, dynamic>> _onParsedDataController =
  StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onParsedData =>
      _onParsedDataController.stream;

  final List<StreamSubscription> _subscriptions = [];
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errors => _errorController.stream;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _writeCharacteristic;

  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  void _notifyError(String message) {
    AppLogger.logError("❌ BLE Error: $message");
    _errorController.add(message);
  }

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




  // 👇 أضف الدالة الجديدة
  Future<void> onDataReceived(Uint8List data, DeviceType type) async {
    // 1️⃣ Parse Raw Data

    try {

      final parsed = DataParser.parse(data, deviceType: type);
      AppLogger.logInfo("📊 Parsed Data: $parsed");

      // 2️⃣ تحويل حسب النوع
      HealthData? healthData;
      final parsedType = parsed["type"];

// حالة: DataParser أرجع HealthData مباشرة (مفتاح "healthData")
      if (parsed.containsKey("healthData") && parsed["healthData"] is HealthData) {
        healthData = parsed["healthData"] as HealthData;
      } else {
        // نحاول بناء HealthData من القيم الخام لو متاحة
        if (parsedType == DeviceType.bloodPressure || parsed.containsKey("systolic")) {
          final int? sys = parsed["systolic"] is int ? parsed["systolic"] as int : null;
          final int? dia = parsed["diastolic"] is int ? parsed["diastolic"] as int : null;
          final int? pulse = parsed["pulse"] is int ? parsed["pulse"] as int : null;

          if (sys != null && dia != null) {
            healthData = HealthData.fromBloodPressureValues(
              systolic: sys,
              diastolic: dia,
              pulse: pulse ?? 0,
              datetime: DateTime.now(),
              source: "bloodPressure",
            );
          }
        } else if (parsedType == DeviceType.glucose || parsed.containsKey("glucose")) {
          final g = parsed["glucose"] ?? parsed["value"];
          if (g != null) {
            final int glucoseVal = (g is int) ? g : (g is double ? g.toInt() : int.parse(g.toString()));
            healthData = HealthData.fromGlucoseValues(
              glucose: glucoseVal,
              datetime: DateTime.now(),
              source: "glucose",
            );
          }
        } else if (parsedType == DeviceType.thermometer || parsed.containsKey("temperature")) {
          final t = parsed["temperature"] ?? parsed["value"];
          if (t != null) {
            final double tempVal = (t is num) ? t.toDouble() : double.parse(t.toString());
            healthData = HealthData.fromThermometerValues(
              temperature: tempVal,
              datetime: DateTime.now(),
              source: "thermometer",
            );
          }
        }
      }
      // ======== نهاية الاستبدال ========


      // 3️⃣ تخزين في Hive
      if (healthData != null) {
        if (!_onParsedDataController.isClosed) {
          _onParsedDataController.add({
            'device': _streamDeviceName(type),
            'source': healthData.source,
            'healthData': healthData,
            'value': healthData.value,
            'unit': healthData.unit,
            'timestamp': healthData.timestamp.toIso8601String(),
            'datetime': healthData.timestamp.toIso8601String(),
            if (healthData.systolic != null) 'systolic': healthData.systolic,
            if (healthData.diastolic != null) 'diastolic': healthData.diastolic,
            if (healthData.pulse != null) 'pulse': healthData.pulse,
            if (healthData.glucose != null) 'glucose': healthData.glucose,
            if (healthData.temperature != null) 'temperature': healthData.temperature,
            'raw': data,
          });
        }

        await StorageService().saveHealthDataWithAdvice(healthData);
        AppLogger.logInfo("💾 Saved health data → ${healthData.type}");
        AppLogger.logInfo("👉 Stored HealthData fields -> sys:${healthData.systolic}, dia:${healthData.diastolic}, pulse:${healthData.pulse}, extra:${healthData.extra}");


        // Logging منظم
        if (healthData.type == "glucose") {
          final glucose = healthData.extra?["glucose"] ?? healthData.value;
          AppLogger.logInfo(
              "🩸 Glucose: $glucose ${healthData.unit}");
        } else if (healthData.type == "temp") {
          AppLogger.logInfo("🌡 Temp: ${healthData.value} ${healthData.unit}");
        } else if (healthData.type == "bp") {
          final sys = healthData.systolic;
          final dia = healthData.diastolic;
          final pulse = healthData.pulse;
          AppLogger.logInfo("🩺 BP: $sys/$dia mmHg | Pulse: $pulse bpm");
        }
      }
    }
    catch (e) {
      AppLogger.logInfo("❌ Error parsing data: $e");
      return;
    }
  }


  void _updateConnectionState(bool state) =>
      _connectionStateController.add(state);


  void dispose() {
    if (!_onParsedDataController.isClosed) {
      _onParsedDataController.close();
    }
    if (!_connectionStateController.isClosed) {
      _connectionStateController.close();
    }
    if (!_errorController.isClosed) {
      _errorController.close();
    }
    _scanSubscription?.cancel();
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

  }

  // 🛰 Simple scan for testing (prints all nearby devices)
  void debugScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      // ✅ Check if Bluetooth is ON
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        AppLogger.logInfo("❌ Cannot start debug scan: Bluetooth is OFF");
        return;
      }

      AppLogger.logInfo("🔍 Starting BLE Debug Scan...");
      await FlutterBluePlus.startScan(timeout: timeout);

      _scanSubscription = FlutterBluePlus.scanResults.listen(
            (results) {
          for (var r in results) {
            AppLogger.logInfo(
                "📡 Found device: ${r.device.platformName} (${r.device.remoteId}) RSSI: ${r.rssi}");
          }
        },
        onError: (error) {
          AppLogger.logInfo("❌ Debug scan error: $error");
        },
      );
    } catch (e) {
      AppLogger.logInfo("❌ Exception in debugScan: $e");
    }
  }







  // 🔍 Scan & connect
  void scanAndConnectTo({
    required String targetName,
    serviceUuid = BleConstants.bloodPressureService,
    notifyCharUuid = BleConstants.bloodPressureNotifyChar,
    String? writeCharUuid,
    DeviceType? deviceType,

    VoidCallback? onError,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Check if Bluetooth is ON
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _notifyError("يرجى تفعيل البلوتوث أولاً");
        onError?.call();
        return;
      }

      AppLogger.logInfo("🔎 Starting scan for $targetName...");
      bool deviceFound = false;

      // 🔐 تأكد من الحصول على صلاحيات Bluetooth و Location
      await _ensureBlePermissions();
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
              _notifyError("فشل الاتصال بالجهاز: $e");
              onError?.call();
            }
            return;
          }
        }
      });
      Future.delayed(timeout, () async {
        if (!deviceFound) {
          await FlutterBluePlus.stopScan();
          await _scanSubscription?.cancel();
          _scanSubscription = null;
          _notifyError("لم يتم العثور على الجهاز $targetName. تأكد أنه قريب ومشغل.");
          onError?.call();
        }
      });
    } catch (e) {
      _notifyError("خطأ أثناء عملية المسح: $e");
      onError?.call();
    }
  }

  // 🔍 Scan for devices
  Stream<List<ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async* {
    // Check if Bluetooth is ON
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _notifyError("يرجى تفعيل البلوتوث أولاً");
      yield [];
      return;
    }

    // 1. أوقف أي بحث قديم ونظف النتائج السابقة
    await FlutterBluePlus.stopScan();

    // 2. ابدأ البحث الجديد
    FlutterBluePlus.startScan(timeout: timeout);

    yield* FlutterBluePlus.scanResults.map((results) {
      // 3. احصل على الأجهزة المتصلة حالياً بالهاتف لضمان ظهورها
      final connectedDevices = FlutterBluePlus.connectedDevices;

      // تحويل الأجهزة المتصلة إلى ScanResult وهمية لتظهر في القائمة
      final List<ScanResult> allResults = [...results];
      for (var d in connectedDevices) {
        if (_isSupportedDevice(d.platformName)) {
          // تأكد من عدم تكرار الجهاز إذا كان موجوداً في الـ scan
          bool exists = allResults.any((r) => r.device.remoteId == d.remoteId);
          if (!exists) {
            allResults.add(ScanResult(
              device: d,
              advertisementData: AdvertisementData(
                advName: d.platformName,
                txPowerLevel: null,
                connectable: true,
                appearance: null,
                manufacturerData: {},
                serviceData: {},
                serviceUuids: [],
              ),
              rssi: -50,
              timeStamp: DateTime.now(),
            ));
          }
        }
      }

      // 4. فلترة نهائية للأجهزة المدعومة فقط
      return allResults.where((r) => _isSupportedDevice(r.device.platformName)).toList();
    });
  }

  // 🧩 ضيف الدالة هنا قبل القوس الأخير بتاع الكلاس
  bool _isSupportedDevice(String name) {
    if (name.isEmpty) return false;
    final allowedPrefixes = [
      'Samico',   // Glucose meter
      'BPM',  // Blood pressure
      'TEMP',  // Thermometer
    ];
    return allowedPrefixes.any((prefix) => name.startsWith(prefix));
  }


  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    AppLogger.logInfo("❌ لم يتم العثور على الجهاز بعد انتهاء المسح");
  }


  Future<void> _ensureBlePermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final androidVersion = androidInfo.version.sdkInt;
    final List<Permission> permissions = [];

    if (androidVersion >= 31) {
      // Android 12+ (BLE Permissions مستقلة)
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ]);
    } else {
      // Android 11 وأقل (Location ضروري للمسح)
      permissions.add(Permission.location);
    }

    // اطلب الصلاحيات فقط لو لسه مش متاحة
    for (var p in permissions) {
      if (await p.isDenied || await p.isRestricted) {
        final result = await p.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          AppLogger.logInfo("⚠ الصلاحية ${p.toString()} مرفوضة من المستخدم");
        }
      }
    }

    // افتح الإعدادات لو الصلاحية مرفوضة دائمًا
    if (await Permission.location.isPermanentlyDenied ||
        await Permission.bluetoothScan.isPermanentlyDenied ||
        await Permission.bluetoothConnect.isPermanentlyDenied) {
      AppLogger.logInfo("⚠ بعض الصلاحيات مرفوضة دائمًا — فتح إعدادات التطبيق");
      await openAppSettings();
    }
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
    // Cleanup previous subscriptions
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    try {
      _connectedDevice = device;
      AppLogger.logInfo("🔌 Connecting to device: ${device.platformName}...");

      // 📡 مراقبة حالة الاتصال (إذا فصل الجهاز فجأة)
      final connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          AppLogger.logInfo("🔌 الجهاز فصل الاتصال");
          _updateConnectionState(false);
          _connectedDevice = null;
        } else if (state == BluetoothConnectionState.connected) {
          _updateConnectionState(true);
        }
      });
      _subscriptions.add(connSub);

      final effectiveType = deviceType ??
          _inferDeviceType(serviceUuid: serviceUuid, notifyCharUuid: notifyCharUuid);

      await device.connect(autoConnect: false).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _notifyError("فشل الاتصال: الجهاز بعيد جداً أو غير مستعد");
          throw Exception("Timeout");
        },
      );

      List<BluetoothService> services = await device.discoverServices();
      AppLogger.logInfo("✅ Services discovered: ${services.length}");

      // Print services & characteristics
      for (BluetoothService service in services) {
        AppLogger.logInfo('🔹 Service UUID: ${service.uuid}');
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          AppLogger.logInfo(
              ' ↳ Characteristic UUID: ${characteristic.uuid}, read=${characteristic.properties.read}, write=${characteristic.properties.write}, notify=${characteristic.properties.notify}');
        }
      }

      _updateConnectionState(true);

      // Assign notify & write characteristics
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() != serviceUuid.toLowerCase()) {
          continue;
        }

        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid.toString().toLowerCase() ==
              notifyCharUuid.toLowerCase()) {
            _notifyCharacteristic = c;
            await c.setNotifyValue(true);

            // Single listen with timeout
            final sub = c.lastValueStream

                .timeout(
              const Duration(seconds: 15),
              onTimeout: (sink) {
                AppLogger.logInfo(
                    "⚠ Timeout: لم تصل بيانات من characteristic ${c.uuid}");
                sink.add([]);
              },
            )
                .listen((rawData) async {
              if (rawData.isEmpty) return;

              AppLogger.logInfo("📥 Raw Data (DEC): $rawData");
              final hexString = rawData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
              AppLogger.logInfo("📥 Raw Data (HEX): $hexString");



              // 1️⃣ استدعي onDataReceived (اللي بيعمل parsing + logging + saving)
              final deviceType = _detectDeviceType(device.platformName);

              await onDataReceived(Uint8List.fromList(rawData), deviceType);

            });


            _subscriptions.add(sub);
          }

          if (writeCharUuid != null &&
              c.uuid.toString().toLowerCase() == writeCharUuid.toLowerCase()) {
            _writeCharacteristic = c;
          }

          if (effectiveType == DeviceType.glucose &&
              _writeCharacteristic != null) {
            try {
              await _sendGlucoseHandshake(_writeCharacteristic);
            } catch (e) {
              _notifyError("فشل مصافحة جهاز السكر: $e");
              onError?.call();
            }
          }
        }
      }

      AppLogger.logInfo(
          "🔹 Notify characteristic found: ${_notifyCharacteristic != null}");
      AppLogger.logInfo(
          "🔹 Write characteristic found: ${_writeCharacteristic != null}");

      if (_notifyCharacteristic == null) {
        throw Exception("❗ Notify characteristic not found");
      }
    } catch (e) {
      _notifyError("فشل الاتصال أو العثور على الجهاز: $e");
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
          if (characteristic.uuid.toString().toLowerCase() ==
              characteristicUuid.toLowerCase()) {
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
    try {
      // 🚀 قطع اتصال "عدواني": ابحث عن أي جهاز طبي متصل بالهاتف وافصله
      final connectedDevices = FlutterBluePlus.connectedDevices;
      for (var device in connectedDevices) {
        if (_isSupportedDevice(device.platformName)) {
          AppLogger.logInfo("🔌 Force disconnecting: ${device.platformName}");
          await device.disconnect();
        }
      }

      if (_connectedDevice != null) {
        AppLogger.logInfo("🔌 Disconnecting from current device: ${_connectedDevice!.platformName}");
        await _connectedDevice!.disconnect();
      }

      // إلغاء جميع الاشتراكات لهذا الجهاز
      for (var sub in _subscriptions) {
        await sub.cancel();
      }
      _subscriptions.clear();

      // تصفير المتغيرات
      _connectedDevice = null;
      _notifyCharacteristic = null;
      _writeCharacteristic = null;

      _updateConnectionState(false);
      AppLogger.logInfo("✅ Disconnected and cleaned up successfully");

    } catch (e) {
      AppLogger.logError("❌ Error during disconnect: $e");
    }

    await _scanSubscription?.cancel();
    _scanSubscription = null;
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

  Future<void> startScan() async {
    AppLogger.logInfo('🟦 BLE: startScan() called');

    // ✅ Check if Bluetooth is ON
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      AppLogger.logInfo("❌ Cannot start scan: Bluetooth is OFF");
      _notifyError("يرجى تفعيل البلوتوث أولاً");
      return;
    }

    // تأكد من الصلاحيات
    await _ensureBlePermissions();

    try {
      AppLogger.logInfo('🟩 Starting BLE scan...');
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

      // استمع لنتائج المسح
      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (results.isEmpty) {
          AppLogger.logInfo("🔍 No devices found yet...");
        } else {
          for (var r in results) {
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : "Unknown";
            AppLogger.logInfo("📡 Found device: $name | RSSI: ${r.rssi}");
          }
        }
      }, onError: (e) {
        AppLogger.logInfo("❌ Scan error: $e");
      });

      // نوقف المسح بعد الوقت المحدد
      Future.delayed(const Duration(seconds: 8), () async {
        await FlutterBluePlus.stopScan();
        AppLogger.logInfo('🛑 Scan stopped (timeout reached)');
      });

    } catch (e) {
      AppLogger.logInfo('🟥 Error while scanning: $e');
    }
  }


  // 🛠 Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
}