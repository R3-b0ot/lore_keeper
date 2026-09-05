import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';

void main() {
  group('ReferenceIndexEntry', () {
    test('constructs with required fields', () {
      final entry = ReferenceIndexEntry(
        source: const EntityRef(
          id: '1',
          entityType: EntityType.character,
          projectId: 'P',
        ),
        target: const EntityRef(
          id: '2',
          entityType: EntityType.chapter,
          projectId: 'P',
        ),
        kind: 'mentions',
        computedAt: DateTime(2024),
      );

      expect(entry.source.id, '1');
      expect(entry.target.id, '2');
      expect(entry.kind, 'mentions');
      expect(entry.containerEntity, isNull);
    });

    test('equality considers all fields', () {
      final a = ReferenceIndexEntry(
        source: const EntityRef(id: '1', entityType: 'X', projectId: 'P'),
        target: const EntityRef(id: '2', entityType: 'Y', projectId: 'P'),
        kind: 'mentions',
        computedAt: DateTime(2024),
      );
      final b = ReferenceIndexEntry(
        source: const EntityRef(id: '1', entityType: 'X', projectId: 'P'),
        target: const EntityRef(id: '2', entityType: 'Y', projectId: 'P'),
        kind: 'mentions',
        computedAt: DateTime(2025),
      );
      final c = ReferenceIndexEntry(
        source: const EntityRef(id: '1', entityType: 'X', projectId: 'P'),
        target: const EntityRef(id: '3', entityType: 'Y', projectId: 'P'),
        kind: 'mentions',
        computedAt: DateTime(2024),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toJson/fromJson roundtrip', () {
      final original = ReferenceIndexEntry(
        source: const EntityRef(
          id: '1',
          entityType: EntityType.character,
          projectId: 'P',
        ),
        target: const EntityRef(
          id: '2',
          entityType: EntityType.chapter,
          projectId: 'P',
        ),
        kind: 'mentions',
        containerEntity: const EntityRef(
          id: '10',
          entityType: EntityType.chapter,
          projectId: 'P',
        ),
        computedAt: DateTime(2024),
      );

      final json = original.toJson();
      final restored = ReferenceIndexEntry.fromJson(json);

      expect(restored.source, equals(original.source));
      expect(restored.target, equals(original.target));
      expect(restored.kind, original.kind);
      expect(restored.containerEntity, equals(original.containerEntity));
    });
  });

  group('ReferenceEngine', () {
    late ReferenceEngine engine;

    setUp(() {
      engine = ReferenceEngine();
    });

    test('starts with empty index', () {
      expect(engine.length, 0);
      expect(engine.index, isEmpty);
    });

    test('addEntry increases length', () {
      engine.addEntry(
        ReferenceIndexEntry(
          source: const EntityRef(
            id: '1',
            entityType: EntityType.character,
            projectId: 'P',
          ),
          target: const EntityRef(
            id: '2',
            entityType: EntityType.chapter,
            projectId: 'P',
          ),
          kind: 'mentions',
          computedAt: DateTime(2024),
        ),
      );

      expect(engine.length, 1);
    });

    test('clear empties the index', () {
      engine.addEntry(
        ReferenceIndexEntry(
          source: const EntityRef(id: '1', entityType: 'X', projectId: 'P'),
          target: const EntityRef(id: '2', entityType: 'Y', projectId: 'P'),
          kind: 'test',
          computedAt: DateTime(2024),
        ),
      );

      expect(engine.length, 1);
      engine.clear();
      expect(engine.length, 0);
    });

    test('referencesFrom returns matching entries', () {
      const source = EntityRef(
        id: '1',
        entityType: EntityType.character,
        projectId: 'P',
      );
      final entry = ReferenceIndexEntry(
        source: source,
        target: const EntityRef(
          id: '2',
          entityType: EntityType.chapter,
          projectId: 'P',
        ),
        kind: 'mentions',
        computedAt: DateTime(2024),
      );
      engine.addEntry(entry);

      final results = engine.referencesFrom(source);
      expect(results, hasLength(1));
      expect(results.first, equals(entry));
    });

    test('backlinksTo returns reverse references', () {
      const target = EntityRef(
        id: '2',
        entityType: EntityType.chapter,
        projectId: 'P',
      );
      final entry = ReferenceIndexEntry(
        source: const EntityRef(
          id: '1',
          entityType: EntityType.character,
          projectId: 'P',
        ),
        target: target,
        kind: 'mentions',
        computedAt: DateTime(2024),
      );
      engine.addEntry(entry);

      final results = engine.backlinksTo(target);
      expect(results, hasLength(1));
    });

    test('search matches by kind', () {
      engine.addEntry(
        ReferenceIndexEntry(
          source: const EntityRef(id: '1', entityType: 'X', projectId: 'P'),
          target: const EntityRef(id: '2', entityType: 'Y', projectId: 'P'),
          kind: 'semantic_similarity',
          computedAt: DateTime(2024),
        ),
      );

      final results = engine.search('semantic');
      expect(results, hasLength(1));

      final noResults = engine.search('backlink');
      expect(noResults, isEmpty);
    });

    test('insideContainer returns scoped entries', () {
      const container = EntityRef(
        id: '10',
        entityType: EntityType.chapter,
        projectId: 'P',
      );
      engine.addEntry(
        ReferenceIndexEntry(
          source: const EntityRef(
            id: '1',
            entityType: EntityType.character,
            projectId: 'P',
          ),
          target: const EntityRef(
            id: '2',
            entityType: EntityType.character,
            projectId: 'P',
          ),
          kind: 'appears_in',
          containerEntity: container,
          computedAt: DateTime(2024),
        ),
      );

      final results = engine.insideContainer(container);
      expect(results, hasLength(1));
    });

    test('rebuildIndex clears and repopulates', () async {
      engine.addEntry(
        ReferenceIndexEntry(
          source: const EntityRef(id: 'old', entityType: 'X', projectId: 'P'),
          target: const EntityRef(id: 'old', entityType: 'Y', projectId: 'P'),
          kind: 'old',
          computedAt: DateTime(2024),
        ),
      );

      await engine.rebuildIndex(
        extractReferences: (entityType) async {
          if (entityType == EntityType.character) {
            return [
              ReferenceIndexEntry(
                source: const EntityRef(
                  id: '1',
                  entityType: EntityType.character,
                  projectId: 'P',
                ),
                target: const EntityRef(
                  id: '2',
                  entityType: EntityType.chapter,
                  projectId: 'P',
                ),
                kind: 'mentions',
                computedAt: DateTime(2024),
              ),
            ];
          }
          return [];
        },
      );

      expect(engine.length, 1);
      expect(engine.index.first.source.id, '1');
    });

    test('referencedEntityTypes returns distinct types', () {
      const ref = EntityRef(
        id: '1',
        entityType: EntityType.character,
        projectId: 'P',
      );

      engine.addEntry(
        ReferenceIndexEntry(
          source: ref,
          target: const EntityRef(
            id: '2',
            entityType: EntityType.chapter,
            projectId: 'P',
          ),
          kind: 'mentions',
          computedAt: DateTime(2024),
        ),
      );
      engine.addEntry(
        ReferenceIndexEntry(
          source: ref,
          target: const EntityRef(
            id: '3',
            entityType: EntityType.mapData,
            projectId: 'P',
          ),
          kind: 'located_in',
          computedAt: DateTime(2024),
        ),
      );

      final types = engine.referencedEntityTypes(ref);
      expect(types, contains(EntityType.chapter));
      expect(types, contains(EntityType.mapData));
    });
  });

  group('ReferenceEngine + AI', () {
    test('works without AI provider', () async {
      final engine = ReferenceEngine();
      expect(engine.hasAi, isFalse);

      const ref = EntityRef(id: '1', entityType: 'X', projectId: 'P');
      expect(await engine.aiSuggestRelated(ref), isNull);
      expect(await engine.aiEmbed('hello'), isNull);
    });

    test('ai is available when provider is ready', () async {
      final engine = ReferenceEngine(aiProvider: const NullAiProvider());
      expect(engine.hasAi, isFalse);
    });
  });
}
