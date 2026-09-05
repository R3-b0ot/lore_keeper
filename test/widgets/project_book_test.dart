// test/widgets/project_book_test.dart
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/project_book/genre_glow.dart';
import 'package:lore_keeper/widgets/project_book/project_book.dart';
import 'package:lore_keeper/widgets/project_book/project_book_view.dart';

BookViewInfo _info({String title = 'The Long Night', double seed = 0.5}) {
  return BookViewInfo(
    title: title,
    genre: 'Fantasy',
    wordCount: '12480',
    time: '2d ago',
    glow: GenreGlowRegistry.styleFor('Fantasy'),
    seed: seed,
  );
}

void main() {
  group('GenreGlowRegistry', () {
    test('resolves full dialog genre labels to their palettes', () {
      expect(
        GenreGlowRegistry.styleFor('Science Fiction').icon,
        LucideIcons.rocket,
      );
      expect(
        GenreGlowRegistry.styleFor('Crime and Mystery').icon,
        LucideIcons.search,
      );
      expect(GenreGlowRegistry.styleFor('True Crime').icon, LucideIcons.search);
      expect(
        GenreGlowRegistry.styleFor('Historical Fiction').icon,
        LucideIcons.landmark,
      );
      expect(GenreGlowRegistry.styleFor('Fantasy').icon, LucideIcons.sparkles);
    });

    test('falls back to the gilded default for unknown or empty genres', () {
      expect(GenreGlowRegistry.styleFor(null).icon, LucideIcons.bookOpen);
      expect(GenreGlowRegistry.styleFor('  ').icon, LucideIcons.bookOpen);
      expect(
        GenreGlowRegistry.styleFor('My Custom Genre').icon,
        LucideIcons.bookOpen,
      );
    });

    test('exact registration wins over keyword matching', () {
      GenreGlowRegistry.register(
        'noir fantasy',
        const GenreGlowStyle(
          coverColors: [Color(0xFF000000), Color(0xFF111111)],
          core: Color(0xFFFFFFFF),
          mid: Color(0xFF888888),
          edge: Color(0xFF222222),
          accent: Color(0xFFFFFFFF),
          particleColor: Color(0xFFFFFFFF),
          svgType: 'shield',
          icon: LucideIcons.shield,
        ),
      );
      expect(
        GenreGlowRegistry.styleFor('noir fantasy').icon,
        LucideIcons.shield,
      );
    });
  });

  group('ProjectBookView', () {
    Future<void> pumpBook(WidgetTester tester, {required double open}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 260,
              height: 340,
              child: ProjectBookView(info: _info(), openAngle: open),
            ),
          ),
        ),
      );
    }

    testWidgets('renders at rest without errors', (tester) async {
      await pumpBook(tester, open: 0);
      expect(tester.takeException(), isNull);
      expect(find.byType(ProjectBookView), findsOneWidget);
    });

    testWidgets('renders fully open without errors', (tester) async {
      await pumpBook(tester, open: 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('ProjectBook', () {
    Widget harness(Widget child) => MaterialApp(
      home: Center(child: SizedBox(width: 260, height: 340, child: child)),
    );

    Project project() => Project(
      title: 'The Long Night',
      createdAt: DateTime.now(),
      genre: 'Fantasy',
    );

    testWidgets('is static at rest and cracks open on hover', (tester) async {
      await tester.pumpWidget(harness(ProjectBook(project: project())));

      // Resting state: cover fully closed.
      var view = tester.widget<ProjectBookView>(find.byType(ProjectBookView));
      expect(view.openAngle, 0.0);

      // The book is a 260x340 box centered in the 800x600 surface, so its
      // center is (400, 300).
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(const Offset(400, 300));
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('tap pushes the opening route and reveals the destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          ProjectBook(
            project: project(),
            destinationBuilder: (_) =>
                const Scaffold(body: Center(child: Text('workspace'))),
          ),
        ),
      );

      await tester.tap(find.byType(ProjectBook));
      // The route's first frame mounts it; the next frame advances the opening
      // so the overlay renders a second copy of the book over the card.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ProjectBookView), findsNWidgets(2));

      // The 1200ms open+zoom transition completes into the destination.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('destination is deferred until the book transition completes', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          ProjectBook(
            project: project(),
            destinationBuilder: (_) =>
                const Scaffold(body: Center(child: Text('workspace'))),
          ),
        ),
      );

      await tester.tap(find.byType(ProjectBook));
      await tester.pump();
      // Mid-transition (~500ms): the book overlay is animating and the heavy
      // destination has NOT been built yet — it must not block the animation.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ProjectBookView), findsNWidgets(2));
      expect(find.text('workspace'), findsNothing);
      expect(tester.takeException(), isNull);

      // Once the book has dissolved, the destination is built exactly once.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('double tap pushes the opening route exactly once', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          ProjectBook(
            project: project(),
            destinationBuilder: (_) =>
                const Scaffold(body: Center(child: Text('workspace'))),
          ),
        ),
      );

      // A double-click: the first tap pushes the opening route, and even with
      // no time between taps the route's non-dismissible barrier already
      // covers the card by the second tap. The open lock (in ProjectBook) and
      // the barrier together must guarantee exactly one navigation — the second
      // tap lands on the barrier and is ignored.
      await tester.tap(find.byType(ProjectBook));
      await tester.tap(find.byType(ProjectBook), warnIfMissed: false);
      await tester.pump();
      await tester.pump();
      expect(find.byType(ProjectBookView), findsNWidgets(2));

      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onOpen override is used and action buttons do not open', (
      tester,
    ) async {
      var settingsTapped = false;
      var deleteTapped = false;
      var opened = false;
      await tester.pumpWidget(
        harness(
          ProjectBook(
            project: project(),
            onSettingsTap: () => settingsTapped = true,
            onDeleteTap: () => deleteTapped = true,
            onOpen: () => opened = true,
          ),
        ),
      );

      await tester.tap(find.byType(ProjectBook));
      expect(opened, isTrue);
      expect(settingsTapped, isFalse);
      expect(deleteTapped, isFalse);
    });

    testWidgets('destination is tappable after the book transition completes '
        '(no invisible pointer-blocking overlay)', (tester) async {
      var destTapped = false;
      await tester.pumpWidget(
        harness(
          ProjectBook(
            project: project(),
            destinationBuilder: (_) => GestureDetector(
              onTap: () => destTapped = true,
              child: const Scaffold(body: Center(child: Text('workspace'))),
            ),
          ),
        ),
      );

      // Open the book and wait for the full transition to complete.
      await tester.tap(find.byType(ProjectBook));
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(find.text('workspace'), findsOneWidget);

      // Tap the destination — must NOT be blocked by a leftover overlay.
      await tester.tap(find.text('workspace'));
      expect(destTapped, isTrue);
    });
  });
}
