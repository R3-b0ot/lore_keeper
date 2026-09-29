/// MS-013 - Find navigates between matches, wraps, and reports a count.
///
/// Cycle 5. The old `_performFind` ran `searchText.indexOf(pattern)` from
/// offset 0 on every press, so it always jumped to the first match and there
/// was no way to reach the second one - let alone wrap, and there was no count
/// anywhere in the dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/widgets/find_replace_dialog.dart';

QuillController _ctl(String text) => QuillController(
      document: Document.fromDelta(Delta()..insert(text)),
      selection: const TextSelection.collapsed(offset: 0),
    );

const _body = 'the cat the dog the bird\n';

/// Mounts the dialog over [controller] and types [query] into the find field.
Future<void> _openWith(WidgetTester tester, QuillController controller,
    {String query = 'the'}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: FindReplaceDialog(controller: controller)),
    ),
  );
  if (query.isNotEmpty) {
    await tester.enterText(find.byType(TextField).first, query);
  }
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(TextButton, label));
  await tester.pump();
}

TextSelection _sel(QuillController c) => c.selection;

void main() {
  group('MS-013 - Find advances and wraps', () {
    testWidgets('repeated Find walks every match then wraps to the first', (
      tester,
    ) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 0);
      expect(_sel(controller).extentOffset, 3);

      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 8);

      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 16);

      await _tap(tester, 'Find');
      expect(
        _sel(controller).baseOffset,
        0,
        reason: 'MS-013: past the last match, wrap to the first',
      );
    });

    testWidgets('the count updates at every step', (tester) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      expect(find.text('3 results'), findsOneWidget);

      await _tap(tester, 'Find');
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('3 results'), findsNothing);

      await _tap(tester, 'Find');
      expect(find.text('2 of 3'), findsOneWidget);

      await _tap(tester, 'Find');
      expect(find.text('3 of 3'), findsOneWidget);

      await _tap(tester, 'Find');
      expect(find.text('1 of 3'), findsOneWidget);
    });

    testWidgets('the selected text is the match, not the whole document', (
      tester,
    ) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      await _tap(tester, 'Find');
      expect(
        controller.document.toPlainText().substring(8, 11),
        'the',
      );
      expect(_sel(controller).start, 8);
      expect(_sel(controller).end, 11);
    });
  });

  group('MS-013 - Previous navigation', () {
    testWidgets('Previous from the first match wraps to the last', (
      tester,
    ) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 0);

      await _tap(tester, 'Previous');
      expect(
        _sel(controller).baseOffset,
        16,
        reason: 'MS-013: before the first match, wrap to the last',
      );
      expect(find.text('3 of 3'), findsOneWidget);
    });

    testWidgets('Previous walks backwards and wraps forwards', (
      tester,
    ) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      await _tap(tester, 'Find');
      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 16);

      await _tap(tester, 'Previous');
      expect(_sel(controller).baseOffset, 8);
      await _tap(tester, 'Previous');
      expect(_sel(controller).baseOffset, 0);
      await _tap(tester, 'Previous');
      expect(_sel(controller).baseOffset, 16);
    });
  });

  group('MS-013 - the count reacts to the query and the case toggle', () {
    testWidgets('a query with no matches says so', (tester) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller, query: 'zebra');

      expect(find.text('No results'), findsOneWidget);

      await _tap(tester, 'Find');
      await _tap(tester, 'Previous');
      // Nothing to select, so the selection is left alone.
      expect(_sel(controller).isValid, isTrue);
      expect(find.text('No results'), findsOneWidget);
    });

    testWidgets('editing the query resets the selection', (tester) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 8);
      expect(find.text('2 of 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'dog');
      await tester.pump();
      expect(find.text('1 result'), findsOneWidget);
    });

    testWidgets('the case toggle changes what counts as a match', (
      tester,
    ) async {
      final controller = _ctl('The cat the dog\n');
      await _openWith(tester, controller, query: 'the');

      // Default is case-insensitive, so "The" counts too.
      expect(find.text('2 results'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(find.text('1 result'), findsOneWidget);
      await _tap(tester, 'Find');
      expect(_sel(controller).baseOffset, 8);
    });

    testWidgets('an empty query shows no count at all', (tester) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller, query: '');

      expect(find.textContaining('of '), findsNothing);
      expect(find.text('No results'), findsNothing);
    });
  });

  group('MS-013 - the count stays truthful after an edit', () {
    testWidgets('Replace drops the stale "n of m" instead of keeping it', (
      tester,
    ) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      await _tap(tester, 'Find');
      await _tap(tester, 'Find');
      expect(find.text('3 of 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'owl');
      await tester.pump();
      await _tap(tester, 'Replace');
      await tester.pump();

      // The third "the" (at offset 16) was selected, so that is the one that
      // changed. Two matches remain, so showing "3 of 3" would be a lie about
      // the document.
      expect(find.text('3 of 3'), findsNothing);
      expect(find.text('2 results'), findsOneWidget);
      expect(
        controller.document.toPlainText(),
        'the cat the dog owl bird\n',
      );
    });

    testWidgets('Replace All drops the stale "n of m"', (tester) async {
      final controller = _ctl(_body);
      await _openWith(tester, controller);

      await _tap(tester, 'Find');
      expect(find.text('1 of 3'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'owl');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Replace All'));
      await tester.pump();

      expect(find.text('1 of 3'), findsNothing);
      expect(find.text('No results'), findsOneWidget);
    });
  });
}
