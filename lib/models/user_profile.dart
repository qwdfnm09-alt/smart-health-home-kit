import 'package:hive/hive.dart';

part 'user_profile.g.dart';

enum PersonalityType {
  strict,
  balanced,
  relaxed,
}


@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final String gender;

  @HiveField(3)
  final List<String> conditions;

  @HiveField(4)
  final PersonalityType personality;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.conditions,
    required this.personality,
  });
}






