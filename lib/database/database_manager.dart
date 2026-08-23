import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/database/database_metadata.dart';
import 'package:lore_keeper/utils/debug_logger.dart';

import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/section.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/models/magic_system.dart';
import 'package:lore_keeper/models/magic_node.dart';
import 'package:lore_keeper/models/calendar_system.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/models/map_data.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/services/trait_service.dart';

const _kMetaBox = 'lorekeeper_meta';
const _kProjectBox = 'projects';
const _kChapterBox = 'chapters';
const _kSectionBox = 'sections';
const _kManuscriptDocumentBox = 'manuscript_documents';
const _kCharacterBox = 'characters';
const _kLinkBox = 'links';
const _kHistoryBox = 'history';
const _kMagicSystemBox = 'magic_systems';
const _kMagicNodeBox = 'magic_nodes';
const _kCalendarSystemBox = 'calendar_systems';
const _kCalendarNodeBox = 'calendar_nodes';
const _kTimelineEventBox = 'timeline_events';
const _kClassificationNodeBox = 'classification_nodes';
const _kMapDataBox = 'map_data';
const _kSettingsBox = 'settings';
const _kTraitsBox = 'custom_traits';
const _kCustomPanelBox = 'customPanel';
const _kCustomFieldBox = 'customField';

class DatabaseManager {
  DatabaseManager._();

  static final DatabaseManager _instance = DatabaseManager._();
  static DatabaseManager get instance => _instance;

  late Box<DatabaseMetadata> _metaBox;
  DatabaseMetadata? _metadata;
  final Map<String, Box> _boxes = {};

  bool _initialized = false;
  bool get isInitialized => _initialized;

  DatabaseMetadata get metadata => _metadata!;

  // ── Box accessors ─────────────────────────────────────────────────────

  Box<Project> get projects => getBox<Project>(_kProjectBox);
  Box<Chapter> get chapters => getBox<Chapter>(_kChapterBox);
  Box<Section> get sections => getBox<Section>(_kSectionBox);
  Box<ManuscriptDocument> get manuscriptDocuments =>
      getBox<ManuscriptDocument>(_kManuscriptDocumentBox);
  Box<Character> get characters => getBox<Character>(_kCharacterBox);
  Box<Link> get links => getBox<Link>(_kLinkBox);
  Box<HistoryEntry> get historyEntries => getBox<HistoryEntry>(_kHistoryBox);
  Box<MagicSystem> get magicSystems => getBox<MagicSystem>(_kMagicSystemBox);
  Box<MagicNode> get magicNodes => getBox<MagicNode>(_kMagicNodeBox);
  Box<CalendarSystem> get calendarSystems =>
      getBox<CalendarSystem>(_kCalendarSystemBox);
  Box<CalendarNode> get calendarNodes => getBox<CalendarNode>(_kCalendarNodeBox);
  Box<TimelineEvent> get timelineEvents =>
      getBox<TimelineEvent>(_kTimelineEventBox);
  Box<ClassificationNode> get classificationNodes =>
      getBox<ClassificationNode>(_kClassificationNodeBox);
  Box<MapData> get mapData => getBox<MapData>(_kMapDataBox);
  Box get settings => getBox(_kSettingsBox);
  Box get customTraits => getBox(_kTraitsBox);
  Box<String> get customPanel => getBox<String>(_kCustomPanelBox);
  Box<String> get customField => getBox<String>(_kCustomFieldBox);

  Box<T> getBox<T>(String name) => _boxes[name] as Box<T>;

  // ── Initialization ────────────────────────────────────────────────────

  Future<void> initialize({String? path}) async {
    if (_initialized) return;

    LkLog.info('DatabaseManager', 'Initializing database');

    try {
      if (path != null) {
        await Hive.initFlutter(path);
      } else {
        await Hive.initFlutter();
      }
      _registerAdapters();

      await _detectAndInitialize();
      await _openApplicationBoxes();

      _initialized = true;
      LkLog.info('DatabaseManager',
          'Database ready (${_boxes.length} boxes loaded)');
    } catch (e, st) {
      LkLog.error('DatabaseManager', 'Initialization failed', e, st);
      await _reportDiagnostics();
      rethrow;
    }
  }

  /// Detects the database state and initializes accordingly.
  ///
  /// Three cases:
  /// 1. Metadata box exists with data → read version, migrate if needed
  /// 2. No metadata box, but legacy application data exists → V1 database
  /// 3. No metadata, no legacy data → fresh installation
  Future<void> _detectAndInitialize() async {
    final metaExists = await Hive.boxExists(_kMetaBox);

    if (metaExists) {
      _metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);

      if (_metaBox.isNotEmpty) {
        _metadata = _metaBox.get('metadata')!;
        LkLog.info('DatabaseManager',
            'Database state detected: version_${_metadata!.schemaVersion}');
        await _runMigrations();
        return;
      }
    }

    // No metadata — check for legacy V1 data.
    final hasLegacyData = await _hasLegacyData();

    if (hasLegacyData) {
      LkLog.info('DatabaseManager', 'Database state detected: legacy_v1');
      _metadata = DatabaseMetadata(
        schemaVersion: 1,
        databaseId: DatabaseMetadata.fresh().databaseId,
        createdAt: DateTime.now(),
      );
      // Ensure metadata box is open for migration recording.
      _metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
      await _runMigrations();
    } else {
      LkLog.info('DatabaseManager', 'Database state detected: fresh');
      _metadata = DatabaseMetadata.fresh();
      _metaBox = await Hive.openBox<DatabaseMetadata>(_kMetaBox);
      await _metaBox.put('metadata', _metadata!);
      LkLog.info('DatabaseManager',
          'Fresh database created (schema v${_metadata!.schemaVersion})');
    }
  }

  /// Checks whether any legacy Lore Keeper data boxes exist on disk.
  ///
  /// Uses Hive's disk-level [Hive.boxExists] — no boxes are opened.
  /// A legacy V1 database may have data in any subset of these boxes,
  /// so we consider the presence of ANY of them as legacy data.
  static Future<bool> _hasLegacyData() async {
    const legacyBoxNames = [
      _kProjectBox,
      _kCharacterBox,
      _kChapterBox,
      _kSectionBox,
      _kLinkBox,
      _kHistoryBox,
      _kMagicSystemBox,
      _kMagicNodeBox,
      _kCalendarSystemBox,
      _kCalendarNodeBox,
      _kTimelineEventBox,
      _kMapDataBox,
      _kSettingsBox,
      _kTraitsBox,
      _kCustomPanelBox,
      _kCustomFieldBox,
    ];

    for (final name in legacyBoxNames) {
      if (await Hive.boxExists(name)) {
        LkLog.debug('DatabaseManager', 'Legacy box found: $name');
        return true;
      }
    }
    return false;
  }

  // ── Adapter registration ──────────────────────────────────────────────

  void _registerAdapters() {
    void reg<T>(int id, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(id)) {
        Hive.registerAdapter(adapter);
      }
    }

    reg(0, ProjectAdapter());
    reg(2, ChapterAdapter());
    reg(3, SectionAdapter());
    reg(4, CharacterAdapter());
    reg(5, LinkAdapter());
    reg(7, MagicSystemAdapter());
    reg(8, MagicNodeAdapter());
    reg(9, MagicAttributeAdapter());
    reg(10, CharacterIterationSafeAdapter());
    reg(11, HistoryEntryAdapter());
    reg(12, CustomTraitAdapter());
    reg(13, CharacterImageAdapter());
    reg(20, CustomFieldAdapter());
    reg(21, CustomPanelAdapter());
    reg(22, MagicImageAdapter());
    reg(26, CalendarSystemAdapter());
    reg(27, CalendarNodeAdapter());
    reg(28, CalendarAttributeAdapter());
    reg(29, TimelineEventAdapter());
    reg(36, ClassificationNodeAdapter());
    reg(37, ClassificationArticleAdapter());
    reg(30, MapDataAdapter());
    reg(31, MapLayerAdapter());
    reg(32, MapStampAdapter());
    reg(33, MapPathAdapter());
    reg(34, MapPolygonAdapter());
    reg(35, OffsetDataAdapter());
    reg(40, ManuscriptDocumentAdapter());
    reg(50, DatabaseMetadataAdapter());
  }

  // ── Migrations ────────────────────────────────────────────────────────

  Future<void> _runMigrations() async {
    final version = _metadata!.schemaVersion;
    if (version >= currentSchemaVersion) return;

    LkLog.info('DatabaseManager',
        'Migrating schema v$version → v$currentSchemaVersion');

    var v = version;
    while (v < currentSchemaVersion) {
      final next = v + 1;
      LkLog.info('DatabaseManager', 'Running migration v$v → v$next');
      await _migrate(v, next);
      v = next;
    }

    _metadata!.schemaVersion = currentSchemaVersion;
    _metadata!.lastMigrationAt = DateTime.now();
    await _metaBox.put('metadata', _metadata!);
  }

  Future<void> _migrate(int oldVersion, int newVersion) async {
    switch (newVersion) {
      case 2:
        await _migrateV1toV2();
        break;
      case 3:
        await _migrateV2toV3();
        break;
      default:
        throw StateError(
            'No migration defined for schema v$newVersion');
    }
  }

  /// V1 → V2: Introduce DatabaseMetadata box and formal schema versioning.
  /// Existing data is not modified. Metadata is created as a fresh record
  /// pointing at the current schema version so future migrations can
  /// detect and apply incremental upgrades.
  Future<void> _migrateV1toV2() async {
    LkLog.info('DatabaseManager', 'Migration V1→V2: recording metadata, '
        'no data modifications');
    _metadata!.schemaVersion = currentSchemaVersion;
    _metadata!.lastMigrationAt = DateTime.now();
    await _metaBox.put('metadata', _metadata!);
    LkLog.info('DatabaseManager', 'Migration V1→V2 complete');
  }

  /// V2 → V3: Add ManuscriptDocument box and migrate existing Chapter/Section
  /// data to the new hierarchical document structure.
  ///
  /// Creates ManuscriptDocument entries for:
  /// - Root Manuscript document per project
  /// - Sections as Part documents
  /// - Chapters as Chapter documents
  /// - Preserves all content, ordering, and project ownership
  Future<void> _migrateV2toV3() async {
    LkLog.info('DatabaseManager',
        'Migration V2→V3: Creating ManuscriptDocument hierarchy from existing Chapter/Section data');

    const int frontMatterSectionKey = -1;

    final projectBox = _boxes[_kProjectBox] as Box<Project>?;
    final chapterBox = _boxes[_kChapterBox] as Box<Chapter>?;
    final sectionBox = _boxes[_kSectionBox] as Box<Section>?;
    final manuscriptBox = _boxes[_kManuscriptDocumentBox] as Box<ManuscriptDocument>?;

    if (projectBox == null || chapterBox == null || sectionBox == null || manuscriptBox == null) {
      LkLog.warning('DatabaseManager', 'Migration V2→V3: Required boxes not available, skipping');
      return;
    }

    final now = DateTime.now();
    int createdCount = 0;

    for (final project in projectBox.values) {
      // Create root Manuscript document
      final manuscriptId = 'manuscript_${project.key}';
      final manuscriptDoc = ManuscriptDocument()
        ..id = manuscriptId
        ..projectId = project.key as int
        ..title = project.bookTitle ?? project.title
        ..documentType = ManuscriptDocumentType.manuscript
        ..parentId = null
        ..orderIndex = 0
        ..status = ManuscriptDocumentStatus.draft
        ..isExpanded = true
        ..createdAt = project.createdAt
        ..modifiedAt = now;

      await manuscriptBox.put(manuscriptId, manuscriptDoc);
      createdCount++;

      // Get sections for this project
      final sections = sectionBox.values
          .where((s) => s.parentProjectId == project.key)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      // Get chapters for this project
      final chapters = chapterBox.values
          .where((c) => c.parentProjectId == project.key)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      // Map section key -> manuscript document ID for Parts
      final sectionToDocId = <dynamic, String>{};

      // Create Part documents for each section
      for (int i = 0; i < sections.length; i++) {
        final section = sections[i];
        final partId = 'part_${section.key}';
        final partDoc = ManuscriptDocument()
          ..id = partId
          ..projectId = project.key as int
          ..title = section.title
          ..documentType = ManuscriptDocumentType.part
          ..parentId = manuscriptId
          ..orderIndex = i
          ..status = ManuscriptDocumentStatus.draft
          ..isExpanded = section.isExpanded
          ..createdAt = now
          ..modifiedAt = now;

        await manuscriptBox.put(partId, partDoc);
        sectionToDocId[section.key] = partId;
        createdCount++;
      }

      // Create Chapter documents
      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        final chapterId = 'chapter_${chapter.key}';
        String? parentId;

        if (chapter.parentSectionKey == frontMatterSectionKey) {
          // Front matter chapters go directly under manuscript root
          parentId = manuscriptId;
        } else if (sectionToDocId.containsKey(chapter.parentSectionKey)) {
          // Regular chapters under their Part
          parentId = sectionToDocId[chapter.parentSectionKey]!;
        } else {
          // Fallback to manuscript root
          parentId = manuscriptId;
        }

        // Determine document type based on key
        ManuscriptDocumentType docType = ManuscriptDocumentType.chapter;
        if (chapter.key is String && (chapter.key as String).startsWith('front_matter_')) {
          docType = ManuscriptDocumentType.frontMatter;
        }

        final chapterDoc = ManuscriptDocument()
          ..id = chapterId
          ..projectId = project.key as int
          ..title = chapter.title
          ..documentType = docType
          ..parentId = parentId
          ..orderIndex = chapter.orderIndex
          ..richTextJson = chapter.richTextJson
          ..status = ManuscriptDocumentStatus.draft
          ..isExpanded = true
          ..createdAt = now
          ..modifiedAt = now
          ..wordCount = _countWords(chapter.richTextJson)
          ..characterCount = chapter.richTextJson?.length ?? 0;

        await manuscriptBox.put(chapterId, chapterDoc);
        createdCount++;
      }
    }

    LkLog.info('DatabaseManager',
        'Migration V2→V3 complete: created $createdCount ManuscriptDocument entries');
  }

  int _countWords(String? json) {
    if (json == null || json.isEmpty) return 0;
    try {
      final doc = json.contains('ops') ? json : '{"ops": $json}';
      // Simple word count from plain text extraction
      final text = doc.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ');
      return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    } catch (_) {
      return 0;
    }
  }

  // ── Box opening ───────────────────────────────────────────────────────

  Future<void> _openApplicationBoxes() async {
    final boxes = <Future Function()>[
      () => _openBox<Project>(_kProjectBox),
      () => _openBox<Chapter>(_kChapterBox),
      () => _openBox<Section>(_kSectionBox),
      () => _openBox<ManuscriptDocument>(_kManuscriptDocumentBox),
      () => _openBox<Character>(_kCharacterBox),
      () => _openBox<Link>(_kLinkBox),
      () => _openBox<HistoryEntry>(_kHistoryBox),
      () => _openBox<MagicSystem>(_kMagicSystemBox),
      () => _openBox<MagicNode>(_kMagicNodeBox),
      () => _openBox<CalendarSystem>(_kCalendarSystemBox),
      () => _openBox<CalendarNode>(_kCalendarNodeBox),
      () => _openBox<TimelineEvent>(_kTimelineEventBox),
      () => _openBox<ClassificationNode>(_kClassificationNodeBox),
      () => _openBox<MapData>(_kMapDataBox),
      () => _openBox(_kSettingsBox),
      () => _openBox(_kTraitsBox),
      () => _openBox<String>(_kCustomPanelBox),
      () => _openBox<String>(_kCustomFieldBox),
    ];

    for (final open in boxes) {
      await open();
    }
  }

  Future<void> _openBox<T>(String name) async {
    LkLog.debug('DatabaseManager', 'Opening box: $name');
    try {
      _boxes[name] = await Hive.openBox<T>(name);
    } catch (e, st) {
      LkLog.error('DatabaseManager', 'Failed to open box $name', e, st);
      rethrow;
    }
  }

  // ── Diagnostics ───────────────────────────────────────────────────────

  Future<void> _reportDiagnostics() async {
    LkLog.info('DatabaseManager', '─── Diagnostic Report ───');
    LkLog.info('DatabaseManager', 'Schema version: ${_metadata?.schemaVersion ?? "unknown"} '
        '(current: $currentSchemaVersion)');
    LkLog.info('DatabaseManager', 'Database ID: ${_metadata?.databaseId ?? "unknown"}');
    LkLog.info('DatabaseManager', 'Created: ${_metadata?.createdAt ?? "unknown"}');
    LkLog.info('DatabaseManager',
        'Last migration: ${_metadata?.lastMigrationAt ?? "never"}');

    final registered = <int>{};
    for (var i = 0; i < 100; i++) {
      if (Hive.isAdapterRegistered(i)) registered.add(i);
    }
    LkLog.info('DatabaseManager',
        'Registered adapters: ${registered.join(', ')}');

    for (final name in _boxes.keys) {
      final box = _boxes[name];
      LkLog.info('DatabaseManager',
          'Box "$name": ${box?.length ?? 0} entries, isOpen=${box?.isOpen}');
    }
    LkLog.info('DatabaseManager', '─── End Report ───');
  }

  // ── Shutdown ──────────────────────────────────────────────────────────

  Future<void> close() async {
    if (!_initialized) return;
    LkLog.info('DatabaseManager', 'Closing database');

    for (final entry in _boxes.entries) {
      try {
        await entry.value.close();
      } catch (e) {
        LkLog.warning('DatabaseManager', 'Error closing box ${entry.key}: $e');
      }
    }
    await _metaBox.close();
    _boxes.clear();
    _initialized = false;
  }

  // ── Testing support ─────────────────────────────────────────────────

  /// Expose adapter registration for tests that call [Hive.init] directly.
  void registerAdaptersForTesting() => _registerAdapters();

  /// Initialize without [Hive.initFlutter] — for unit tests that
  /// call [Hive.init] with a temp directory.
  Future<void> initializeForTesting() async {
    if (_initialized) return;
    _registerAdapters();
    await _detectAndInitialize();
    await _openApplicationBoxes();
    _initialized = true;
  }
}
