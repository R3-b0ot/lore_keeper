import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/section.dart';
import 'package:lore_keeper/services/manuscript_service.dart';

/// A provider to manage the list of chapters in the manuscript using Hive.
class ChapterListProvider with ChangeNotifier {
  late final ManuscriptService _manuscriptService;
  List<Chapter> _chapters = [];
  List<Section> _sections = [];
  bool _isReordering = false; // Add a flag to prevent race conditions
  // New properties to hold front matter chapters
  Chapter? _frontPage;
  Chapter? _indexPage;
  Chapter? _aboutAuthorPage;
  bool _isInitialized = false;
  final int _projectId;

  ChapterListProvider(this._projectId) {
    // Initialize the service with the required Hive boxes.
    _manuscriptService = ManuscriptService(
      projectId: _projectId,
      chapterBox: Hive.box<Chapter>('chapters'),
      sectionBox: Hive.box<Section>('sections'),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    _sections = _manuscriptService.getSections();
    await _loadFrontMatter(); // Load or create front matter pages
    // For simplicity, we'll load chapters from the first section if it exists.
    if (_sections.isNotEmpty) {
      _chapters = _manuscriptService.getChaptersForSection(_sections.first.key);
    }

    // If after loading, there are no chapters, create a default one.
    // This handles new projects automatically.
    if (_chapters.isEmpty && !_isInitialized) {
      // Avoid creating chapters on subsequent reloads if they were deleted.
      await createNewChapter('A New Beginning', isDefault: true);
      return; // createNewChapter calls _loadData again, so we exit here.
    }
    _isInitialized = true;
    notifyListeners();
  }

  bool get isInitialized => _isInitialized;
  List<Chapter> get chapters => _chapters;
  Chapter? get frontPage => _frontPage;
  Chapter? get indexPage => _indexPage;
  Chapter? get aboutAuthorPage => _aboutAuthorPage;

  Future<void> _loadFrontMatter() async {
    _frontPage = _manuscriptService.getFrontMatterChapter(0);
    _indexPage = _manuscriptService.getFrontMatterChapter(1);
    _aboutAuthorPage = _manuscriptService.getFrontMatterChapter(2);

    _frontPage ??= await _manuscriptService.createFrontMatterChapter(
      'Front Page',
      0,
    );

    _indexPage ??= await _manuscriptService.createFrontMatterChapter(
      'Index',
      1,
    );

    _aboutAuthorPage ??= await _manuscriptService.createFrontMatterChapter(
      'About Author',
      2,
    );
  }

  Future<dynamic> createNewChapter(
    String title, {
    bool isDefault = false,
  }) async {
    // Assume we are adding to the first section for now.
    // A more robust implementation would allow section selection.
    if (_sections.isEmpty) {
      await _manuscriptService.createSection('Part 1');
      // Reload sections before proceeding
      _sections = _manuscriptService.getSections();
    }
    final sectionKey = _sections.first.key;
    final newChapterKey = await _manuscriptService.createChapter(
      title,
      sectionKey,
    );

    // If this is the default chapter for a new project, set it as last edited.
    if (isDefault) {
      final projectBox = Hive.box<Project>('projects');
      final project = projectBox.get(_projectId);
      project?.lastEditedChapterKey = newChapterKey.toString();
      await project?.save();
    }

    _loadData(); // Reload chapters
    return newChapterKey;
  }

  Future<void> updateChapterTitle(dynamic chapterKey, String newTitle) async {
    final chapter = _manuscriptService.getChapter(chapterKey);
    if (chapter == null) return;

    chapter.title = newTitle;
    // For front matter pages with negative keys, we must use put.
    if (chapterKey is String && chapterKey.startsWith('front_matter_')) {
      await Hive.box<Chapter>('chapters').put(chapterKey, chapter);
    } else {
      await chapter.save();
    }
    _loadData();
  }

  Future<void> deleteChapter(dynamic chapterKey) async {
    final chapter = _manuscriptService.getChapter(chapterKey);
    if (chapter != null) {
      await chapter.delete();
      // Re-index the remaining chapters to fill the gap.
      await _manuscriptService.reorderChaptersInSection(
        chapter.parentSectionKey,
      );
      _loadData();
    }
  }

  Future<void> reorderChapter(int oldIndex, int newIndex) async {
    // If a reorder operation is already in progress, ignore this call.
    if (_isReordering) return;
    _isReordering = true;

    // The ReorderableListView widget moves the item in the list for us before calling onReorder.
    // If the item is dragged downwards, newIndex will be one greater than its final position.
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Create a new list based on the reordered state.
    final List<Chapter> reorderedChapters = List.from(_chapters);
    final Chapter movedChapter = reorderedChapters.removeAt(oldIndex);
    reorderedChapters.insert(newIndex, movedChapter);

    // Call the service to persist the new order indices.
    await _manuscriptService.updateChapterOrder(reorderedChapters);

    _loadData(); // Reload data to ensure UI consistency.

    _isReordering = false; // Release the lock
  }

  /// Updates the content of a specific chapter.
  Future<void> updateChapterContent(
    dynamic chapterKey,
    String newContent,
  ) async {
    debugPrint('PROVIDER: Updating content for chapter key: $chapterKey');
    final chapter = _manuscriptService.getChapter(chapterKey);
    if (chapter == null) {
      debugPrint('PROVIDER: Chapter not found for key: $chapterKey');
      return;
    }
    debugPrint(
      'PROVIDER: Chapter found: ${chapter.title}, key: ${chapter.key}',
    );

    await _manuscriptService.saveChapterContent(chapter, newContent);

    // Update the project's last edited chapter key
    final projectBox = Hive.box<Project>('projects');
    final project = projectBox.get(_projectId);
    project?.lastEditedChapterKey = chapterKey.toString();
    await project?.save();
    debugPrint(
      'PROVIDER: Content update completed for chapter: ${chapter.title}',
    );
    // No need to notify listeners as content change doesn't affect the list.
  }

  Chapter? getChapter(dynamic chapterKey) =>
      _manuscriptService.getChapter(chapterKey);
}
