import '../models/medication.dart';
import '../models/medication_intake.dart';
import '../utils/logger.dart';
import 'medication_notification_service.dart';
import 'storage_service.dart';

class MedicationSummary {
  final Medication medication;
  final int totalDoses;
  final int takenDoses;
  final int missedDoses;
  final int pendingDoses;
  final double adherenceRate;
  final bool isOutOfStock;
  final bool isLowStock;

  const MedicationSummary({
    required this.medication,
    required this.totalDoses,
    required this.takenDoses,
    required this.missedDoses,
    required this.pendingDoses,
    required this.adherenceRate,
    required this.isOutOfStock,
    required this.isLowStock,
  });
}

class MedicationService {
  static final MedicationService _instance = MedicationService._internal();
  factory MedicationService() => _instance;
  MedicationService._internal();

  static const Duration _missedGracePeriod = Duration(hours: 2);

  final StorageService _storage = StorageService();

  Future<Medication> addMedication({
    required String name,
    required int timesPerDay,
    required List<int> doseTimes,
    required int pillsPerBox,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Medication name cannot be empty');
    }
    if (timesPerDay <= 0) {
      throw ArgumentError('timesPerDay must be greater than zero');
    }
    if (pillsPerBox <= 0) {
      throw ArgumentError('pillsPerBox must be greater than zero');
    }
    if (doseTimes.length != timesPerDay) {
      throw ArgumentError('doseTimes count must match timesPerDay');
    }

    final medication = Medication(
      id: 'med_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmedName,
      timesPerDay: timesPerDay,
      doseTimes: doseTimes,
      pillsPerBox: pillsPerBox,
      remainingPills: pillsPerBox,
      createdAt: DateTime.now(),
    );

    await _storage.saveMedication(medication);
    await ensureDailyIntakesForMedication(medication);
    await _syncMedicationNotifications(medication.id);
    return medication;
  }

  List<Medication> getAllMedications() {
    return _storage.getAllMedications();
  }

  Future<Medication> updateMedication({
    required String medicationId,
    required String name,
    required int timesPerDay,
    required List<int> doseTimes,
    required int pillsPerBox,
  }) async {
    final existing = _storage.getMedicationById(medicationId);
    if (existing == null) {
      throw StateError('Medication not found');
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Medication name cannot be empty');
    }
    if (timesPerDay <= 0) {
      throw ArgumentError('timesPerDay must be greater than zero');
    }
    if (pillsPerBox <= 0) {
      throw ArgumentError('pillsPerBox must be greater than zero');
    }
    if (doseTimes.length != timesPerDay) {
      throw ArgumentError('doseTimes count must match timesPerDay');
    }

    final currentTaken = existing.pillsPerBox - existing.remainingPills;
    final adjustedRemaining = pillsPerBox - currentTaken;

    final updated = existing.copyWith(
      name: trimmedName,
      timesPerDay: timesPerDay,
      doseTimes: doseTimes,
      pillsPerBox: pillsPerBox,
      remainingPills: adjustedRemaining < 0 ? 0 : adjustedRemaining,
    );

    await _storage.saveMedication(updated);
    await _reconcileTodayPendingIntakes(updated);
    await _syncMedicationNotifications(updated.id);
    return updated;
  }

  Future<void> toggleMedicationActive(String medicationId, bool isActive) async {
    final existing = _storage.getMedicationById(medicationId);
    if (existing == null) {
      throw StateError('Medication not found');
    }

    final updated = existing.copyWith(isActive: isActive);
    await _storage.saveMedication(updated);

    if (!isActive) {
      await MedicationNotificationService.cancelMedicationNotifications(
        updated.id,
        _storage.getMedicationIntakesByMedicationId(updated.id),
      );
      return;
    }

    await ensureDailyIntakesForMedication(updated);
    await _syncMedicationNotifications(updated.id);
  }

  Future<void> deleteMedication(String medicationId) async {
    final existing = _storage.getMedicationById(medicationId);
    if (existing == null) {
      throw StateError('Medication not found');
    }

    final intakes = _storage.getMedicationIntakesByMedicationId(medicationId);
    await MedicationNotificationService.cancelMedicationNotifications(
      medicationId,
      intakes,
    );
    await _storage.deleteMedicationIntakesByMedicationId(medicationId);
    await _storage.deleteMedication(medicationId);
  }

  Future<Medication> refillMedication(String medicationId) async {
    final existing = _storage.getMedicationById(medicationId);
    if (existing == null) {
      throw StateError('Medication not found');
    }

    final updated = existing.copyWith(
      remainingPills: existing.pillsPerBox,
    );

    await _storage.saveMedication(updated);
    await _syncMedicationNotifications(updated.id);
    return updated;
  }

  Future<void> ensureDailyIntakesForMedication(
    Medication medication, {
    DateTime? date,
  }) async {
    if (!medication.isActive) return;

    final targetDate = _startOfDay(date ?? DateTime.now());
    final todayIntakes = _storage
        .getMedicationIntakesByMedicationId(medication.id)
        .where((intake) => _isSameDay(intake.scheduledAt, targetDate))
        .toList();

    final existingTimes = todayIntakes
        .map((intake) => intake.scheduledAt.millisecondsSinceEpoch)
        .toSet();

    final scheduledTimes = _buildScheduleTimes(medication, targetDate);

    for (final scheduledAt in scheduledTimes) {
      if (existingTimes.contains(scheduledAt.millisecondsSinceEpoch)) {
        continue;
      }

      final intake = MedicationIntake(
        id: 'intake_${medication.id}_${scheduledAt.millisecondsSinceEpoch}',
        medicationId: medication.id,
        scheduledAt: scheduledAt,
      );

      await _storage.saveMedicationIntake(intake);
    }
  }

  Future<void> ensureDailyIntakesForAllActiveMedications({
    DateTime? date,
  }) async {
    final medications = _storage
        .getAllMedications()
        .where((medication) => medication.isActive)
        .toList();

    for (final medication in medications) {
      await ensureDailyIntakesForMedication(medication, date: date);
    }
  }

  List<MedicationIntake> getMedicationIntakes(String medicationId) {
    return _storage.getMedicationIntakesByMedicationId(medicationId);
  }

  List<MedicationIntake> getTodayMedicationIntakes(String medicationId) {
    final today = DateTime.now();
    return _storage
        .getMedicationIntakesByMedicationId(medicationId)
        .where((intake) => _isSameDay(intake.scheduledAt, today))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> markIntakeTaken(
    String intakeId, {
    int? quantityTaken,
  }) async {
    final intake = _findIntakeById(intakeId);
    if (intake == null) {
      throw StateError('Medication intake not found');
    }

    if (intake.status == 'taken') {
      return;
    }

    final medication = _storage.getMedicationById(intake.medicationId);
    if (medication == null) {
      throw StateError('Medication not found for intake');
    }

    final actualQuantity = quantityTaken ?? intake.quantityTaken;
    if (actualQuantity <= 0) {
      throw ArgumentError('quantityTaken must be greater than zero');
    }
    if (actualQuantity > medication.remainingPills) {
      throw StateError('Not enough remaining pills');
    }

    final updatedIntake = intake.copyWith(
      status: 'taken',
      takenAt: DateTime.now(),
      quantityTaken: actualQuantity,
    );

    final updatedMedication = medication.copyWith(
      remainingPills: medication.remainingPills > 0
          ? medication.remainingPills - actualQuantity
          : 0,
    );

    await _storage.saveMedicationIntake(updatedIntake);
    await _storage.saveMedication(updatedMedication);
    await _syncMedicationNotifications(updatedMedication.id);
  }

  Future<void> markIntakeMissed(String intakeId) async {
    final intake = _findIntakeById(intakeId);
    if (intake == null) {
      throw StateError('Medication intake not found');
    }

    if (intake.status == 'missed') {
      return;
    }

    final updatedIntake = intake.copyWith(
      status: 'missed',
      clearTakenAt: true,
    );

    await _storage.saveMedicationIntake(updatedIntake);
    await _syncMedicationNotifications(updatedIntake.medicationId);
  }

  Future<void> markPastPendingIntakesAsMissed({
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final allIntakes = _storage.getAllMedicationIntakes();

    for (final intake in allIntakes) {
      final shouldMarkMissed = intake.status == 'pending' &&
          intake.scheduledAt.add(_missedGracePeriod).isBefore(currentTime);
      if (shouldMarkMissed) {
        await _storage.saveMedicationIntake(
          intake.copyWith(status: 'missed'),
        );
        await _syncMedicationNotifications(intake.medicationId);
      }
    }
  }

  bool isOutOfStock(Medication medication) {
    return medication.remainingPills <= 0;
  }

  bool isLowStock(Medication medication) {
    final estimatedDailyPills = _estimatedDailyPillsUsage(medication);
    return medication.remainingPills > 0 &&
        medication.remainingPills <= (estimatedDailyPills * 2);
  }

  MedicationSummary buildMedicationSummary(String medicationId) {
    final medication = _storage.getMedicationById(medicationId);
    if (medication == null) {
      throw StateError('Medication not found');
    }

    final intakes = _storage.getMedicationIntakesByMedicationId(medicationId);
    final totalDoses = intakes.length;
    final takenDoses = intakes.where((intake) => intake.status == 'taken').length;
    final missedDoses = intakes.where((intake) => intake.status == 'missed').length;
    final pendingDoses = intakes.where((intake) => intake.status == 'pending').length;
    final adherenceRate = totalDoses == 0 ? 0.0 : takenDoses / totalDoses;

    return MedicationSummary(
      medication: medication,
      totalDoses: totalDoses,
      takenDoses: takenDoses,
      missedDoses: missedDoses,
      pendingDoses: pendingDoses,
      adherenceRate: adherenceRate,
      isOutOfStock: isOutOfStock(medication),
      isLowStock: isLowStock(medication),
    );
  }

  MedicationIntake? _findIntakeById(String intakeId) {
    try {
      return _storage
          .getAllMedicationIntakes()
          .cast<MedicationIntake?>()
          .firstWhere((intake) => intake?.id == intakeId);
    } catch (e) {
      AppLogger.logError('❌ Medication intake lookup failed', e);
      return null;
    }
  }

  Future<void> _reconcileTodayPendingIntakes(Medication medication) async {
    final today = _startOfDay(DateTime.now());
    final todaysIntakes = _storage
        .getMedicationIntakesByMedicationId(medication.id)
        .where((intake) => _isSameDay(intake.scheduledAt, today))
        .toList();

    final targetTimes = _buildScheduleTimes(medication, today);
    final targetKeys =
        targetTimes.map((time) => time.millisecondsSinceEpoch).toSet();

    for (final intake in todaysIntakes) {
      final isFuturePending =
          intake.status == 'pending' && intake.scheduledAt.isAfter(DateTime.now());
      if (isFuturePending &&
          !targetKeys.contains(intake.scheduledAt.millisecondsSinceEpoch)) {
        await _storage.deleteMedicationIntake(intake.id);
      }
    }

    await ensureDailyIntakesForMedication(medication, date: today);
  }

  List<DateTime> _buildScheduleTimes(
    Medication medication,
    DateTime date,
  ) {
    return medication.normalizedDoseTimes
        .map((minutes) {
          final hour = minutes ~/ 60;
          final minute = minutes % 60;
          return DateTime(date.year, date.month, date.day, hour, minute);
        })
        .toList();
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  int _estimatedDailyPillsUsage(Medication medication) {
    final takenIntakes = _storage
        .getMedicationIntakesByMedicationId(medication.id)
        .where((intake) => intake.status == 'taken')
        .toList();

    if (takenIntakes.isEmpty) {
      return medication.timesPerDay;
    }

    final totalTakenPills = takenIntakes.fold<int>(
      0,
      (sum, intake) => sum + intake.quantityTaken,
    );

    final averagePillsPerDose = totalTakenPills / takenIntakes.length;
    final estimatedDailyPills =
        (averagePillsPerDose * medication.timesPerDay).ceil();

    return estimatedDailyPills < medication.timesPerDay
        ? medication.timesPerDay
        : estimatedDailyPills;
  }

  Future<void> syncAllMedicationNotifications() async {
    final medications = _storage
        .getAllMedications()
        .where((medication) => medication.isActive)
        .toList();

    for (final medication in medications) {
      await _syncMedicationNotifications(medication.id);
    }
  }

  Future<void> syncMedicationSystemOnAppStart() async {
    try {
      await ensureDailyIntakesForAllActiveMedications();
      await markPastPendingIntakesAsMissed();
      await syncAllMedicationNotifications();
    } catch (e, st) {
      AppLogger.logError('❌ Medication startup sync failed', e, st);
    }
  }

  Future<void> _syncMedicationNotifications(String medicationId) async {
    final medication = _storage.getMedicationById(medicationId);
    if (medication == null) return;

    final intakes = _storage.getMedicationIntakesByMedicationId(medicationId);

    await MedicationNotificationService.syncMedicationNotifications(
      medication: medication,
      intakes: intakes,
      isLowStock: isLowStock(medication),
      isOutOfStock: isOutOfStock(medication),
    );
  }
}
