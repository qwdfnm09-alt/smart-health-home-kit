import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/animated_routes.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'alerts_screen.dart';
import 'glucose_screen.dart';
import 'blood_pressure_screen.dart';
import 'thermometer_screen.dart';
import '../services/storage_service.dart';
import '../utils/helper.dart';
import '../utils/constants.dart';
import '../models/health_data.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  late AnimationController _controller;
  double _backgroundOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _backgroundOpacity = 1.0;
      });
    });
  }

  void _startScan() async {
    try {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('جاري البحث عن الأجهزة...')),
      );
      _scanResults = [];
      _isScanning = true;
    });
    _bleService.scanForDevices(timeout: const Duration(seconds: 8)).listen((results) {
      setState(() {
        _scanResults = results;
      });
    }).onDone(() {
      setState(() {
        _isScanning = false;
      });
      _bleService.stopScan(); // إضافة هذا السطر
    });
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر بدء المسح: $e')),
      );
    }
  }


  void _stopScan() {
    _bleService.stopScan();
    setState(() {
      _isScanning = false;
    });

  }


  void _connectToDevice(BluetoothDevice device) async {
    try {
      await _bleService.connectToDevice(
        device,
        serviceUuid: "YOUR_SERVICE_UUID",
        notifyCharUuid: "YOUR_NOTIFY_CHAR_UUID",
      );
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/device',
          arguments: device.platformName,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال بالجهاز: $e')),
      );
    }
  }

  List<HealthData> _getLatestReadingsByType(List<HealthData> healthData) {
    final Map<String, HealthData> latest = {};
    for (final data in healthData) {
      if (!latest.containsKey(data.type) || data.timestamp.isAfter(latest[data.type]!.timestamp)) {
        latest[data.type] = data;
      }
    }
    return latest.values.toList();
  }

  @override
  void dispose() {
    _scanResults.clear(); // تفريغ النتائج القديمة
    _controller.dispose();
    _bleService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, createFadeRoute(const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => Navigator.push(context, createFadeRoute(const ReportScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(context, createSlideRoute(const AlertsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          FloatingActionButton(
            onPressed: _isScanning ? _stopScan : _startScan,
            child: Icon(_isScanning ? Icons.stop : Icons.search),
          ),
        ],
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _backgroundOpacity,
            duration: const Duration(seconds: 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/welcome_bg.png',
                  fit: BoxFit.cover,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withValues(alpha: 0)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                    ),
                    child: const Icon(Icons.favorite, size: 60, color: Colors.tealAccent),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: StorageService().healthDataBox.listenable(),
                    builder: (context, box, _) {
                      final healthData = box.values.cast<HealthData>().toList();
                      return ListView(
                        children: <Widget>[
                          Text(
                            t.smartDevices,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (healthData.isNotEmpty) ...[
                            Text(
                              t.recentReadings,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ..._getLatestReadingsByType(healthData).map((data) {
                              final value = Helper.formatValueByType(data.type, data.value);
                              final isOut = Helper.isOutOfRangeByType(data.type, data.value, Constants.alertThresholds);
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    "${data.type} - $value",
                                    style: TextStyle(
                                      color: isOut ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isOut ? "⚠ ${t.outOfRangeWarning}" : "✅ ${t.withinNormalRange}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Text(
                                    Helper.formatDate(data.timestamp),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, createFadeRoute(const ReportScreen())),
                                child: Text(t.viewAll),
                              ),
                            ),
                          ],
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.bloodtype, color: Colors.red),
                              title: Text(t.glucoseDevice),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  createSlideRoute(const GlucoseScreen()),
                                );
                                if (updated == true) setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.favorite, color: Colors.blue),
                              title: Text(t.bloodPressureDevice),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  createSlideRoute(const BloodPressureScreen()),
                                );
                                if (updated == true) setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.thermostat, color: Colors.orange),
                              title: Text(t.thermometerDevice),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  createSlideRoute(const ThermometerScreen()),
                                );
                                if (updated == true) setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, createSlideRoute(const AlertsScreen())),
                            icon: const Icon(Icons.warning),
                            label: Text(t.viewAlerts),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, createFadeRoute(const ReportScreen())),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(t.generateReport),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.availableDevices,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: RefreshIndicator(
                              onRefresh: () async {
                                if (_isScanning) _stopScan();
                                _startScan();
                              },
                              child: Builder(
                                builder: (context) {
                                  final filteredResults = _scanResults
                                      .where((r) => r.device.platformName.isNotEmpty)
                                      .toList();

                                  return filteredResults.isEmpty
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.bluetooth_disabled, size: 50, color: Colors.grey),
                                        const SizedBox(height: 10),
                                        Text(t.noDevicesFound),
                                      ],
                                    ),
                                  )
                                      : ListView.builder(
                                    itemCount: filteredResults.length,
                                    itemBuilder: (context, index) {
                                      final result = filteredResults[index];
                                      final device = result.device;
                                      return Card(
                                        child: ListTile(
                                          title: Text(device.platformName),
                                          subtitle: Text(device.remoteId.str),
                                          trailing: const Icon(Icons.bluetooth),
                                          onTap: () => _connectToDevice(device),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



