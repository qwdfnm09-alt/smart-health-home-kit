// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthAlertAdapter extends TypeAdapter<HealthAlert> {
  @override
  final int typeId = 2;

  @override
  HealthAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthAlert(
      message: fields[0] as String,
      type: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HealthAlert obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
