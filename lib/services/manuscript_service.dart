// lib/services/manuscript_service.dart (FINAL CORRECTED VERSION)

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Removed unused import for main.dart as we no longer rely on its global variables
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/section.dart';

// ⚠️ Global variables chapterBox and sectionBox are removed from this file.

const int frontMatterSectionKey = -1;
// Use specific negative keys for front matter pages to avoid conflicts.
const int frontPageHiveKey = -1;
const int indexPageHiveKey = -2;
const int aboutAuthorHiveKey = -3;

class ManuscriptService {
  final int projectId;
  // ⭐️ FIX: Define local, private final variables to hold the injected Hive Boxes ⭐️
  final Box<Chapter> _chapterBox;
  final Box<Section> _sectionBox;

  static const String emptyRichTextJson = '''
    {"ops": [{"insert":"\\n"}]}
  ''';

  // ⭐️ FIX: Require the Hive Boxes to be passed in the constructor ⭐️
  ManuscriptService({
    required this.projectId,
    required Box<Chapter> chapterBox,
    required Box<Section> sectionBox,
  }) : _chapterBox = chapterBox,
       _sectionBox = sectionBox;

  // Initialization is no longer needed here as the boxes are passed in already open.
  // We can remove the redundant method:
  // void _initializeHiveBoxes() async { ... }

  // -----------------------------------------------------------------
  // READ
  // -----------------------------------------------------------------

  List<Section> getSections() {
    // ⭐️ FIX: Use the injected _sectionBox ⭐️
    return _sectionBox.values
        .where((s) => s.parentProjectId == projectId)
        .toList()
        .cast<Section>()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  List<Chapter> getChaptersForSection(dynamic sectionKey) {
    // ⭐️ FIX: Use the injected _chapterBox ⭐️
    return _chapterBox.values
        .where(
          (c) =>
              c.parentProjectId == projectId &&
              c.parentSectionKey == sectionKey,
        )
        .toList()
        .cast<Chapter>()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  Chapter? getChapter(dynamic chapterKey) {
    // This method now handles both positive auto-increment keys and our
    // custom negative keys for front matter.
    if (chapterKey is int) {
      if (chapterKey < 0) {
        // For negative keys, we must search by a composite key since Hive's `get`
        // only works for its own positive keys.
        // The `get` method works for negative keys if they were added with `put`.
        return _chapterBox.get(chapterKey);
      }
      // For positive keys, `get` is efficient.
      return _chapterBox.get(chapterKey);
    }
    if (chapterKey is String) {
      return _chapterBox.get(chapterKey);
    }
    return null;
  }

  Chapter? getFrontMatterChapter(int orderIndex) {
    try {
      return _chapterBox.values.firstWhere(
        (c) =>
            c.parentProjectId == projectId &&
            c.parentSectionKey == frontMatterSectionKey &&
            c.orderIndex == orderIndex,
      );
    } catch (e) {
      return null; // Not found
    }
  }

  // -----------------------------------------------------------------
  // CREATE/UPDATE/DELETE
  // -----------------------------------------------------------------

  Future<dynamic> createSection(String title) async {
    final sections = getSections();
    final newSection = Section()
      ..title = title
      ..parentProjectId = projectId
      ..orderIndex = sections.length;

    // ⭐️ FIX: Use the injected _sectionBox ⭐️
    return _sectionBox.add(newSection);
  }

  Future<dynamic> createChapter(String title, int sectionKey) async {
    final chapters = getChaptersForSection(sectionKey);
    final newChapter = Chapter()
      ..title = title
      ..richTextJson = ManuscriptService.emptyRichTextJson
      ..parentProjectId = projectId
      ..parentSectionKey = sectionKey
      ..orderIndex = chapters.length;

    // ⭐️ FIX: Use the injected _chapterBox ⭐️
    return _chapterBox.add(newChapter);
  }

  Future<Chapter> createFrontMatterChapter(String title, int orderIndex) async {
    // Determine the specific negative key based on the order index.
    final String hiveKey;
    if (orderIndex == 0) {
      hiveKey = 'front_matter_$frontPageHiveKey';
    } else if (orderIndex == 1) {
      hiveKey = 'front_matter_$indexPageHiveKey';
    } else {
      hiveKey = 'front_matter_$aboutAuthorHiveKey';
    }

    final newChapter = Chapter()
      ..title = title
      ..parentProjectId = projectId
      ..parentSectionKey =
          frontMatterSectionKey // Special key
      ..orderIndex = orderIndex
      ..richTextJson = '[]'; // Start with empty content

    // Use `put` with our custom string key.
    await _chapterBox.put(hiveKey, newChapter);

    debugPrint('Created front matter page "$title" with key $hiveKey');
    // CRITICAL FIX: Return the object retrieved from the box, which has the key assigned.
    return _chapterBox.get(hiveKey)!;
  }

  Future<void> saveChapterContent(Chapter chapter, String richTextJson) async {
    chapter.richTextJson = richTextJson;
    // For front matter pages with string keys, use put; otherwise, use save.
    if (chapter.key is String &&
        (chapter.key as String).startsWith('front_matter_')) {
      await _chapterBox.put(chapter.key, chapter);
    } else {
      await chapter.save();
    }
  }

  Future<void> reorderChaptersInSection(dynamic sectionKey) async {
    final chapters = getChaptersForSection(sectionKey);
    // The list is already sorted by orderIndex.
    for (int i = 0; i < chapters.length; i++) {
      chapters[i].orderIndex = i;
      await chapters[i].save();
    }
  }

  Future<void> updateChapterOrder(List<Chapter> chapters) async {
    // Iterate through the reordered list and update the orderIndex for each chapter.
    for (int i = 0; i < chapters.length; i++) {
      chapters[i].orderIndex = i;
      await chapters[i].save();
    }
  }
}
