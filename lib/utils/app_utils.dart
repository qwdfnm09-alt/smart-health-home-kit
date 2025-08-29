// lib/utils/app_utils.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'constants.dart';
import 'helper.dart';

void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor ?? Colors.black87,
      duration: const Duration(seconds: 3),
    ),
  );
}

Future<void> launchURL(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

String getDeviceDisplayName(String type) {
  switch (type) {
    case DeviceTypes.glucose:
      return 'جلوكوز الدم';
    case DeviceTypes.bloodPressure:
      return 'ضغط الدم';
    case DeviceTypes.temperature:
      return 'درجة الحرارة';
    default:
      return 'جهاز صحي';
  }
}

String getHealthDataUnit(String type) {
  switch (type) {
    case DeviceTypes.glucose:
      return 'mg/dL';
    case DeviceTypes.bloodPressure:
      return 'mmHg';
    case DeviceTypes.temperature:
      return '°C';
    default:
      return '';
  }
}

Color getReadingColor(double value, String type) {
  const thresholds = Constants.alertThresholds;

  switch (type) {
    case DeviceTypes.glucose:
      return Helper.isOutOfRangeByType(type, value, thresholds)
          ? Colors.red
          : Colors.green;

    case DeviceTypes.temperature:
      return Helper.isOutOfRangeByType(type, value, thresholds)
          ? Colors.orange
          : Colors.green;

    case DeviceTypes.bloodPressure:
      return Helper.isOutOfRangeByType(type, value, thresholds)
          ? Colors.red
          : Colors.green;

    default:
      return Colors.grey;
  }
}
