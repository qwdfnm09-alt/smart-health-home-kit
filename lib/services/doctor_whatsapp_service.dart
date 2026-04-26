import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../utils/helper.dart';

class DoctorWhatsAppService {
  static String normalizePhone(String phone) {
    var normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    } else if (normalized.startsWith('00')) {
      normalized = normalized.substring(2);
    }

    return normalized;
  }

  static bool isValidPhone(String phone) {
    final normalized = normalizePhone(phone);
    return normalized.length >= 10;
  }

  static String buildReportMessage({
    required UserProfile profile,
    required List<HealthData> healthData,
    required String reportLabel,
    required bool isArabic,
  }) {
    final sortedData = [...healthData]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final conditions = profile.conditions
        .where((condition) => condition.trim().isNotEmpty)
        .join(', ');

    final readingsText = sortedData
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final reading = entry.value;
          final value = Helper.formatDisplayText(reading);
          final date = Helper.formatDate(reading.timestamp);

          return isArabic
              ? '$index. $value\nالتاريخ: $date'
              : '$index. $value\nDate: $date';
        })
        .join('\n\n');

    return isArabic
        ? 'تقرير صحي من تطبيق T-MED\n'
            'نوع التقرير: $reportLabel\n'
            'الاسم: ${profile.name}\n'
            'العمر: ${profile.age}\n'
            'الجنس: ${profile.gender}\n'
            'الأمراض المزمنة: ${conditions.isEmpty ? 'لا يوجد' : conditions}\n'
            'عدد القراءات: ${healthData.length}\n\n'
            'القراءات:\n$readingsText'
        : 'Health report from T-MED\n'
            'Report type: $reportLabel\n'
            'Name: ${profile.name}\n'
            'Age: ${profile.age}\n'
            'Gender: ${profile.gender}\n'
            'Chronic conditions: ${conditions.isEmpty ? 'None' : conditions}\n'
            'Total readings: ${healthData.length}\n\n'
            'Readings:\n$readingsText';
  }

  static Future<void> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = normalizePhone(phone);
    final whatsappUri = Uri.parse(
      'https://wa.me/$normalizedPhone?text=${Uri.encodeComponent(message)}',
    );

    final launched = await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const HttpException('Could not open WhatsApp');
    }
  }
}
