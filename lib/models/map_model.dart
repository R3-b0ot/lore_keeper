import 'package:hive/hive.dart';

part 'map_model.g.dart';

@HiveType(typeId: 6) // Use a unique typeId
class MapModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String? description;

  @HiveField(2)
  String filePath; // Path to the uploaded file

  @HiveField(3)
  String fileType; // 'jpeg', 'png', 'svg', 'eps'

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  int parentProjectId;

  MapModel({
    required this.name,
    this.description,
    required this.filePath,
    required this.fileType,
    required this.parentProjectId,
  }) : createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  void updateTimestamp() {
    updatedAt = DateTime.now();
  }
}
