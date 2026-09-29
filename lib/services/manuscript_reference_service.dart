// lib/services/manuscript_reference_service.dart

import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/services/reference_attribute.dart';

/// Service for extracting and managing inline references from manuscript documents.
///
/// Parses Quill Delta JSON for `ref:` links and syncs them with the
/// database ReferenceEngine index. Provides backlink queries for the UI.
class ManuscriptReferenceService {
  final int projectId;
  final ReferenceEngine _referenceEngine;
  final Box<ManuscriptDocument> _documentBox;

  ManuscriptReferenceService({
    required this.projectId,
    required ReferenceEngine referenceEngine,
    required Box<ManuscriptDocument> documentBox,
  }) : _referenceEngine = referenceEngine,
       _documentBox = documentBox;

  /// The shared [ReferenceEngine] backing this service.
  ///
  /// Exposed so consumers and topology tests can verify the service never
  /// diverges onto a private, unpopulated engine of its own — every reference
  /// producer in the manuscript pipeline must observe the shell's single index.
  ReferenceEngine get referenceEngine => _referenceEngine;

  /// Documents whose Delta JSON has been handed to `jsonDecode` since this
  /// service was constructed (Cycle 4b).
  ///
  /// Exists as *counted* evidence that the scoped re-index does less work than
  /// a full rebuild, and as a cheap way for a test to assert the scope of a
  /// call without reaching into Hive. Monotonic; never reset.
  int get parsedDocumentCount => _parsedDocumentCount;
  int _parsedDocumentCount = 0;

  /// Extract all inline references from a manuscript document's content.
  ///
  /// Scans the Quill Delta JSON for link attributes with `ref:` prefix.
  /// Returns a list of (targetEntityRef, kind) pairs found in the document.
  List<(EntityRef target, String kind)> extractReferencesFromDocument(
    ManuscriptDocument doc,
  ) {
    final references = <(EntityRef, String)>[];

    if (doc.richTextJson == null || doc.richTextJson!.isEmpty) {
      return references;
    }
    _parsedDocumentCount++;

    try {
      final jsonDoc = jsonDecode(doc.richTextJson!);
      final ops = jsonDoc is List ? jsonDoc : (jsonDoc['ops'] as List? ?? []);

      for (final op in ops) {
        if (op is Map && op['attributes'] is Map) {
          final attrs = op['attributes'] as Map;
          final link = attrs['link'] as String?;
          if (link != null && ReferenceTarget.isReference(link)) {
            final target = ReferenceTarget.decode(link);
            if (target != null) {
              final entityType = mapReferenceTypeToEntityType(target.type);
              final entityRef = EntityRef.fromKey(
                key: target.id,
                entityType: entityType,
                projectId: projectId.toString(),
              );
              references.add((entityRef, 'mentions'));
            }
          }
        }
      }
    } catch (_) {
      // Invalid JSON, skip
    }

    return references;
  }

  /// Extract all inline references from all manuscript documents in the project.
  List<ReferenceIndexEntry> extractAllReferences() {
    final entries = <ReferenceIndexEntry>[];
    final now = DateTime.now();

    final docs = _documentBox.values
        .where((d) => d.projectId == projectId)
        .toList();

    for (final doc in docs) {
      final sourceRef = EntityRef.fromKey(
        key: doc.id,
        entityType: EntityType.manuscriptDocument,
        projectId: projectId.toString(),
      );

      final refs = extractReferencesFromDocument(doc);
      for (final (target, kind) in refs) {
        entries.add(
          ReferenceIndexEntry(
            source: sourceRef,
            target: target,
            kind: kind,
            containerEntity: sourceRef,
            computedAt: now,
          ),
        );
      }
    }

    return entries;
  }

  /// Rebuild the reference index for all manuscript documents in this project.
  ///
  /// MS-014: this method owns *only* entries whose source is a
  /// [EntityType.manuscriptDocument]. The engine is shared with the rest of
  /// the app (spec §10: the index is derived, never duplicated), so other
  /// producers may legitimately hold entries on it. Calling `clear()` here
  /// silently destroyed every one of them on each 2s autosave — Character- and
  /// relationship-sourced backlinks vanished and reappeared only if something
  /// else happened to repopulate them. Removing just the manuscript-sourced
  /// slice keeps this method's ownership honest without touching anyone else's
  /// data.
  ///
  /// This is still a full re-scan of the project's documents, not an
  /// incremental single-document update. That is correct — a document's edits
  /// can change its outbound references anywhere — but it means every autosave
  /// re-parses every manuscript. See the Cycle 4 log for the performance note.
  Future<void> rebuildIndex() async {
    final entries = extractAllReferences();
    _referenceEngine.removeWhere(
      (e) => e.source.entityType == EntityType.manuscriptDocument,
    );
    for (final entry in entries) {
      _referenceEngine.addEntry(entry);
    }
  }

  /// The [EntityRef] a manuscript document is indexed under.
  EntityRef _sourceRefFor(String documentId) => EntityRef.fromKey(
    key: documentId,
    entityType: EntityType.manuscriptDocument,
    projectId: projectId.toString(),
  );

  /// Re-index exactly one document (Cycle 4b).
  ///
  /// This is the autosave path. [rebuildIndex] re-parses every document in the
  /// project, which with the 2s debounce meant a full-project scan on every
  /// pause in typing — and was the largest single contributor to the teardown
  /// window diagnosed in Cycle 3b-4.
  ///
  /// A body edit can only change what *that* document emits, so this removes
  /// only that document's prior entries and re-adds only its current ones.
  /// Every other document's entries keep object identity, so nothing else is
  /// re-parsed and nothing else's `computedAt` moves.
  ///
  /// **Scope warning — this is deliberately NOT a general-purpose rebuild.**
  /// It is correct only when the sole change is one document's `richTextJson`.
  /// Structural operations change what a document emits too, and must keep
  /// calling [rebuildIndex]:
  ///
  /// - **delete** — the document is gone from the box, so there is nothing to
  ///   re-parse; its entries are removed by `ReferenceIntegrityService`
  ///   (`removeSource`/`removeTarget`) from `ManuscriptBinderService.deleteDocument`,
  ///   which also handles the inbound backlinks. Calling this with a deleted id
  ///   is a safe no-op, but the binder's path is the correct owner.
  /// - **move / reorder** — these change `parentId`/`orderIndex`. They do not
  ///   change the document's own outbound entries today, so the index is
  ///   unaffected; that is why the autosave path may ignore them. If a future
  ///   change makes a document emit hierarchy-derived entries, this method must
  ///   be accompanied by a full rebuild on those operations.
  /// - **rename** — changes the title, which the current extractor does not
  ///   index. Same caveat as move.
  /// - **create** — a brand-new document contributes nothing until it has
  ///   content; a full rebuild (or a scoped call) picks it up.
  ///
  /// [rebuildIndex] remains the correct entry point for module-session init and
  /// for any path that cannot name a single changed document.
  Future<void> rebuildIndexFor(String documentId) async {
    // Remove this document's prior entries first, so a body edit that *dropped*
    // a reference cannot leave a dangling backlink behind.
    _referenceEngine.removeWhere(
      (e) =>
          e.source.entityType == EntityType.manuscriptDocument &&
          e.source.id == documentId,
    );

    final doc = _documentBox.get(documentId);
    // Missing, or belonging to another project: nothing to re-add. The removal
    // above is still the right outcome for a document that no longer exists.
    if (doc == null || doc.projectId != projectId) return;

    final sourceRef = _sourceRefFor(documentId);
    final now = DateTime.now();
    for (final (target, kind) in extractReferencesFromDocument(doc)) {
      _referenceEngine.addEntry(
        ReferenceIndexEntry(
          source: sourceRef,
          target: target,
          kind: kind,
          containerEntity: sourceRef,
          computedAt: now,
        ),
      );
    }
  }

  /// Get all backlinks pointing to a specific entity.
  List<ReferenceIndexEntry> getBacklinksTo(EntityRef target) {
    return _referenceEngine.backlinksTo(target);
  }

  /// Get all references originating from a manuscript document.
  List<ReferenceIndexEntry> getReferencesFrom(ManuscriptDocument doc) {
    final sourceRef = EntityRef.fromKey(
      key: doc.id,
      entityType: EntityType.manuscriptDocument,
      projectId: projectId.toString(),
    );
    return _referenceEngine.referencesFrom(sourceRef);
  }

  /// Get all references inside a container (e.g., a Part or Chapter).
  List<ReferenceIndexEntry> getReferencesInContainer(String containerDocId) {
    final containerRef = EntityRef.fromKey(
      key: containerDocId,
      entityType: EntityType.manuscriptDocument,
      projectId: projectId.toString(),
    );
    return _referenceEngine.insideContainer(containerRef);
  }

  /// Search references by query string.
  List<ReferenceIndexEntry> searchReferences(String query) {
    return _referenceEngine.search(query);
  }

  /// Get all distinct entity types referenced by a document.
  Set<String> getReferencedEntityTypes(ManuscriptDocument doc) {
    final sourceRef = EntityRef.fromKey(
      key: doc.id,
      entityType: EntityType.manuscriptDocument,
      projectId: projectId.toString(),
    );
    return _referenceEngine.referencedEntityTypes(sourceRef);
  }

  /// Map [ReferenceEntityType] to its corresponding [EntityType] string.
  ///
  /// Each inline-reference type maps to a distinct entity type so backlinks
  /// resolve to the correct module (a Location link must never be conflated
  /// with a Character link).
  String mapReferenceTypeToEntityType(ReferenceEntityType type) {
    return switch (type) {
      ReferenceEntityType.character => EntityType.character,
      ReferenceEntityType.location => EntityType.location,
      ReferenceEntityType.item => EntityType.item,
      ReferenceEntityType.organization => EntityType.organization,
      ReferenceEntityType.species => EntityType.species,
      ReferenceEntityType.faction => EntityType.faction,
      ReferenceEntityType.timelineEvent => EntityType.timelineEvent,
      ReferenceEntityType.manuscriptDocument => EntityType.manuscriptDocument,
      ReferenceEntityType.research => EntityType.customTrait,
      ReferenceEntityType.calendarDate => EntityType.calendarNode,
    };
  }
}
