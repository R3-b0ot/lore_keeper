/// Unit tests for [ReferenceNameResolver] — the shared, project-scoped
/// display-name + existence resolution used by the Inspector (C0-3) and the
/// stale-backlink purge on entity deletion (C0-1).
///
/// The resolver is box-injected so it is tested with in-memory Hive boxes
/// (no live database singleton required).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_metadata.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/services/reference_name_resolver.dart';

const _projA = '1';
const _projB = '2';

ManuscriptDocument _doc(String id, String projectId) {
  return ManuscriptDocument()
    ..id = id
    ..projectId = int.parse(projectId)
    ..title = 'Doc $id';
}

TimelineEvent _timelineEvent(String id, String projectId, String name) {
  return TimelineEvent(
    id: id,
    projectId: int.parse(projectId),
    name: name,
    tier: 'major',
    absoluteYear: 100,
    absoluteDayOfYear: 10,
    iconKey: 'star',
    colorValue: 0xFF000000,
    lore: '',
  );
}

ClassificationNode _speciesNode(String id, String projectId, String name) {
  return ClassificationNode(
    id: id,
    projectId: int.parse(projectId),
    rank: 'species',
    name: name,
    normalizedName: ClassificationNode.normalizeName(name),
  );
}

ReferenceIndexEntry _entry(EntityRef source, EntityRef target) =>
    ReferenceIndexEntry(
      source: source,
      target: target,
      kind: 'mentions',
      containerEntity: source,
      computedAt: DateTime(2025),
    );

EntityRef _ref(String id, String type, String project) =>
    EntityRef(id: id, entityType: type, projectId: project);

void main() {
  late Directory dir;
  late Box<Character> charBox;
  late Box<ClassificationNode> speciesBox;
  late Box<TimelineEvent> timelineBox;
  late Box<ManuscriptDocument> docBox;
  late ReferenceNameResolver resolverA;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lk_resolver_');
    Hive.init(dir.path);
    // Generic registration matches DatabaseManager._registerAdapters():
    // registering a raw TypeAdapter silently registers a dynamic-type adapter
    // that hijacks ALL box writes on this Hive instance, routing every value
    // through the first-registered adapter.
    void register<T>(int id, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(id)) {
        Hive.registerAdapter<T>(adapter);
      }
    }

    register<Character>(4, CharacterAdapter());
    register<TimelineEvent>(29, TimelineEventAdapter());
    register<ClassificationNode>(36, ClassificationNodeAdapter());
    register<ManuscriptDocument>(40, ManuscriptDocumentAdapter());

    speciesBox = await Hive.openBox<ClassificationNode>('classification_nodes');
    timelineBox = await Hive.openBox<TimelineEvent>('timeline_events');
    docBox = await Hive.openBox<ManuscriptDocument>('manuscript_documents');
    charBox = await Hive.openBox<Character>('characters');

    resolverA = ReferenceNameResolver(
      projectId: int.parse(_projA),
      characters: charBox,
      classificationNodes: speciesBox,
      timelineEvents: timelineBox,
      manuscriptDocuments: docBox,
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  group('resolveById', () {
    test('resolves a character by its numeric Hive key', () async {
      final key = await charBox.add(
        Character(name: 'Aria', parentProjectId: 1),
      );
      expect(resolverA.resolveById('$key', EntityType.character), 'Aria');
    });

    test('resolves a character by name when the id is not a key', () async {
      await charBox.add(Character(name: 'Thorin', parentProjectId: 1));
      expect(resolverA.resolveById('Thorin', EntityType.character), 'Thorin');
    });

    test('resolves a species node by its string id', () async {
      await speciesBox.add(_speciesNode('sp_1', _projA, 'Dragon'));
      expect(resolverA.resolveById('sp_1', EntityType.species), 'Dragon');
    });

    test('resolves a timeline event by its string id', () async {
      await timelineBox.add(_timelineEvent('ev_1', _projA, 'The Fall'));
      expect(
        resolverA.resolveById('ev_1', EntityType.timelineEvent),
        'The Fall',
      );
    });

    test('resolves a manuscript document by its id', () async {
      await docBox.put('doc_1', _doc('doc_1', _projA));
      expect(
        resolverA.resolveById('doc_1', EntityType.manuscriptDocument),
        'Doc doc_1',
      );
    });

    test(
      'returns null for a cross-project entity (project isolation)',
      () async {
        final key = await charBox.add(
          Character(name: 'Elsewhere', parentProjectId: 2),
        );
        expect(resolverA.resolveById('$key', EntityType.character), isNull);
        await speciesBox.add(_speciesNode('sp_9', _projB, 'Alien'));
        expect(resolverA.resolveById('sp_9', EntityType.species), isNull);
      },
    );

    test('returns null for unknown ids and unsupported types', () async {
      expect(
        resolverA.resolveById('does_not_exist', EntityType.character),
        isNull,
      );
      expect(resolverA.resolveById('x', EntityType.location), isNull);
      expect(resolverA.resolveById('x', EntityType.customTrait), isNull);
    });
  });

  group('entityExists', () {
    test('true only for entities present in the (scoped) box', () async {
      final key = await charBox.add(
        Character(name: 'Lyra', parentProjectId: 1),
      );
      await speciesBox.add(_speciesNode('sp_1', _projA, 'Wolf'));
      await timelineBox.add(_timelineEvent('ev_1', _projA, 'Battle'));
      await docBox.put('doc_1', _doc('doc_1', _projA));

      expect(
        resolverA.entityExists(_ref('$key', EntityType.character, _projA)),
        isTrue,
      );
      expect(
        resolverA.entityExists(_ref('sp_1', EntityType.species, _projA)),
        isTrue,
      );
      expect(
        resolverA.entityExists(_ref('ev_1', EntityType.timelineEvent, _projA)),
        isTrue,
      );
      expect(
        resolverA.entityExists(
          _ref('doc_1', EntityType.manuscriptDocument, _projA),
        ),
        isTrue,
      );
    });

    test('false for deleted (removed from box) entities', () async {
      final key = await charBox.add(
        Character(name: 'Gone', parentProjectId: 1),
      );
      final c = charBox.get(key)!;
      await c.delete();
      expect(
        resolverA.entityExists(_ref('$key', EntityType.character, _projA)),
        isFalse,
      );
    });

    test('false for cross-project lookups and unsupported types', () async {
      await charBox.add(Character(name: 'Local', parentProjectId: 1));
      expect(
        resolverA.entityExists(_ref('999', EntityType.character, _projA)),
        isFalse,
      );
      expect(
        resolverA.entityExists(_ref('1', EntityType.character, _projB)),
        isFalse,
      );
      expect(
        resolverA.entityExists(_ref('1', EntityType.location, _projA)),
        isFalse,
      );
    });
  });

  group('purgeStale (C0-1 deletion integrity)', () {
    /// Simulates a deletion flow: the character is removed from its box, then
    /// [ReferenceNameResolver.purgeStale] is invoked over the shared engine.
    test('removes dangling backlinks after an entity is deleted', () async {
      final charAKey = await charBox.add(
        Character(name: 'Deleted', parentProjectId: 1),
      );
      final charBKey = await charBox.add(
        Character(name: 'Survivor', parentProjectId: 1),
      );
      await speciesBox.add(_speciesNode('sp_1', _projA, 'Dragon'));
      await docBox.put('doc_1', _doc('doc_1', _projA));
      await docBox.put('doc_2', _doc('doc_2', _projA));

      final engine = ReferenceEngine();
      engine.addEntry(
        _entry(
          _ref('doc_1', EntityType.manuscriptDocument, _projA),
          _ref('$charAKey', EntityType.character, _projA),
        ),
      );
      engine.addEntry(
        _entry(
          _ref('doc_2', EntityType.manuscriptDocument, _projA),
          _ref('$charBKey', EntityType.character, _projA),
        ),
      );
      engine.addEntry(
        _entry(
          _ref('doc_1', EntityType.manuscriptDocument, _projA),
          _ref('sp_1', EntityType.species, _projA),
        ),
      );

      // Delete charAKey from the box (simulating CharacterListProvider.deleteCharacter).
      await charBox.get(charAKey)!.delete();

      final removed = resolverA.purgeStale(engine);

      // Only the charA-doc_1 backlink and nothing referencing sp_1/doc_2 etc.
      expect(removed, hasLength(1));
      expect(removed.single.target.id, '$charAKey');
      // The other entries survive.
      expect(engine.index, hasLength(2));
    });

    test('cross-project refs with live entities are NOT purged', () async {
      await docBox.put('doc_1', _doc('doc_1', _projB));
      final survivorKey = await charBox.add(
        Character(name: 'Survivor', parentProjectId: 2),
      );
      final engine = ReferenceEngine();
      engine.addEntry(
        _entry(
          _ref('doc_1', EntityType.manuscriptDocument, _projB),
          _ref('$survivorKey', EntityType.character, _projB),
        ),
      );
      // A different project's live character must survive even after a purge
      // issued from this project's resolver.
      final removed = resolverA.purgeStale(engine);
      expect(removed, isEmpty);
      expect(engine.index, hasLength(1));
    });

    test('recreated entity with same id does NOT inherit stale refs', () async {
      // char_1 exists, is referenced, then deleted (dangling entry).
      final key = await charBox.add(
        Character(name: 'Once', parentProjectId: 1),
      );
      final engine = ReferenceEngine();
      engine.addEntry(
        _entry(
          _ref('doc_1', EntityType.manuscriptDocument, _projA),
          _ref(key.toString(), EntityType.character, _projA),
        ),
      );

      // Delete → purge clears the dangling entry.
      await charBox.get(key)!.delete();
      resolverA.purgeStale(engine);
      expect(engine.index, isEmpty);

      // Recreate with the same key; a fresh index build would re-add the ref,
      // but it must not inherit the OLD dangling entry (nothing stale remains).
      await charBox.put(key, Character(name: 'Reborn', parentProjectId: 1));
      expect(
        resolverA.entityExists(
          _ref(key.toString(), EntityType.character, _projA),
        ),
        isTrue,
      );
      expect(engine.index, isEmpty);
    });

    // Before the fix, this test's expectation was the opposite — it asserted
    // that unsupported types ARE purged as stale. That assertion encoded the
    // bug, so it was replaced rather than left to fail. RED proof that the
    // location entry really did survive-before/purge-after is in the log: the
    // pre-fix run of this same test fails on `expected: isEmpty, actual: has
    // length 1`.
    test('MS-016: a Location ref survives the purge (no canonical source)',
        () async {
      await docBox.put('doc_1', _doc('doc_1', _projA));
      final engine = ReferenceEngine();
      engine.addEntry(
        _entry(
          _ref('doc_1', EntityType.manuscriptDocument, _projA),
          _ref('loc_1', EntityType.location, _projA),
        ),
      );

      final removed = resolverA.purgeStale(engine);

      // Location has no box, so entityExists reports false. Treating that as
      // "deleted" silently discarded every Location/Item/Organization mention
      // on the first purge after any entity deletion.
      expect(removed, isEmpty);
      expect(
        engine.backlinksTo(_ref('loc_1', EntityType.location, _projA)),
        hasLength(1),
        reason: 'a type with no canonical source must never be purged (MS-016)',
      );
    });

    test('MS-016: every sourceless type survives, not just Location', () async {
      await docBox.put('doc_1', _doc('doc_1', _projA));
      final engine = ReferenceEngine();
      const sourceless = [
        EntityType.location,
        EntityType.item,
        EntityType.organization,
        EntityType.faction,
        EntityType.customTrait,
        EntityType.calendarNode,
        EntityType.mapData,
        EntityType.mapLayer,
      ];
      for (final type in sourceless) {
        engine.addEntry(
          _entry(
            _ref('doc_1', EntityType.manuscriptDocument, _projA),
            _ref('x_1', type, _projA),
          ),
        );
      }

      final removed = resolverA.purgeStale(engine);

      expect(removed, isEmpty);
      expect(
        engine.length,
        sourceless.length,
        reason: 'no sourceless type may be purged (MS-016)',
      );
    });

    test('MS-016: a genuinely deleted Character is still purged', () async {
      final charKey = await charBox.add(
        Character(name: 'Doomed', parentProjectId: 1),
      );
      await docBox.put('doc_1', _doc('doc_1', _projA));
      await docBox.put('doc_2', _doc('doc_2', _projA));

      final engine = ReferenceEngine();
      final deletedRef = _ref('$charKey', EntityType.character, _projA);
      final survivorRef = _ref('sp_1', EntityType.species, _projA);
      await speciesBox.add(_speciesNode('sp_1', _projA, 'Dragon'));
      engine.addEntry(
        _entry(_ref('doc_1', EntityType.manuscriptDocument, _projA), deletedRef),
      );
      engine.addEntry(
        _entry(_ref('doc_2', EntityType.manuscriptDocument, _projA), deletedRef),
      );
      engine.addEntry(
        _entry(
          _ref('doc_1', EntityType.manuscriptDocument, _projA),
          survivorRef,
        ),
      );

      await charBox.get(charKey)!.delete();

      final removed = resolverA.purgeStale(engine);

      // MS-016 must not regress real deletion: a type that HAS a canonical
      // source and is gone from it is still removed.
      expect(removed, hasLength(2));
      expect(engine.backlinksTo(deletedRef), isEmpty);
      expect(engine.backlinksTo(survivorRef), hasLength(1));
    });

    test('MS-016: entityIsDefinitelyGone is false without a source, true after '
        'deletion', () async {
      final charKey = await charBox.add(
        Character(name: 'Temporary', parentProjectId: 1),
      );
      final charRef = _ref('$charKey', EntityType.character, _projA);

      // No canonical source yet -> not *definitely* gone.
      expect(
        resolverA.entityIsDefinitelyGone(
          _ref('loc_1', EntityType.location, _projA),
        ),
        isFalse,
      );
      expect(
        resolverA.entityIsDefinitelyGone(
          _ref('item_1', EntityType.item, _projA),
        ),
        isFalse,
      );
      // Live character -> not gone.
      expect(resolverA.entityIsDefinitelyGone(charRef), isFalse);

      await charBox.get(charKey)!.delete();

      // Deleted from a box that exists -> definitely gone.
      expect(resolverA.entityIsDefinitelyGone(charRef), isTrue);
    });
  });
}
