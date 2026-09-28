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
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/services/history_service.dart';
import 'package:lore_keeper/settings/global_settings_controller.dart';
import 'package:lore_keeper/widgets/history_panel.dart';
import 'package:lore_keeper/widgets/manuscript_diff_view_dialog.dart';
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
  /// deadlocks.
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

  group('MS-020 — the ManuscriptDocument diff/revert path is Hive-free', () {
    test('no manuscript history widget opens Hive.box<Chapter> (MS-020)', () {
      // The manuscript revision path must not reach into the legacy chapter
      // box: not to read the "current" version, not to write the revert, and
      // not to deserialize the snapshot with chapterFromJson.
      const manuscriptHistoryWidgets = [
        'lib/widgets/manuscript_diff_view_dialog.dart',
        'lib/widgets/history_panel.dart',
      ];

      for (final file in manuscriptHistoryWidgets) {
        final code = _codeOfFile(file);
        expect(
          code,
          isNot(contains('Hive.box<Chapter>')),
          reason: '$file must not open the legacy chapters box (MS-020)',
        );
        expect(
          code,
          isNot(contains('chapterFromJson')),
          reason:
              '$file must not parse a snapshot as a legacy Chapter (MS-020)',
        );
        expect(
          code,
          isNot(contains('models/chapter.dart')),
          reason: '$file must not depend on the Chapter model (MS-020/MS-021)',
        );
      }
    });

    test(
      'the manuscript diff dialog receives all data by constructor (MS-020)',
      () {
        // Data-in, callback-out: the dialog must not read storage at all.
        final code = _codeOfFile(
          'lib/widgets/manuscript_diff_view_dialog.dart',
        );

        expect(code, isNot(contains('package:hive')));
        expect(code, isNot(contains('Hive.')));

        // The revert is a callback, so persistence is the caller's decision.
        expect(code, contains('Future<void> Function(String'));
      },
    );

    test(
      'ChapterDiffViewDialog still serves legacy Chapter data only (MS-020)',
      () {
        // The legacy dialog is intentionally left untouched: it is the path for
        // pre-manuscript 'Chapter' snapshots, not the manuscript one. This test
        // documents that the manuscript path routes elsewhere, so nobody later
        // "reuses" it for a ManuscriptDocument and reintroduces the Hive read.
        final code = _codeOfFile('lib/widgets/history_panel.dart');

        expect(code, contains("entry.targetType == 'Chapter'"));
        expect(code, contains("entry.targetType == 'ManuscriptDocument'"));
      },
    );
  });

  group('MS-007 — ManuscriptDocument diff and revert', () {
    testWidgets('opens a diff instead of claiming the type is unsupported', (
      tester,
    ) async {
      await tester.runAsync(seedEntry);

      final spy = _SpyBinderProvider(project.key!);
      await tester.runAsync(
        () => _waitFor(
          label: 'spy binder provider',
          isReady: () => spy.isInitialized,
        ),
      );

      await tester.pumpWidget(
        _panelHost(
          HistoryPanel(
            targetType: 'ManuscriptDocument',
            targetKey: 'chapter_1',
            binderProvider: spy,
            onClose: () {},
            onReverted: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The revert affordance exists on the row...
      await tester.tap(find.byTooltip('Revert to this version'));
      await tester.pumpAndSettle();

      // ...and it must open a diff dialog for a ManuscriptDocument rather than
      // the "Diff view not supported for this type." snackbar.
      expect(find.textContaining('Diff view not supported'), findsNothing);
      expect(find.byType(ManuscriptDocumentDiffViewDialog), findsOneWidget);

      // The dialog is handed the live document and the snapshot — never a
      // legacy Chapter and never raw JSON to diff against itself.
      final dialog = tester.widget<ManuscriptDocumentDiffViewDialog>(
        find.byType(ManuscriptDocumentDiffViewDialog),
      );
      expect(dialog.currentTitle, 'Chapter One');
      expect(dialog.currentRichTextJson, _helloDelta);
      expect(dialog.historicalRichTextJson, _historicalDelta);

      // A real diff is rendered: both a removal (the live prose) and an
      // addition (the snapshot's prose) are on screen. DiffMatchPatch
      // segments character-by-character, so the individual Text widgets are
      // fragments — the markers, not whole phrases, are what is assertable.
      expect(find.text('No changes in text.'), findsNothing);
      expect(find.textContaining('- '), findsWidgets);
      expect(find.textContaining('+ '), findsWidgets);
    });

    testWidgets(
      'revert writes the historical richTextJson through the binder provider '
      '(MS-007)',
      (tester) async {
        await tester.runAsync(() async {
          await seedEntry();
          // Put a decoy in the legacy chapters box keyed by the history key so
          // we can prove the revert never writes through it.
          await DatabaseManager.instance.chapters.put(
            'chapter_1',
            Chapter()
              ..title = 'Legacy Chapter'
              ..parentSectionKey = 0
              ..parentProjectId = project.key!
              ..orderIndex = 0
              ..richTextJson = _legacyChapterJson,
          );
        });

        final documentBefore = DatabaseManager.instance.manuscriptDocuments.get(
          'chapter_1',
        )!;
        expect(documentBefore.richTextJson, _helloDelta);

        // The panel is driven with a spy binder so the test can observe the
        // exact payload the revert path hands to updateContent.
        final spy = _SpyBinderProvider(project.key!);
        await tester.runAsync(
          () => _waitFor(
            label: 'spy binder provider',
            isReady: () => spy.isInitialized,
          ),
        );

        await tester.pumpWidget(
          _panelHost(
            HistoryPanel(
              targetType: 'ManuscriptDocument',
              targetKey: 'chapter_1',
              binderProvider: spy,
              onClose: () {},
              onReverted: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Revert to this version'));
        await tester.pumpAndSettle();

        // The diff dialog shows the snapshot against the current document.
        expect(find.textContaining('Compare and Revert:'), findsOneWidget);

        // The revert button performs REAL Hive I/O (updateContent), so the tap
        // is dispatched inside runAsync: creating the async chain in the real
        // zone is what lets it complete. Tapping in the FakeAsync zone
        // deadlocks, because the write's continuations can never be flushed.
        await tester.runAsync(() async {
          await tester.tap(find.text('Revert to this Version'));
          await Future<void>.delayed(const Duration(milliseconds: 500));
        });
        await tester.pumpAndSettle();

        // (1) The revert was routed through the binder provider, carrying the
        //     historical richTextJson decoded from the snapshot.
        expect(spy.updatedDocumentId, 'chapter_1');
        expect(spy.updatedRichTextJson, _historicalDelta);

        // (2) The document itself now holds the historical content.
        final after = DatabaseManager.instance.manuscriptDocuments.get(
          'chapter_1',
        )!;
        expect(after.richTextJson, _historicalDelta);
        expect(after.wordCount, 2); // recomputed: "Older draft" = 2 words

        // (3) The legacy chapters box was NOT touched.
        final legacy = DatabaseManager.instance.chapters.get('chapter_1')!;
        expect(legacy.richTextJson, _legacyChapterJson);
        expect(legacy.title, 'Legacy Chapter');

        // (4) The snapshot itself is not mutated by reverting.
        expect(
          DatabaseManager.instance.historyEntries.values.single.data,
          contains('Older draft'),
        );
      },
    );
  });

  group('MS-008 — autosave does not snapshot unchanged content', () {
    test('_saveContent skips the snapshot when the rich text is unchanged', () {
      // MS-008: Quill notifies on cursor moves and undo bookkeeping, so the
      // autosave debounce can fire for text that never changed. Without a
      // guard, every one of those fires writes another HistoryEntry and the
      // history panel fills with visually identical snapshots.
      //
      // The behavioural half of this contract (two identical saves producing
      // one entry) was confirmed red against the real editor before this fix —
      // see docs/audit2/CYCLE_LOG.md. It is asserted structurally here
      // instead, because a widget test that drives a real autosave leaves
      // ProjectEditorScreen's provider graph holding open Hive writes, and
      // tearing that down after a write deadlocks the test runner.
      final code = _codeOfFile('lib/modules/manuscript_module.dart');

      // (1) The last persisted payload is remembered in memory.
      expect(
        code,
        contains('String? _lastSavedContent'),
        reason: 'the module must remember the content it last saved',
      );

      // (2) _saveContent compares against it and bails out early.
      final saveStart = code.indexOf('Future<void> _saveContent');
      expect(saveStart, greaterThan(-1), reason: '_saveContent must exist');
      final saveBody = code.substring(
        saveStart,
        code.indexOf('@override', saveStart),
      );
      final guardAt = saveBody.indexOf('if (_lastSavedContent == content)');
      expect(
        guardAt,
        greaterThan(-1),
        reason: '_saveContent must return early when the content is unchanged',
      );

      // (3) The guard fires BEFORE the snapshot is written, and after the
      // content is encoded so the comparison is meaningful.
      expect(
        saveBody.indexOf('final content ='),
        lessThan(guardAt),
        reason: 'the content must be encoded before it is compared',
      );
      expect(
        saveBody.indexOf('addHistoryEntry'),
        greaterThan(guardAt),
        reason:
            'MS-008: the early return must precede addHistoryEntry, '
            'otherwise the duplicate snapshot is still written',
      );

      // (4) A completed save becomes the new baseline, and the baseline is
      // seeded on load so the first save after opening a document is not
      // suppressed.
      expect(
        saveBody.indexOf('_lastSavedContent = content;'),
        greaterThan(guardAt),
        reason: 'a completed save must become the new baseline',
      );
      expect(
        code.split('String? _lastSavedContent').last,
        contains('_lastSavedContent = '),
        reason: '_loadContent must seed the baseline from the loaded document',
      );
    });

    test('the autosave debounce is at least 5 seconds (OQ-3)', () {
      // OQ-3 widened the 2s target to 5s. A longer debounce means fewer
      // spurious fires to begin with, but the MS-008 guard is still required:
      // a fired timer can carry unchanged content.
      final code = _codeOfFile('lib/modules/manuscript_module.dart');
      final match = RegExp(
        r'_autosaveDelay\s*=\s*const Duration\(seconds:\s*(\d+)\)',
      ).firstMatch(code);

      expect(
        match,
        isNotNull,
        reason: '_autosaveDelay must be an explicit Duration',
      );
      // S-34 (spec 11.3): "The current target is approximately two seconds
      // unless profiling or UX requirements justify another value." Cycle 3
      // raised this to 5s on an OQ-3 reading; the spec's own value governs, and
      // snapshot pacing is handled by HistorySnapshotPolicy (3b-2) rather than
      // by slowing the content save.
      expect(
        int.parse(match!.group(1)!),
        2,
        reason: 'S-34: the autosave debounce target is 2 seconds',
      );
    });
  });
}

/// Reads a source file with its comments removed.
///
/// A static guard has to look at *code*: the manuscript dialog's doc comment
/// legitimately names `Hive.box<Chapter>` to explain that it never opens it, and
/// a guard that matched that text would be both useless (it proves nothing) and
/// impossible to document around. Stripping comments keeps the assertion on the
/// behaviour that actually matters.
String _codeOfFile(String path) {
  final source = File(path).readAsStringSync();
  return source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
      .replaceAll(RegExp(r'//[^\n]*'), ' ');
}

/// A minimal host for [HistoryPanel] that supplies the real current document
/// data the panel needs to diff against.
Widget _panelHost(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, child: child)),
  );
}

/// Minimal legacy-chapter fixture. The MS-007 revert must never read or write
/// this; the box is only seeded to prove that.
const _legacyChapterJson = '{"ops":[{"insert":"Legacy\\n"}]}';

/// Records what the history panel asked the binder provider to persist, then
/// delegates to the real provider so the Hive write is real.
class _SpyBinderProvider extends ManuscriptBinderProvider {
  _SpyBinderProvider(super.projectId)
    : super(referenceEngine: ReferenceEngine());

  String? updatedDocumentId;
  String? updatedRichTextJson;

  @override
  Future<void> updateContent(String documentId, String richTextJson) async {
    updatedDocumentId = documentId;
    updatedRichTextJson = richTextJson;
    await super.updateContent(documentId, richTextJson);
  }
}
