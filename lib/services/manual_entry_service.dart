import '../models/health_data.dart';
import 'storage_service.dart';

class ManualEntryService {
  static const String manualSource = 'manual';

  Future<void> saveGlucose({
    required int glucose,
    DateTime? timestamp,
  }) async {
    final data = HealthData.fromGlucoseValues(
      glucose: glucose,
      datetime: timestamp ?? DateTime.now(),
      source: manualSource,
    ).copyWith(
      extra: {
        'entryMode': manualSource,
        'glucose': glucose,
      },
    );

    await StorageService().saveHealthDataWithAdvice(data);
  }

  Future<void> saveTemperature({
    required double temperature,
    DateTime? timestamp,
  }) async {
    final data = HealthData.fromThermometerValues(
      temperature: temperature,
      datetime: timestamp ?? DateTime.now(),
      source: manualSource,
    ).copyWith(
      extra: {
        'entryMode': manualSource,
        'temperature': temperature,
      },
    );

    await StorageService().saveHealthDataWithAdvice(data);
  }

  Future<void> saveBloodPressure({
    required int systolic,
    required int diastolic,
    required int pulse,
    DateTime? timestamp,
  }) async {
    final data = HealthData.fromBloodPressureValues(
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      datetime: timestamp ?? DateTime.now(),
      source: manualSource,
    ).copyWith(
      extra: {
        'entryMode': manualSource,
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
      },
    );

    await StorageService().saveHealthDataWithAdvice(data);
  }
}
