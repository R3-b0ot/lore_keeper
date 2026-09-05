// lib/services/manuscript_binder_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/services/reference_integrity_service.dart';
import 'package:lore_keeper/services/reference_name_resolver.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/entity_ref.dart';

class ManuscriptBinderService {
  final int projectId;
  final Box<ManuscriptDocument> _documentBox;
  final Box<Project> _projectBox;
  late final ReferenceIntegrityService _referenceIntegrityService;
  ReferenceNameResolver? _fullResolver;

  ManuscriptBinderService({
    required this.projectId,
    required Box<ManuscriptDocument> documentBox,
    required Box<Project> projectBox,
    required ReferenceEngine referenceEngine,
  }) : _documentBox = documentBox,
       _projectBox = projectBox {
    _referenceIntegrityService = ReferenceIntegrityService(
      engine: referenceEngine,
      entityExists: (ref) {
        // Fast path: manuscript documents resolve from the injected box so
        // the service stays testable without a live database singleton.
        if (ref.entityType == EntityType.manuscriptDocument) {
          return documentBox.get(ref.id) != null;
        }
        // Cross-module types (characters, species, timeline events) defer to
        // the canonical project-scoped resolver built from the live database.
        // Built lazily so tests that never touch other types avoid the
        // (uninitialized) database singleton.
        return (_fullResolver ??= ReferenceNameResolver.fromDatabase(
          projectId,
        )).entityExists(ref);
      },
    );
  }

  // ========================================================================
  // QUERIES
  // ========================================================================

  /// Get the root manuscript document for this project
  ManuscriptDocument? getManuscriptRoot() {
    try {
      return _documentBox.values.firstWhere(
        (d) =>
            d.projectId == projectId &&
            d.documentType == ManuscriptDocumentType.manuscript,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all documents for this project
  List<ManuscriptDocument> getAllDocuments() {
    return _documentBox.values.where((d) => d.projectId == projectId).toList()
      ..sort((a, b) {
        // Sort by parent first, then by orderIndex
        if (a.parentId != b.parentId) {
          return (a.parentId ?? '').compareTo(b.parentId ?? '');
        }
        return a.orderIndex.compareTo(b.orderIndex);
      });
  }

  /// Get direct children of a document
  List<ManuscriptDocument> getChildren(String parentId) {
    return _documentBox.values
        .where((d) => d.projectId == projectId && d.parentId == parentId)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  /// Get a document by ID
  ManuscriptDocument? getDocument(String documentId) {
    return _documentBox.get(documentId);
  }

  /// Get document by ID with project check
  ManuscriptDocument? getDocumentForProject(String documentId) {
    final doc = _documentBox.get(documentId);
    if (doc != null && doc.projectId == projectId) {
      return doc;
    }
    return null;
  }

  /// Get all descendants of a document (recursive)
  List<ManuscriptDocument> getDescendants(String parentId) {
    final children = getChildren(parentId);
    final all = <ManuscriptDocument>[...children];
    for (final child in children) {
      all.addAll(getDescendants(child.id));
    }
    return all;
  }

  /// Get ancestor chain up to root
  List<ManuscriptDocument> getAncestors(String documentId) {
    final ancestors = <ManuscriptDocument>[];
    ManuscriptDocument? current = getDocument(documentId);
    while (current?.parentId != null) {
      final parent = getDocument(current!.parentId!);
      if (parent != null) {
        ancestors.add(parent);
        current = parent;
      } else {
        break;
      }
    }
    return ancestors.reversed.toList(); // Root first
  }

  // ========================================================================
  // CREATE
  // ========================================================================

  /// Create a new document as child of parent
  Future<ManuscriptDocument> createDocument({
    required String title,
    required ManuscriptDocumentType type,
    required String parentId,
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
    String? purpose,
  }) async {
    final parent = _documentBox.get(parentId);
    if (parent == null || parent.projectId != projectId) {
      throw ArgumentError('Invalid parent document');
    }

    // Validate type hierarchy
    _validateTypeHierarchy(parent.documentType, type);

    final children = getChildren(parentId);
    final newOrderIndex = orderIndex ?? children.length;

    // Shift existing siblings
    await _shiftSiblings(parentId, newOrderIndex, 1);

    final id =
        '${type.label.toLowerCase().replaceAll(' ', '_')}_${const Uuid().v4()}';
    final now = DateTime.now();

    final doc = ManuscriptDocument()
      ..id = id
      ..projectId = projectId
      ..title = title
      ..documentType = type
      ..parentId = parentId
      ..orderIndex = newOrderIndex
      ..richTextJson = richTextJson ?? ManuscriptModule.emptyRichTextJson
      ..status = status
      ..summary = summary
      ..povCharacterId = povCharacterId
      ..locationId = locationId
      ..timelineEventId = timelineEventId
      ..plotline = plotline
      ..characterIds = characterIds ?? []
      ..tagIds = tagIds ?? []
      ..purpose = purpose
      ..isExpanded = true
      ..createdAt = now
      ..modifiedAt = now
      ..wordCount = _countWords(
        richTextJson ?? ManuscriptModule.emptyRichTextJson,
      )
      ..characterCount =
          (richTextJson ?? ManuscriptModule.emptyRichTextJson).length;

    await _documentBox.put(id, doc);

    // Update parent's modified time
    parent.modifiedAt = now;
    await parent.save();

    // Update project modified time
    _updateProjectModifiedTime();

    return doc;
  }

  /// Create a root manuscript document for a project
  Future<ManuscriptDocument> createManuscriptRoot(Project project) async {
    final existing = getManuscriptRoot();
    if (existing != null) return existing;

    final id = 'manuscript_${project.key}';
    final now = DateTime.now();

    final doc = ManuscriptDocument()
      ..id = id
      ..projectId = projectId
      ..title = project.bookTitle ?? project.title
      ..documentType = ManuscriptDocumentType.manuscript
      ..parentId = null
      ..orderIndex = 0
      ..status = ManuscriptDocumentStatus.draft
      ..isExpanded = true
      ..createdAt = project.createdAt
      ..modifiedAt = now;

    await _documentBox.put(id, doc);
    return doc;
  }

  // ========================================================================
  // UPDATE
  // ========================================================================

  /// Update document title
  Future<void> updateTitle(String documentId, String newTitle) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.title = newTitle;
    doc.modifiedAt = DateTime.now();
    await doc.save();
    _updateProjectModifiedTime();
  }

  /// Update document content (rich text JSON)
  Future<void> updateContent(String documentId, String richTextJson) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.richTextJson = richTextJson;
    doc.modifiedAt = DateTime.now();
    doc.wordCount = _countWords(richTextJson);
    doc.characterCount = richTextJson.length;
    await doc.save();
    _updateProjectModifiedTime();
  }

  /// Update document status
  Future<void> updateStatus(
    String documentId,
    ManuscriptDocumentStatus status,
  ) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.status = status;
    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  /// Update the scene's purpose (the narrative intent / role it plays).
  Future<void> updatePurpose(String documentId, String? purpose) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.purpose = (purpose == null || purpose.trim().isEmpty)
        ? null
        : purpose.trim();
    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  /// Toggle a document's favorite flag (persisted and project-scoped).
  ///
  /// Favorites must survive restarts and be exposed through Collections
  /// (spec §11). The flag lives on the document so it serializes with it.
  Future<void> setFavorite(String documentId, bool isFavorite) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.isFavorite = isFavorite;
    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  /// Update document metadata
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
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    if (summary != null) doc.summary = summary;
    if (povCharacterId != null) doc.povCharacterId = povCharacterId;
    if (locationId != null) doc.locationId = locationId;
    if (timelineEventId != null) doc.timelineEventId = timelineEventId;
    if (plotline != null) doc.plotline = plotline;
    if (characterIds != null) doc.characterIds = characterIds;
    if (tagIds != null) doc.tagIds = tagIds;
    if (isExpanded != null) doc.isExpanded = isExpanded;
    if (purpose != null) doc.purpose = purpose;

    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  /// Assign or clear the scene's linked timeline event.
  ///
  /// Unlike [updateMetadata], this allows explicitly clearing (unlinking) the
  /// linked event by passing [timelineEventId] as `null`. The link is stored on
  /// the document and resolved via the ReferenceEngine (spec §15, §17) so no
  /// duplicate relationship table is created.
  Future<void> updateTimelineEvent(
    String documentId,
    String? timelineEventId,
  ) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.timelineEventId = timelineEventId;
    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  /// Assign or clear the scene's calendar date (§16).
  ///
  /// [systemKey], [year] and [dayOfYear] are stored together so the assigned
  /// date stays rendered through the correct Chronology. Null clears the date.
  /// No second calendar implementation is introduced; the values describe a
  /// point in the project's existing CalendarSystem/Chronology.
  Future<void> updateCalendarDate(
    String documentId, {
    int? systemKey,
    int? year,
    int? dayOfYear,
  }) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    doc.calendarDateSystemKey = systemKey ?? 0;
    doc.calendarDateYear = year ?? 0;
    doc.calendarDateDayOfYear = dayOfYear ?? 0;
    doc.modifiedAt = DateTime.now();
    await doc.save();
  }

  /// Reorder document among siblings
  Future<void> reorderDocument(String documentId, int newIndex) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    final parentId = doc.parentId;
    if (parentId == null) return; // Cannot reorder root

    final children = getChildren(parentId);
    final oldIndex = children.indexWhere((c) => c.id == documentId);
    if (oldIndex == -1) return;

    // Adjust newIndex if moving down
    int adjustedIndex = newIndex;
    if (oldIndex < newIndex) {
      adjustedIndex -= 1;
    }
    adjustedIndex = adjustedIndex.clamp(0, children.length - 1);

    if (oldIndex == adjustedIndex) return;

    // Remove from current position
    final movedDoc = children.removeAt(oldIndex);
    // Insert at new position
    children.insert(adjustedIndex, movedDoc);

    // Update all order indices
    for (int i = 0; i < children.length; i++) {
      children[i].orderIndex = i;
      await children[i].save();
    }

    _updateProjectModifiedTime();
  }

  /// Move document to a new parent
  Future<void> moveDocument(String documentId, String newParentId) async {
    final doc = getDocumentForProject(documentId);
    final newParent = getDocumentForProject(newParentId);

    if (doc == null || newParent == null) return;
    if (doc.id == newParentId) return; // Cannot move to self

    // Check for circular reference
    if (_wouldCreateCycle(doc.id, newParentId)) {
      throw StateError('Cannot move document: would create circular reference');
    }

    // Validate type hierarchy
    _validateTypeHierarchy(newParent.documentType, doc.documentType);

    final oldParentId = doc.parentId;

    // Remove from old siblings
    if (oldParentId != null) {
      final oldSiblings = getChildren(oldParentId);
      for (int i = 0; i < oldSiblings.length; i++) {
        oldSiblings[i].orderIndex = i;
        await oldSiblings[i].save();
      }
    }

    // Add to new parent at end
    final newSiblings = getChildren(newParentId);
    doc.parentId = newParentId;
    doc.orderIndex = newSiblings.length;
    doc.modifiedAt = DateTime.now();
    await doc.save();

    _updateProjectModifiedTime();
  }

  // ========================================================================
  // DELETE
  // ========================================================================

  /// Delete a document and optionally its children
  Future<void> deleteDocument(
    String documentId, {
    bool deleteChildren = false,
  }) async {
    final doc = getDocumentForProject(documentId);
    if (doc == null) return;

    final children = getChildren(documentId);

    if (children.isNotEmpty && !deleteChildren) {
      throw StateError(
        'Document has children. Use deleteChildren: true to delete recursively.',
      );
    }

    // Delete children first if requested
    if (deleteChildren) {
      for (final child in children) {
        await deleteDocument(child.id, deleteChildren: true);
      }
    } else if (children.isNotEmpty) {
      // Promote children to parent's level
      final parentId = doc.parentId;
      for (final child in children) {
        await moveDocument(child.id, parentId ?? getManuscriptRoot()!.id);
      }
    }

    // Remove from siblings
    if (doc.parentId != null) {
      final siblings = getChildren(doc.parentId!);
      for (int i = 0; i < siblings.length; i++) {
        siblings[i].orderIndex = i;
        await siblings[i].save();
      }
    }

    // Remove reference index entries where this document is the source (outbound refs)
    // and remove inbound backlinks pointing to this document
    final docRef = EntityRef.fromKey(
      key: doc.id,
      entityType: EntityType.manuscriptDocument,
      projectId: projectId.toString(),
    );
    _referenceIntegrityService.removeSource(docRef);
    _referenceIntegrityService.removeTarget(docRef);

    await doc.delete();
    _updateProjectModifiedTime();
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  void _validateTypeHierarchy(
    ManuscriptDocumentType parentType,
    ManuscriptDocumentType childType,
  ) {
    final validChildren =
        <ManuscriptDocumentType, List<ManuscriptDocumentType>>{
          ManuscriptDocumentType.manuscript: [
            ManuscriptDocumentType.part,
            ManuscriptDocumentType.chapter,
            ManuscriptDocumentType.frontMatter,
            ManuscriptDocumentType.backMatter,
          ],
          ManuscriptDocumentType.part: [
            ManuscriptDocumentType.chapter,
            ManuscriptDocumentType.section,
          ],
          ManuscriptDocumentType.chapter: [ManuscriptDocumentType.scene],
          ManuscriptDocumentType.section: [
            ManuscriptDocumentType.scene,
            ManuscriptDocumentType.note,
            ManuscriptDocumentType.research,
          ],
          ManuscriptDocumentType.frontMatter: [],
          ManuscriptDocumentType.backMatter: [],
          ManuscriptDocumentType.scene: [ManuscriptDocumentType.note],
          ManuscriptDocumentType.note: [],
          ManuscriptDocumentType.research: [],
          ManuscriptDocumentType.custom: [],
        };

    final allowed = validChildren[parentType] ?? [];
    if (!allowed.contains(childType)) {
      debugPrint('Warning: Unusual hierarchy: $parentType -> $childType');
      // Allow but warn - don't throw to maintain flexibility
    }
  }

  bool _wouldCreateCycle(String documentId, String newParentId) {
    if (documentId == newParentId) return true;
    final ancestors = getAncestors(newParentId);
    return ancestors.any((a) => a.id == documentId);
  }

  Future<void> _shiftSiblings(String parentId, int fromIndex, int shift) async {
    final children = getChildren(parentId);
    for (int i = fromIndex; i < children.length; i++) {
      children[i].orderIndex += shift;
      await children[i].save();
    }
  }

  void _updateProjectModifiedTime() {
    final project = _projectBox.get(projectId);
    if (project != null) {
      project.lastModified = DateTime.now();
      project.save();
    }
  }

  int _countWords(String json) {
    if (json.isEmpty) return 0;
    try {
      final text = json.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ');
      return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    } catch (_) {
      return 0;
    }
  }
}

/// Module-level constants for compatibility
class ManuscriptModule {
  static const String emptyRichTextJson = '{"ops":[{"insert":"\\n"}]}';
}
