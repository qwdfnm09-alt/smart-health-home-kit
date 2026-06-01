import 'package:hive/hive.dart';

import '../medication.dart';

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 20;

  @override
  Medication read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final timesPerDay = reader.readInt();
    final pillsPerBox = reader.readInt();
    final remainingPills = reader.readInt();
    final isActive = reader.readBool();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    List<int>? doseTimes;
    try {
      final rawDoseTimes = reader.readList();
      doseTimes = rawDoseTimes.whereType<int>().toList();
    } catch (_) {
      doseTimes = Medication.defaultDoseTimesFor(timesPerDay);
    }

    return Medication(
      id: id,
      name: name,
      timesPerDay: timesPerDay,
      doseTimes: doseTimes,
      pillsPerBox: pillsPerBox,
      remainingPills: remainingPills,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.timesPerDay);
    writer.writeInt(obj.pillsPerBox);
    writer.writeInt(obj.remainingPills);
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeList(obj.normalizedDoseTimes);
  }
}
