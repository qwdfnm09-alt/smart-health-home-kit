import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../models/health_data.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';


enum ChartFilter { week, month, all, day }
enum SelectedDevice { glucose, temp, bp }


class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  ChartFilter selectedFilter = ChartFilter.all;
  SelectedDevice selectedDevice = SelectedDevice.glucose; // الافتراضي سكر

  Widget _buildDeviceSelector(AppLocalizations t) {
    return Row(
      children: [
        _buildDeviceCard(
          label: t.glucose,
          icon: Icons.bloodtype,
          isSelected: selectedDevice == SelectedDevice.glucose,
          onTap: () {
            setState(() {
              selectedDevice = SelectedDevice.glucose;
            });
          },
        ),
        const SizedBox(width: 8),
        _buildDeviceCard(
          label: t.temperature,
          icon: Icons.thermostat,
          isSelected: selectedDevice == SelectedDevice.temp,
          onTap: () {
            setState(() {
              selectedDevice = SelectedDevice.temp;
            });
          },
        ),
        const SizedBox(width: 8),
        _buildDeviceCard(
          label: t.bloodpressure,
          icon: Icons.monitor_heart,
          isSelected: selectedDevice == SelectedDevice.bp,
          onTap: () {
            setState(() {
              selectedDevice = SelectedDevice.bp;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? Colors.blue : Colors.grey.shade300;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;


    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  List<HealthData> _filterData(List<HealthData> data) {
    final now = DateTime.now();
    List<HealthData> filtered;
    
    if (selectedFilter == ChartFilter.day) {
      filtered = data.where((d) => d.timestamp.isAfter(now.subtract(const Duration(days: 1)))).toList();
    } else if (selectedFilter == ChartFilter.week) {
      filtered = data.where((d) => d.timestamp.isAfter(now.subtract(const Duration(days: 7)))).toList();
    } else if (selectedFilter == ChartFilter.month) {
      filtered = data.where((d) => d.timestamp.isAfter(now.subtract(const Duration(days: 30)))).toList();
    } else {
      filtered = data;
    }

    return _sampleData(filtered);
  }

  // 📉 دالة تقليل البيانات (Sampling) لتحسين الأداء
  List<HealthData> _sampleData(List<HealthData> data, {int maxPoints = 50}) {
    if (data.length <= maxPoints) return data;

    final List<HealthData> sampled = [];
    final double step = data.length / maxPoints;

    for (int i = 0; i < maxPoints; i++) {
      final int index = (i * step).floor();
      sampled.add(data[index]);
    }
    
    // تأكد دائماً من وجود آخر قراءة لأهميتها للمستخدم
    if (data.isNotEmpty && !sampled.contains(data.last)) {
      sampled.removeLast();
      sampled.add(data.last);
    }

    return sampled;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Charts"),
        actions: [
          PopupMenuButton<ChartFilter>(
            onSelected: (value) {
              setState(() => selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: ChartFilter.day, child: Text("Last 1 days")),
              const PopupMenuItem(value: ChartFilter.week, child: Text("Last 7 days")),
              const PopupMenuItem(value: ChartFilter.month, child: Text("Last 30 days")),
              const PopupMenuItem(value: ChartFilter.all, child: Text("All Data")),
            ],
          ),
        ],
      ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildDeviceSelector(t),      // ✅ الكروت الجديدة فوق
              const SizedBox(height: 24),

              // ✅ هنا نعرض chart واحد بس حسب الجهاز المختار
              if (selectedDevice == SelectedDevice.glucose) ...[
                GlucoseChart(filter: _filterData),
              ] else if (selectedDevice == SelectedDevice.temp) ...[
                TempChart(filter: _filterData),
              ] else if (selectedDevice == SelectedDevice.bp) ...[
                BpChart(filter: _filterData),
              ],
            ],
          ),
        ),
    );
  }
}

class GlucoseChart extends StatelessWidget {
  final List<HealthData> Function(List<HealthData>) filter;
  const GlucoseChart({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    final glucoseData = filter(
      storage.getAllByType(DataTypes.glucose),
    );

    if (glucoseData.length < 2) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              "Not enough glucose data",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];

    for (int i = 0; i < glucoseData.length; i++) {
      final data = glucoseData[i];
      spots.add(
        FlSpot(i.toDouble(), data.value), // use index for X-axis
      );
    }

    final allValues = spots.map((e) => e.y).toList();
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);

    // 🔹 مدى منطقي للسكر (يحمي من القيم الشاذة)
    final minY = ((minVal - 15).clamp(50.0, double.infinity)).toDouble();
    final maxY = ((maxVal + 15).clamp(0.0, 300.0)).toDouble();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Glucose (mg/dL)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                // 🧭 Y Axis
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: 25,
                    getTitlesWidget: (value, _) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                // 🧭 X Axis (نقلل التكدس)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: glucoseData.length > 6 ? 2 : 1,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index >= 0 && index < glucoseData.length) {
                        final dt = glucoseData[index].timestamp;
                        return Text(
                          "${dt.day}/${dt.month}",
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



class TempChart extends StatelessWidget {
  final List<HealthData> Function(List<HealthData>) filter;
  const TempChart({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    // نفس المصدر القديم بس بعد الفلتر
    final tempData = filter(
      storage.getAllByType(DataTypes.temp), // "temp" زي ما عندك
    );

    if (tempData.length < 2) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              "Not enough temperature data",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];

    for (int i = 0; i < tempData.length; i++) {
      final temp = tempData[i].value;

      // تجاهل أي قراءة غير منطقية طبيًا
      if (temp < 34 || temp > 42) continue;

      spots.add(
        FlSpot(i.toDouble(), temp),
      );
    }
    if (spots.length < 2) {
      return const Center(
        child: Text("No valid temperature readings"),
      );
    }


    // تحديد المدى المناسب للمحور Y
    final allValues = spots.map((e) => e.y).toList();
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);

    // مدى منطقي لدرجات الحرارة (مع شوية margin)
    final minY = ((minVal - 0.5).clamp(34.0, double.infinity)).toDouble();
    final maxY = ((maxVal + 0.5).clamp(0.0, 42.0)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Temperature (°C)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 0.5,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(1),
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
                      if (index >= 0 && index < tempData.length) {
                        final dt = tempData[index].timestamp;
                        return Text(
                          "${dt.day}/${dt.month}",
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class BpChart extends StatelessWidget {
  final List<HealthData> Function(List<HealthData>) filter;
  const BpChart({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();

    // نفس المصدر القديم بالظبط
    final allReadings = filter(storage.getAllByType(DataTypes.bp));

    if (allReadings.length < 2) {
      return Card(
        color: Colors.grey.shade100,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              "Not enough blood pressure data",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    final pulseSpots = <FlSpot>[];

    for (int i = 0; i < allReadings.length; i++) {
      final data = allReadings[i];
      systolicSpots.add(
        FlSpot(i.toDouble(), data.systolic?.toDouble() ?? 0),
      );
      diastolicSpots.add(
        FlSpot(i.toDouble(), data.diastolic?.toDouble() ?? 0),
      );
      pulseSpots.add(
        FlSpot(i.toDouble(), data.pulse?.toDouble() ?? 0),
      );
    }

    // الحدود الطبيعية من Constants.bpThresholds
    final sysMin =
    Constants.bpThresholds[DataTypes.bp]!["bp_systolic"]!["min"]!;
    final sysMax =
    Constants.bpThresholds[DataTypes.bp]!["bp_systolic"]!["max"]!;
    final diaMin =
    Constants.bpThresholds[DataTypes.bp]!["bp_diastolic"]!["min"]!;
    final diaMax =
    Constants.bpThresholds[DataTypes.bp]!["bp_diastolic"]!["max"]!;

    // 📊 تحديد مدى Y تلقائيًا بناءً على القيم والحدود
    final allValues = [
      ...systolicSpots.map((e) => e.y),
      ...diastolicSpots.map((e) => e.y),
      ...pulseSpots.map((e) => e.y),
      sysMin,
      sysMax,
      diaMin,
      diaMax,
    ];
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);

    final minY = ((minVal - 10).clamp(30, double.infinity)).toDouble();
    final maxY = ((maxVal + 10).clamp(0, 250)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Blood Pressure",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            key: ValueKey(allReadings.length),
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
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
                        if (index >= 0 && index < allReadings.length) {
                          final dt = allReadings[index].timestamp;
                          return Text(
                            "${dt.day}/${dt.month}",
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: sysMin,
                      color: Colors.blue.shade300,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.centerLeft,
                        labelResolver: (_) => "SYS Min",
                      ),
                    ),
                    HorizontalLine(
                      y: sysMax,
                      color: Colors.blue.shade300,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.centerLeft,
                        labelResolver: (_) => "SYS Max",
                      ),
                    ),
                    HorizontalLine(
                      y: diaMin,
                      color: Colors.green.shade300,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.centerLeft,
                        labelResolver: (_) => "DIA Min",
                      ),
                    ),
                    HorizontalLine(
                      y: diaMax,
                      color: Colors.green.shade300,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.centerLeft,
                        labelResolver: (_) => "DIA Max",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
