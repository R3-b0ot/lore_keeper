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
  ///
  /// This is the *resolution* predicate and is still what reporting paths
  /// ([findStaleEntries], [groupByUnresolved], [unresolvedCount]) use, so an
  /// unresolvable-but-valid mention is still surfaced to the author.
  final bool Function(EntityRef) entityExists;

  /// Resolves whether an entity is *known* to have been deleted, as opposed to
  /// merely being unresolvable (MS-016).
  ///
  /// Defaults to [entityExists], which preserves the original purge behaviour
  /// for any existing caller. Supply [ReferenceNameResolver.entityIsDefinitelyGone]
  /// to stop types with no canonical data source from being purged as if they
  /// had been deleted.
  final bool Function(EntityRef) entityIsDefinitelyGone;

  ReferenceIntegrityService({
    required this.engine,
    required this.entityExists,
    bool Function(EntityRef)? entityIsDefinitelyGone,
  }) : // Polarity note: this predicate answers "was it deleted?", so the
      // fallback has to *negate* the resolution predicate. Defaulting to
      // `entityExists` itself would mean "exists" and purge every entry whose
      // source or target resolves — the exact inverse of the old behaviour.
        entityIsDefinitelyGone =
            entityIsDefinitelyGone ?? ((ref) => !entityExists(ref));

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

  /// Remove all entries whose source or target is *known to have been deleted*
  /// from the index.
  ///
  /// MS-016: this is a removal decision, so it uses
  /// [entityIsDefinitelyGone] rather than [entityExists]. An entity type with
  /// no canonical data source resolves to false under [entityExists] simply
  /// because nothing can be looked up, and purging on that basis would
  /// irreversibly discard valid mentions of every not-yet-implemented type.
  ///
  /// Reporting is deliberately left on [entityExists] via [findStaleEntries], so
  /// unresolved mentions are still surfaced — they are just no longer deleted.
  ///
  /// Returns the removed entries for logging / undo purposes.
  List<ReferenceIndexEntry> purgeStaleEntries() {
    final gone = engine.index
        .where(
          (e) => entityIsDefinitelyGone(e.source) || entityIsDefinitelyGone(e.target),
        )
        .toList();
    engine.removeWhere(
      (e) =>
          entityIsDefinitelyGone(e.source) || entityIsDefinitelyGone(e.target),
    );
    return gone;
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
