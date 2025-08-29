import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../devices/thermometer.dart';
import '../models/health_data.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../services/alert_service.dart';
import '../services/pdf_service.dart';
import '../l10n/app_localizations.dart'; // ✅ الترجمة
import '../utils/helper.dart';
import '../utils/constants.dart';



class ThermometerScreen extends StatefulWidget {
  const ThermometerScreen({super.key});

  @override
  State<ThermometerScreen> createState() => _ThermometerScreenState();
}

class _ThermometerScreenState extends State<ThermometerScreen> {
  final BleService _bleService = BleService();
  final Thermometer _thermometer = Thermometer();
  final StorageService _storage = StorageService();

  HealthData? _latestReading;
  List<HealthData> _allReadings = [];
  final List<HealthData> _allData = [];


  // ======= Improvements =======
  bool _isConnecting = false;
  String _selectedFilter = 'week'; // day | week | month
  int _retryCount = 0;
  final int _maxRetries = 3;
  bool _dialogShown = false;
  // ============================


  @override
  void initState() {
    super.initState();
    if (_bleService.isConnected) {
      // ✅ لو الجهاز لسه متوصل مفيش داعي تعيد الاتصال
      _loadReadings();
    } else {
      _startBLEConnection();
    }
    _loadReadings();
    Future.delayed(Duration.zero, () {
      if (!_dialogShown) {
        _dialogShown = true; // ✅ مش هيظهر تاني
        _showConnectDialog(); // ✅ نعرض خيار الاتصال
      }
    });
  }

  void _showConnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("الاتصال بجهاز الحرارة"),
        content: const Text("هل ترغب في الاتصال تلقائيًا بالجهاز الآن؟"),
        actions: [
          TextButton(
            child: const Text("لا"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("نعم"),
            onPressed: () {
              Navigator.pop(context);
              _startBLEConnection(); // ✅ يبدأ الاتصال بعد الموافقة
            },
          ),
        ],
      ),
    );
  }


  void _startBLEConnection() {
    if (_bleService.isConnected) return; // ✅ منع إعادة الاتصال لو متصل بالفعل
    _isConnecting = true;

    setState(() {});


    _bleService.scanAndConnectTo(
      onError: () {
        _retryCount++;
        if (_retryCount <= _maxRetries) {
          // ✅ عرض رسالة للمستخدم
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("إعادة المحاولة... ($_retryCount/$_maxRetries)"),
                duration: const Duration(seconds: 2),
              ),
            );
          }

          Future.delayed(const Duration(seconds: 5), _startBLEConnection);
        } else {
          setState(() => _isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("فشل الاتصال بعد عدة محاولات!")),
          );
        }
      },

      targetName: _thermometer.deviceName,
      serviceUuid: _thermometer.serviceUuid,
      notifyCharUuid: _thermometer.notifyCharUuid,
      onData: (data) async {
        _retryCount = 0; // ✅ إعادة تعيين العدّاد عند النجاح
        final parsed = _thermometer.handleData(data);
        if (data.isEmpty) {
          setState(() => _isConnecting = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("فشل الاتصال بالجهاز!")),
            );
          }
          return;
        }

        

        if (parsed != null) {
          await _storage.addHealthData(parsed);
          await AlertService.checkForAlert(parsed);

          setState(() {
            _latestReading = parsed;
            _allReadings.insert(0, parsed);
            _isConnecting = false; // ✅ بعد الاتصال نوقف حالة التحميل
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("تم حفظ القراءة بنجاح")),
            );
          }
        }
      },
    );
  }

  void _loadReadings() {
    final all = _storage
        .getAllHealthData()
        .where((d) => d.type == 'temperature')
        .toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _allData.clear();
      _allData.addAll(all);   // ✅ عشان الفلترة تشتغل صح
    _allReadings = all.take(20).toList(); // ✅ عرض آخر 20 قراءة فقط
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

    final file = await PdfService.generateTemperatureReport(
      profile: profile,
      data: _allReadings,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.reportGenerated)),
    );

      await PdfService.openFile(file);

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

    final baseline36 = List.generate(
      _allReadings.length,
          (i) => FlSpot(i.toDouble(), 36.0),
    );
    final baseline375 = List.generate(
      _allReadings.length,
          (i) => FlSpot(i.toDouble(), 37.5),
    );




    final spots = _allReadings
        .asMap()
        .entries
        .map((e) => FlSpot(
      e.key.toDouble(),
      e.value.value,
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
              color: Colors.orange,
              barWidth: 3,
              dotData: const  FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withValues(alpha: 0.2),
              ),
            ),
            // خط 36.0
             LineChartBarData(
             spots: baseline36,
              isCurved: false,
             color: Colors.grey.shade600, // ✅ لون أوضح
             barWidth: 1,
               dashArray: [5, 5], // ✅ dashed line
               dotData: const FlDotData(show: false),
            ),
             // خط 37.5
             LineChartBarData(
             spots: baseline375,
             isCurved: false,
             color: Colors.grey.shade600,
             barWidth: 1,
               dashArray: [5, 5],
               dotData: const FlDotData(show: false),
             ),
          ],
            betweenBarsData: [
            // ✅ النطاق الطبيعي (36.0 - 37.5)
            BetweenBarsData(
            fromIndex: 1,
            toIndex: 2,
            color: Colors.green.withValues(alpha:0.1),



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
    _bleService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;


    return Scaffold(
      appBar: AppBar(
        title: Text(t.thermometerDevice),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth),
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
                      Text("🌡️ ${t.lastReading}", style: const TextStyle(fontSize: 18)),

                      _latestReading != null
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(
                          Helper.formatValueByType(_latestReading!.type, _latestReading!.value),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Helper.isOutOfRangeByType(
                              _latestReading!.type,
                              _latestReading!.value,
                              Constants.alertThresholds,
                            )
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                          Text(
                            Helper.isOutOfRangeByType(
                              _latestReading!.type,
                              _latestReading!.value,
                              Constants.alertThresholds,
                            )
                                ? "⚠ ${t.outOfRangeWarning}"
                                : "✅ ${t.withinNormalRange}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            Helper.formatDate(_latestReading!.timestamp),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (!_isConnecting)
                            ElevatedButton.icon(
                              onPressed: _startBLEConnection,
                              icon: const Icon(Icons.bluetooth),
                              label: Text(t.reconnect),
                            ),
                        ],
                      )
                          : Text(t.noReading),
                      const SizedBox(height: 24),

                      Card(
                        color: Colors.grey.shade100,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ملخص القراءات:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  const SizedBox(width: 6),
                                  Text("داخل النطاق: ${_allReadings.where((d) => !Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}"),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.red, size: 18),
                                  const SizedBox(width: 6),
                                  Text("خارج النطاق: ${_allReadings.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),



                      // Chart header + filter
                      Row(
                        children: [
                          Text("${t.chart}:", style: const TextStyle(fontSize: 18)),
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




                      const SizedBox(height: 8),
                      _buildChart(t),

                      Text("${t.recentReadings}:", style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      ..._allReadings.map((data) {
                        final value = Helper.formatValueByType(data.type, data.value);
                        final isOut = Helper.isOutOfRangeByType(data.type, data.value, Constants.alertThresholds);
                        return Card(
                          color: data == _latestReading ? Colors.blue.shade50 : null,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              value,
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


                      // Alerts section
                       if (_allReadings.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds))) ...[
                         Text("⚠️ ${t.alerts}", style: const TextStyle(fontSize: 18)),
                         const SizedBox(height: 8),
                         Text("عدد القراءات خارج النطاق: ${_allReadings.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}"),
                         const SizedBox(height: 8),
                         ..._allReadings
                             .where((d) => Helper.isOutOfRangeByType(
                             d.type, d.value, Constants.alertThresholds))
                             .map((d) => Text(
                           "• ${Helper.formatValueByType(d.type, d.value)} (${Helper.formatDate(d.timestamp)}) خارج النطاق",
                           style: const TextStyle(color: Colors.red),
                         )),
                       ]else
                         const Text("✅ لا توجد قراءات خارج النطاق", style: TextStyle(color: Colors.green)),


                      const SizedBox(height: 24),
                      Text("✅ ${t.autoConnection}"),
                      const SizedBox(height: 16),
                      Text("⚠️ ${t.smartAlertEnabled}"),
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

