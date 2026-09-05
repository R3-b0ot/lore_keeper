// lib/providers/manuscript_binder_provider.dart

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/services/manuscript_binder_service.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';

/// Provider for managing the Manuscript Binder hierarchy.
/// Uses ManuscriptBinderService for all data operations.
class ManuscriptBinderProvider extends ChangeNotifier {
  final int _projectId;
  final ReferenceEngine _referenceEngine;
  late final ManuscriptBinderService _service;
  List<ManuscriptDocument> _documents = [];
  ManuscriptDocument? _manuscriptRoot;
  bool _isInitialized = false;

  /// The single shared [ReferenceEngine] backing this binder. Exposed so all
  /// manuscript consumers (binder, reference service, collections) observe one
  /// index rather than each creating a private, unpopulated engine.
  ReferenceEngine get referenceEngine => _referenceEngine;

  ManuscriptBinderProvider(
    this._projectId, {
    required ReferenceEngine referenceEngine,
  })  : _referenceEngine = referenceEngine {
    _initialize(referenceEngine);
  }

  Future<void> _initialize(ReferenceEngine referenceEngine) async {
    final db = DatabaseManager.instance;
    _service = ManuscriptBinderService(
      projectId: _projectId,
      documentBox: db.manuscriptDocuments,
      projectBox: db.projects,
      referenceEngine: referenceEngine,
    );

    await _loadData();
  }

  Future<void> _loadData() async {
    _documents = _service.getAllDocuments();
    _manuscriptRoot = _service.getManuscriptRoot();

    // Ensure manuscript root exists
    if (_manuscriptRoot == null) {
      final project = DatabaseManager.instance.projects.get(_projectId);
      if (project != null) {
        _manuscriptRoot = await _service.createManuscriptRoot(project);
        _documents.add(_manuscriptRoot!);
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  bool get isInitialized => _isInitialized;
  ManuscriptDocument? get manuscriptRoot => _manuscriptRoot;
  int get projectId => _projectId;
  List<ManuscriptDocument> get allDocuments => List.unmodifiable(_documents);

  /// Get direct children of a document for UI display
  List<ManuscriptDocument> getChildren(String parentId) {
    return _service.getChildren(parentId);
  }

  /// Get a document by ID
  ManuscriptDocument? getDocument(String documentId) {
    return _service.getDocumentForProject(documentId);
  }

  /// Get ancestor chain for breadcrumb navigation
  List<ManuscriptDocument> getAncestors(String documentId) {
    return _service.getAncestors(documentId);
  }

  /// Get all descendants (for search, statistics, etc.)
  List<ManuscriptDocument> getDescendants(String parentId) {
    return _service.getDescendants(parentId);
  }

  // ========================================================================
  // CREATE OPERATIONS
  // ========================================================================

  Future<ManuscriptDocument> createChild({
    required String parentId,
    required String title,
    required ManuscriptDocumentType type,
    int? orderIndex,
    String? richTextJson,
    ManuscriptDocumentStatus status = ManuscriptDocumentStatus.draft,
    String? summary,
    String? povCharacterId,
    String? locationId,
    String? timelineEventId,
    String? plotline,
    List<String>? characterIds,
    List<String>? tagIds,
  }) async {
    final doc = await _service.createDocument(
      title: title,
      type: type,
      parentId: parentId,
      orderIndex: orderIndex,
      richTextJson: richTextJson,
      status: status,
      summary: summary,
      povCharacterId: povCharacterId,
      locationId: locationId,
      timelineEventId: timelineEventId,
      plotline: plotline,
      characterIds: characterIds,
      tagIds: tagIds,
    );

    _documents.add(doc);
    notifyListeners();
    return doc;
  }

  Future<ManuscriptDocument> createPart({
    required String parentId,
    required String title,
    int? orderIndex,
  }) async {
    return createChild(
      parentId: parentId,
      title: title,
      type: ManuscriptDocumentType.part,
      orderIndex: orderIndex,
    );
  }

  Future<ManuscriptDocument> createChapter({
    required String parentId,
    required String title,
    int? orderIndex,
  }) async {
    return createChild(
      parentId: parentId,
      title: title,
      type: ManuscriptDocumentType.chapter,
      orderIndex: orderIndex,
    );
  }

  Future<ManuscriptDocument> createScene({
    required String parentId,
    required String title,
    int? orderIndex,
  }) async {
    return createChild(
      parentId: parentId,
      title: title,
      type: ManuscriptDocumentType.scene,
      orderIndex: orderIndex,
    );
  }

  Future<ManuscriptDocument> createNote({
    required String parentId,
    required String title,
    int? orderIndex,
  }) async {
    return createChild(
      parentId: parentId,
      title: title,
      type: ManuscriptDocumentType.note,
      orderIndex: orderIndex,
    );
  }

  Future<ManuscriptDocument> createResearch({
    required String parentId,
    required String title,
    int? orderIndex,
  }) async {
    return createChild(
      parentId: parentId,
      title: title,
      type: ManuscriptDocumentType.research,
      orderIndex: orderIndex,
    );
  }

  // ========================================================================
  // UPDATE OPERATIONS
  // ========================================================================

  Future<void> updateTitle(String documentId, String newTitle) async {
    await _service.updateTitle(documentId, newTitle);
    _refreshDocument(documentId);
  }

  Future<void> updateContent(String documentId, String richTextJson) async {
    await _service.updateContent(documentId, richTextJson);
    _refreshDocument(documentId);
  }

  Future<void> updateStatus(
    String documentId,
    ManuscriptDocumentStatus status,
  ) async {
    await _service.updateStatus(documentId, status);
    _refreshDocument(documentId);
  }

  Future<void> updateMetadata(
    String documentId, {
    String? summary,
    String? povCharacterId,
    String? locationId,
    String? timelineEventId,
    String? plotline,
    List<String>? characterIds,
    List<String>? tagIds,
    bool? isExpanded,
    String? purpose,
  }) async {
    await _service.updateMetadata(
      documentId,
      summary: summary,
      povCharacterId: povCharacterId,
      locationId: locationId,
      timelineEventId: timelineEventId,
      plotline: plotline,
      characterIds: characterIds,
      tagIds: tagIds,
      isExpanded: isExpanded,
      purpose: purpose,
    );
    _refreshDocument(documentId);
  }

  /// Set the scene's narrative purpose, clearing it when [purpose] is blank.
  Future<void> updatePurpose(String documentId, String? purpose) async {
    await _service.updatePurpose(documentId, purpose);
    _refreshDocument(documentId);
  }

  /// Assign or clear the scene's linked timeline event (spec §15).
  ///
  /// Passing `null` unlinks the current event; passing an id links it.
  Future<void> updateTimelineEvent(
    String documentId,
    String? timelineEventId,
  ) async {
    await _service.updateTimelineEvent(documentId, timelineEventId);
    _refreshDocument(documentId);
  }

  /// Assign or clear the scene's calendar date (§16).
  Future<void> updateCalendarDate(
    String documentId, {
    int? systemKey,
    int? year,
    int? dayOfYear,
  }) async {
    await _service.updateCalendarDate(
      documentId,
      systemKey: systemKey,
      year: year,
      dayOfYear: dayOfYear,
    );
    _refreshDocument(documentId);
  }

  /// Toggle whether a document is favorited (persisted + project-scoped).
  Future<void> toggleFavorite(String documentId) async {
    final doc = getDocument(documentId);
    if (doc == null) return;
    await _service.setFavorite(documentId, !doc.isFavorite);
    _refreshDocument(documentId);
  }

  Future<void> setExpanded(String documentId, bool expanded) async {
    await _service.updateMetadata(documentId, isExpanded: expanded);
    _refreshDocument(documentId);
  }

  // ========================================================================
  // REORDER / MOVE
  // ========================================================================

  Future<void> reorderDocument(String documentId, int newIndex) async {
    await _service.reorderDocument(documentId, newIndex);
    _reloadAll();
  }

  Future<void> moveDocument(String documentId, String newParentId) async {
    await _service.moveDocument(documentId, newParentId);
    _reloadAll();
  }

  // ========================================================================
  // DELETE
  // ========================================================================

  Future<void> deleteDocument(
    String documentId, {
    bool deleteChildren = false,
  }) async {
    await _service.deleteDocument(documentId, deleteChildren: deleteChildren);
    _documents.removeWhere((d) => d.id == documentId);
    notifyListeners();
  }

  // ========================================================================
  // SEARCH & UTILITIES
  // ========================================================================

  List<ManuscriptDocument> searchDocuments(String query) {
    if (query.isEmpty) return _documents;
    final lower = query.toLowerCase();
    return _documents
        .where(
          (d) =>
              d.title.toLowerCase().contains(lower) ||
              (d.summary?.toLowerCase().contains(lower) ?? false) ||
              (d.richTextJson?.toLowerCase().contains(lower) ?? false) ||
              (d.plotline?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  List<ManuscriptDocument> getDocumentsByType(ManuscriptDocumentType type) {
    return _documents.where((d) => d.documentType == type).toList();
  }

  List<ManuscriptDocument> getDocumentsByStatus(
    ManuscriptDocumentStatus status,
  ) {
    return _documents.where((d) => d.status == status).toList();
  }

  /// Get total word count for manuscript
  int getTotalWordCount() {
    return _documents.fold(0, (sum, d) => sum + d.wordCount);
  }

  /// Get total word count for a branch
  int getBranchWordCount(String documentId) {
    final descendants = _service.getDescendants(documentId);
    final doc = _service.getDocument(documentId);
    int total = doc?.wordCount ?? 0;
    for (final d in descendants) {
      total += d.wordCount;
    }
    return total;
  }

  // ========================================================================
  // INTERNAL
  // ========================================================================

  void _refreshDocument(String documentId) {
    final updated = _service.getDocument(documentId);
    if (updated != null) {
      final index = _documents.indexWhere((d) => d.id == documentId);
      if (index != -1) {
        _documents[index] = updated;
      } else {
        _documents.add(updated);
      }
      notifyListeners();
    }
  }

  void _reloadAll() {
    _documents = _service.getAllDocuments();
    _manuscriptRoot = _service.getManuscriptRoot();
    notifyListeners();
  }
}
