/// MS-018 — `duplicateDocument` (Cycle 7).
///
/// Before this cycle a "Duplicate" action existed, but only as two private
/// widget methods (`manuscript_binder.dart:_duplicateDocument` and
/// `manuscript_corkboard.dart:_duplicateCard`) that each re-listed a dozen
/// fields by hand. Neither was reachable from the service, neither was
/// testable without a widget, and the two lists had already drifted.
///
/// Decision under test: **a duplicate copies the whole subtree.** A chapter's
/// scenes are part of what "this chapter" means to a writer - duplicating the
/// chapter and leaving it empty would produce a document that looks copied but
/// has lost its contents, which is the worse failure. Copying is also
/// self-consistent: a fresh id maps to fresh child ids, and nothing in the
/// reference index points at the originals, so the copy is a clean subtree
/// rather than a set of documents that half-reference deleted ones.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/services/manuscript_binder_service.dart';

void main() {
  late Directory dir;
  late Box<ManuscriptDocument> docBox;
  late Box<Project> projectBox;
  late ManuscriptBinderService service;
  late Project project;
  late ManuscriptDocument root;
  late ManuscriptDocument part;
  late ManuscriptDocument chapter;
  late ManuscriptDocument scene;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_duplicate_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(ManuscriptDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectAdapter());
    }
    docBox = await Hive.openBox<ManuscriptDocument>('manuscript_documents');
    projectBox = await Hive.openBox<Project>('projects');

    project = Project(title: 'Duplicate Test', createdAt: DateTime.now());
    final key = await projectBox.add(project);
    project = projectBox.get(key)!;

    service = ManuscriptBinderService(
      projectId: project.key!,
      documentBox: docBox,
      projectBox: projectBox,
      referenceEngine: ReferenceEngine(),
    );
    root = await service.createManuscriptRoot(project);
    part = await service.createDocument(
      title: 'Part One',
      type: ManuscriptDocumentType.part,
      parentId: root.id,
    );
    chapter = await service.createDocument(
      title: 'Chapter One',
      type: ManuscriptDocumentType.chapter,
      parentId: part.id,
      richTextJson: '{"ops":[{"insert":"Chapter body\\n"}]}',
      status: ManuscriptDocumentStatus.draft,
      summary: 'A summary',
      povCharacterId: 'char_1',
      plotline: 'main',
    );
    scene = await service.createDocument(
      title: 'Scene One',
      type: ManuscriptDocumentType.scene,
      parentId: chapter.id,
      richTextJson: '{"ops":[{"insert":"Scene body\\n"}]}',
    );
  });

  tearDown(() async {
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  group('MS-018 — duplicating a single document', () {
    test('the copy has a new id and the same content', () async {
      final copy = await service.duplicateDocument(chapter.id);

      expect(copy, isNotNull);
      expect(copy!.id, isNot(chapter.id));
      expect(copy.richTextJson, chapter.richTextJson);
      expect(copy.documentType, chapter.documentType);
    });

    test('the title is suffixed with " (copy)"', () async {
      final copy = await service.duplicateDocument(chapter.id);

      expect(copy!.title, 'Chapter One (copy)');
      expect(copy.title, endsWith(' (copy)'));
    });

    test('the copy is a sibling immediately after the original', () async {
      final copy = await service.duplicateDocument(chapter.id);

      expect(copy!.parentId, chapter.parentId);
      expect(copy.orderIndex, chapter.orderIndex + 1);
    });

    test('duplicating the last sibling still lands directly after it', () async {
      // Two chapters under the part; duplicating the second must not push a
      // sibling off the end or renumber the original.
      final second = await service.createDocument(
        title: 'Chapter Two',
        type: ManuscriptDocumentType.chapter,
        parentId: part.id,
      );

      final copy = await service.duplicateDocument(second.id);

      final siblings = service.getChildren(part.id).map((d) => d.title).toList();
      expect(siblings, ['Chapter One', 'Chapter Two', 'Chapter Two (copy)']);
      expect(copy!.orderIndex, second.orderIndex + 1);
    });

    test('other metadata is carried across', () async {
      final copy = await service.duplicateDocument(chapter.id);

      expect(copy!.status, chapter.status);
      expect(copy.summary, chapter.summary);
      expect(copy.povCharacterId, chapter.povCharacterId);
      expect(copy.plotline, chapter.plotline);
    });

    test('order indices stay contiguous and later siblings are pushed down', () async {
      await service.createDocument(
        title: 'Chapter Two',
        type: ManuscriptDocumentType.chapter,
        parentId: part.id,
      );

      final copy = await service.duplicateDocument(chapter.id);

      final siblings = service.getChildren(part.id);
      expect(siblings.map((d) => d.title).toList(), [
        'Chapter One',
        'Chapter One (copy)',
        'Chapter Two',
      ]);
      expect(siblings.map((d) => d.orderIndex).toList(), [0, 1, 2]);
      expect(copy!.orderIndex, 1);
    });

    test('duplicating an unknown id returns null rather than throwing', () async {
      expect(await service.duplicateDocument('nope'), isNull);
    });

    test('the original is untouched', () async {
      final before = docBox.get(chapter.id)!;

      await service.duplicateDocument(chapter.id);

      final after = docBox.get(chapter.id)!;
      expect(after.title, before.title);
      expect(after.richTextJson, before.richTextJson);
      expect(after.orderIndex, before.orderIndex);
    });
  });

  group('MS-018 — a duplicate copies the whole subtree', () {
    test('the child is duplicated too, with a fresh id', () async {
      final copy = await service.duplicateDocument(chapter.id);
      final copyScenes = service.getChildren(copy!.id);

      expect(copyScenes, hasLength(1));
      expect(copyScenes.single.id, isNot(scene.id));
      expect(copyScenes.single.title, scene.title);
    });

    test('the duplicated child re-parents to the copy, not the original', () async {
      final copy = await service.duplicateDocument(chapter.id);
      final copyScene = service.getChildren(copy!.id).single;

      expect(copyScene.parentId, copy.id);
      expect(copyScene.parentId, isNot(chapter.id));
    });

    test('the duplicated child keeps its content', () async {
      final copy = await service.duplicateDocument(chapter.id);
      final copyScene = service.getChildren(copy!.id).single;

      expect(copyScene.richTextJson, scene.richTextJson);
    });

    test('the original still owns its own child', () async {
      await service.duplicateDocument(chapter.id);

      final originalScenes = service.getChildren(chapter.id);
      expect(originalScenes, hasLength(1));
      expect(originalScenes.single.id, scene.id);
    });

    test('the subtree copies recursively, not just one level', () async {
      final note = await service.createDocument(
        title: 'A Note',
        type: ManuscriptDocumentType.note,
        parentId: scene.id,
        richTextJson: '{"ops":[{"insert":"Note body\\n"}]}',
      );

      final copy = await service.duplicateDocument(chapter.id);
      final copyScene = service.getChildren(copy!.id).single;
      final copyNote = service.getChildren(copyScene.id).single;

      expect(copyNote.id, isNot(note.id));
      expect(copyNote.parentId, copyScene.id);
      expect(copyNote.richTextJson, note.richTextJson);
    });

    test('a duplicated document id never collides with an existing one', () async {
      final copy = await service.duplicateDocument(chapter.id);
      final ids = docBox.values.map((d) => d.id).toSet();

      expect(ids, contains(copy!.id));
      expect(ids.where((id) => id == copy.id), hasLength(1));
    });
  });
}
