// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineTaskAdapter extends TypeAdapter<RoutineTask> {
  @override
  final int typeId = 15;

  @override
  RoutineTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoutineTask(
      title: fields[0] as String,
      description: fields[1] as String,
      time: fields[2] as String,
      isCompleted: fields[3] as bool,
      category: fields[4] as String,
      type: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RoutineTask obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.time)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
