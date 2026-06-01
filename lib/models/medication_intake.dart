import 'package:hive/hive.dart';

class MedicationIntake extends HiveObject {
  final String id;
  final String medicationId;
  final DateTime scheduledAt;
  DateTime? takenAt;
  String status;
  final int quantityTaken;

  MedicationIntake({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    this.status = 'pending',
    this.quantityTaken = 1,
  });

  MedicationIntake copyWith({
    String? id,
    String? medicationId,
    DateTime? scheduledAt,
    DateTime? takenAt,
    bool clearTakenAt = false,
    String? status,
    int? quantityTaken,
  }) {
    return MedicationIntake(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      takenAt: clearTakenAt ? null : (takenAt ?? this.takenAt),
      status: status ?? this.status,
      quantityTaken: quantityTaken ?? this.quantityTaken,
    );
  }
}
