import 'package:hive/hive.dart';

part 'link.g.dart';

@HiveType(typeId: 5) // A new, unique typeId
class Link extends HiveObject {
  // The source of the link (e.g., the character we are viewing)
  @HiveField(0)
  late String entity1Type;

  @HiveField(1)
  late dynamic entity1Key;

  // The target of the link (e.g., another character, a location)
  @HiveField(2)
  late String entity2Type;

  @HiveField(3)
  late dynamic entity2Key;

  // The description of the relationship
  @HiveField(4)
  late String description;

  // The date or time period of the relationship
  @HiveField(5)
  String? date;

  @HiveField(6) // New field for source iteration
  int? entity1IterationIndex;

  @HiveField(7) // New field for target iteration
  int? entity2IterationIndex;

  Link(); // Add an empty constructor
}
