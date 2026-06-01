import 'package:hive/hive.dart';

import '../medication_intake.dart';

class MedicationIntakeAdapter extends TypeAdapter<MedicationIntake> {
  @override
  final int typeId = 21;

  @override
  MedicationIntake read(BinaryReader reader) {
    final id = reader.readString();
    final medicationId = reader.readString();
    final scheduledAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasTakenAt = reader.readBool();

    return MedicationIntake(
      id: id,
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      takenAt: hasTakenAt
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      status: reader.readString(),
      quantityTaken: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicationIntake obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.medicationId);
    writer.writeInt(obj.scheduledAt.millisecondsSinceEpoch);
    writer.writeBool(obj.takenAt != null);
    if (obj.takenAt != null) {
      writer.writeInt(obj.takenAt!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.status);
    writer.writeInt(obj.quantityTaken);
  }
}
