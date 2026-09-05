// lib/services/reference_name_resolver.dart

import 'package:hive/hive.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/services/reference_integrity_service.dart';

/// Canonical display-name resolver for referenceable entities.
///
/// Maps an [EntityRef] (or a raw id + [EntityType]) to a human-readable name
/// by looking up the authoritative Hive box for the entity's type. It is
/// strictly project-scoped: a cross-project id must never resolve.
///
/// Used by the Inspector (C0-3) and as the source of canonical names for the
/// @mention autocomplete (C0-2). No duplicate relationship index is created —
/// this only reads names from existing boxes.
class ReferenceNameResolver {
  /// The project whose entities this resolver may look up.
  final int projectId;

  final Box<Character> _characters;
  final Box<ClassificationNode> _classificationNodes;
  final Box<TimelineEvent> _timelineEvents;
  final Box<ManuscriptDocument> _manuscriptDocuments;

  ReferenceNameResolver({
    required this.projectId,
    required Box<Character> characters,
    required Box<ClassificationNode> classificationNodes,
    required Box<TimelineEvent> timelineEvents,
    required Box<ManuscriptDocument> manuscriptDocuments,
  }) : _characters = characters,
       _classificationNodes = classificationNodes,
       _timelineEvents = timelineEvents,
       _manuscriptDocuments = manuscriptDocuments;

  /// Build a resolver wired to the application's live [DatabaseManager] boxes.
  factory ReferenceNameResolver.fromDatabase(int projectId) {
    final db = DatabaseManager.instance;
    return ReferenceNameResolver(
      projectId: projectId,
      characters: db.characters,
      classificationNodes: db.classificationNodes,
      timelineEvents: db.timelineEvents,
      manuscriptDocuments: db.manuscriptDocuments,
    );
  }

  /// Resolve a readable name for [ref], or `null` when the entity does not
  /// exist in this project or its type has no canonical name source.
  String? resolve(EntityRef ref) {
    return resolveById(ref.id, ref.entityType);
  }

  /// Resolve a readable name for [entityId] of [entityType].
  ///
  /// Returns `null` when the entity cannot be found in the current project,
  /// when it belongs to another project, or when the type has no known name
  /// source. Callers should fall back to showing the raw id in that case.
  String? resolveById(String entityId, String entityType) {
    switch (entityType) {
      case EntityType.character:
        final character = _characterByNameOrKey(entityId);
        return character?.name;
      case EntityType.species:
        final node = _speciesNode(entityId);
        return node?.name;
      case EntityType.timelineEvent:
        final event = _timelineEvent(entityId);
        return event?.name;
      case EntityType.manuscriptDocument:
        final doc = _manuscriptDocuments.get(entityId);
        return (doc != null && doc.projectId == projectId) ? doc.title : null;
      default:
        // Location/Item/Org/Faction/Research/Magic/Calendar have no canonical
        // readable-name source in this release. Return null → caller shows id.
        return null;
    }
  }

  Character? _characterByNameOrKey(String entityId) {
    final key = int.tryParse(entityId);
    if (key != null) {
      final byKey = _characters.get(key);
      if (byKey != null && byKey.parentProjectId == projectId) return byKey;
      return null;
    }
    for (final c in _characters.values) {
      if (c.parentProjectId == projectId && c.name == entityId) return c;
    }
    return null;
  }

  ClassificationNode? _speciesNode(String entityId) {
    for (final node in _classificationNodes.values) {
      if (node.projectId == projectId && node.id == entityId) return node;
    }
    return null;
  }

  TimelineEvent? _timelineEvent(String entityId) {
    for (final event in _timelineEvents.values) {
      if (event.projectId == projectId && event.id == entityId) return event;
    }
    return null;
  }

  /// Report whether the entity referenced by [ref] still exists in its box,
  /// scoped to the project the reference belongs to.
  ///
  /// This is the single source of truth used by [ReferenceIntegrityService] to
  /// detect stale backlinks: a target whose owning entity was deleted must
  /// resolve to false so the manuscript index can purge the dangling entry.
  /// Like [resolveById], types without a canonical box (Location, Item,
  /// Organization, Faction, Research) resolve to false.
  bool entityExists(EntityRef ref) {
    final targetProjectId = int.tryParse(ref.projectId) ?? -1;
    switch (ref.entityType) {
      case EntityType.character:
        final key = int.tryParse(ref.id);
        if (key != null) {
          final c = _characters.get(key);
          return c != null && c.parentProjectId == targetProjectId;
        }
        return _characters.values.any(
          (c) => c.parentProjectId == targetProjectId && c.name == ref.id,
        );
      case EntityType.species:
        return _nodeExists(targetProjectId, ref.id);
      case EntityType.timelineEvent:
        return _timelineEvents.values.any(
          (e) => e.projectId == targetProjectId && e.id == ref.id,
        );
      case EntityType.manuscriptDocument:
        final doc = _manuscriptDocuments.get(ref.id);
        return doc != null && doc.projectId == targetProjectId;
      default:
        return false;
    }
  }

  bool _nodeExists(int projectId, String id) {
    return _classificationNodes.values.any(
      (n) => n.projectId == projectId && n.id == id,
    );
  }

  /// Remove dangling entries from [engine] whose source or target no longer
  /// resolves, using this resolver's canonical project-scoped existence check.
  ///
  /// This is the single purge entry point for entity deletion: after an entity
  /// is removed from its box, calling this re-points the shared manuscript
  /// index back to a consistent state by dropping any lingering backlinks to
  /// the deleted entity. Because [entityExists] is project-scoped, entities
  /// that still exist in *other* projects are never purged (cross-project
  /// isolation).
  List<ReferenceIndexEntry> purgeStale(ReferenceEngine engine) {
    final service = ReferenceIntegrityService(
      engine: engine,
      entityExists: entityExists,
    );
    return service.purgeStaleEntries();
  }

  /// Production entry point for entity providers: purge stale entries from the
  /// shared [engine] using the live database's boxes.
  ///
  /// [entityExists] scopes each check by the reference's own [EntityRef.projectId]
  /// (not this resolver's project), so building the resolver from the database
  /// with a placeholder project id is safe — a ref in project 1 is never
  /// validated against project 2 entities.
  static List<ReferenceIndexEntry> purgeStaleFromDatabase(
    ReferenceEngine engine,
  ) {
    return ReferenceNameResolver.fromDatabase(-1).purgeStale(engine);
  }
}