import 'package:hive/hive.dart';

part 'user_profile.g.dart';

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


  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.conditions,
  });
}





