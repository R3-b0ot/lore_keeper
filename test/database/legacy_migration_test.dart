import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_metadata.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/calendar_system.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/models/timeline_event.dart';

/// Legacy V1 box names — must match those used by DatabaseManager._hasLegacyData.
const _kMetaBox = 'lorekeeper_meta';
const _kProjectBox = 'projects';
const _kCalendarSystemBox = 'calendar_systems';
const _kCalendarNodeBox = 'calendar_nodes';
const _kTimelineEventBox = 'timeline_events';

/// Register all adapters needed for legacy V1 data seeding.
/// Guards against double-registration with [Hive.isAdapterRegistered].
void _registerTestAdapters() {
  void reg<T>(int id, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(id)) {
      Hive.registerAdapter(adapter);
    }
  }

  reg(0, ProjectAdapter());
  reg(26, CalendarSystemAdapter());
  reg(27, CalendarNodeAdapter());
  reg(28, CalendarAttributeAdapter());
  reg(29, TimelineEventAdapter());
  reg(50, DatabaseMetadataAdapter());
}

/// Detect legacy data using the same logic as DatabaseManager._hasLegacyData.
Future<bool> _detectLegacyData() async {
  const legacyBoxNames = [
    _kProjectBox,
    _kCalendarSystemBox,
    _kCalendarNodeBox,
    _kTimelineEventBox,
  ];

  for (final name in legacyBoxNames) {
    if (await Hive.boxExists(name)) return true;
  }
  return false;
}

/// Detect database state — mirrors DatabaseManager._detectAndInitialize logic.
Future<String> _detectDatabaseState() async {
  final metaExists = await Hive.boxExists(_kMetaBox);

  if (metaExists) {
    final metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
    if (metaBox.isNotEmpty) {
      final meta = metaBox.get('metadata')!;
      final state = 'version_${meta.schemaVersion}';
      await metaBox.close();
      return state;
    }
    await metaBox.close();
  }

  if (await _detectLegacyData()) return 'legacy_v1';
  return 'fresh';
}

void main() {
  _registerTestAdapters();

  group('Legacy V1 database detection', () {
    late String tempPath;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('lk_legacy_test_');
      tempPath = dir.path;
      Hive.init(tempPath);
    });

    tearDown(() async {
      await Hive.close();
    });

    test(
      'detects legacy_v1 when metadata box missing but data exists',
      () async {
        // Seed legacy V1 data: create boxes and write real domain data.
        final projectBox = await Hive.openBox<Project>(_kProjectBox);
        await projectBox.add(
          Project(
            title: 'The Great Novel',
            createdAt: DateTime(2024, 1, 15),
            description: 'A test project',
            genre: 'Fantasy',
          ),
        );

        final calSystemBox = await Hive.openBox<CalendarSystem>(
          _kCalendarSystemBox,
        );
        final systemKey = await calSystemBox.add(
          CalendarSystem(
            name: 'Middle-earth Calendar',
            projectId: 0,
            rootNodeId: 'root_era',
            isConfigured: true,
          ),
        );

        final calNodeBox = await Hive.openBox<CalendarNode>(_kCalendarNodeBox);
        await calNodeBox.add(
          CalendarNode(
            id: 'root_era',
            systemKey: systemKey,
            parentId: null,
            type: 'era',
            title: 'Third Age',
            iconKey: 'shield',
            colorValue: 0xFF4A90D9,
            content: 'The Age of Middle-earth',
            attributes: [CalendarAttribute(label: 'Start', value: 'Year 1')],
            childrenOrder: ['child_1'],
          ),
        );

        final timelineBox = await Hive.openBox<TimelineEvent>(
          _kTimelineEventBox,
        );
        await timelineBox.add(
          TimelineEvent(
            id: 'evt_1',
            projectId: 0,
            name: 'Fellowship Formed',
            tier: 'major',
            absoluteYear: 3018,
            absoluteDayOfYear: 300,
            iconKey: 'ring',
            colorValue: 0xFFD4AF37,
            lore: 'The Fellowship of the Ring departs Rivendell.',
            calendarSystemKey: systemKey,
            linkedCharacterIds: ['char_1', 'char_2'],
          ),
        );

        // Close all boxes — simulate app shutdown.
        await projectBox.close();
        await calSystemBox.close();
        await calNodeBox.close();
        await timelineBox.close();

        // Verify no metadata box exists.
        expect(await Hive.boxExists(_kMetaBox), isFalse);

        // Detection should find legacy data.
        expect(await _detectLegacyData(), isTrue);
        expect(await _detectDatabaseState(), equals('legacy_v1'));
      },
    );

    test('detects fresh when no boxes exist', () async {
      // No boxes created — clean temp directory.
      expect(await _detectLegacyData(), isFalse);
      expect(await _detectDatabaseState(), equals('fresh'));
    });

    test('V1→V2 migration preserves all seeded data', () async {
      // ── Phase 1: Seed legacy V1 database ──────────────────────────────
      final projectBox = await Hive.openBox<Project>(_kProjectBox);
      final projectIdx = await projectBox.add(
        Project(
          title: 'The Great Novel',
          createdAt: DateTime(2024, 1, 15),
          description: 'A test project',
          genre: 'Fantasy',
        ),
      );

      final calSystemBox = await Hive.openBox<CalendarSystem>(
        _kCalendarSystemBox,
      );
      final systemKey = await calSystemBox.add(
        CalendarSystem(
          name: 'Middle-earth Calendar',
          projectId: 0,
          rootNodeId: 'root_era',
          isConfigured: true,
        ),
      );

      final calNodeBox = await Hive.openBox<CalendarNode>(_kCalendarNodeBox);
      final nodeIdx = await calNodeBox.add(
        CalendarNode(
          id: 'root_era',
          systemKey: systemKey,
          parentId: null,
          type: 'era',
          title: 'Third Age',
          iconKey: 'shield',
          colorValue: 0xFF4A90D9,
          content: 'The Age of Middle-earth',
          attributes: [CalendarAttribute(label: 'Start', value: 'Year 1')],
          childrenOrder: ['child_1'],
        ),
      );

      final timelineBox = await Hive.openBox<TimelineEvent>(_kTimelineEventBox);
      final eventIdx = await timelineBox.add(
        TimelineEvent(
          id: 'evt_1',
          projectId: 0,
          name: 'Fellowship Formed',
          tier: 'major',
          absoluteYear: 3018,
          absoluteDayOfYear: 300,
          iconKey: 'ring',
          colorValue: 0xFFD4AF37,
          lore: 'The Fellowship of the Ring departs Rivendell.',
          calendarSystemKey: systemKey,
          linkedCharacterIds: ['char_1', 'char_2'],
        ),
      );

      // Verify seed data is correct.
      expect(projectBox.length, 1);
      expect(projectBox.getAt(projectIdx)!.title, 'The Great Novel');
      expect(calSystemBox.length, 1);
      expect(calSystemBox.getAt(0)!.name, 'Middle-earth Calendar');
      expect(calNodeBox.length, 1);
      expect(calNodeBox.getAt(nodeIdx)!.title, 'Third Age');
      expect(calNodeBox.getAt(nodeIdx)!.attributes.length, 1);
      expect(timelineBox.length, 1);
      expect(timelineBox.getAt(eventIdx)!.name, 'Fellowship Formed');

      // Close all boxes — simulate app shutdown.
      await projectBox.close();
      await calSystemBox.close();
      await calNodeBox.close();
      await timelineBox.close();

      // ── Phase 2: Simulate DatabaseManager V1→V2 migration ─────────────
      // 1. Detect state.
      final state = await _detectDatabaseState();
      expect(state, equals('legacy_v1'));

      // 2. Create metadata with schemaVersion 1 (simulating legacy detection).
      final metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
      final metadata = DatabaseMetadata(
        schemaVersion: 1,
        databaseId: DatabaseMetadata.fresh().databaseId,
        createdAt: DateTime.now(),
      );
      await metaBox.put('metadata', metadata);

      // 3. Run V1→V2 migration (set version to current).
      metadata.schemaVersion = currentSchemaVersion;
      metadata.lastMigrationAt = DateTime.now();
      await metaBox.put('metadata', metadata);
      await metaBox.close();

      // ── Phase 3: Verify migration result ──────────────────────────────
      final stateAfter = await _detectDatabaseState();
      expect(stateAfter, equals('version_$currentSchemaVersion'));

      // ── Phase 4: Reopen boxes and verify ALL data survived ────────────
      final projectBox2 = await Hive.openBox<Project>(_kProjectBox);
      expect(projectBox2.length, 1);
      final p = projectBox2.getAt(0)!;
      expect(p.title, 'The Great Novel');
      expect(p.description, 'A test project');
      expect(p.genre, 'Fantasy');
      expect(p.createdAt, DateTime(2024, 1, 15));
      await projectBox2.close();

      final calSystemBox2 = await Hive.openBox<CalendarSystem>(
        _kCalendarSystemBox,
      );
      expect(calSystemBox2.length, 1);
      final cs = calSystemBox2.getAt(0)!;
      expect(cs.name, 'Middle-earth Calendar');
      expect(cs.projectId, 0);
      expect(cs.rootNodeId, 'root_era');
      expect(cs.isConfigured, isTrue);
      await calSystemBox2.close();

      final calNodeBox2 = await Hive.openBox<CalendarNode>(_kCalendarNodeBox);
      expect(calNodeBox2.length, 1);
      final cn = calNodeBox2.getAt(0)!;
      expect(cn.id, 'root_era');
      expect(cn.title, 'Third Age');
      expect(cn.type, 'era');
      expect(cn.iconKey, 'shield');
      expect(cn.colorValue, 0xFF4A90D9);
      expect(cn.content, 'The Age of Middle-earth');
      expect(cn.attributes.length, 1);
      expect(cn.attributes[0].label, 'Start');
      expect(cn.attributes[0].value, 'Year 1');
      expect(cn.childrenOrder, ['child_1']);
      await calNodeBox2.close();

      final timelineBox2 = await Hive.openBox<TimelineEvent>(
        _kTimelineEventBox,
      );
      expect(timelineBox2.length, 1);
      final te = timelineBox2.getAt(0)!;
      expect(te.id, 'evt_1');
      expect(te.name, 'Fellowship Formed');
      expect(te.tier, 'major');
      expect(te.absoluteYear, 3018);
      expect(te.absoluteDayOfYear, 300);
      expect(te.iconKey, 'ring');
      expect(te.colorValue, 0xFFD4AF37);
      expect(te.lore, 'The Fellowship of the Ring departs Rivendell.');
      expect(te.calendarSystemKey, systemKey);
      expect(te.linkedCharacterIds, ['char_1', 'char_2']);
      await timelineBox2.close();

      // Verify no boxes were deleted.
      expect(await Hive.boxExists(_kProjectBox), isTrue);
      expect(await Hive.boxExists(_kCalendarSystemBox), isTrue);
      expect(await Hive.boxExists(_kCalendarNodeBox), isTrue);
      expect(await Hive.boxExists(_kTimelineEventBox), isTrue);
      expect(await Hive.boxExists(_kMetaBox), isTrue);
    });
  });

  group('Fresh installation detection', () {
    late String tempPath;

    setUp(() {
      final dir = Directory.systemTemp.createTempSync('lk_fresh_test_');
      tempPath = dir.path;
      Hive.init(tempPath);
    });

    tearDown(() async {
      await Hive.close();
    });

    test('fresh install creates V2 metadata with no legacy data', () async {
      // No legacy boxes exist.
      expect(await _detectLegacyData(), isFalse);

      // Simulate fresh install: create metadata at current schema version.
      final metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
      final meta = DatabaseMetadata.fresh();
      expect(meta.schemaVersion, currentSchemaVersion);
      await metaBox.put('metadata', meta);
      await metaBox.close();

      // Re-verify.
      final state = await _detectDatabaseState();
      expect(state, equals('version_$currentSchemaVersion'));
    });

    test('existing V2 metadata is detected without migration', () async {
      // Simulate existing V2 database with metadata already present.
      final metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
      final meta = DatabaseMetadata.fresh();
      await metaBox.put('metadata', meta);
      await metaBox.close();

      // Detection should report current version.
      final state = await _detectDatabaseState();
      expect(state, equals('version_$currentSchemaVersion'));
    });

    test('fresh install metadata has unique database ID', () async {
      final metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);

      final a = DatabaseMetadata.fresh();
      await metaBox.put('meta_a', a);

      await Future.delayed(const Duration(milliseconds: 20));
      final b = DatabaseMetadata.fresh();
      await metaBox.put('meta_b', b);

      expect(a.databaseId, isNot(equals(b.databaseId)));
      expect(a.schemaVersion, currentSchemaVersion);
      expect(b.schemaVersion, currentSchemaVersion);

      await metaBox.close();
    });
  });

  group('DatabaseMetadata integrity', () {
    test('currentSchemaVersion is at least 2', () {
      expect(currentSchemaVersion, greaterThanOrEqualTo(2));
    });

    test('DatabaseMetadata schemaVersion field is persisted', () async {
      final dir = Directory.systemTemp.createTempSync('lk_meta_integrity_');
      Hive.init(dir.path);

      final metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
      final meta = DatabaseMetadata.fresh();
      await metaBox.put('metadata', meta);

      final restored = metaBox.get('metadata')!;
      expect(restored.schemaVersion, currentSchemaVersion);
      expect(restored.databaseId, meta.databaseId);
      expect(restored.createdAt, meta.createdAt);

      await metaBox.close();
      await Hive.close();
    });
  });
}
