import 'package:hive/hive.dart';

part 'magic_system.g.dart';

@HiveType(typeId: 7)
class MagicSystem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int projectId;

  @HiveField(2)
  String rootNodeId;

  @HiveField(3)
  String? lastSelectedNodeId;

  @HiveField(4)
  bool isConfigured;

  @HiveField(5)
  int createdAt;

  @HiveField(6)
  int updatedAt;

  MagicSystem({
    required this.name,
    required this.projectId,
    required this.rootNodeId,
    this.lastSelectedNodeId,
    this.isConfigured = false,
    int? createdAt,
    int? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
