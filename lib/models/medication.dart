import 'package:hive/hive.dart';

class Medication extends HiveObject {
  final String id;
  final String name;
  final int timesPerDay;
  final List<int> doseTimes;
  final int pillsPerBox;
  int remainingPills;
  bool isActive;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.name,
    required this.timesPerDay,
    List<int>? doseTimes,
    required this.pillsPerBox,
    required this.remainingPills,
    this.isActive = true,
    required this.createdAt,
  }) : doseTimes = _normalizeDoseTimes(
          doseTimes ?? defaultDoseTimesFor(timesPerDay),
          timesPerDay,
        );

  Medication copyWith({
    String? id,
    String? name,
    int? timesPerDay,
    List<int>? doseTimes,
    int? pillsPerBox,
    int? remainingPills,
    bool? isActive,
    DateTime? createdAt,
  }) {
    final nextTimesPerDay = timesPerDay ?? this.timesPerDay;
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      timesPerDay: nextTimesPerDay,
      doseTimes: doseTimes ?? this.doseTimes,
      pillsPerBox: pillsPerBox ?? this.pillsPerBox,
      remainingPills: remainingPills ?? this.remainingPills,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  List<int> get normalizedDoseTimes => _normalizeDoseTimes(doseTimes, timesPerDay);

  static List<int> defaultDoseTimesFor(int timesPerDay) {
    final predefinedTimes = <int, List<int>>{
      1: [9 * 60],
      2: [9 * 60, 21 * 60],
      3: [9 * 60, 15 * 60, 21 * 60],
      4: [9 * 60, 13 * 60, 17 * 60, 21 * 60],
    };

    if (predefinedTimes.containsKey(timesPerDay)) {
      return List<int>.from(predefinedTimes[timesPerDay]!);
    }

    if (timesPerDay <= 1) {
      return [9 * 60];
    }

    const startMinutes = 9 * 60;
    const endMinutes = 21 * 60;
    final interval = (endMinutes - startMinutes) / (timesPerDay - 1);

    return List<int>.generate(timesPerDay, (index) {
      return (startMinutes + (interval * index)).round();
    });
  }

  static List<int> _normalizeDoseTimes(List<int> source, int timesPerDay) {
    final sanitized = source
        .where((minutes) => minutes >= 0 && minutes < 24 * 60)
        .toSet()
        .toList()
      ..sort();

    if (sanitized.length == timesPerDay && timesPerDay > 0) {
      return sanitized;
    }

    return defaultDoseTimesFor(timesPerDay);
  }
}
