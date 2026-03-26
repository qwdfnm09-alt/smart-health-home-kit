// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_advice.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthAdviceAdapter extends TypeAdapter<HealthAdvice> {
  @override
  final int typeId = 10;

  @override
  HealthAdvice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthAdvice(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as AdviceCategory,
      priority: fields[4] as AdvicePriority,
      measurementTime: fields[5] as DateTime,
      risk: fields[6] as AdviceRisk,
      type: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HealthAdvice obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.measurementTime)
      ..writeByte(6)
      ..write(obj.risk)
      ..writeByte(7)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthAdviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
