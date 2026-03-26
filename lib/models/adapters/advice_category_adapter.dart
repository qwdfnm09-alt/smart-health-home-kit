import 'package:hive/hive.dart';
import '../health_advice.dart';

class AdviceCategoryAdapter extends TypeAdapter<AdviceCategory> {
  @override
  final int typeId = 11;

  @override
  AdviceCategory read(BinaryReader reader) {
    return AdviceCategory.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, AdviceCategory obj) {
    writer.writeByte(obj.index);
  }
}
