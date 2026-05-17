import 'package:hive/hive.dart';

part 'calendar_node.g.dart';

@HiveType(typeId: 27)
class CalendarNode extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int systemKey;

  @HiveField(2)
  String? parentId;

  @HiveField(3)
  String type;

  @HiveField(4)
  String title;

  @HiveField(5)
  String iconKey;

  @HiveField(6)
  int colorValue;

  @HiveField(7)
  String content;

  @HiveField(8)
  List<CalendarAttribute> attributes;

  @HiveField(9)
  List<String> childrenOrder;

  @HiveField(10)
  int createdAt;

  @HiveField(11)
  int updatedAt;

  CalendarNode({
    required this.id,
    required this.systemKey,
    required this.parentId,
    required this.type,
    required this.title,
    required this.iconKey,
    required this.colorValue,
    required this.content,
    required this.attributes,
    required this.childrenOrder,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}

@HiveType(typeId: 28)
class CalendarAttribute extends HiveObject {
  @HiveField(0)
  String label;

  @HiveField(1)
  String value;

  CalendarAttribute({required this.label, required this.value});
}
