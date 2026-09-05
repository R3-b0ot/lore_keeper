/// Unit tests for [ManuscriptCollectionsService].
///
/// Covers custom-collection persistence (survives restart, project-scoped),
/// custom-collection filtering, and entity-collection resolution through the
/// ReferenceEngine (no duplicate relationship index).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';
import 'package:lore_keeper/models/manuscript_collection.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/services/manuscript_collections_service.dart';

void main() {
  late Directory dir;
  late Box<ManuscriptCollection> collectionBox;
  late Box<ManuscriptDocument> documentBox;
  late ReferenceEngine engine;
  late ManuscriptCollectionsService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_collections_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(ManuscriptDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(ManuscriptCollectionAdapter());
    }
    collectionBox = await Hive.openBox<ManuscriptCollection>(
      'manuscript_collections',
    );
    documentBox = await Hive.openBox<ManuscriptDocument>(
      'manuscript_documents',
    );
    engine = ReferenceEngine();
    service = ManuscriptCollectionsService(
      projectId: 1,
      collectionBox: collectionBox,
      documentBox: documentBox,
      referenceEngine: engine,
    );
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  ManuscriptDocument doc({
    required String id,
    int projectId = 1,
    ManuscriptDocumentType? type,
    ManuscriptDocumentStatus? status,
  }) {
    final d = ManuscriptDocument()
      ..id = id
      ..projectId = projectId
      ..title = id
      ..documentType = type ?? ManuscriptDocumentType.chapter
      ..status = status ?? ManuscriptDocumentStatus.draft;
    return d;
  }

  group('custom collections', () {
    test('persist and are scoped to a project', () async {
      await service.createCollection(name: 'Aria Scenes');
      await service.createCollection(name: 'War Chapters');

      final project1 = service.getAllCollections();
      expect(project1, hasLength(2));

      final otherService = ManuscriptCollectionsService(
        projectId: 2,
        collectionBox: collectionBox,
        documentBox: documentBox,
        referenceEngine: engine,
      );
      expect(otherService.getAllCollections(), isEmpty);
    });

    test('filter documents by type and status', () async {
      await documentBox.putAll({
        'scene_goals': doc(
          id: 'scene_goals',
          type: ManuscriptDocumentType.scene,
          status: ManuscriptDocumentStatus.complete,
        ),
        'scene_draft': doc(
          id: 'scene_draft',
          type: ManuscriptDocumentType.scene,
          status: ManuscriptDocumentStatus.draft,
        ),
        'chapter_draft': doc(
          id: 'chapter_draft',
          type: ManuscriptDocumentType.chapter,
          status: ManuscriptDocumentStatus.draft,
        ),
      });
      final collection = await service.createCollection(
        name: 'Complete Scenes',
        documentType: ManuscriptDocumentType.scene,
        status: ManuscriptDocumentStatus.complete,
      );

      final matched = service.documentsForCollection(collection);
      expect(matched.map((d) => d.id), ['scene_goals']);
    });

    test('rename and delete', () async {
      final collection = await service.createCollection(name: 'Old Name');
      await service.renameCollection(collection.id, 'New Name');
      expect(service.getAllCollections().single.name, 'New Name');

      await service.deleteCollection(collection.id);
      expect(service.getAllCollections(), isEmpty);
    });
  });

  group('entity collections via ReferenceEngine', () {
    test(
      'resolves documents that reference an entity through backlinks',
      () async {
        await documentBox.putAll({
          'ch1': doc(id: 'ch1'),
          'ch2': doc(id: 'ch2'),
        });

        final entityRef = EntityRef.fromKey(
          key: 'char_42',
          entityType: EntityType.character,
          projectId: '1',
        );
        engine.addEntry(
          ReferenceIndexEntry(
            source: EntityRef.fromKey(
              key: 'ch1',
              entityType: EntityType.manuscriptDocument,
              projectId: '1',
            ),
            target: entityRef,
            kind: 'mentions',
            containerEntity: EntityRef.fromKey(
              key: 'ch1',
              entityType: EntityType.manuscriptDocument,
              projectId: '1',
            ),
            computedAt: DateTime.now(),
          ),
        );

        final matched = service.documentsForEntity(entityRef);
        expect(matched.map((d) => d.id), ['ch1']);
      },
    );
  });
}
