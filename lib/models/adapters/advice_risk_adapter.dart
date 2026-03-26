import 'package:hive/hive.dart';
import '../health_advice.dart';

class AdviceRiskAdapter extends TypeAdapter<AdviceRisk> {
  @override
  final int typeId = 13;

  @override
  AdviceRisk read(BinaryReader reader) {
    return AdviceRisk.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AdviceRisk obj) {
    writer.writeByte(obj.index);
  }
}

