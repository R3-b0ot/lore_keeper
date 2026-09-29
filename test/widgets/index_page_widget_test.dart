/// The front-matter Index page (Cycle 6, MS-019).
///
/// The Index page is the manuscript's table of contents, so it has to list the
/// documents the author actually works in. Those are `ManuscriptDocument`s in
/// the binder. A chapter created through the binder after the 2026 redesign has
/// no legacy `Chapter` row at all, and its id is a uuid (`chapter_<uuid>`), not
/// the `chapter_<legacyKey>` mirror that `DatabaseManager` synthesises when it
/// pairs a legacy chapter with a manuscript document.
///
/// These tests therefore create documents **through `ManuscriptBinderService`
/// only** and assert they reach the rendered list. No legacy chapter is
/// created for the document under test, because a test that seeded one would
/// pass against the old implementation and prove nothing.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/services/manuscript_binder_service.dart';
import 'package:lore_keeper/widgets/index_page_widget.dart';

Future<void> _waitFor({
  required String label,
  required bool Function() isReady,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (!isReady() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(isReady(), isTrue, reason: '$label did not initialize');
}

void main() {
  late Directory dir;
  late Project project;
  late ManuscriptBinderService binderService;
  late ManuscriptBinderProvider binderProvider;
  late ChapterListProvider chapterProvider;
  late ManuscriptDocument binderOnlyChapter;
  late ManuscriptDocument binderOnlyScene;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('index_page_');
    Hive.init(dir.path);
    await DatabaseManager.instance.initializeForTesting();

    project = Project(title: 'Index Test', createdAt: DateTime.now());
    await DatabaseManager.instance.projects.add(project);
    project = DatabaseManager.instance.projects.getAt(0)!;

    final referenceEngine = ReferenceEngine();

    binderService = ManuscriptBinderService(
      projectId: project.key!,
      documentBox: DatabaseManager.instance.manuscriptDocuments,
      projectBox: DatabaseManager.instance.projects,
      referenceEngine: referenceEngine,
    );
    final root = await binderService.createManuscriptRoot(project);

    // Created through the service only: no legacy Chapter anywhere near them.
    binderOnlyChapter = await binderService.createDocument(
      title: 'Binder Only Chapter',
      type: ManuscriptDocumentType.chapter,
      parentId: root.id,
    );
    binderOnlyScene = await binderService.createDocument(
      title: 'Binder Only Scene',
      type: ManuscriptDocumentType.scene,
      parentId: binderOnlyChapter.id,
    );

    // Every Hive mutation happens here rather than inside `testWidgets`:
    // a widget test body runs under fake async, and a real Hive write awaited
    // there never completes.
    chapterProvider = ChapterListProvider(project.key!);
    await _waitFor(
      label: 'chapter provider',
      isReady: () => chapterProvider.isInitialized,
    );

    binderProvider = ManuscriptBinderProvider(
      project.key!,
      referenceEngine: referenceEngine,
    );
    await _waitFor(
      label: 'binder provider',
      isReady: () =>
          binderProvider.isInitialized && binderProvider.manuscriptRoot != null,
    );
  });

  tearDown(() async {
    // DatabaseManager must release its boxes before Hive is closed, and the
    // delete is best-effort: Windows may still hold a handle.
    await DatabaseManager.instance.close();
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  /// Whether any legacy `Chapter` carries [title] for this project.
  ///
  /// `ChapterListProvider` manufactures a default chapter of its own when the
  /// legacy box is empty, so "the legacy box is empty" is not a premise this
  /// fixture can assert. What matters is that the document under test has no
  /// legacy twin by name.
  bool legacyChapterTitled(String title) {
    return DatabaseManager.instance.chapters.values.any(
      (c) => c.parentProjectId == project.key && c.title == title,
    );
  }

  /// The document id the page last reported, or null if nothing was tapped.
  String? selectedId;

  /// Mounts the page against the binder, recording the emitted document id.
  Future<void> pumpIndex(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndexPageWidget(
            binderProvider: binderProvider,
            onDocumentSelected: (id) => selectedId = id,
          ),
        ),
      ),
    );
    // Not pumpAndSettle: settling never terminates here.
    await tester.pump();
    await tester.pump();
  }

  group('MS-019 - the Index page lists manuscript documents', () {
    testWidgets(
      'a chapter created only through the binder appears on the Index page',
      (tester) async {
        expect(legacyChapterTitled('Binder Only Chapter'), isFalse);
        expect(binderOnlyChapter.id, isNotEmpty);

        await pumpIndex(tester);

        expect(
          find.text('Binder Only Chapter'),
          findsOneWidget,
          reason:
              'a manuscript chapter with no legacy Chapter twin must still be '
              'listed (MS-019)',
        );
      },
    );

    testWidgets('scenes are listed too, not just chapters', (tester) async {
      expect(legacyChapterTitled('Binder Only Scene'), isFalse);
      expect(binderOnlyScene.documentType, ManuscriptDocumentType.scene);

      await pumpIndex(tester);

      expect(find.text('Binder Only Scene'), findsOneWidget);
    });

    testWidgets(
      'the page no longer reads the legacy chapters box at all',
      (tester) async {
        // The legacy provider manufactured its own default chapter. It must
        // not show up here, because the page reads the binder now.
        expect(chapterProvider.chapters, isNotEmpty);

        await pumpIndex(tester);

        for (final legacy in chapterProvider.chapters) {
          expect(
            find.text(legacy.title),
            findsNothing,
            reason:
                'legacy chapter "${legacy.title}" leaked onto the Index page; '
                'it must come from the binder only (MS-019)',
          );
        }
      },
    );

    testWidgets('tapping a row reports its manuscript document id', (
      tester,
    ) async {
      await pumpIndex(tester);

      await tester.tap(find.text('Binder Only Chapter'));
      await tester.pump();

      expect(
        selectedId,
        binderOnlyChapter.id,
        reason: 'the page must report the document id, not a legacy key',
      );
      expect(
        int.tryParse(selectedId ?? ''),
        isNull,
        reason: 'a binder document id is a uuid, not a legacy chapter key',
      );
    });

    testWidgets('the search box still filters the listed documents', (
      tester,
    ) async {
      await pumpIndex(tester);

      await tester.enterText(find.byType(TextField).first, 'Scene');
      await tester.pump();

      expect(find.text('Binder Only Scene'), findsOneWidget);
      expect(find.text('Binder Only Chapter'), findsNothing);
    });
  });
}
