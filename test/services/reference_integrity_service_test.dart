/// Unit tests for [ReferenceIntegrityService], the shared deletion-integrity
/// mechanism for the ReferenceEngine index (spec §14 / §27).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/services/reference_integrity_service.dart';

EntityRef ref(String id, String type, String project) =>
    EntityRef(id: id, entityType: type, projectId: project);

ReferenceIndexEntry entry(
  EntityRef source,
  EntityRef target, {
  String kind = 'mentions',
}) => ReferenceIndexEntry(
  source: source,
  target: target,
  kind: kind,
  containerEntity: source,
  computedAt: DateTime(2025),
);

void main() {
  const projA = '1';
  const projB = '2';

  final characterA = ref('char_1', EntityType.character, projA);
  final locationA = ref('loc_1', EntityType.location, projA);
  final docAA = ref('doc_1', EntityType.manuscriptDocument, projA);
  final docAB = ref('doc_2', EntityType.manuscriptDocument, projA);
  final characterB = ref('char_9', EntityType.character, projB);

  ReferenceEngine makeEngine() {
    final e = ReferenceEngine();
    e.addEntry(entry(docAA, characterA));
    e.addEntry(entry(docAB, characterA));
    e.addEntry(entry(docAA, locationA));
    e.addEntry(entry(docAB, characterB));
    return e;
  }

  bool Function(EntityRef) exists(Set<(String, String, String)> existing) =>
      (ref) => existing.contains((ref.id, ref.entityType, ref.projectId));

  group('planDeletion', () {
    test('separates outbound and inbound references', () {
      final engine = makeEngine();
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => true,
      );

      // Delete loc_1: it is a target in one entry (from docAA).
      final plan = service.planDeletion(locationA);
      expect(plan.outbound, isEmpty);
      expect(plan.inbound, hasLength(1));
      expect(plan.all, hasLength(1));
    });

    test('doc with both inbound and outbound yields both groups', () {
      final engine = ReferenceEngine();
      final ch1 = ref('c1', EntityType.character, projA);
      final doc = ref('d1', EntityType.manuscriptDocument, projA);
      engine.addEntry(entry(doc, ch1)); // outbound
      engine.addEntry(entry(ch1, doc)); // inbound
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => true,
      );

      final plan = service.planDeletion(doc);
      expect(plan.outbound, hasLength(1));
      expect(plan.inbound, hasLength(1));
    });
  });

  group('execute', () {
    test('cancel leaves the index untouched', () {
      final engine = makeEngine();
      final before = engine.length;
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => true,
      );
      final removed = service.execute(characterA, DeletionStrategy.cancel);
      expect(removed, isEmpty);
      expect(engine.length, before);
    });

    test('preserve leaves index intact (entries become unresolved)', () {
      final engine = makeEngine();
      final before = engine.length;
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => true,
      );
      final affected = service.execute(characterA, DeletionStrategy.preserve);
      expect(engine.length, before, reason: 'preserve must not mutate index');
      expect(affected, isNotEmpty);
    });

    test('removeReferences removes both inbound and outbound', () {
      final engine = ReferenceEngine();
      final ch = ref('c1', EntityType.character, projA);
      final doc = ref('d1', EntityType.manuscriptDocument, projA);
      engine.addEntry(entry(doc, ch));
      engine.addEntry(entry(ch, doc));
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => true,
      );
      service.execute(ch, DeletionStrategy.removeReferences);
      expect(engine.length, 0);
    });
  });

  group('stale-entry cleanup', () {
    test('findStaleEntries reports broken references only', () {
      final existing = <(String, String, String)>{
        (docAA.id, docAA.entityType, docAA.projectId),
        (docAB.id, docAB.entityType, docAB.projectId),
        // characterA and locationA are "deleted"; characterB exists
        (characterB.id, characterB.entityType, characterB.projectId),
      };
      // mimic deletion: characterA & locationA removed -> their refs stale
      final engine2 = ReferenceEngine();
      engine2.addEntry(entry(docAA, characterA));
      engine2.addEntry(entry(docAB, characterA));
      engine2.addEntry(entry(docAA, locationA));
      engine2.addEntry(entry(docAB, characterB));

      final service = ReferenceIntegrityService(
        engine: engine2,
        entityExists: exists(existing),
      );
      final stale = service.findStaleEntries();
      // characterA (2) + locationA (1) stale; characterB exists
      expect(stale, hasLength(3));
    });

    test('purgeStaleEntries removes only stale entries', () {
      final engine = ReferenceEngine();
      final a = ref('a', EntityType.character, projA);
      final b = ref('b', EntityType.character, projA);
      final doc = ref('d', EntityType.manuscriptDocument, projA);
      engine.addEntry(entry(doc, a));
      engine.addEntry(entry(doc, b));
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (r) => r != a,
      );
      final removed = service.purgeStaleEntries();
      expect(removed, hasLength(1));
      expect(engine.length, 1);
      expect(engine.index.single.target, b);
    });

    test('stale reference never reattaches to recreated entity', () {
      // Delete char_1, then recreate char_1: the stale entry must not
      // silently re-link. purgeStaleEntries must drop it on delete.
      final engine = ReferenceEngine();
      final doc = ref('d', EntityType.manuscriptDocument, projA);
      final ch = ref('ch', EntityType.character, projA);
      engine.addEntry(entry(doc, ch));

      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => false, // char was deleted
      );
      service.purgeStaleEntries();
      expect(engine.length, 0);

      // Recreate the same id now "exists" again -> no stale link remains
      final service2 = ReferenceIntegrityService(
        engine: engine,
        entityExists: (_) => true,
      );
      expect(service2.hasUnresolvedReferences, isFalse);
    });
  });

  group('cross-project isolation', () {
    test('Project A target never resolves a Project B reference', () {
      final engine = makeEngine();
      // characterB lives in Project B; a Project B backlink query works.
      final projBBacklinks = engine.backlinksTo(
        EntityRef(
          id: characterB.id,
          entityType: characterB.entityType,
          projectId: projB,
        ),
      );
      expect(projBBacklinks, isNotEmpty);

      // A Project A query must never return a Project B-only entry: loc_1
      // only exists in Project A and its single inbound ref is project-scoped.
      final locABacklinks = engine.backlinksTo(
        EntityRef(
          id: locationA.id,
          entityType: locationA.entityType,
          projectId: projA,
        ),
      );
      expect(locABacklinks, isNotEmpty);
      expect(
        locABacklinks.every((e) => e.source.projectId == projA),
        isTrue,
        reason: 'all inbound refs to loc_1 must come from Project A',
      );
    });
  });

  group('unresolved reporting', () {
    test('groupByUnresolved groups by missing entity', () {
      final engine = ReferenceEngine();
      final doc = ref('d', EntityType.manuscriptDocument, projA);
      final ch = ref('ch', EntityType.character, projA);
      final loc = ref('lo', EntityType.location, projA);
      engine.addEntry(entry(doc, ch));
      engine.addEntry(entry(doc, loc));
      final service = ReferenceIntegrityService(
        engine: engine,
        entityExists: (r) => r == doc, // only the doc exists
      );
      final groups = service.groupByUnresolved();
      expect(groups, contains(ch));
      expect(groups, contains(loc));
    });
  });
}
