/// Corkboard reorder regression test — Cycle 0.6 (spec §7 / P1-2 fix).
///
/// Verifies that ManuscriptCorkboard reorders use the canonical
/// ManuscriptBinderProvider.reorderDocument() path so that:
///   - Corkboard order matches provider order after reorder
///   - Binder sees the same order
///   - Persisted order survives a provider reload
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/database_manager.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/manuscript_binder_provider.dart';

void main() {
  late Directory dir;
  late Project project;
  late ManuscriptBinderProvider binderProvider;

  Future<void> waitForReady() async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!binderProvider.isInitialized && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(binderProvider.isInitialized, isTrue);
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('corkboard_reorder_');
    Hive.init(dir.path);
    await DatabaseManager.instance.initializeForTesting();

    project = Project(title: 'Reorder Test', createdAt: DateTime.now());
    await DatabaseManager.instance.projects.add(project);
    project = DatabaseManager.instance.projects.getAt(0)!;

    binderProvider = ManuscriptBinderProvider(
      project.key!,
      referenceEngine: ReferenceEngine(),
    );
    await waitForReady();
    expect(binderProvider.manuscriptRoot, isNotNull);
  });

  tearDown(() async {
    await DatabaseManager.instance.close();
    await Hive.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  group('Corkboard canonical reorder path', () {
    test('reorderDocument updates provider sibling order correctly', () async {
      final root = binderProvider.manuscriptRoot!;

      // Create three siblings.
      final alpha = await binderProvider.createChild(
        parentId: root.id,
        title: 'Alpha',
        type: ManuscriptDocumentType.scene,
      );
      await binderProvider.createChild(
        parentId: root.id,
        title: 'Beta',
        type: ManuscriptDocumentType.scene,
      );
      await binderProvider.createChild(
        parentId: root.id,
        title: 'Gamma',
        type: ManuscriptDocumentType.scene,
      );

      // Verify initial order: Alpha(0) Beta(1) Gamma(2)
      var children = binderProvider.getChildren(root.id);
      expect(children.map((d) => d.title).toList(), ['Alpha', 'Beta', 'Gamma']);

      // Move Alpha to the last position.
      // reorderDocument(alpha.id, 3) → adjustedIndex = 3-1 = 2 → Beta Gamma Alpha.
      await binderProvider.reorderDocument(alpha.id, 3);

      children = binderProvider.getChildren(root.id);
      final titles = children.map((d) => d.title).toList();
      expect(titles.length, 3);
      // Alpha moved to the end.
      expect(titles.last, 'Alpha');
      expect(titles.first, 'Beta');
    });

    test(
      'reorderDocument persists: new ManuscriptBinderProvider sees updated order',
      () async {
        final root = binderProvider.manuscriptRoot!;

        final a = await binderProvider.createChild(
          parentId: root.id,
          title: 'First',
          type: ManuscriptDocumentType.scene,
        );
        await binderProvider.createChild(
          parentId: root.id,
          title: 'Second',
          type: ManuscriptDocumentType.scene,
        );
        await binderProvider.createChild(
          parentId: root.id,
          title: 'Third',
          type: ManuscriptDocumentType.scene,
        );

        // Verify initial order.
        var children = binderProvider.getChildren(root.id);
        expect(children[0].title, 'First');
        expect(children[1].title, 'Second');
        expect(children[2].title, 'Third');

        // Move 'First' to after 'Second': reorderDocument uses the same index
        // semantics as ReorderableListView — newIndex is the target slot index
        // in the list BEFORE removal, so moving down requires +1 offset.
        // reorderDocument(a.id, 2) → adjustedIndex = 2-1 = 1 → order: Second First Third.
        await binderProvider.reorderDocument(a.id, 2);

        // Order is now updated in provider.
        children = binderProvider.getChildren(root.id);
        expect(children[0].title, 'Second');
        expect(children[1].title, 'First');
        expect(children[2].title, 'Third');

        // Create a fresh provider to verify persistence.
        final freshProvider = ManuscriptBinderProvider(
          project.key!,
          referenceEngine: ReferenceEngine(),
        );
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!freshProvider.isInitialized &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(freshProvider.isInitialized, isTrue);

        final persistedChildren = freshProvider.getChildren(root.id);
        expect(persistedChildren[0].title, 'Second');
        expect(persistedChildren[1].title, 'First');
        expect(persistedChildren[2].title, 'Third');
      },
    );

    test(
      'corkboard reorder source contract: _onReorder uses provider.reorderDocument',
      () {
        // Static contract: the Corkboard's _onReorder must call
        // widget.provider.reorderDocument rather than the old manual loop.
        final source = File(
          'lib/widgets/manuscript_corkboard.dart',
        ).readAsStringSync();

        expect(
          source,
          contains('widget.provider.reorderDocument'),
          reason:
              'Corkboard _onReorder must use canonical reorderDocument (spec §7 / P1-2 fix)',
        );
        // Must NOT contain the old manual orderIndex loop.
        expect(
          source,
          isNot(contains('_cards[i].orderIndex = i')),
          reason: 'Old manual orderIndex assignment must be removed',
        );
      },
    );
  });
}
