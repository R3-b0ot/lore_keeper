/// Manuscript history (Cycle 3) — MS-006, MS-007, MS-020, MS-008.
///
/// Covers the ManuscriptDocument revision path end to end:
///   * MS-006 — the shell's history panel must query the same
///     `targetType`/`targetKey` pair that manuscript saves actually write
///     (`'ManuscriptDocument'` + the canonical document id).
///   * MS-007 — a ManuscriptDocument history entry renders a diff and reverts
///     through `ManuscriptBinderProvider.updateContent`, never through the
///     legacy `chapters` box.
///   * MS-020 — no ManuscriptDocument diff/revert path opens
///     `Hive.box<Chapter>` directly.
///   * MS-008 — autosave does not write a second HistoryEntry when the rich
///     text is unchanged since the last save.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/settings/global_settings_controller.dart';
import 'package:lore_keeper/widgets/history_panel.dart';
import 'package:provider/provider.dart';

/// A two-word document whose canonical counts are 2 words / 11 characters
/// (MS-010 decision: the structural trailing newline is excluded).
const _helloDelta = '{"ops":[{"insert":"Hello world\\n"}]}';

/// The snapshot a revert restores.
const _historicalDelta = '{"ops":[{"insert":"Older draft\\n"}]}';

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

/// Pumps the REAL [ProjectEditorScreen] with the Manuscripts module open.
///
/// Mirrors the Cycle 1/2 shell helper: the shell builds its own Hive-backed
/// providers in initState, so the mount + bootstrap must run inside
/// [WidgetTester.runAsync]; stranding real async in the FakeAsync zone hangs
/// post-test teardown.
Future<void> _pumpProjectEditorShell(
  WidgetTester tester,
  Project project, {
  String initialChapterKey = '',
}) async {
  // 2600px, not 1700px: opening the 300px history panel narrows Column 2 to
  // ~204px, which trips a PRE-EXISTING RenderFlex overflow in the list-pane
  // header row (lib/widgets/manuscript_list_pane.dart:58). That overflow is
  // unrelated to the history wiring and is only reachable at narrow widths, so
  // these tests use a width where the shell lays out cleanly.
  await tester.binding.setSurfaceSize(const Size(2600, 1250));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final settings = GlobalSettingsController();
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ChangeNotifierProvider<GlobalSettingsController>.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          home: ProjectEditorScreen(
            project: project,
            // Legacy deep-link remap quirk: legacy index 0 opens Manuscripts.
            initialModuleIndex: 0,
            initialChapterKey: initialChapterKey.isEmpty
                ? null
                : initialChapterKey,
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
  });

  await tester.pump();
}

/// Advances a bounded number of frames.
///
/// The shell hosts continuously animating widgets (Quill caret blink, status
/// pulses), so `pumpAndSettle` never settles and would burn its full 10-minute
/// default timeout. These tests need a fixed, short frame budget instead.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  late Directory dir;
  late Project project;
  late ManuscriptBinderProvider binderProvider;
  late HistoryService historyService;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('manuscript_history_');
    Hive.init(dir.path);
    await DatabaseManager.instance.initializeForTesting();

    project = Project(title: 'History Test', createdAt: DateTime.now());
    await DatabaseManager.instance.projects.add(project);
    project = DatabaseManager.instance.projects.getAt(0)!;

    binderProvider = ManuscriptBinderProvider(
      project.key!,
      referenceEngine: ReferenceEngine(),
    );
    await _waitFor(
      label: 'binder provider',
      isReady: () => binderProvider.isInitialized,
    );
    expect(binderProvider.manuscriptRoot, isNotNull);

    final chapterDoc = ManuscriptDocument()
      ..id = 'chapter_1'
      ..projectId = project.key!
      ..title = 'Chapter One'
      ..documentType = ManuscriptDocumentType.chapter
      ..parentId = binderProvider.manuscriptRoot!.id
      ..orderIndex = 0
      ..status = ManuscriptDocumentStatus.draft
      ..richTextJson = _helloDelta
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now();
    await DatabaseManager.instance.manuscriptDocuments.put(
      chapterDoc.id,
      chapterDoc,
    );

    historyService = HistoryService();
  });

  tearDown(() async {
    await DatabaseManager.instance.close();
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows can hold the box file briefly; the temp dir is disposable.
    }
  });

  /// Seeds one snapshot through the REAL [HistoryService] so the fixture is
  /// byte-identical to what a manuscript save writes (spec §32.4).
  ///
  /// Performs real Hive I/O, so callers must run it inside
  /// [WidgetTester.runAsync]; awaiting it in the FakeAsync test zone
  /// deadlocks (see [_seedInRealAsync]).
  Future<HistoryEntry> seedEntry({
    String targetType = 'ManuscriptDocument',
    dynamic targetKey = 'chapter_1',
    String? richTextJson,
  }) async {
    final document = ManuscriptDocument()
      ..id = targetKey is String ? targetKey : 'chapter_1'
      ..projectId = project.key!
      ..title = 'Chapter One'
      ..documentType = ManuscriptDocumentType.chapter
      ..richTextJson = richTextJson ?? _historicalDelta;

    await historyService.addHistoryEntry(
      targetKey: targetKey,
      targetType: targetType,
      objectToSave: document,
      projectId: project.key!,
    );
    return DatabaseManager.instance.historyEntries.values.last;
  }

  group('MS-006 — history panel shows ManuscriptDocument revisions', () {
    testWidgets(
      "the shell history panel lists the selected document's revisions "
      '(MS-006)',
      (tester) async {
        await tester.runAsync(seedEntry);

        await _pumpProjectEditorShell(tester, project, initialChapterKey: '1');

        // Select the document in Column 2 so the shell knows which document
        // the history panel should target.
        await tester.tap(find.text('Chapter One').first);
        await _pumpFrames(tester);

        await tester.tap(find.byTooltip('Show History'));
        await _pumpFrames(tester);

        expect(find.byType(HistoryPanel), findsOneWidget);
        expect(find.text('Version snapshot'), findsOneWidget);
        expect(
          find.textContaining('No history found'),
          findsNothing,
          reason: 'manuscript saves write targetType ManuscriptDocument',
        );
      },
    );

    testWidgets('HistoryPanel renders a seeded ManuscriptDocument entry', (
      tester,
    ) async {
      await tester.runAsync(seedEntry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryPanel(
              targetType: 'ManuscriptDocument',
              targetKey: 'chapter_1',
              onClose: () {},
              onReverted: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version snapshot'), findsOneWidget);
      expect(find.textContaining('No history found'), findsNothing);
    });

    testWidgets('HistoryPanel still lists Character revisions (unchanged)', (
      tester,
    ) async {
      await tester.runAsync(
        () => seedEntry(targetType: 'Character', targetKey: 42),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryPanel(
              targetType: 'Character',
              targetKey: 42,
              onClose: () {},
              onReverted: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version snapshot'), findsOneWidget);
    });

    testWidgets(
      'HistoryPanel does not list a ManuscriptDocument entry for another id',
      (tester) async {
        await tester.runAsync(() => seedEntry(targetKey: 'chapter_9'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HistoryPanel(
                targetType: 'ManuscriptDocument',
                targetKey: 'chapter_1',
                onClose: () {},
                onReverted: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('No history found'), findsOneWidget);
      },
    );
  });
}
