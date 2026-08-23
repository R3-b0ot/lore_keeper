import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/database/database_metadata.dart';

void main() {
  group('DatabaseMetadata', () {
    test('fresh() creates metadata with current schema version', () {
      final meta = DatabaseMetadata.fresh();

      expect(meta.schemaVersion, currentSchemaVersion);
      expect(meta.databaseId, startsWith('db_'));
      expect(meta.createdAt, isA<DateTime>());
      expect(meta.lastMigrationAt, isNull);
      expect(meta.referenceIndexVersion, 0);
      expect(meta.aiModelId, isNull);
      expect(meta.aiModelVersion, isNull);
    });

    test('fresh() generates unique database IDs', () async {
      final a = DatabaseMetadata.fresh();
      // Ensure different timestamp for uniqueness (IDs use millis)
      await Future.delayed(const Duration(milliseconds: 20));
      final b = DatabaseMetadata.fresh();

      expect(a.databaseId, isNot(equals(b.databaseId)));
    });

    test('equality is based on schemaVersion and databaseId only', () {
      final a = DatabaseMetadata(
        schemaVersion: 2,
        databaseId: 'db_test',
        createdAt: DateTime(2024),
      );
      final b = DatabaseMetadata(
        schemaVersion: 2,
        databaseId: 'db_test',
        createdAt: DateTime(2025),
      );
      final c = DatabaseMetadata(
        schemaVersion: 3,
        databaseId: 'db_test',
        createdAt: DateTime(2024),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = DatabaseMetadata(
        schemaVersion: 2,
        databaseId: 'db_test',
        createdAt: DateTime(2024),
      );
      final b = DatabaseMetadata(
        schemaVersion: 2,
        databaseId: 'db_test',
        createdAt: DateTime(2025),
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('all fields are assignable', () {
      final meta = DatabaseMetadata(
        schemaVersion: 1,
        databaseId: 'db_test',
        createdAt: DateTime(2024),
        lastMigrationAt: DateTime(2024, 6),
        referenceIndexVersion: 3,
        aiModelId: 'nomic-embed',
        aiModelVersion: '1.0.0',
      );

      expect(meta.schemaVersion, 1);
      expect(meta.databaseId, 'db_test');
      expect(meta.lastMigrationAt, DateTime(2024, 6));
      expect(meta.referenceIndexVersion, 3);
      expect(meta.aiModelId, 'nomic-embed');
      expect(meta.aiModelVersion, '1.0.0');
    });
  });

  group('currentSchemaVersion', () {
    test('is at least 2 (V1→V2 migration introduced)', () {
      expect(currentSchemaVersion, greaterThanOrEqualTo(2));
    });
  });
}
