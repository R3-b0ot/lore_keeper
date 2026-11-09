/// MS-012 - Replace All uses live document coordinates.
///
/// Cycle 5. The old `_replaceAll` searched a plain-text snapshot taken before
/// any edit while mutating the live document, so every replacement whose length
/// differed from the query shifted the coordinates of the ones still to come.
/// It also crashed outright on a shorter replacement and on an empty one.
///
/// Replace-all here is driven through the dialog's own button, not through a
/// copy of the algorithm, so these tests fail for the same reason the user
/// would see it fail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/widgets/find_replace_dialog.dart';

QuillController _ctl(Document doc) => QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

Document _plain(String text) => Document.fromDelta(Delta()..insert(text));

Map<String, dynamic> _attributesAt(QuillController c, int offset) =>
    c.document
        .collectStyle(offset, 1)
        .attributes
        .map((k, v) => MapEntry(k, v.value));

/// Mounts the dialog, types the query, and presses Replace All.
Future<void> _replaceAllVia(
  WidgetTester tester,
  QuillController controller,
  String query,
  String replacement,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: FindReplaceDialog(controller: controller)),
    ),
  );
  await tester.enterText(find.byType(TextField).first, query);
  await tester.enterText(find.byType(TextField).last, replacement);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Replace All'));
  await tester.pump();
}

void main() {
  group('MS-012 - replace-all does not drift', () {
    testWidgets('the drift case: replacement longer than the query', (
      tester,
    ) async {
      // Substring semantics, so the "a" inside "cat" and "and" count too.
      final controller = _ctl(_plain('a cat and a dog\n'));

      await _replaceAllVia(tester, controller, 'a', 'bbb');
      await tester.pumpAndSettle();

      expect(
        controller.document.toPlainText(),
        'bbb cbbbt bbbnd bbb dog\n',
      );
    });

    testWidgets('same-length replacement', (tester) async {
      final controller = _ctl(_plain('a cat and a dog\n'));

      await _replaceAllVia(tester, controller, 'a', 'A');
      await tester.pumpAndSettle();

      // No drift is even possible here, which makes it the control case.
      expect(controller.document.toPlainText(), 'A cAt And A dog\n');
    });

    testWidgets('replacement shorter than the query, multiple matches', (
      tester,
    ) async {
      final controller = _ctl(_plain('cat cat cat\n'));

      await _replaceAllVia(tester, controller, 'cat', 'x');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'x x x\n');
    });

    testWidgets('an empty replacement is a pure deletion and does not crash', (
      tester,
    ) async {
      final controller = _ctl(_plain('cat cat cat\n'));

      await _replaceAllVia(tester, controller, 'cat', '');
      await tester.pumpAndSettle();

      // The three "cat"s go; the two separating spaces stay.
      expect(controller.document.toPlainText(), '  \n');
    });

    testWidgets('the drift case repeated three times in a row is stable', (
      tester,
    ) async {
      final controller = _ctl(_plain('a cat and a dog\n'));

      await _replaceAllVia(tester, controller, 'a', 'bbb');
      await tester.pumpAndSettle();
      expect(controller.document.toPlainText(), 'bbb cbbbt bbbnd bbb dog\n');

      // Running it again on the new text must still be correct, i.e. the four
      // "a" positions are recomputed rather than carried over.
      await _replaceAllVia(tester, controller, 'b', 'z');
      await tester.pumpAndSettle();
      expect(controller.document.toPlainText(), 'zzz czzzt zzznd zzz dog\n');
    });

    testWidgets('an empty query replaces nothing', (tester) async {
      final controller = _ctl(_plain('a cat and a dog\n'));

      await _replaceAllVia(tester, controller, '', 'x');
      await tester.pumpAndSettle();

      expect(
        controller.document.toPlainText(),
        'a cat and a dog\n',
        reason: 'a zero-length query would otherwise match everywhere',
      );
    });

    testWidgets('overlapping candidates do not both match', (tester) async {
      // "aa" occurs at 0 and 1, but matching must be non-overlapping or
      // replace-all would rewrite text it had just produced.
      final controller = _ctl(_plain('aaa\n'));

      await _replaceAllVia(tester, controller, 'aa', 'b');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'ba\n');
    });
  });

  group('MS-012 - replace-all preserves attributes on every occurrence', () {
    testWidgets('every replaced mention keeps its link, not just the first', (
      tester,
    ) async {
      // Two mentions, each followed by the query word "walked". The first
      // occurrence and the second must both keep their ref: link, and the
      // plain "walked" runs must not acquire one.
      final doc = Document.fromDelta(
        Delta()
          ..insert('Aiden', {'link': 'ref:Character:1'})
          ..insert(' walked ')
          ..insert('Lyra', {'link': 'ref:Character:2'})
          ..insert(' walked home\n'),
      );
      final controller = _ctl(doc);

      await _replaceAllVia(tester, controller, 'walked', 'ran');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Aiden ran Lyra ran home\n');
      expect(
        _attributesAt(controller, 0)['link'],
        'ref:Character:1',
        reason: 'the first mention is untouched',
      );
      expect(
        _attributesAt(controller, 6),
        isEmpty,
        reason: 'the first replaced "walked" was plain and must stay plain',
      );
      expect(
        _attributesAt(controller, 10)['link'],
        'ref:Character:2',
        reason: 'the second mention is untouched',
      );
      expect(
        _attributesAt(controller, 16),
        isEmpty,
        reason: 'MS-012: the LAST replaced occurrence must be treated the '
            'same as the first, not inherit the link from its neighbour',
      );
    });

    testWidgets('replacing a mention on every occurrence keeps every link', (
      tester,
    ) async {
      final doc = Document.fromDelta(
        Delta()
          ..insert('Aiden', {'link': 'ref:Character:1'})
          ..insert(' and ')
          ..insert('Lyra', {'link': 'ref:Character:2'})
          ..insert(' and more\n'),
      );
      final controller = _ctl(doc);

      // Same length, so any failure here is about attributes or ordering,
      // not about drift.
      await _replaceAllVia(tester, controller, 'and', 'AND');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Aiden AND Lyra AND more\n');
      expect(_attributesAt(controller, 0)['link'], 'ref:Character:1');
      expect(_attributesAt(controller, 6), isEmpty);
      expect(_attributesAt(controller, 10)['link'], 'ref:Character:2');
      expect(_attributesAt(controller, 16), isEmpty);
    });

    testWidgets('an empty replacement inside a mention leaves the rest linked',
        (tester) async {
      final doc = Document.fromDelta(
        Delta()
          ..insert('Aiden', {'link': 'ref:Character:1'})
          ..insert(' walked home\n'),
      );
      final controller = _ctl(doc);

      // Delete every "d": one from "Aiden", one from "walked".
      await _replaceAllVia(tester, controller, 'd', '');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Aien walke home\n');
      expect(
        _attributesAt(controller, 0)['link'],
        'ref:Character:1',
        reason: 'deleting a character from a mention must not unlink it',
      );
    });
  });
}
