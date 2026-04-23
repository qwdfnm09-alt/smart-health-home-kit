import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../devices/glucose_meter.dart';
import '../models/health_data.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../l10n/app_localizations.dart'; // ✅ الترجمة
import '../utils/helper.dart';
import '../utils/constants.dart';
import 'dart:async';
import '../utils/device_type.dart';
import '../utils/logger.dart';




class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({super.key});

  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  final BleService _bleService = BleService();
  final GlucoseMeter _glucoseMeter = GlucoseMeter();
  final StorageService _storage = StorageService();


  HealthData? _latestReading;
  List<HealthData> _allReadings = [];
  final List<HealthData> _allData = [];



  // ======= Improvements =======
  bool _isConnecting = false;
  String _selectedFilter = 'week'; // day | week | month
  StreamSubscription<Map<String, dynamic>>? _parsedSub;
  // ============================

  VoidCallback? _boxListener;




  @override
  void initState() {
    super.initState();

    // ✅ بدء الاتصال التلقائي إذا تم تمرير جهاز
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final device = ModalRoute.of(context)?.settings.arguments;
      if (device is BluetoothDevice) {
        _startBLEConnectionWithDevice(device);
      }
    });

    // listen to hive box changes so screen updates when new data saved
    final box = StorageService().healthDataBox;
    _boxListener = () {
      // when box changes, reload readings from storage
      _loadReadings();
    };
    box.listenable().addListener(_boxListener!);

    _loadReadings(); // ✅ تحديث القائمة بعد كل قراءة جديدة

    // ✅ لو متصل مسبقًا
    if (_bleService.isConnected) {
      _loadReadings();
    }

    // ✅ استمع للداتا المتفككة من DataParser
    _parsedSub = _bleService.onParsedData.listen((parsed) async {
      if (parsed['device'] == 'glucose') {
        final healthData = parsed['healthData'];
        if (healthData is! HealthData) return;

        setState(() {
          _latestReading = healthData;
          _isConnecting = false;
        });

        _loadReadings(); // ✅ التحديث يأتي من البيانات المحفوظة عبر BleService

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ قراءة السكر")),
          );
        }
      }
    });
  }





  void _startBLEConnectionWithDevice(BluetoothDevice device) {
    setState(() => _isConnecting = true);

    _bleService.connectToDevice(
      device,
      serviceUuid: _glucoseMeter.serviceUuid,
      notifyCharUuid: _glucoseMeter.notifyCharUuid,
      deviceType: DeviceType.glucose,
      onError: () {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
      },
    );
  }

  void _startBLEConnection() {
    if (_bleService.isConnected) return;

    setState(() => _isConnecting = true);

    _bleService.scanAndConnectTo(
      targetName: _glucoseMeter.deviceName, // أو الاسم اللي انت معرفه
      serviceUuid: _glucoseMeter.serviceUuid,
      notifyCharUuid: _glucoseMeter.notifyCharUuid,
      deviceType: DeviceType.glucose, // ✅ مهم عشان DataParser يعرف
      onError: () {
        AppLogger.logInfo("❌ Connection failed - check name/uuid/permissions");
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل الاتصال")),
        );
      },
    );
  }


  void _loadReadings() {
    final all = _storage
        .getAllHealthData()
        .where((d) => d.type == DataTypes.glucose)
        .toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (!mounted) return;
    setState(() {
      _allData.clear();
      _allData.addAll(all); // ✅ عشان الفلترة تشتغل صح
    _allReadings = all; // ✅ عرض آخر 20 قراءة فقط
    if (_allReadings.isNotEmpty) _latestReading = _allReadings.first;
    });
  }

  void _filterReadings() {
    final now = DateTime.now();
    setState(() {
      _allReadings = _allData.where((d) {
        if (_selectedFilter == 'day') {
          return d.timestamp.isAfter(now.subtract(const Duration(days: 1)));
        } else if (_selectedFilter == 'week') {
          return d.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        } else {
          return d.timestamp.isAfter(now.subtract(const Duration(days: 30)));
        }
      }).toList();
      // ✅ ضيف الترتيب حسب التاريخ الأحدث
      _allReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // ✅ خليه يحدد آخر قراءة بعد الفلترة
      if (_allReadings.isNotEmpty) _latestReading = _allReadings.first;
    });
  }

  void _generatePdfReport() async {
    final t = AppLocalizations.of(context)!; // ✅ أضف ده هنا
    final profile = _storage.getUserProfile();
    if (profile == null) return;

    final allData = _storage
        .getAllHealthData()
        .where((d) => d.type == DataTypes.glucose)
        .toList();

    final file = await PdfService.generateReport(
      profile: profile,
      healthDataList: allData,
    );

    if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reportGenerated)),
      );

      await PdfService.openFile(file);

  }

  Widget _buildLatestReadingCard(AppLocalizations t) {
    if (_latestReading == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Text(t.noReading)),
        ),
      );
    }

    final isOut = Helper.isOutOfRangeByType(
      _latestReading!.type,
      _latestReading!.value,
      Constants.alertThresholds,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isOut
              ? [Colors.red.shade300, Colors.red.shade600]
              : [Colors.green.shade300, Colors.green.shade600],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bloodtype, color: Colors.white),
              const SizedBox(width: 6),
              Text(t.lastReading, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${_latestReading!.value} ${_latestReading!.unit}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            isOut ? t.outOfRangeWarning : t.withinNormalRange,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            Helper.formatDate(_latestReading!.timestamp),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(AppLocalizations t) {
    final inRange = _allReadings.where((d) =>
    !Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length;

    final outRange = _allReadings.where((d) =>
        Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length;

    return Row(
      children: [
        Expanded(child: _buildStatCard(t.withinNormalRange, inRange, Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(t.outOfRangeWarning, outRange, Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            color == Colors.green ? Icons.check_circle : Icons.warning,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: color)),
          Text(
            "$value",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingItem(HealthData data, AppLocalizations t) {
    final isOut = Helper.isOutOfRangeByType(
        data.type, data.value, Constants.alertThresholds);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          isOut ? Icons.warning : Icons.check_circle,
          color: isOut ? Colors.red : Colors.green,
        ),
        title: Text(
          "${data.value} ${data.unit}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOut ? Colors.red : Colors.green,
          ),
        ),
        subtitle: Text(Helper.formatDate(data.timestamp)),
      ),
    );
  }

  Widget _buildChart(AppLocalizations t) {
    if (_allReadings.length < 2) {
      return Card(
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(t.notEnoughData, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        ),
      );
    }


    final spots = _allReadings
        .asMap()
        .entries
        .map((e) => FlSpot(
      e.key.toDouble(),
      e.value.value.toDouble(),
    ))
        .toList();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        key: ValueKey(_allReadings.length),
        height: 250,
        child: LineChart(
        LineChartData(
          gridData: const  FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < _allReadings.length) {
                    final dt = _allReadings[index].timestamp;
                    return Text(
                      "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, _) => Text('${value.toInt()}'),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: const  FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withValues(alpha: 0.2)
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // تأكد من تنظيف أي اتصال/اشتراك في BleService
    _parsedSub?.cancel();
    try {
      if (_boxListener != null) {
        StorageService().healthDataBox.listenable().removeListener(_boxListener!);
      }
    } catch (_) {}
    _bleService.disconnect();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;


    return Scaffold(
      appBar: AppBar(
        title: Text(t.glucoseDevice),
        actions: [
          IconButton(
            icon: Icon(
              _bleService.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: _bleService.isConnected ? Colors.green : null,
            ),
            onPressed: _startBLEConnection,
          ),

          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
          )
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isConnecting
              ? const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("جارٍ الاتصال بالجهاز...", style: TextStyle(fontSize: 16)),
            ],
          )

              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // 🔥 كارت آخر قراءة
                      _buildLatestReadingCard(t),

                      const SizedBox(height: 16),
                      // 🔥 Summary
                      _buildSummary(t),

                      const SizedBox(height: 10),
                      Divider(color: Colors.grey.shade300),

                      const SizedBox(height: 16),

                      // 🔥 Chart
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.bar_chart, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Text(t.chart, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Spacer(),
                                  DropdownButton<String>(
                                    value: _selectedFilter,
                                    items: const [
                                      DropdownMenuItem(value: 'day', child: Text('يوم')),
                                      DropdownMenuItem(value: 'week', child: Text('أسبوع')),
                                      DropdownMenuItem(value: 'month', child: Text('شهر')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFilter = value!;
                                        _filterReadings();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildChart(t),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 🔥 Recent readings
                      Text(t.recentReadings, style: const TextStyle(fontSize: 18)),

                      const SizedBox(height: 8),
                      if (_allReadings.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(Icons.bloodtype, size: 60, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text("ابدأ بقياس أول قراءة", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      else
                        ..._allReadings.map((data) => _buildReadingItem(data, t)),

                      const SizedBox(height: 20),
                    ],
                  ),
          ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, true); // ✅ يرجع للـ HomeScreen
        },
        icon: const Icon(Icons.check),
        label: Text(t.done), // أو "تم" لو أضفت المفتاح في الترجمة
      ),
    );
  }
}
