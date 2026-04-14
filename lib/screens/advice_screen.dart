import 'package:flutter/material.dart';
import '../models/health_advice.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';


class AdviceScreen extends StatefulWidget {
  const AdviceScreen({super.key});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}


enum SelectedDevice { glucose, temp, bp, ai }

class _AdviceScreenState extends State<AdviceScreen> {
  SelectedDevice selectedDevice = SelectedDevice.glucose;

  Widget _buildDeviceSelector(AppLocalizations t) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
          const SizedBox(width: 8),
          _buildDeviceCard(
            label: "نصائح AI",
            icon: Icons.psychology,
            isSelected: selectedDevice == SelectedDevice.ai,
            onTap: () => setState(() => selectedDevice = SelectedDevice.ai),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
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
            Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(
              color: isSelected ? colorScheme.primary : Colors.black87,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
  
  final Set<String> _reviewed = {};
  final Set<String> _remindLater = {};

  Box? _remindBox;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    _remindBox = await Hive.openBox('remindLaterBox');
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
      case AdviceCategory.food: return const Icon(Icons.restaurant, size: 28);
      case AdviceCategory.activity: return const Icon(Icons.directions_run, size: 28);
      case AdviceCategory.measurement: return const Icon(Icons.monitor_heart, size: 28);
      case AdviceCategory.lifestyle: return const Icon(Icons.self_improvement, size: 28);
      case AdviceCategory.warning: return const Icon(Icons.warning, size: 28);
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
              case SelectedDevice.glucose: return advice.type == DataTypes.glucose;
              case SelectedDevice.temp: return advice.type == DataTypes.temp;
              case SelectedDevice.bp: return advice.type == DataTypes.bp;
              case SelectedDevice.ai: return advice.type == "ai";
            }
          }).toList();

          if (adviceList.isEmpty) {
            return const Center(
              child: Text("لا توجد نصائح حالياً", style: TextStyle(fontSize: 18)),
            );
          }

          adviceList.sort((a, b) => b.measurementTime.compareTo(a.measurementTime));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adviceList.length,
            itemBuilder: (context, index) {
              final advice = adviceList[index];
              final formattedTime = DateFormat('dd/MM HH:mm').format(advice.measurementTime);
              final isReviewed = _reviewed.contains(advice.id);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: advice.type == "ai" 
                  ? Colors.teal.withValues(alpha: 0.1)
                  : _getPriorityColor(advice.priority).withAlpha(38),
                child: ExpansionTile(
                  leading: advice.type == "ai" 
                    ? const Icon(Icons.psychology, color: Colors.teal, size: 28)
                    : _getCategoryIcon(advice.category),
                  title: Text(
                    advice.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isReviewed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('تاريخ النصيحة: $formattedTime'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(advice.description, style: const TextStyle(fontSize: 16)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.check, color: Colors.green),
                          label: const Text("تمت القراءة"),
                          onPressed: () => setState(() => _reviewed.add(advice.id)),
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
