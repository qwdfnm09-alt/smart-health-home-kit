// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthDataAdapter extends TypeAdapter<HealthData> {
  @override
  final int typeId = 0;

  @override
  HealthData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthData(
      type: fields[0] as String,
      value: fields[1] as double,
      timestamp: fields[2] as DateTime,
      unit: fields[3] as String,
      source: fields[4] as String,
      systolic: fields[5] as int?,
      diastolic: fields[6] as int?,
      pulse: fields[7] as int?,
      temperature: fields[8] as double?,
      glucose: fields[9] as int?,
      extra: (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, HealthData obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.systolic)
      ..writeByte(6)
      ..write(obj.diastolic)
      ..writeByte(7)
      ..write(obj.pulse)
      ..writeByte(8)
      ..write(obj.temperature)
      ..writeByte(9)
      ..write(obj.glucose)
      ..writeByte(10)
      ..write(obj.extra);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
