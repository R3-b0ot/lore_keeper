/// Manuscript revert correctness (Cycle 3b, item 3).
///
/// A revert from the history panel used to be lossy in two independent ways:
///
///   1. `ManuscriptBinderProvider.updateContent` overwrote the live document
///      without recording what it replaced, so the very act of undoing a change
///      destroyed it. The revert was not undoable.
///   2. The open editor kept its stale buffer and its stale baselines, so it
///      still displayed the pre-revert prose. The next autosave then either
///      wrote that stale text back over the revert, or — because the editor
///      believed nothing had changed — silently ignored the revert until the
///      author's next keystroke, which then overwrote it.
///
/// These tests drive a real [ManuscriptEditor] with a real [QuillController]
/// over in-memory Hive, mounting only [ManuscriptModule] rather than the whole
/// [ProjectEditorScreen] shell: the shell's own provider graph leaves open Hive
/// writes at teardown and deadlocks the test runner (see Cycle 3b item 4).
library;

import 'dart:convert';
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
import 'package:lore_keeper/modules/manuscript_module.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';

/// The content the document holds when the panel is opened.
const _currentDelta = '{"ops":[{"insert":"Current draft\\n"}]}';

/// The snapshot the author reverts to.
const _historicalDelta = '{"ops":[{"insert":"Older draft\\n"}]}';

/// An extra edit the author made but had not yet autosaved when they reverted.
///
/// Quill asserts the final op ends with a newline, so every insert here does.
const _unsavedEditDelta =
    '{"ops":[{"insert":"Current draft\\n"},{"insert":"TYPO\\n"}]}';

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

/// The Delta ops of a stored payload, ready for [Document.fromJson].
///
/// `richTextJson` has two shapes in this codebase and the editor itself
/// tolerates both (see `ManuscriptEditor._applyDocumentContent`): the model
/// adapter and `HistoryService` write `{"ops": [...]}`, while the editor's
/// autosave writes Quill's bare `[{...}]`. Both must read the same here.
List<dynamic> _opsOf(String payload) {
  final decoded = jsonDecode(payload);
  if (decoded is List) return decoded;
  return (decoded as Map<String, dynamic>)['ops'] as List<dynamic>;
}

String _plainTextOf(ManuscriptDocument doc) {
  if (doc.richTextJson == null) return '';
  return _opsOf(doc.richTextJson!)
      .whereType<Map<String, dynamic>>()
      .map((op) => op['insert'] as String? ?? '')
      .join()
      .trim();
}

/// History entries recorded for [documentId] as plain text, newest last.
List<String> _snapshotTexts(String documentId) {
  final box = Hive.box<HistoryEntry>('history');
  final entries =
      box.values
          .where(
            (e) =>
                e.targetType == 'ManuscriptDocument' &&
                e.targetKey == documentId,
          )
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return entries.map((e) {
    final decoded = jsonDecode(e.data) as Map<String, dynamic>;
    return (decoded['richTextJson'] as String? ?? '');
  }).toList();
}

void main() {
  late Directory dir;
  late Project project;
  late ManuscriptBinderProvider binderProvider;
  late ChapterListProvider chapterProvider;
  late CharacterListProvider characterProvider;

  const documentId = 'chapter_1';

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('manuscript_revert_');
    Hive.init(dir.path);
    await DatabaseManager.instance.initializeForTesting();

    project = Project(title: 'Revert Test', createdAt: DateTime.now());
    await DatabaseManager.instance.projects.add(project);
    project = DatabaseManager.instance.projects.getAt(0)!;

    final referenceEngine = ReferenceEngine();

    // Seed the chapter BEFORE the binder provider is constructed: the provider
    // caches the document list at construction, so a document written
    // afterwards is invisible to the editor's chapter-key resolution.
    final doc = ManuscriptDocument()
      ..id = documentId
      ..projectId = project.key!
      ..title = 'Chapter One'
      ..documentType = ManuscriptDocumentType.chapter
      ..parentId = 'manuscript_root'
      ..orderIndex = 0
      ..richTextJson = _currentDelta
      ..status = ManuscriptDocumentStatus.draft
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now();
    await DatabaseManager.instance.manuscriptDocuments.put(doc.id, doc);

    binderProvider = ManuscriptBinderProvider(
      project.key!,
      referenceEngine: referenceEngine,
    );
    await _waitFor(
      label: 'binder provider',
      isReady: () => binderProvider.isInitialized,
    );

    chapterProvider = ChapterListProvider(project.key!);
    await _waitFor(
      label: 'chapter provider',
      isReady: () => chapterProvider.isInitialized,
    );

    characterProvider = CharacterListProvider(
      project.key!,
      referenceEngine: referenceEngine,
    );
    await _waitFor(
      label: 'character provider',
      isReady: () => characterProvider.isInitialized,
    );
  });

  tearDown(() async {
    await DatabaseManager.instance.close();
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  group('3b-3 — a revert is undoable', () {
    test(
      'revertContentTo snapshots the content it is about to replace',
      () async {
        await binderProvider.revertContentTo(documentId, _historicalDelta);

        // (1) The document now holds the historical content...
        final doc = binderProvider.getDocument(documentId)!;
        expect(_plainTextOf(doc), 'Older draft');

        // (2) ...and the content it replaced is recoverable, so the revert
        // itself can be undone from the panel.
        final snapshots = _snapshotTexts(documentId);
        expect(snapshots, isNotEmpty, reason: 'the revert must be undoable');
        expect(
          snapshots.any((json) => json.contains('Current draft')),
          isTrue,
          reason:
              'the pre-revert content must be snapshotted before it is '
              'overwritten, otherwise undoing a change destroys it',
        );
      },
    );

    test('revertContentTo writes the historical content', () async {
      await binderProvider.revertContentTo(documentId, _historicalDelta);

      final stored = DatabaseManager.instance.manuscriptDocuments.get(
        documentId,
      )!;
      expect(stored.richTextJson, _historicalDelta);
    });

    test(
      'revertContentTo is a no-op when the content already matches',
      () async {
        // Reverting to the version already loaded must not record a duplicate
        // snapshot of the current content — the same rule HistorySnapshotPolicy
        // applies on the autosave path.
        await binderProvider.revertContentTo(documentId, _currentDelta);

        expect(_snapshotTexts(documentId), isEmpty);
        final stored = DatabaseManager.instance.manuscriptDocuments.get(
          documentId,
        )!;
        expect(stored.richTextJson, _currentDelta);
      },
    );
  });

  group('3b-3 — the open editor follows a revert', () {
    // ── Harness ────────────────────────────────────────────────────────────
    //
    // Mounts the real ManuscriptEditor inside the real ManuscriptModule over
    // in-memory Hive, and re-pumps it with a new revert signal.
    //
    // Two zone rules make this deterministic:
    //   * The module's initState and every write do real Hive I/O, so mounts and
    //     writes run inside [WidgetTester.runAsync] (the real event loop); the
    //     tree is rendered under the fake clock afterwards.
    //   * The autosave debounce is a Timer created while the test is inside
    //     runAsync, so it lives in the REAL zone and fires on real time.
    //     `tester.pump(3s)` would advance only the fake clock and never save
    //     anything, so waiting for a save means waiting in real time.
    late QuillController? editorController;

    Future<void> pumpEditor(
      WidgetTester tester, {
      required int revertSignal,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            home: ManuscriptModule(
              projectId: project.key!,
              selectedChapterKey: '1',
              chapterProvider: chapterProvider,
              characterProvider: characterProvider,
              onChapterSelected: (_) {},
              onControllerReady: (controller) => editorController = controller,
              onGrammarCheckReady: (_) {},
              binderProvider: binderProvider,
              sharedReferenceEngine: binderProvider.referenceEngine,
              revertSignal: revertSignal,
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// Lets the real-zone autosave debounce fire and its write complete.
    Future<void> settleAutosave(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      await tester.pump();
    }

    String storedText() => _plainTextOf(
      DatabaseManager.instance.manuscriptDocuments.get(documentId)!,
    );

    testWidgets('the editor autosaves an edit after the 2s debounce', (
      tester,
    ) async {
      // Substrate for the two tests below: if a plain edit never reaches
      // storage in this harness, "the autosave did not overwrite the revert"
      // would pass vacuously.
      await pumpEditor(tester, revertSignal: 0);
      expect(editorController!.document.toPlainText().trim(), 'Current draft');

      await tester.runAsync(() async {
        editorController!.document = Document.fromJson([
          {'insert': 'Probed\n'},
        ]);
      });
      await settleAutosave(tester);

      expect(storedText(), 'Probed');
    });

    testWidgets('the editor displays the reverted content', (tester) async {
      await pumpEditor(tester, revertSignal: 0);
      expect(editorController!.document.toPlainText().trim(), 'Current draft');

      // The panel's revert path: snapshot + overwrite through the provider,
      // then the shell bumps the signal so the editor re-syncs.
      await tester.runAsync(
        () => binderProvider.revertContentTo(documentId, _historicalDelta),
      );
      await pumpEditor(tester, revertSignal: 1);

      expect(
        editorController!.document.toPlainText().trim(),
        'Older draft',
        reason:
            'a revert must be visible in the open editor, not only in '
            'storage — otherwise the author is still reading the text they '
            'just undid',
      );
    });

    testWidgets('a pending debounce and the next autosave both keep the revert', (
      tester,
    ) async {
      await pumpEditor(tester, revertSignal: 0);
      expect(editorController!.document.toPlainText().trim(), 'Current draft');

      // An edit the author has NOT yet autosaved: the buffer differs from
      // storage and a 2s debounce is now armed in the real zone.
      await tester.runAsync(() async {
        editorController!.document = Document.fromJson(
          _opsOf(_unsavedEditDelta),
        );
      });
      expect(
        storedText(),
        'Current draft',
        reason: 'precondition: the edit is still unsaved',
      );

      // Revert while that edit is still pending — the exact moment the old
      // code lost the change.
      await tester.runAsync(
        () => binderProvider.revertContentTo(documentId, _historicalDelta),
      );
      await pumpEditor(tester, revertSignal: 1);

      // (1) The editor shows the reverted content.
      expect(editorController!.document.toPlainText().trim(), 'Older draft');

      // (2) The armed debounce is cancelled. It captured the pre-revert buffer,
      // so if it merely survives the revert it writes that text back.
      await settleAutosave(tester);
      expect(
        storedText(),
        'Older draft',
        reason:
            'the pending debounce carries pre-revert text and must be '
            'cancelled when the editor re-syncs, not left to fire',
      );

      // (3) The next real edit is based on the reverted content. This is the
      // failure that actually loses work: the author sees stale prose, types a
      // fix, and the revert is gone.
      await tester.runAsync(() async {
        editorController!.document = Document.fromJson([
          ..._opsOf(_historicalDelta),
          {'insert': 'Extra\n'},
        ]);
      });
      await settleAutosave(tester);

      expect(storedText(), 'Older draft\nExtra');
      expect(
        storedText(),
        isNot(contains('Current draft')),
        reason: 'the editor must have re-based onto the reverted content',
      );
    });
  });
}
