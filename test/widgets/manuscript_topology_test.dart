/// Manuscript Workspace Topology regression tests (Cycle 0.5).
///
/// The canonical Manuscript workspace topology is:
///   Column 2 → [ManuscriptListPane]  (the single host of Binder / Corkboard /
///              Outliner / Collections, with its own view-switcher header)
///   Column 3 → [ManuscriptEditor]    (the Quill editor)
///   Column 4 → Inspector panel
///
/// Historically `ManuscriptModule`/`ManuscriptEditor` echoed a second nested
/// left panel (a `_LeftPanelMode`-driven `_buildLeftPanel()`) rendering an
/// additional Binder/Corkboard/Outliner/Collections plus its own view switcher.
/// These tests pin the corrected topology so the duplicate cannot regress:
/// the four list views may be instantiated only by [ManuscriptListPane].
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
import 'package:lore_keeper/widgets/manuscript_list_pane.dart';
import 'package:lore_keeper/widgets/manuscript_outliner.dart';

// ---------------------------------------------------------------------------
// Static architecture contract
// ---------------------------------------------------------------------------

void main() {
  group('static topology contract', () {
    test('ManuscriptModule/ManuscriptEditor no longer defines the legacy left '
        'panel architecture', () {
      final source = File(
        'lib/modules/manuscript_module.dart',
      ).readAsStringSync();

      expect(source, contains('class ManuscriptModule'));
      expect(source, contains('class ManuscriptEditor'));

      // The nested navigation architecture must be gone.
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
  });

  // -------------------------------------------------------------------------
  // Runtime topology (widget tests)
  // -------------------------------------------------------------------------

  group('runtime topology', () {
    late Directory dir;
    late Project project;
    late ManuscriptBinderProvider binderProvider;
    late ChapterListProvider chapterProvider;
    late CharacterListProvider characterProvider;

    /// Waits (bounded) for a provider to finish its async bootstrap.
    Future<void> waitFor<T>({
      required String label,
      required bool Function() isReady,
    }) async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!isReady() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(isReady(), isTrue, reason: '$label did not initialize');
    }

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
      await waitFor(
        label: 'binder provider',
        isReady: () => binderProvider.isInitialized,
      );
      expect(binderProvider.manuscriptRoot, isNotNull);

      // The chapter/character providers' async bootstrap must complete here,
      // in setUp's real-async zone, so no fire-and-forget load chain is left
      // running after the widget test ends (which would hit closed Hive boxes).
      chapterProvider = ChapterListProvider(project.key!);
      await waitFor(
        label: 'chapter provider',
        isReady: () => chapterProvider.isInitialized,
      );
      characterProvider = CharacterListProvider(
        project.key!,
        referenceEngine: referenceEngine,
      );
      await waitFor(
        label: 'character provider',
        isReady: () => characterProvider.isInitialized,
      );
    });

    tearDown(() async {
      await DatabaseManager.instance.close();
      await Hive.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {
        // Best-effort cleanup; the temp dir may already be locked.
      }
    });

    testWidgets('ManuscriptListPane switches among all four views', (
      tester,
    ) async {
      // A desktop-sized content area gives the pane enough vertical room.
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
                provider: binderProvider,
                selectedDocumentId: root.id,
                onDocumentSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Binder is the default view.
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
      'ManuscriptModule renders editor + inspector with no nested list views',
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

        // Let the editor's async bootstrap (binder select, reference index
        // rebuild, content load) settle.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.byType(ManuscriptBinder), findsNothing);
        expect(find.byType(ManuscriptCorkboard), findsNothing);
        expect(find.byType(ManuscriptOutliner), findsNothing);
        expect(find.byType(ManuscriptCollections), findsNothing);

        // Column 3 (editor) and Column 4 (inspector) are still present.
        expect(find.text('Select a document'), findsOneWidget);
        expect(find.text('Words: 0'), findsOneWidget);
      },
    );
  });
}
