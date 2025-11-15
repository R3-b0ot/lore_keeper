// lib/models/chapter.dart

import 'package:hive_flutter/hive_flutter.dart';

part 'chapter.g.dart'; // Hive generated file

@HiveType(typeId: 2) // Use a unique typeId
class Chapter extends HiveObject {
  // Hive fields must be defined and usually non-final (writable)

  @HiveField(0)
  late String title;

  // The field that was causing the setter error. Must be writable.
  @HiveField(1)
  late int parentSectionKey;

  @HiveField(2)
  late int parentProjectId;

  @HiveField(3)
  late int orderIndex;

  // This is where the rich text JSON from the editor is stored.
  @HiveField(4)
  String? richTextJson;

  // You may also have a constructor, but for a simple Hive model,
  // initializing fields with 'late' is sufficient.
  Map<String, dynamic> toJson() {
    return {
      // Note: 'key' is part of HiveObject and not included in manual toJson
      'title': title,
      'richTextJson': richTextJson,
      'parentProjectId': parentProjectId,
      'parentSectionKey': parentSectionKey,
      'orderIndex': orderIndex,
    };
  }
}

// This function is used for reverting history, so it remains outside the class.
Chapter chapterFromJson(Map<String, dynamic> json) {
  final chapter = Chapter()
    ..title = json['title']
    ..richTextJson = json['richTextJson']
    ..parentProjectId = json['parentProjectId']
    ..parentSectionKey = json['parentSectionKey']
    ..orderIndex = json['orderIndex'];

  // Note: We cannot set the 'key' directly as it's managed by Hive.
  // When we revert, we will 'put' this object back into the box using the old key.
  return chapter;
}
