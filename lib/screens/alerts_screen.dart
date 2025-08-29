import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/health_alert.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart'; // ✅ استيراد الترجمة

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final storage = StorageService();
    final t = AppLocalizations.of(context)!; // ✅ الترجمة

    return Scaffold(
      appBar: AppBar(title: Text('🔔 ${t.healthAlerts}')), // ✅ عنوان مترجم
      body: ValueListenableBuilder(
        valueListenable: Hive.box<HealthAlert>('alerts').listenable(),
        builder: (context, Box<HealthAlert> box, _) {
          final alerts = box.values.toList().reversed.toList();

          if (alerts.isEmpty) {
            return Center(child: Text(t.noAlerts)); // ✅ لا توجد تنبيهات
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
                    '🕒 ${alert.timestamp.toLocal()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

