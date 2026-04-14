import 'package:hive/hive.dart';
import 'user_profile.dart';

class PersonalityTypeAdapter extends TypeAdapter<PersonalityType> {
  @override
  final int typeId = 3;

  @override
  PersonalityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PersonalityType.strict;
      case 1:
        return PersonalityType.balanced;
      case 2:
        return PersonalityType.relaxed;
      default:
        return PersonalityType.balanced;
    }
  }

  @override
  void write(BinaryWriter writer, PersonalityType obj) {
    writer.writeByte(obj.index);
  }
}
