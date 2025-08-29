import '../models/health_data.dart';
import '../models/health_alert.dart';
import 'storage_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';
import '../utils/helper.dart';

class AlertService {
  static Future<void> checkForAlert(HealthData data) async {
    String? message;

    // التحقق إذا كانت القراءة خارج النطاق
    if (Helper.isOutOfRangeByType(data.type, data.value, Constants.alertThresholds)) {
      switch (data.type) {
        case 'blood_pressure':
          final bp = Helper.parseBloodPressure(data.value);
          message = "⚠️ قراءة ضغط غير طبيعية: ${bp['systolic']}/${bp['diastolic']} mmHg";
          break;
        case 'glucose':
          message = "⚠️ قراءة سكر غير طبيعية: ${Helper.formatGlucose(data.value)}";
          break;
        case 'temperature':
          message = "⚠️ درجة حرارة غير طبيعية: ${Helper.formatTemperature(data.value)}";
          break;
      }
    }

    if (message != null) {
      await StorageService().addAlert(
        HealthAlert(
          type: data.type,
          message: message,
          timestamp: DateTime.now(),
        ),
      );

      AppLogger.logInfo("🔔 تنبيه جديد: $message");
    }
  }

  static Future<void> checkAndGenerateAlert(HealthData data) async {
    await checkForAlert(data);
  }
}
