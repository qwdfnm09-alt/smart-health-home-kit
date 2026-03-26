import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/health_alert.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

// ✅ استيراد الترجمة

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

enum SelectedDevice { glucose, temp, bp }

class _AlertsScreenState extends State<AlertsScreen> {
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

  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text('🔔 ${t.healthAlerts}')),
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
              valueListenable: Hive.box<HealthAlert>('alerts').listenable(),
              builder: (context, Box<HealthAlert> box, _) {
                // فلتر حسب الجهاز المختار
                final alerts = box.values
                    .where((a) {
                  switch (selectedDevice) {
                    case SelectedDevice.glucose:
                      return a.type == DataTypes.glucose;
                    case SelectedDevice.temp:
                      return a.type == DataTypes.temp;
                    case SelectedDevice.bp:
                      return a.type == DataTypes.bp;
                  }
                })
                    .toList()
                    .reversed
                    .toList();

                if (alerts.isEmpty) {
                  return Center(
                    child: Text(t.noAlerts),
                  );
                }

                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        title: Text(alert.message),
                        subtitle: Text(
                          '🕒 ${DateFormat('yyyy-MM-dd HH:mm').format(alert.timestamp)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            await alert.delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t.alertDeleted)),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
