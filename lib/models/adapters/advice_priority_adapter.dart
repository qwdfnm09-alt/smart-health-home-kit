import 'package:hive/hive.dart';
import '../health_advice.dart';

class AdvicePriorityAdapter extends TypeAdapter<AdvicePriority> {
  @override
  final int typeId = 12;

  @override
  AdvicePriority read(BinaryReader reader) {
    return AdvicePriority.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AdvicePriority obj) {
    writer.writeByte(obj.index);
  }
}
