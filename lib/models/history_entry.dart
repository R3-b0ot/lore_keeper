import 'package:hive/hive.dart';

part 'history_entry.g.dart';

@HiveType(typeId: 11) // Make sure this typeId is unique
class HistoryEntry {
  @HiveField(0)
  late String targetType; // e.g., 'Character', 'Chapter'

  @HiveField(1)
  late dynamic targetKey; // The key of the object being snapshotted

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late String data; // JSON string of the object's state before the change

  @HiveField(4)
  String? changeDescription; // Optional: A summary of what changed

  HistoryEntry({
    required this.targetType,
    required this.targetKey,
    required this.timestamp,
    required this.data,
    this.changeDescription,
  });
}
