import '../models/health_data.dart';
import '../models/health_alert.dart';
import 'storage_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';


class AlertService {
  static Future<void> checkForAlert(HealthData data) async {
    String? message;

    switch (data.type) {
      case DataTypes.bp:
        final systolic = data.systolic ?? 0;
        final diastolic = data.diastolic ?? 0;
        final bpRange = Constants.bpThresholds[DataTypes.bp]!;

        if (systolic > bpRange["bp_systolic"]!["max"]! || diastolic > bpRange["bp_diastolic"]!["max"]!) {
          message = "⚠️ ضغط مرتفع: ${systolic.toInt()}/${diastolic.toInt()} mmHg";
        } else if (systolic < bpRange["bp_systolic"]!["min"]! || diastolic < bpRange["bp_diastolic"]!["min"]!) {
          message = "⚠️ ضغط منخفض: ${systolic.toInt()}/${diastolic.toInt()} mmHg";
        }
        break;

      case DataTypes.glucose:
        final glucose = data.glucose ?? data.value;
        final range = Constants.alertThresholds[DataTypes.glucose]!;

        if (glucose > range["max"]!) {
          message = "⚠️ سكر مرتفع: ${glucose.toInt()} mg/dL";
        } else if (glucose < range["min"]!) {
          message = "⚠️ سكر منخفض: ${glucose.toInt()} mg/dL";
        }
        break;

      case DataTypes.temp:
        final temp = data.temperature ?? data.value;
        final range = Constants.alertThresholds[DataTypes.temp]!;

        if (temp > range["max"]!) {
          message = "⚠️ حرارة مرتفعة: ${temp.toStringAsFixed(1)} °C";
        } else if (temp < range["min"]!) {
          message = "⚠️ حرارة منخفضة: ${temp.toStringAsFixed(1)} °C";
        }
        break;
    }

    if (message != null) {
      final storage = StorageService();

      // هات آخر تنبيه
      final alerts = storage.getAllAlerts();

      bool exists = alerts.any((a) =>
      a.type == data.type &&
          a.message == message &&
          a.timestamp.difference(data.timestamp).inSeconds.abs() < 5);

      if (!exists) {
        await storage.addAlert(
          HealthAlert(
            type: data.type,
            message: message,
            timestamp: data.timestamp,
          ),
        );
      }
      AppLogger.logInfo("🔔 تنبيه جديد: $message");
    }
  }
  static Future<void> checkAndGenerateAlert(HealthData data) async {
    await checkForAlert(data);
  }
}
