// lib/models/section.dart

import 'package:hive_flutter/hive_flutter.dart';

part 'section.g.dart';

@HiveType(typeId: 3) // ⭐️ FIX: Changed typeId from 2 to 3 ⭐️
class Section extends HiveObject {
  @HiveField(0)
  late String title;

  @HiveField(1)
  late int orderIndex;

  @HiveField(2)
  late int parentProjectId;

  // A boolean to track if the section is expanded in the UI (optional, but useful)
  @HiveField(3)
  bool isExpanded = true;

  // Sections will not directly contain chapters in Hive;
  // Chapters will reference the Section's key for organization.
  @HiveField(4)
  int? parentSectionKey;
}
