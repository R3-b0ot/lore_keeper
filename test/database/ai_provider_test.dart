import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/database/ai/ai_metadata.dart';
import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/entity_ref.dart';

void main() {
  group('AiMetadataEntry', () {
    test('constructs with required fields', () {
      final entry = AiMetadataEntry(
        entityId: '42',
        entityType: EntityType.character,
        kind: 'suggested_link',
        modelId: 'nomic-embed',
        modelVersion: '1.0.0',
        generatedAt: DateTime(2024),
        payload: {'targetId': '99'},
      );

      expect(entry.entityId, '42');
      expect(entry.entityType, EntityType.character);
      expect(entry.kind, 'suggested_link');
      expect(entry.confidence, isNull);
    });

    test('isStale returns true when model changed', () {
      final entry = AiMetadataEntry(
        entityId: '42',
        entityType: EntityType.character,
        kind: 'embedding',
        modelId: 'model-v1',
        modelVersion: '1.0.0',
        generatedAt: DateTime(2024),
        payload: {},
      );

      expect(entry.isStale('model-v2', '1.0.0'), isTrue);
      expect(entry.isStale('model-v1', '2.0.0'), isTrue);
      expect(entry.isStale('model-v1', '1.0.0'), isFalse);
    });

    test('toJson/fromJson roundtrip', () {
      final original = AiMetadataEntry(
        entityId: '42',
        entityType: EntityType.character,
        kind: 'embedding',
        modelId: 'nomic',
        modelVersion: '1.0',
        generatedAt: DateTime(2024, 6, 15, 12, 30),
        confidence: 0.85,
        payload: {'vector': [0.1, 0.2, 0.3]},
      );

      final json = original.toJson();
      final restored = AiMetadataEntry.fromJson(json);

      expect(restored.entityId, original.entityId);
      expect(restored.entityType, original.entityType);
      expect(restored.kind, original.kind);
      expect(restored.modelId, original.modelId);
      expect(restored.modelVersion, original.modelVersion);
      expect(restored.confidence, original.confidence);
      expect(restored.payload, original.payload);
    });

    test('confidence is preserved through serialization', () {
      final entry = AiMetadataEntry(
        entityId: '1',
        entityType: 'X',
        kind: 'test',
        modelId: 'm',
        modelVersion: '1',
        generatedAt: DateTime(2024),
        confidence: 0.99,
        payload: {},
      );

      final restored = AiMetadataEntry.fromJson(entry.toJson());
      expect(restored.confidence, 0.99);
    });
  });

  group('NullAiProvider', () {
    late NullAiProvider provider;

    setUp(() {
      provider = const NullAiProvider();
    });

    test('is never ready', () {
      expect(provider.isReady, isFalse);
    });

    test('load always returns false', () async {
      expect(await provider.load(), isFalse);
    });

    test('embed returns null', () async {
      expect(await provider.embed('hello'), isNull);
    });

    test('suggestRelated returns null', () async {
      const ref = EntityRef(id: '1', entityType: 'X', projectId: 'P');
      expect(await provider.suggestRelated(ref), isNull);
    });

    test('unload does not throw', () async {
      await provider.unload();
    });

    test('name and modelId are empty', () {
      expect(provider.name, 'null');
      expect(provider.modelId, '');
      expect(provider.modelVersion, '');
    });
  });
}
