import 'package:flutter/material.dart';
import '../models/health_advice.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import '../l10n/app_localizations.dart';


class AdviceScreen extends StatefulWidget {
  const AdviceScreen({super.key});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}


enum SelectedDevice { glucose, temp, bp }

class _AdviceScreenState extends State<AdviceScreen> {
  SelectedDevice selectedDevice = SelectedDevice.glucose; // الافتراضي سكر

  Widget _buildDeviceSelector(AppLocalizations t) {
    return Row(
      children: [
        _buildDeviceCard(
          label: t.glucose,
          icon: Icons.bloodtype,
          isSelected: selectedDevice == SelectedDevice.glucose,
          onTap: () => setState(() => selectedDevice = SelectedDevice.glucose),
        ),
        const SizedBox(width: 8),
        _buildDeviceCard(
          label: t.temperature,
          icon: Icons.thermostat,
          isSelected: selectedDevice == SelectedDevice.temp,
          onTap: () => setState(() => selectedDevice = SelectedDevice.temp),
        ),
        const SizedBox(width: 8),
        _buildDeviceCard(
          label: t.bloodpressure,
          icon: Icons.monitor_heart,
          isSelected: selectedDevice == SelectedDevice.bp,
          onTap: () => setState(() => selectedDevice = SelectedDevice.bp),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
  final Map<String, bool> _expanded = {};
  final Set<String> _reviewed = {};
  final Set<String> _remindLater = {};

  Box? _remindBox; // nullable عشان async gap

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    _remindBox = await Hive.openBox('remindLaterBox');

    // تحميل النصائح اللي اخترنا "ذكرني لاحقًا" قبل كده
    final savedKeys = _remindBox!.keys.cast<String>();
    setState(() {
      _remindLater.addAll(savedKeys);
    });
  }

  Color _getPriorityColor(AdvicePriority priority) {
    switch (priority) {
      case AdvicePriority.high:
        return AppColors.alertHigh;
      case AdvicePriority.medium:
        return Colors.orangeAccent;
      case AdvicePriority.low:
        return Colors.green;
    }
  }

  Icon _getCategoryIcon(AdviceCategory category) {
    switch (category) {
      case AdviceCategory.food:
        return const Icon(Icons.restaurant, size: 28);
      case AdviceCategory.activity:
        return const Icon(Icons.directions_run, size: 28);
      case AdviceCategory.measurement:
        return const Icon(Icons.monitor_heart, size: 28);
      case AdviceCategory.lifestyle:
        return const Icon(Icons.self_improvement, size: 28);
      case AdviceCategory.warning:
        return const Icon(Icons.warning, size: 28);
    }
  }


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text("نصائحك الصحية")),
      body: Column(
          children: [

          const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDeviceSelector(t),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: ValueListenableBuilder(
        valueListenable: Hive.box<HealthAdvice>('adviceBox').listenable(),
        builder: (context, box, _) {
          final adviceList = box.values.where((advice) {
            switch (selectedDevice) {
              case SelectedDevice.glucose:
                return advice.type == DataTypes.glucose;
              case SelectedDevice.temp:
                return advice.type == DataTypes.temp;
              case SelectedDevice.bp:
                return advice.type == DataTypes.bp;
            }
          }).toList();
          AppLogger.logInfo('🧠 advice values = ${box.values}');

          if (adviceList.isEmpty) {
            return const Center(
              child: Text("لا توجد نصائح حالياً", style: TextStyle(fontSize: 18)),
            );
          }

          // 🔹 ترتيب حسب الأولوية
          adviceList.sort(
                (a, b) => b.priority.index.compareTo(a.priority.index),
          );

          // 🔹 تهيئة expanded map
          for (var advice in adviceList) {
            _expanded.putIfAbsent(advice.id, () => false);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adviceList.length,
            itemBuilder: (context, index) {
              final advice = adviceList[index];
              final formattedTime =
              DateFormat('dd/MM/yyyy – HH:mm').format(advice.measurementTime);

              final isExpanded = _expanded[advice.id] ?? false;
              final isReviewed = _reviewed.contains(advice.id);
              final isRemind = _remindLater.contains(advice.id);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _getPriorityColor(advice.priority).withAlpha(38),
                child: ExpansionTile(
                  key: PageStorageKey(advice.id),
                  initiallyExpanded: isExpanded,
                  onExpansionChanged: (val) {
                    setState(() => _expanded[advice.id] = val);
                  },
                  leading: _getCategoryIcon(advice.category),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          advice.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            decoration:
                            isReviewed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isRemind)
                        const Icon(Icons.alarm, color: Colors.blue),
                    ],
                  ),
                  subtitle:
                  Text('وقت القياس: $formattedTime'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        advice.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.check, color: Colors.green),
                          label: const Text("تمت المراجعة"),
                          onPressed: () {
                            setState(() {
                              _reviewed.add(advice.id);
                              _remindLater.remove(advice.id);
                              _remindBox?.delete(advice.id);
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.alarm, color: Colors.blue),
                          label: const Text("ذكرني لاحقًا"),
                          onPressed: _remindBox == null
                              ? null
                              : () {
                            setState(() {
                              _remindLater.add(advice.id);
                              _remindBox!
                                  .put(advice.id, advice.description);
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    )]
      )
    );
  }
}
