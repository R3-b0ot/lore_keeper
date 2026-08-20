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

  /// The calendar system this event belongs to (Hive key of CalendarSystem).
  /// 0 or negative means unassigned (legacy events).
  @HiveField(11)
  int calendarSystemKey;

  /// Duration in days (0 = single day/instant event).
  @HiveField(12)
  int durationDays;

  /// Linked character IDs (keys from Character model).
  @HiveField(13)
  List<String> linkedCharacterIds;

  /// Linked location IDs (keys from Location model, if available).
  @HiveField(14)
  List<String> linkedLocationIds;

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
    this.calendarSystemKey = 0,
    this.durationDays = 0,
    List<String>? linkedCharacterIds,
    List<String>? linkedLocationIds,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
       linkedCharacterIds = linkedCharacterIds ?? [],
       linkedLocationIds = linkedLocationIds ?? [];

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
