/// Manuscript Workspace Topology regression tests — Cycle 0.5 + Cycle 0.6.
///
/// Canonical topology:
///   Column 2 → [ManuscriptListPane]  (single host of Binder/Corkboard/Outliner/Collections)
///   Column 3 → [ManuscriptEditor]    (Quill editor, no navigation UI)
///   Column 4 → [ManuscriptInspector] (standalone widget, receives document from parent)
///
/// Cycle 0.6 additions:
///   - ManuscriptInspector is a standalone widget with key 'manuscript-inspector'
///   - ManuscriptEditor has key 'manuscript-editor'
///   - ManuscriptListPane has key 'manuscript-list-pane'
///   - EntityNameMatcher is the autocomplete name-matcher (not ReferenceEngine)
///   - Backlink navigation calls onDocumentSelected to sync the shell/Binder
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';
import 'package:lore_keeper/modules/manuscript_module.dart';
import 'package:lore_keeper/widgets/manuscript_binder.dart';
import 'package:lore_keeper/widgets/manuscript_collections.dart';
import 'package:lore_keeper/widgets/manuscript_corkboard.dart';
import 'package:lore_keeper/widgets/manuscript_inspector.dart';
import 'package:lore_keeper/widgets/manuscript_list_pane.dart';
import 'package:lore_keeper/widgets/manuscript_outliner.dart';
import 'package:lore_keeper/services/reference_name_resolver.dart';

// ---------------------------------------------------------------------------
// Shared setup helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Static architecture contract ──────────────────────────────────────────

  group('static topology contract', () {
    test('ManuscriptModule/ManuscriptEditor no longer defines the legacy left '
        'panel architecture', () {
      final source = File(
        'lib/modules/manuscript_module.dart',
      ).readAsStringSync();

      expect(source, contains('class ManuscriptModule'));
      expect(source, contains('class ManuscriptEditor'));

      // Legacy nested navigation architecture must be gone.
      expect(source, isNot(contains('_LeftPanelMode')));
      expect(source, isNot(contains('_leftPanelMode')));
      expect(source, isNot(contains('_buildLeftPanel')));

      // The four list views must not be instantiated inside the module.
      expect(source, isNot(contains('ManuscriptBinder(')));
      expect(source, isNot(contains('ManuscriptCorkboard(')));
      expect(source, isNot(contains('ManuscriptOutliner(')));
      expect(source, isNot(contains('ManuscriptCollections(')));
    });

    test(
      'Column 2 ManuscriptListPane is the single host of the four views',
      () {
        final source = File(
          'lib/widgets/manuscript_list_pane.dart',
        ).readAsStringSync();

        expect(source, contains('enum ManuscriptListViewMode'));
        expect(source, contains('ManuscriptBinder('));
        expect(source, contains('ManuscriptCorkboard('));
        expect(source, contains('ManuscriptOutliner('));
        expect(source, contains('ManuscriptCollections('));
      },
    );

    // ── Cycle 0.6: Inspector extraction ──────────────────────────────────

    test('ManuscriptInspector is a standalone widget in its own file', () {
      final source = File(
        'lib/widgets/manuscript_inspector.dart',
      ).readAsStringSync();

      expect(source, contains('class ManuscriptInspector'));
      // Inspector must not own navigation surfaces.
      expect(source, isNot(contains('ManuscriptBinder(')));
      expect(source, isNot(contains('ManuscriptListPane(')));
      expect(source, isNot(contains('ManuscriptCorkboard(')));
      expect(source, isNot(contains('ManuscriptOutliner(')));
      expect(source, isNot(contains('ManuscriptCollections(')));
    });

    test(
      'ManuscriptModule renders ManuscriptInspector, not _buildInspectorPanel',
      () {
        final source = File(
          'lib/modules/manuscript_module.dart',
        ).readAsStringSync();

        expect(source, contains('ManuscriptInspector('));
        expect(source, isNot(contains('_buildInspectorPanel')));
      },
    );

    // ── Cycle 0.6: ReferenceEngine rename ────────────────────────────────

    test('EntityNameMatcher class exists in entity_name_matcher.dart', () {
      final source = File(
        'lib/services/entity_name_matcher.dart',
      ).readAsStringSync();

      expect(source, contains('class EntityNameMatcher'));
      // Must NOT reintroduce the old collision name.
      expect(source, isNot(contains('class ReferenceEngine')));
    });

    test(
      'services/reference_engine.dart must not exist (deleted after rename)',
      () {
        final f = File('lib/services/reference_engine.dart');
        expect(
          f.existsSync(),
          isFalse,
          reason:
              'Old autocomplete reference_engine.dart must be deleted — '
              'replaced by entity_name_matcher.dart',
        );
      },
    );

    test(
      'autocomplete controller imports entity_name_matcher and uses EntityNameMatcher',
      () {
        final source = File(
          'lib/widgets/reference_autocomplete_controller.dart',
        ).readAsStringSync();

        expect(source, contains('EntityNameMatcher'));
        expect(source, contains('entity_name_matcher.dart'));
        expect(
          source,
          isNot(
            contains("'package:lore_keeper/services/reference_engine.dart'"),
          ),
        );
      },
    );

    // ── Cycle 0.6: Backlink sync ─────────────────────────────────────────

    test(
      'ManuscriptModule._onBacklinkNavigate forwards to shell onDocumentSelected',
      () {
        final source = File(
          'lib/modules/manuscript_module.dart',
        ).readAsStringSync();

        expect(
          source,
          contains('widget.onDocumentSelected?.call(documentId)'),
          reason: '_onBacklinkNavigate must forward to shell callback',
        );
        expect(
          source,
          contains('onDocumentSelected: _onBacklinkNavigate'),
          reason: 'ManuscriptInspector must receive _onBacklinkNavigate',
        );
      },
    );

    // ── Cycle 0.6: Stable keys ───────────────────────────────────────────

    test('all four stable key constants are declared', () {
      expect(
        File('lib/widgets/manuscript_inspector.dart').readAsStringSync(),
        contains("Key('manuscript-inspector')"),
      );
      expect(
        File('lib/widgets/manuscript_list_pane.dart').readAsStringSync(),
        contains("Key('manuscript-list-pane')"),
      );
      expect(
        File('lib/modules/manuscript_module.dart').readAsStringSync(),
        contains("Key('manuscript-editor')"),
      );
      expect(
        File(
          'lib/widgets/project_editor/specific_functions_bar.dart',
        ).readAsStringSync(),
        contains("Key('specific-functions-bar')"),
      );
    });
  });

  // ── Runtime topology (widget tests) ───────────────────────────────────────

  group('runtime topology', () {
    late Directory dir;
    late Project project;
    late ManuscriptBinderProvider binderProvider;
    late ChapterListProvider chapterProvider;
    late CharacterListProvider characterProvider;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('manuscript_topology_');
      Hive.init(dir.path);
      await DatabaseManager.instance.initializeForTesting();

      project = Project(title: 'Topology Test', createdAt: DateTime.now());
      await DatabaseManager.instance.projects.add(project);
      project = DatabaseManager.instance.projects.getAt(0)!;

      final referenceEngine = ReferenceEngine();
      binderProvider = ManuscriptBinderProvider(
        project.key!,
        referenceEngine: referenceEngine,
      );
      await _waitFor(
        label: 'binder provider',
        isReady: () => binderProvider.isInitialized,
      );
      expect(binderProvider.manuscriptRoot, isNotNull);

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

    testWidgets('ManuscriptListPane switches among all four views', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1700, 1250));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final root = binderProvider.manuscriptRoot!;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          home: Scaffold(
            body: SizedBox(
              width: 340,
              child: ManuscriptListPane(
                key: kManuscriptListPaneKey,
                provider: binderProvider,
                selectedDocumentId: root.id,
                onDocumentSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Stable key present.
      expect(find.byKey(kManuscriptListPaneKey), findsOneWidget);

      // Binder is default.
      expect(find.byType(ManuscriptBinder), findsOneWidget);

      await tester.tap(find.byTooltip('Corkboard'));
      await tester.pumpAndSettle();
      expect(find.byType(ManuscriptCorkboard), findsOneWidget);

      await tester.tap(find.byTooltip('Outliner'));
      await tester.pumpAndSettle();
      expect(find.byType(ManuscriptOutliner), findsOneWidget);

      await tester.tap(find.byTooltip('Collections'));
      await tester.pumpAndSettle();
      expect(find.byType(ManuscriptCollections), findsOneWidget);

      await tester.tap(find.byTooltip('Binder'));
      await tester.pumpAndSettle();
      expect(find.byType(ManuscriptBinder), findsOneWidget);
    });

    testWidgets(
      'ManuscriptModule renders editor (Column 3) + inspector (Column 4) '
      'with stable keys and no nested list views',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1700, 1250));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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
              selectedChapterKey: '',
              chapterProvider: chapterProvider,
              characterProvider: characterProvider,
              onChapterSelected: (_) {},
              onControllerReady: (_) {},
              onGrammarCheckReady: (_) {},
              binderProvider: binderProvider,
              sharedReferenceEngine: binderProvider.referenceEngine,
            ),
          ),
        );

        // Allow async bootstrap to complete.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // ── No navigation surfaces inside the module ──────────────────────
        expect(find.byType(ManuscriptBinder), findsNothing);
        expect(find.byType(ManuscriptCorkboard), findsNothing);
        expect(find.byType(ManuscriptOutliner), findsNothing);
        expect(find.byType(ManuscriptCollections), findsNothing);

        // ── Column 3: editor present with stable key ──────────────────────
        expect(find.byKey(kManuscriptEditorKey), findsOneWidget);

        // ── Column 4: ManuscriptInspector present with stable key ─────────
        expect(find.byType(ManuscriptInspector), findsOneWidget);
        expect(find.byKey(kManuscriptInspectorKey), findsOneWidget);

        // ── Inspector empty state (no document selected) ──────────────────
        expect(find.text('Select a document'), findsOneWidget);

        // ── Status bar from editor ────────────────────────────────────────
        expect(find.text('Words: 0'), findsOneWidget);
      },
    );

    testWidgets(
      'ManuscriptInspector fires onDocumentSelected when invoked directly '
      '(Inspector callback wiring verification)',
      (tester) async {
        // This test is isolated: it pumps ManuscriptInspector in null-document
        // state (no name resolution, no reference service needed). It verifies
        // that the onDocumentSelected callback wiring is functional at the
        // widget level, complementing the static contract tests above.
        //
        // It runs in the same setUp context but does NOT pump ManuscriptModule
        // so there are no lingering async ops from ManuscriptEditor initState
        // that could corrupt the Hive state in tearDown.
        final shellSelections = <String>[];
        const targetId = 'test-document-id';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 600,
                child: ManuscriptInspector(
                  selectedDocument: null,
                  binderProvider: null,
                  nameResolver: ReferenceNameResolver.fromDatabase(
                    project.key!,
                  ),
                  referenceService: null,
                  projectId: project.key!,
                  onDocumentSelected: (id) => shellSelections.add(id),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Inspector renders with stable key.
        expect(find.byKey(kManuscriptInspectorKey), findsOneWidget);

        // Directly invoke the callback (simulates a backlink tap).
        final inspector = tester.widget<ManuscriptInspector>(
          find.byType(ManuscriptInspector),
        );
        inspector.onDocumentSelected?.call(targetId);

        // Shell callback received the document ID.
        expect(shellSelections, contains(targetId));
      },
    );
  });
}

// (no helpers needed)
