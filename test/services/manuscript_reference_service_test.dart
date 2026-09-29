/// Unit tests for [ManuscriptReferenceService] reference-type mapping.
///
/// Verifies that each inline `ReferenceEntityType` maps to a distinct
/// [EntityType] so backlinks never conflate a Location/Item/Organization
/// with a Character (which would corrupt the DB-level reference index).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/services/manuscript_reference_service.dart';
import 'package:lore_keeper/services/reference_attribute.dart';

void main() {
  group('ManuscriptReferenceService reference-type mapping', () {
    test('every ReferenceEntityType maps to a distinct EntityType', () {
      final expected = <ReferenceEntityType, String>{
        ReferenceEntityType.character: EntityType.character,
        ReferenceEntityType.location: EntityType.location,
        ReferenceEntityType.item: EntityType.item,
        ReferenceEntityType.organization: EntityType.organization,
        ReferenceEntityType.species: EntityType.species,
        ReferenceEntityType.faction: EntityType.faction,
        ReferenceEntityType.timelineEvent: EntityType.timelineEvent,
        ReferenceEntityType.manuscriptDocument: EntityType.manuscriptDocument,
        ReferenceEntityType.research: EntityType.customTrait,
        ReferenceEntityType.calendarDate: EntityType.calendarNode,
      };
      expect(ReferenceEntityType.values.length, expected.length);
      expect(
        expected.values.toSet().length,
        expected.length,
        reason: 'target EntityTypes must be unique',
      );
    });

    test('EntityType includes manuscript, location, item, organization', () {
      expect(EntityType.all, contains(EntityType.manuscriptDocument));
      expect(EntityType.all, contains(EntityType.location));
      expect(EntityType.all, contains(EntityType.item));
      expect(EntityType.all, contains(EntityType.organization));
      expect(EntityType.all.length, equals(EntityType.all.toSet().length));
    });

    test('extractReferencesFromDocument stores distinct target types', () async {
      final dir = await Directory.systemTemp.createTemp('hive_map_ref_');
      Hive.init(dir.path);
      Hive.registerAdapter(ManuscriptDocumentAdapter());
      final box = await Hive.openBox<ManuscriptDocument>(
        'manuscript_documents',
      );

      final doc = ManuscriptDocument()
        ..id = 'doc_1'
        ..projectId = 7
        ..title = 'Chapter One'
        ..documentTypeIndex = ManuscriptDocumentType.chapter.index;
      doc.richTextJson =
          '[{"insert":"Link to "},{"insert":"","attributes":{"link":"ref:Location:loc_1"}},{"insert":" and "},{"insert":"","attributes":{"link":"ref:Item:item_2"}},{"insert":" end"}]';
      await box.put(doc.id, doc);

      final service = ManuscriptReferenceService(
        projectId: 7,
        referenceEngine: ReferenceEngine(),
        documentBox: box,
      );
      final refs = service.extractReferencesFromDocument(doc);

      final loc = refs.where((r) => r.$1.id == 'loc_1').toList();
      final item = refs.where((r) => r.$1.id == 'item_2').toList();
      expect(loc, hasLength(1));
      expect(loc.single.$1.entityType, EntityType.location);
      expect(item, hasLength(1));
      expect(item.single.$1.entityType, EntityType.item);

      service.rebuildIndex();
      final backlinks = service.getBacklinksTo(
        EntityRef(id: 'loc_1', entityType: EntityType.location, projectId: '7'),
      );
      expect(backlinks, isNotEmpty);

      await box.close();
      await Hive.deleteFromDisk();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
  });

  group('MS-014 — rebuildIndex only owns manuscript-sourced entries', () {
    late Directory dir;
    late Box<ManuscriptDocument> box;
    late ReferenceEngine engine;
    late ManuscriptReferenceService service;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('hive_ms014_');
      Hive.init(dir.path);
      // The adapter registry is global and outlives Hive.deleteFromDisk(), so
      // a second registration throws "already a TypeAdapter for typeId 40".
      // Register once per process, not once per test.
      if (!Hive.isAdapterRegistered(ManuscriptDocumentAdapter().typeId)) {
        Hive.registerAdapter(ManuscriptDocumentAdapter());
      }
      box = await Hive.openBox<ManuscriptDocument>('manuscript_documents');
      engine = ReferenceEngine();
      service = ManuscriptReferenceService(
        projectId: 7,
        referenceEngine: engine,
        documentBox: box,
      );
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteFromDisk();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    final charSource = EntityRef(
      id: '5',
      entityType: EntityType.character,
      projectId: '7',
    );
    final factionTarget = EntityRef(
      id: 'fac_1',
      entityType: EntityType.faction,
      projectId: '7',
    );

    /// A non-manuscript entry: sourced by a Character, not a document.
    ReferenceIndexEntry characterEntry() => ReferenceIndexEntry(
      source: charSource,
      target: factionTarget,
      kind: 'linked_to',
      computedAt: DateTime(2026),
    );

    /// A manuscript-sourced entry, as the real extractor produces.
    ReferenceIndexEntry manuscriptEntry() => ReferenceIndexEntry(
      source: EntityRef(
        id: 'doc_1',
        entityType: EntityType.manuscriptDocument,
        projectId: '7',
      ),
      target: EntityRef(
        id: 'loc_1',
        entityType: EntityType.location,
        projectId: '7',
      ),
      kind: 'mentions',
      computedAt: DateTime(2026),
    );

    test('a non-manuscript-sourced entry survives rebuildIndex', () async {
      engine.addEntry(characterEntry());
      expect(engine.length, 1);

      await service.rebuildIndex();

      // MS-014: rebuildIndex owns manuscript documents' entries only. It must
      // not wipe entries produced by other producers on the shared engine.
      expect(
        engine.backlinksTo(factionTarget),
        hasLength(1),
        reason:
            'a Character-sourced entry must survive a manuscript rebuildIndex',
      );
      expect(engine.referencesFrom(charSource), hasLength(1));
    });

    test('stale manuscript entries are still replaced, not merely kept',
        () async {
      // A manuscript entry pointing at a character that no longer appears in
      // the document must disappear on rebuild.
      engine.addEntry(manuscriptEntry());
      expect(engine.length, 1);

      // The document box is empty, so the extractor finds nothing and the
      // stale manuscript entry must be gone afterwards.
      await service.rebuildIndex();

      expect(
        engine.referencesFrom(
          EntityRef(
            id: 'doc_1',
            entityType: EntityType.manuscriptDocument,
            projectId: '7',
          ),
        ),
        isEmpty,
        reason: 'MS-014 must not degrade rebuildIndex into a no-op append',
      );
    });

    test('rebuildIndex is idempotent across repeated calls', () async {
      final doc = ManuscriptDocument()
        ..id = 'doc_1'
        ..projectId = 7
        ..title = 'Chapter One'
        ..documentTypeIndex = ManuscriptDocumentType.chapter.index;
      doc.richTextJson =
          '[{"insert":"","attributes":{"link":"ref:Location:loc_1"}}]';
      await box.put(doc.id, doc);

      engine.addEntry(characterEntry());
      await service.rebuildIndex();
      final afterFirst = engine.length;
      await service.rebuildIndex();

      expect(
        engine.length,
        afterFirst,
        reason: 'a second rebuild must replace, not duplicate, its own entries',
      );
      // The non-manuscript entry is still there after both rebuilds.
      expect(engine.referencesFrom(charSource), hasLength(1));
      expect(
        engine.backlinksTo(
          EntityRef(
            id: 'loc_1',
            entityType: EntityType.location,
            projectId: '7',
          ),
        ),
        hasLength(1),
      );
    });
  });
}
