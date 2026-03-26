import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../devices/blood_pressure.dart';
import '../models/blood_pressure_reading.dart' show BloodPressureReading;
import '../models/health_data.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../services/alert_service.dart';
import '../services/pdf_service.dart';
import '../l10n/app_localizations.dart'; // ✅ استيراد الترجمة
import '../utils/helper.dart';
import '../utils/constants.dart';
import 'dart:async';
import '../utils/device_type.dart';
import '../utils/logger.dart';




class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  final BleService _bleService = BleService();
  final BloodPressureMonitor _bpMonitor = BloodPressureMonitor();
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
      if (parsed['device'] == 'blood_pressure') {
        final bp = BloodPressureReading.fromMap(parsed);


        // هنا حوّل GlucoseReading -> HealthData (علشان التخزين والـ UI اللي مبني على HealthData)
        final healthData = HealthData(
          type: "bp",
          value: (bp.systolic * 1000 + bp.diastolic * 10 + bp.pulse).toDouble(),
          timestamp: bp.datetime,
          unit: "mmHg",
          source: bp.source,
        );

        // 1️⃣ احفظ القياس
        await _storage.addHealthData(healthData);
        // 2️⃣ هات بيانات المستخدم (لازم await)
        final userProfile =_storage.getUserProfile();
        if (userProfile == null) return;

          // 4️⃣ احفظ النصائح
        await _storage.saveHealthDataWithAdvice(healthData);
          // 5️⃣ Alerts
          AlertService.checkForAlert(healthData);
          // 6️⃣ UI update
          setState(() {
            _latestReading = healthData;
            _allReadings.insert(0, healthData);
            _isConnecting = false;
          });

          _loadReadings(); // ✅ تحديث القائمة بعد كل قراءة جديدة

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم حفظ قراءة الضغط")),
            );
          }
        }
    });
  }




  void _startBLEConnection() {
    if (_bleService.isConnected) return; // ✅ منع إعادة الاتصال لو متصل بالفعل

    setState(() => _isConnecting = true);




    _bleService.scanAndConnectTo(
    targetName: _bpMonitor.deviceName,
      serviceUuid: _bpMonitor.serviceUuid,
      notifyCharUuid: _bpMonitor.notifyCharUuid,
      deviceType: DeviceType.bloodPressure,
      onData: (_) {},
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
        .where((d) => d.type == DataTypes.bp)
        .toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _allReadings = all;
      _allData.clear();
      _allData.addAll(all);   // ✅ عشان الفلترة تشتغل صح
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
        .where((d) => d.type == DataTypes.bp)
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

    final isOut = Helper.isBloodPressureAbnormal(_latestReading!);

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
              const Icon(Icons.monitor_heart, color: Colors.white),
              const SizedBox(width: 6),
              Text(t.lastReading, style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Helper.formatDisplayText(_latestReading!),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            isOut ? " ${t.outOfRangeWarning}" : " ${t.withinNormalRange}",
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
    final inRange = _allReadings
        .where((d) => !Helper.isBloodPressureAbnormal(d))
        .length;

    final outRange = _allReadings
        .where((d) => Helper.isBloodPressureAbnormal(d))
        .length;

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
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingItem(HealthData data, AppLocalizations t) {
    final isOut = Helper.isBloodPressureAbnormal(data);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          isOut ? Icons.warning : Icons.check_circle,
          color: isOut ? Colors.red : Colors.green,
        ),
        title: Text(
          Helper.formatDisplayText(data),
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
            child: Text(
              t.notEnoughData,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    final pulseSpots = <FlSpot>[];

    for (int i = 0; i < _allReadings.length; i++) {
      final data = _allReadings[i];
      systolicSpots.add(FlSpot(i.toDouble(), data.systolic?.toDouble() ?? 0));
      diastolicSpots.add(FlSpot(i.toDouble(), data.diastolic?.toDouble() ?? 0));
      pulseSpots.add(FlSpot(i.toDouble(), data.pulse?.toDouble() ?? 0));

    }

    // الحدود الطبيعية من Constants.bpThresholds
    final sysMin = Constants.bpThresholds[DataTypes.bp]!["bp_systolic"]!["min"]!;
    final sysMax = Constants.bpThresholds[DataTypes.bp]!["bp_systolic"]!["max"]!;
    final diaMin = Constants.bpThresholds[DataTypes.bp]!["bp_diastolic"]!["min"]!;
    final diaMax = Constants.bpThresholds[DataTypes.bp]!["bp_diastolic"]!["max"]!;

    // 📊 تحديد المدى تلقائيًا بناءً على القيم والحدود
    final allValues = [
      ...systolicSpots.map((e) => e.y),
      ...diastolicSpots.map((e) => e.y),
      ...pulseSpots.map((e) => e.y),
      sysMin, sysMax, diaMin, diaMax
    ];
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);

    final minY = ((minVal - 10).clamp(30, double.infinity)).toDouble();
    final maxY = ((maxVal + 10).clamp(0, 250)).toDouble();


    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        key: ValueKey(_allReadings.length),
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 10,
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index >= 0 && index < _allReadings.length) {
                      final dt = _allReadings[index].timestamp;
                      return Text(
                        "${dt.day}/${dt.month}",
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            minY: minY,
            maxY: maxY,


            lineBarsData: [
              // ✅ الضغط الانقباضي
              LineChartBarData(
                spots: systolicSpots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
              // ✅ الضغط الانبساطي
              LineChartBarData(
                spots: diastolicSpots,
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
              // ✅ النبض
              LineChartBarData(
                spots: pulseSpots,
                isCurved: true,
                color: Colors.orange,
                barWidth: 2,
                dotData: const FlDotData(show: true),
              ),
            ],

            // 🧭 خطوط الحد الأدنى والأقصى (Reference Lines)
            extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(y: sysMin, color: Colors.blue.shade300, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.centerLeft, labelResolver: (_) => "SYS Min")),
            HorizontalLine(y: sysMax, color: Colors.blue.shade300, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.centerLeft, labelResolver: (_) => "SYS Max")),
            HorizontalLine(y: diaMin, color: Colors.green.shade300, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.centerLeft, labelResolver: (_) => "DIA Min")),
            HorizontalLine(y: diaMax, color: Colors.green.shade300, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.centerLeft, labelResolver: (_) => "DIA Max")),

           ]),
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
        title: Text(t.bloodPressureDevice),
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isConnecting
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                              const Icon(Icons.bar_chart, color: Colors.orange),
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
                      Icon(Icons.device_thermostat, size: 60, color: Colors.grey),
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

