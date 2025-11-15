import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/models/project.dart';

class HistoryService {
  final Box<HistoryEntry> _historyBox;
  final Box<Project> _projectBox;

  HistoryService()
    : _historyBox = Hive.box<HistoryEntry>('history'),
      _projectBox = Hive.box<Project>('projects');

  Future<void> addHistoryEntry({
    required dynamic targetKey,
    required String targetType,
    required dynamic objectToSave,
    required int projectId,
  }) async {
    final project = _projectBox.get(projectId);
    final historyLimit = project?.historyLimit ?? 10;

    // 1. Create the new history entry
    final newEntry = HistoryEntry(
      targetType: targetType,
      targetKey: targetKey,
      timestamp: DateTime.now(),
      data: jsonEncode(objectToSave.toJson()),
    );

    await _historyBox.add(newEntry);

    // 2. Prune old entries for the same target
    // Use .toMap() to get both the key and the value (HistoryEntry)
    final allEntriesForTarget = _historyBox
        .toMap()
        .entries
        .where(
          (entry) =>
              entry.value.targetKey == targetKey &&
              entry.value.targetType == targetType,
        )
        .toList();

    // Sort by timestamp, oldest first
    allEntriesForTarget.sort(
      (a, b) => a.value.timestamp.compareTo(b.value.timestamp),
    );

    // If we exceed the limit, delete the oldest ones
    if (allEntriesForTarget.length > historyLimit) {
      final entriesToDelete = allEntriesForTarget.length - historyLimit;
      for (int i = 0; i < entriesToDelete; i++) {
        await _historyBox.delete(allEntriesForTarget[i].key);
      }
    }
  }
}
