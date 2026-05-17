import 'package:hive/hive.dart';

part 'timeline_event.g.dart';

@HiveType(typeId: 29)
class TimelineEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int projectId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String tier;

  @HiveField(4)
  int absoluteYear;

  @HiveField(5)
  int absoluteDayOfYear;

  @HiveField(6)
  String iconKey;

  @HiveField(7)
  int colorValue;

  @HiveField(8)
  String lore;

  @HiveField(9)
  int createdAt;

  @HiveField(10)
  int updatedAt;

  TimelineEvent({
    required this.id,
    required this.projectId,
    required this.name,
    required this.tier,
    required this.absoluteYear,
    required this.absoluteDayOfYear,
    required this.iconKey,
    required this.colorValue,
    required this.lore,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
