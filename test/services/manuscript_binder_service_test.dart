/// Unit tests for the `purpose` scene-metadata field.
///
/// Verifies the [ManuscriptDocument] model serializes the purpose field and
/// that [ManuscriptBinderService] persists/clears it. Purpose is listed as
/// a scene-metadata Inspector field in the spec Definition of Done (§12, §33).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/services/manuscript_binder_service.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/utils/manuscript_text_stats.dart';

void main() {
  late Directory dir;
  late Box<ManuscriptDocument> docBox;
  late Box<Project> projectBox;
  late ManuscriptBinderService service;
  late Project project;
  late ReferenceEngine referenceEngine;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_purpose_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(ManuscriptDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectAdapter());
    }
    docBox = await Hive.openBox<ManuscriptDocument>('manuscript_documents');
    projectBox = await Hive.openBox<Project>('projects');

    project = Project(title: 'Test Book', createdAt: DateTime.now());
    final projectKey = await projectBox.add(project);
    project = projectBox.get(projectKey)!;

    referenceEngine = ReferenceEngine();
    service = ManuscriptBinderService(
      projectId: project.key!,
      documentBox: docBox,
      projectBox: projectBox,
      referenceEngine: referenceEngine,
    );
    await service.createManuscriptRoot(project);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('toJson/fromJson round-trips the purpose field', () {
    final doc = ManuscriptDocument()
      ..id = 'x'
      ..projectId = 1
      ..title = 'Scene'
      ..purpose = 'Foreshadow the betrayal';

    final restored = ManuscriptDocument.fromJson(doc.toJson());
    expect(restored.purpose, 'Foreshadow the betrayal');
  });

  test('updatePurpose persists the value and stamps modifiedAt', () async {
    final sceneDoc = await service.createDocument(
      title: 'Scene One',
      type: ManuscriptDocumentType.scene,
      parentId: 'manuscript_${project.key!}',
      orderIndex: 0,
    );

    await service.updatePurpose(sceneDoc.id, 'Introduce the antagonist');

    final reloaded = docBox.get(sceneDoc.id)!;
    expect(reloaded.purpose, 'Introduce the antagonist');
    expect(reloaded.modifiedAt, isNotNull);
  });

  test('updatePurpose clears blank text to null', () async {
    final sceneDoc = await service.createDocument(
      title: 'Scene Two',
      type: ManuscriptDocumentType.scene,
      parentId: 'manuscript_${project.key!}',
      orderIndex: 0,
    );

    await service.updatePurpose(sceneDoc.id, 'Raise the stakes');
    await service.updatePurpose(sceneDoc.id, '   ');

    expect(docBox.get(sceneDoc.id)!.purpose, isNull);
  });

  test(
    'timelineEventId is assigned and cleared via updateTimelineEvent',
    () async {
      final sceneDoc = await service.createDocument(
        title: 'Scene Three',
        type: ManuscriptDocumentType.scene,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
      );

      await service.updateTimelineEvent(sceneDoc.id, 'evt_coronation');
      expect(docBox.get(sceneDoc.id)!.timelineEventId, 'evt_coronation');

      await service.updateTimelineEvent(sceneDoc.id, null);
      expect(docBox.get(sceneDoc.id)!.timelineEventId, isNull);
    },
  );

  test('timelineEventId survives a JSON round-trip', () {
    final doc = ManuscriptDocument()
      ..id = 'x'
      ..projectId = 1
      ..title = 'Scene'
      ..timelineEventId = 'evt_battle';

    final restored = ManuscriptDocument.fromJson(doc.toJson());
    expect(restored.timelineEventId, 'evt_battle');
  });

  test('updateCalendarDate assigns and clears the scene date', () async {
    final sceneDoc = await service.createDocument(
      title: 'Scene Four',
      type: ManuscriptDocumentType.scene,
      parentId: 'manuscript_${project.key!}',
      orderIndex: 0,
    );

    await service.updateCalendarDate(
      sceneDoc.id,
      systemKey: 7,
      year: 1123,
      dayOfYear: 45,
    );
    var reloaded = docBox.get(sceneDoc.id)!;
    expect(reloaded.hasCalendarDate, isTrue);
    expect(reloaded.calendarDateSystemKey, 7);
    expect(reloaded.calendarDateYear, 1123);
    expect(reloaded.calendarDateDayOfYear, 45);

    await service.updateCalendarDate(
      sceneDoc.id,
      systemKey: 0,
      year: 0,
      dayOfYear: 0,
    );
    reloaded = docBox.get(sceneDoc.id)!;
    expect(reloaded.hasCalendarDate, isFalse);
  });

  test('calendar date survives a JSON round-trip', () {
    final doc = ManuscriptDocument()
      ..id = 'x'
      ..projectId = 1
      ..title = 'Scene'
      ..calendarDateSystemKey = 3
      ..calendarDateYear = 500
      ..calendarDateDayOfYear = 120;

    final restored = ManuscriptDocument.fromJson(doc.toJson());
    expect(restored.hasCalendarDate, isTrue);
    expect(restored.calendarDateSystemKey, 3);
    expect(restored.calendarDateYear, 500);
    expect(restored.calendarDateDayOfYear, 120);
  });

  // ── MS-009: canonical word count through updateContent ──────────────────

  group('word count is canonical (MS-009)', () {
    test('updateContent stores wordCount == 2 for "Hello world\\n"', () async {
      final doc = await service.createDocument(
        title: 'Scene',
        type: ManuscriptDocumentType.scene,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
      );

      await service.updateContent(
        doc.id,
        '{"ops":[{"insert":"Hello world\\n"}]}',
      );

      final reloaded = docBox.get(doc.id)!;
      // The stored count must match ManuscriptTextStats.wordCount exactly.
      expect(reloaded.wordCount, 2);
      expect(
        reloaded.wordCount,
        ManuscriptTextStats.wordCount('Hello world\n'),
      );
      // MS-010: characterCount is plain-text length with the single
      // structural trailing "\n" excluded -> 11 (not 12, not the JSON's 36).
      expect(reloaded.characterCount, 11);
      expect(
        reloaded.characterCount,
        ManuscriptTextStats.characterCount('Hello world\n'),
      );
    });

    test('updateContent stores 0 words for an empty document', () async {
      final doc = await service.createDocument(
        title: 'Empty',
        type: ManuscriptDocumentType.scene,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
      );

      await service.updateContent(doc.id, '{"ops":[{"insert":"\\n"}]}');

      expect(docBox.get(doc.id)!.wordCount, 0);
      expect(docBox.get(doc.id)!.characterCount, 0);
    });

    test('createDocument with content counts the same words', () async {
      final doc = await service.createDocument(
        title: 'Seeded',
        type: ManuscriptDocumentType.scene,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
        richTextJson: '{"ops":[{"insert":"Hello world\\n"}]}',
      );

      expect(doc.wordCount, 2);
      // MS-010: 11 = plain-text length minus the structural trailing "\n".
      expect(doc.characterCount, 11);
    });

    test('createDocument with no content counts 0 words', () async {
      final doc = await service.createDocument(
        title: 'Blank',
        type: ManuscriptDocumentType.scene,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
      );

      // Previously the empty document reported 25 "characters" — the length
      // of the emptyRichTextJson envelope itself.
      expect(doc.wordCount, 0);
      expect(doc.characterCount, 0);
    });
  });

  group('Cycle 4b — structural changes still purge correctly', () {
    // Non-regression guard for the incremental re-index. A scoped rebuild only
    // helps the "this document's body changed" case; delete/move/rename must
    // still leave a correct index, and those paths never go through the
    // autosave's scoped call.

    EntityRef docRef(String id, int projectId) => EntityRef(
      id: id,
      entityType: EntityType.manuscriptDocument,
      projectId: '$projectId',
    );

    EntityRef locRef(String id, int projectId) => EntityRef(
      id: id,
      entityType: EntityType.location,
      projectId: '$projectId',
    );

    /// An outbound entry: [sourceId] mentions a Location called [targetId].
    ReferenceIndexEntry mention(
      String sourceId,
      String targetId,
      int projectId,
    ) => ReferenceIndexEntry(
      source: docRef(sourceId, projectId),
      target: locRef(targetId, projectId),
      kind: 'mentions',
      containerEntity: docRef(sourceId, projectId),
      computedAt: DateTime(2026),
    );

    /// An inbound entry: [sourceId] mentions the *document* [targetId].
    ///
    /// Separate from [mention] because the target must be typed
    /// `manuscriptDocument` — a Location ref carrying a document's id would
    /// not be matched by `removeTarget(docRef(...))`, and the test would fail
    /// for a reason unrelated to the behaviour under test.
    ReferenceIndexEntry mentionDocument(
      String sourceId,
      String targetId,
      int projectId,
    ) => ReferenceIndexEntry(
      source: docRef(sourceId, projectId),
      target: docRef(targetId, projectId),
      kind: 'mentions',
      containerEntity: docRef(sourceId, projectId),
      computedAt: DateTime(2026),
    );

    test('deleting a document removes its outbound and inbound entries',
        () async {
      final keeper = await service.createDocument(
        title: 'Keeper',
        type: ManuscriptDocumentType.chapter,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
      );
      final doomed = await service.createDocument(
        title: 'Doomed',
        type: ManuscriptDocumentType.chapter,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 1,
      );
      final pid = project.key!;

      referenceEngine.addEntry(mention(doomed.id, 'loc_a', pid));
      referenceEngine.addEntry(mention(keeper.id, 'loc_b', pid));
      // Inbound backlinks: documents pointing AT the doomed one, and the
      // doomed one pointing at the keeper.
      referenceEngine.addEntry(mentionDocument(keeper.id, doomed.id, pid));
      referenceEngine.addEntry(mentionDocument(doomed.id, keeper.id, pid));
      expect(referenceEngine.length, 4);

      await service.deleteDocument(doomed.id);

      // No entry may still name the deleted document as source or target.
      expect(
        referenceEngine.index.where(
          (e) => e.source.id == doomed.id || e.target.id == doomed.id,
        ),
        isEmpty,
        reason: 'a deleted document must leave no stale entries (Cycle 4b)',
      );
      // The surviving document's own outbound ref is untouched.
      expect(
        referenceEngine.referencesFrom(docRef(keeper.id, pid)).map(
          (e) => e.target.id,
        ),
        contains('loc_b'),
      );
    });

    test('deleting a document is correct even with no index entries at all',
        () async {
      final doc = await service.createDocument(
        title: 'Empty',
        type: ManuscriptDocumentType.chapter,
        parentId: 'manuscript_${project.key!}',
        orderIndex: 0,
      );
      await service.deleteDocument(doc.id);
      expect(docBox.get(doc.id), isNull);
    });
  });
}
