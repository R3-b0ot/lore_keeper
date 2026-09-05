/// Shared deletion-integrity service for the ReferenceEngine index.
///
/// §14 / §27 of the Master Spec: when an entity or manuscript document is
/// deleted, inbound/outbound references must be handled explicitly.
///
/// The service operates on the in-memory [ReferenceEngine] index and accepts
/// resolver callbacks so it never couples to specific Hive boxes.
library;

import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';

/// Three deletion strategies defined by the spec §14.
enum DeletionStrategy {
  /// Do nothing; the delete is aborted.
  cancel,

  /// Remove all index entries that reference the entity, but leave the
  /// remaining outbound references from other entities untouched.
  preserve,

  /// Remove every index entry whose source OR target matches the entity.
  removeReferences,
}

/// A set of [ReferenceIndexEntry]s grouped by reason for the caller to
/// present before committing.
class DeletionPlan {
  /// Index entries where the entity appears as a *source* (outbound refs).
  final List<ReferenceIndexEntry> outbound;

  /// Index entries where the entity appears as a *target* (inbound backlinks).
  final List<ReferenceIndexEntry> inbound;

  /// All entries combined.
  List<ReferenceIndexEntry> get all => [...outbound, ...inbound];

  /// Whether there are any entries at all.
  bool get isEmpty => outbound.isEmpty && inbound.isEmpty;

  const DeletionPlan({required this.outbound, required this.inbound});
}

/// Service that manages reference integrity when entities or documents
/// are deleted, rebuilt, or purged.
///
/// Consumed by:
/// - entity deletion dialogs (Character/Location/Item/Org/...)
/// - manuscript document deletion (Binder delete)
/// - background stale-entry cleanup
/// - project reset / purge
class ReferenceIntegrityService {
  /// The engine whose index this service operates on.
  final ReferenceEngine engine;

  /// Resolves whether an entity identified by [EntityRef] still exists in
  /// the authoritative data source (Hive box, etc.).
  ///
  /// Return `true` if the entity exists; `false` if it has been deleted or
  /// was never created.
  final bool Function(EntityRef) entityExists;

  ReferenceIntegrityService({required this.engine, required this.entityExists});

  // ── Deletion Planning ─────────────────────────────────────────────────

  /// Build a [DeletionPlan] for removing [entityRef] from the index.
  ///
  /// Does **not** mutate the index; the caller must decide the strategy
  /// and then call [execute].
  DeletionPlan planDeletion(EntityRef entityRef) {
    return DeletionPlan(
      outbound: engine.referencesFrom(entityRef),
      inbound: engine.backlinksTo(entityRef),
    );
  }

  /// Execute a deletion strategy for [entityRef].
  ///
  /// Only [DeletionStrategy.removeReferences] mutates the index. The
  /// [DeletionStrategy.preserve] strategy leaves the index intact so the
  /// entries can later be surfaced via [findStaleEntries] (the entity no
  /// longer exists). [DeletionStrategy.cancel] is a no-op.
  ///
  /// Always returns the entries affected by the chosen strategy so the
  /// caller can present them before committing.
  List<ReferenceIndexEntry> execute(
    EntityRef entityRef,
    DeletionStrategy strategy,
  ) {
    switch (strategy) {
      case DeletionStrategy.cancel:
        return const [];

      case DeletionStrategy.preserve:
        // Keep the index entries; they are now unresolved. Return them so
        // the caller can flag/report them.
        return [
          ...engine.referencesFrom(entityRef),
          ...engine.backlinksTo(entityRef),
        ];

      case DeletionStrategy.removeReferences:
        final removed = <ReferenceIndexEntry>[];
        removed.addAll(engine.referencesFrom(entityRef));
        removed.addAll(engine.backlinksTo(entityRef));
        engine.removeWhere(
          (e) => e.source == entityRef || e.target == entityRef,
        );
        return removed;
    }
  }

  // ── Source / Target Cleanup ───────────────────────────────────────────

  /// Remove all index entries where the *source* is [sourceRef].
  ///
  /// Used when a manuscript document is deleted: its outbound references
  /// are removed from the index.
  List<ReferenceIndexEntry> removeSource(EntityRef sourceRef) {
    final entries = engine.referencesFrom(sourceRef);
    engine.removeWhere((e) => e.source == sourceRef);
    return entries;
  }

  /// Remove all index entries where the *target* is [targetRef].
  ///
  /// Used when you want to strip all references *to* an entity without
  /// touching references *from* other entities.
  List<ReferenceIndexEntry> removeTarget(EntityRef targetRef) {
    final entries = engine.backlinksTo(targetRef);
    engine.removeWhere((e) => e.target == targetRef);
    return entries;
  }

  // ── Stale-Entry Cleanup ──────────────────────────────────────────────

  /// Find all entries whose source or target no longer exists in the
  /// authoritative data.
  List<ReferenceIndexEntry> findStaleEntries() {
    return engine.index
        .where((e) => !entityExists(e.source) || !entityExists(e.target))
        .toList();
  }

  /// Remove all stale entries from the index.
  ///
  /// Returns the removed entries for logging / undo purposes.
  List<ReferenceIndexEntry> purgeStaleEntries() {
    final stale = findStaleEntries();
    engine.removeWhere(
      (e) => !entityExists(e.source) || !entityExists(e.target),
    );
    return stale;
  }

  // ── Purge / Reset ────────────────────────────────────────────────────

  /// Remove **all** index entries.
  ///
  /// Used during project reset or full rebuild.
  void purgeAll() {
    engine.clear();
  }

  // ── Unresolved-Reference Reporting ───────────────────────────────────

  /// Group entries by their unresolved entity (source or target)
  /// for diagnostic UI.
  Map<EntityRef, List<ReferenceIndexEntry>> groupByUnresolved() {
    final map = <EntityRef, List<ReferenceIndexEntry>>{};
    for (final entry in engine.index) {
      if (!entityExists(entry.source)) {
        map.putIfAbsent(entry.source, () => []).add(entry);
      }
      if (!entityExists(entry.target)) {
        map.putIfAbsent(entry.target, () => []).add(entry);
      }
    }
    return map;
  }

  /// Count of entries referencing at least one nonexistent entity.
  int get unresolvedCount => findStaleEntries().length;

  /// Whether the index contains any broken references.
  bool get hasUnresolvedReferences => unresolvedCount > 0;
}
