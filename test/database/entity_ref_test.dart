import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/database/entity_ref.dart';

void main() {
  group('EntityRef', () {
    test('constructs with required fields', () {
      const ref = EntityRef(
        id: '42',
        entityType: EntityType.character,
        projectId: '1',
      );

      expect(ref.id, '42');
      expect(ref.entityType, EntityType.character);
      expect(ref.projectId, '1');
    });

    test('fromKey creates ref from dynamic Hive key', () {
      final ref = EntityRef.fromKey(
        key: 42,
        entityType: EntityType.chapter,
        projectId: '1',
      );

      expect(ref.id, '42');
      expect(ref.asKey, 42);
    });

    test('fromKey with string key', () {
      final ref = EntityRef.fromKey(
        key: 'uuid-123',
        entityType: EntityType.timelineEvent,
        projectId: '1',
      );

      expect(ref.id, 'uuid-123');
      expect(ref.asKey, 'uuid-123');
    });

    test('equality ignores createdAt and other non-identity fields', () {
      const a = EntityRef(id: '1', entityType: 'X', projectId: 'P');
      const b = EntityRef(id: '1', entityType: 'X', projectId: 'P');
      const c = EntityRef(id: '2', entityType: 'X', projectId: 'P');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality considers all three fields', () {
      const a = EntityRef(id: '1', entityType: 'X', projectId: 'P1');
      const b = EntityRef(id: '1', entityType: 'X', projectId: 'P2');

      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent', () {
      const a = EntityRef(id: '1', entityType: 'X', projectId: 'P');
      const b = EntityRef(id: '1', entityType: 'X', projectId: 'P');

      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString is readable', () {
      const ref = EntityRef(
        id: '42',
        entityType: EntityType.character,
        projectId: '1',
      );

      expect(ref.toString(), contains('Character'));
      expect(ref.toString(), contains('42'));
    });

    test('toJson/fromJson roundtrip', () {
      const original = EntityRef(
        id: '42',
        entityType: EntityType.character,
        projectId: '1',
      );

      final json = original.toJson();
      final restored = EntityRef.fromJson(json);

      expect(restored, equals(original));
    });

    test('toJson produces expected structure', () {
      const ref = EntityRef(id: '42', entityType: 'Character', projectId: '1');

      final json = ref.toJson();
      expect(json, {'id': '42', 'entityType': 'Character', 'projectId': '1'});
    });
  });

  group('EntityType', () {
    test('all list contains expected types', () {
      expect(EntityType.all, contains(EntityType.project));
      expect(EntityType.all, contains(EntityType.chapter));
      expect(EntityType.all, contains(EntityType.character));
      expect(EntityType.all, contains(EntityType.calendarSystem));
      expect(EntityType.all, contains(EntityType.timelineEvent));
      expect(EntityType.all, contains(EntityType.mapData));
    });

    test('all list has no duplicates', () {
      expect(EntityType.all.length, equals(EntityType.all.toSet().length));
    });
  });
}
