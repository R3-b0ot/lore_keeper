/// MS-029 — hierarchy invariants are enforced, not merely logged (Cycle 7,
/// closing B5 D6).
///
/// `ManuscriptBinderService._validateTypeHierarchy` consulted a complete
/// parent→child table and then, on a violation, logged a warning and carried
/// on. A document tree could therefore be built that the model says is illegal:
/// a Scene parented directly to a Manuscript, a Note under a Part, a Part under
/// a Chapter. Every consumer of the tree then has to defend against a shape the
/// schema forbids, and the author who produced it gets no feedback.
///
/// These tests pin the enforced table:
///
///   manuscript -> {part, chapter, frontMatter, backMatter}
///   part       -> {chapter, section}
///   chapter    -> {scene}
///   section    -> {scene, note, research}
///   scene      -> {note}
///
/// The important half is not that a throw happens, but that **nothing was
/// written**: a rejected operation must leave the Hive box byte-for-byte as it
/// was, or the enforcement is cosmetic.
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
    dir = await Directory.systemTemp.createTemp('hive_hierarchy_');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(ManuscriptDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProjectAdapter());
    }
    docBox = await Hive.openBox<ManuscriptDocument>('manuscript_documents');
    projectBox = await Hive.openBox<Project>('projects');

    project = Project(title: 'Hierarchy Test', createdAt: DateTime.now());
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
    );
    scene = await service.createDocument(
      title: 'Scene One',
      type: ManuscriptDocumentType.scene,
      parentId: chapter.id,
    );
  });

  tearDown(() async {
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  /// A stable snapshot of the whole box, for before/after comparison.
  Map<String, String> snapshot() {
    return {
      for (final doc in docBox.values) doc.id: '${doc.parentId}/${doc.documentType}',
    };
  }

  group('MS-029 — invalid hierarchies are rejected at move time', () {
    test('moving a Scene under a Manuscript (skipping Part/Chapter) throws', () {
      expect(
        () => service.moveDocument(scene.id, root.id),
        throwsA(isA<StateError>()),
      );
    });

    test('a rejected move leaves the Hive box completely unchanged', () async {
      final before = snapshot();

      await service
          .moveDocument(scene.id, root.id)
          .then((_) {})
          .catchError((Object _) {});

      expect(snapshot(), equals(before));
      // And the in-memory document was not mutated either: moveDocument writes
      // parentId before saving, so a partial write would show up here.
      expect(service.getDocument(scene.id)!.parentId, chapter.id);
    });

    test('moving a Note under a Part throws (part allows no notes)', () async {
      final note = await service.createDocument(
        title: 'A Note',
        type: ManuscriptDocumentType.note,
        parentId: scene.id,
      );

      expect(() => service.moveDocument(note.id, part.id), throwsA(isA<StateError>()));
      expect(service.getDocument(note.id)!.parentId, scene.id);
    });

    test('moving a Part under a Chapter throws', () async {
      expect(() => service.moveDocument(part.id, chapter.id), throwsA(isA<StateError>()));
      expect(service.getDocument(part.id)!.parentId, root.id);
    });
  });

  group('MS-029 — invalid hierarchies are rejected at create time', () {
    test('creating a Scene directly under a Manuscript throws', () {
      expect(
        () => service.createDocument(
          title: 'Orphan Scene',
          type: ManuscriptDocumentType.scene,
          parentId: root.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a rejected create writes nothing to the box', () async {
      final before = snapshot();

      await service
          .createDocument(
            title: 'Orphan Scene',
            type: ManuscriptDocumentType.scene,
            parentId: root.id,
          )
          .then((_) {})
          .catchError((Object _) {});

      expect(snapshot(), equals(before), reason: 'the rejected document must not exist');
      expect(service.getDocument('scene_orphan'), isNull);
    });

    test('creating a Part under a Chapter throws', () async {
      expect(
        () => service.createDocument(
          title: 'Nested Part',
          type: ManuscriptDocumentType.part,
          parentId: chapter.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('a Note under a Section is allowed', () async {
      final section = await service.createDocument(
        title: 'Section One',
        type: ManuscriptDocumentType.section,
        parentId: part.id,
      );
      final note = await service.createDocument(
        title: 'Section Note',
        type: ManuscriptDocumentType.note,
        parentId: section.id,
      );
      expect(note.parentId, section.id);
    });
  });

  group('MS-029 — legal operations are unaffected', () {
    test('a Scene under a Chapter is a valid move', () async {
      final otherChapter = await service.createDocument(
        title: 'Chapter Two',
        type: ManuscriptDocumentType.chapter,
        parentId: part.id,
      );

      await service.moveDocument(scene.id, otherChapter.id);

      expect(service.getDocument(scene.id)!.parentId, otherChapter.id);
    });

    test('a Chapter under a Part is a valid move', () async {
      final otherPart = await service.createDocument(
        title: 'Part Two',
        type: ManuscriptDocumentType.part,
        parentId: root.id,
      );

      await service.moveDocument(chapter.id, otherPart.id);

      expect(service.getDocument(chapter.id)!.parentId, otherPart.id);
    });

    test('the whole seeded tree survives enforcement', () {
      expect(service.getDocument(part.id)!.parentId, root.id);
      expect(service.getDocument(chapter.id)!.parentId, part.id);
      expect(service.getDocument(scene.id)!.parentId, chapter.id);
    });
  });
}
