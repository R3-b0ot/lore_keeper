// lib/services/manuscript_collections_service.dart

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/manuscript_collection.dart';
import 'package:lore_keeper/models/manuscript_document.dart';

/// Entity kinds that can back an "Entity Collection".
///
/// An Entity Collection groups manuscript documents that reference a specific
/// entity (Character, Species, etc.) through the central ReferenceEngine.
/// No duplicate relationship/index is created (spec §10).
enum EntityCollectionKind {
  character('Characters', EntityType.character),
  species('Species', EntityType.species),
  location('Locations', EntityType.location),
  organization('Organizations', EntityType.organization),
  faction('Factions', EntityType.faction),
  timelineEvent('Timeline Events', EntityType.timelineEvent);

  const EntityCollectionKind(this.label, this.entityType);
  final String label;
  final String entityType;
}

/// Persistence + resolution for Manuscript Collections.
///
/// - Custom collections are stored in a Hive box (survive restart, project
///   scoped) — spec §10.
/// - Entity collections resolve through [ReferenceEngine] backlinks and are
///   derived (never duplicated into a separate index) — spec §10.
/// - Favorites are persisted on each [ManuscriptDocument] (spec §11).
class ManuscriptCollectionsService {
  final int projectId;
  final Box<ManuscriptCollection> _collectionBox;
  final Box<ManuscriptDocument> _documentBox;
  final ReferenceEngine _referenceEngine;

  ManuscriptCollectionsService({
    required this.projectId,
    required Box<ManuscriptCollection> collectionBox,
    required Box<ManuscriptDocument> documentBox,
    required ReferenceEngine referenceEngine,
  }) : _collectionBox = collectionBox,
       _documentBox = documentBox,
       _referenceEngine = referenceEngine;

  // ── Custom Collections ──────────────────────────────────────────────────

  /// All custom collections for this project, newest first.
  List<ManuscriptCollection> getAllCollections() {
    final list =
        _collectionBox.values.where((c) => c.projectId == projectId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Create a new custom collection.
  Future<ManuscriptCollection> createCollection({
    required String name,
    ManuscriptDocumentType? documentType,
    ManuscriptDocumentStatus? status,
  }) async {
    final collection = ManuscriptCollection(
      id: const Uuid().v4(),
      projectId: projectId,
      name: name,
      documentTypeIndex: documentType?.index,
      statusIndex: status?.index,
    );
    await _collectionBox.put(collection.id, collection);
    return collection;
  }

  /// Rename a custom collection.
  Future<void> renameCollection(String collectionId, String newName) async {
    final collection = _collectionBox.get(collectionId);
    if (collection == null || collection.projectId != projectId) return;
    collection.name = newName;
    await collection.save();
  }

  /// Delete a custom collection.
  Future<void> deleteCollection(String collectionId) async {
    final collection = _collectionBox.get(collectionId);
    if (collection == null || collection.projectId != projectId) return;
    await collection.delete();
  }

  /// Documents matched by a custom collection's type/status filters.
  List<ManuscriptDocument> documentsForCollection(
    ManuscriptCollection collection,
  ) {
    return _documentsInProject().where((d) {
      if (collection.documentType != null &&
          d.documentType != collection.documentType) {
        return false;
      }
      if (collection.status != null && d.status != collection.status) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Entity Collections ──────────────────────────────────────────────────

  /// Manuscript documents that reference a given entity, resolved through the
  /// ReferenceEngine's backlinks (no duplicate relationship index).
  ///
  /// [entityRef] must already be scoped to the correct project.
  List<ManuscriptDocument> documentsForEntity(EntityRef entityRef) {
    final backlinks = _referenceEngine.backlinksTo(entityRef);
    final docIds = backlinks
        .where((e) => e.source.entityType == EntityType.manuscriptDocument)
        .map((e) => e.source.id)
        .toSet();

    return _documentsInProject().where((d) => docIds.contains(d.id)).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  List<ManuscriptDocument> _documentsInProject() =>
      _documentBox.values.where((d) => d.projectId == projectId).toList();

  /// Build an [EntityRef] for a referenceable entity id across the whole
  /// project (characters, timeline events, etc.).
  EntityRef refFor(EntityCollectionKind kind, String entityId) =>
      EntityRef.fromKey(
        key: entityId,
        entityType: kind.entityType,
        projectId: projectId.toString(),
      );
}
