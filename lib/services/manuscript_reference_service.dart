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
  Future<void> rebuildIndex() async {
    final entries = extractAllReferences();
    _referenceEngine.clear();
    for (final entry in entries) {
      _referenceEngine.addEntry(entry);
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
