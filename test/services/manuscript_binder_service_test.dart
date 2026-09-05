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
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';

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
}
