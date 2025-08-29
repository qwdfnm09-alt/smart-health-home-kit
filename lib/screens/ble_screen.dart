import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../config/ble_config.dart';

class BleScreen extends StatefulWidget {
  const BleScreen({super.key});

  @override
  State<BleScreen> createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  final BleService _bleService = BleService();

  List<ScanResult> _devices = [];
  Map<String, dynamic>? _latestData;

  // NEW: علشان ما يحصلش duplicated listeners
  StreamSubscription<Map<String, dynamic>>? _dataSub;
  StreamSubscription<bool>? _connSub;

  bool _isConnected = false; // NEW

  @override
  void initState() {
    super.initState();

    // اسمع حالة الاتصال
    _connSub = _bleService.connectionState.listen((connected) {
      setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  void _startScan() {
    _bleService.scanForDevices().listen((results) {
      setState(() {
        _devices = results;
      });
    });
  }

  void _stopScan() {
    _bleService.stopScan();
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(
        device,
        serviceUuid: BleConfig.serviceUuid,
        notifyCharUuid: BleConfig.notifyCharUuid,
        writeCharUuid: BleConfig.writeCharUuid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('متصل بـ ${device.platformName}')),
      );

      // NEW: سمع ستريم الداتا مرة واحدة بس
      await _dataSub?.cancel();
      _dataSub = _bleService.onParsedData.listen((parsed) {
        setState(() => _latestData = parsed);
        debugPrint("📊 بيانات مستلمة: $parsed");
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال: $e')),
      );
    }
  }

  Future<void> _disconnect() async {
    await _bleService.disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم فصل الاتصال')),
    );
    setState(() => _latestData = null);
    await _dataSub?.cancel();
    _dataSub = null;
  }

  @override
  Widget build(BuildContext context) {
    final status = _isConnected ? 'متصل' : 'غير متصل';

    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة BLE — $status'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.link : Icons.link_off),
            onPressed: _disconnect,
            tooltip: 'قطع الاتصال',
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('ابدأ البحث'),
                onPressed: _startScan,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('أوقف البحث'),
                onPressed: _stopScan,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index].device;
                return ListTile(
                  title: Text(device.platformName.isEmpty ? '(بدون اسم)' : device.platformName),
                  subtitle: Text(device.remoteId.str),
                  trailing: ElevatedButton(
                    child: const Text('اتصل'),
                    onPressed: () => _connect(device),
                  ),
                );
              },
            ),
          ),
          if (_latestData != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("آخر قراءة:", style: Theme.of(context).textTheme.titleLarge),
                  Text("🩺 الضغط: ${_latestData!['bloodPressure']}"),
                  Text("🍬 السكر: ${_latestData!['glucose']}"),
                  Text("🌡 الحرارة: ${_latestData!['temperature']}"),
                  Text("⏱ الوقت: ${_latestData!['timestamp']}"),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
