/// MS-011 - replace preserves the matched span's Quill attributes.
///
/// Cycle 5. These tests pin the *attribute* half of find & replace. The
/// offset half is MS-012 and lives in `manuscript_find_replace_test.dart`.
///
/// The behaviour under test was established by observation, not from the B5
/// trace, which had the mechanism backwards - see CYCLE_LOG.md Cycle 5.
library;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/widgets/find_replace_dialog.dart';

/// Builds a controller over [doc].
QuillController _ctl(Document doc) => QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

/// A `ref:` mention over the first word, plain prose after it.
Document _mentionDoc() => Document.fromDelta(
      Delta()
        ..insert('Eryll', {'link': 'ref:Character:7'})
        ..insert(' walked home\n'),
    );

/// Selects `[offset, offset + length)` the way the dialog's Find does.
void _select(QuillController c, int offset, int length) => c.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + length),
      ChangeSource.local,
    );

/// The attribute map covering the single character at [offset].
///
/// `collectStyle` reports the attributes that apply across the whole range, so
/// a one-character range is an exact "what is this character formatted with?"
/// query - which is what lets these tests assert about a specific character
/// rather than about the line it happens to sit on.
Map<String, dynamic> _attributesAt(QuillController c, int offset) =>
    c.document
        .collectStyle(offset, 1)
        .attributes
        .map((k, v) => MapEntry(k, v.value));

/// Runs the dialog's own Replace button end-to-end.
Future<void> _replaceVia(
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
  // Find, then Replace - the selection-driven contract of the Replace button.
  await tester.tap(find.widgetWithText(TextButton, 'Find'));
  await tester.pump();
  await tester.tap(find.widgetWithText(TextButton, 'Replace'));
  await tester.pump();
}

void main() {
  group('MS-011 - replace preserves attributes on the replaced span', () {
    testWidgets('a ref: mention next to a plain word is untouched by a '
        'replacement of that plain word', (tester) async {
      final controller = _ctl(_mentionDoc());

      // "Eryll"(0-5, linked) + " walked home\n". "walked" is 6..12, plain.
      _select(controller, 6, 6);
      await _replaceVia(tester, controller, 'walked', 'ran');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Eryll ran home\n');
      // The mention keeps its link...
      expect(
        _attributesAt(controller, 0)['link'],
        'ref:Character:7',
        reason: 'the mention adjacent to the edit must be untouched',
      );
      // ...and the new text must not have inherited anything from the
      // deletion it performed.
      expect(
        _attributesAt(controller, 7),
        isEmpty,
        reason: '"ran" was never attributed, so nothing may leak onto it',
      );
    });

    testWidgets('replacing the mention text keeps the mention', (
      tester,
    ) async {
      final controller = _ctl(_mentionDoc());

      _select(controller, 0, 5);
      await _replaceVia(tester, controller, 'Eryll', 'Aria');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Aria walked home\n');
      expect(
        _attributesAt(controller, 0)['link'],
        'ref:Character:7',
        reason: 'MS-011: the replaced span was attributed, so the '
            'replacement inherits exactly that attribute set',
      );
      expect(
        _attributesAt(controller, 5),
        isEmpty,
        reason: 'the following plain run must not be swept up',
      );
    });

    testWidgets('every attribute on the span is preserved, not just link', (
      tester,
    ) async {
      final doc = Document.fromDelta(
        Delta()
          ..insert('Eryll', {'link': 'ref:Character:7', 'bold': true})
          ..insert(' walked\n'),
      );
      final controller = _ctl(doc);

      _select(controller, 0, 5);
      await _replaceVia(tester, controller, 'Eryll', 'Aria');
      await tester.pumpAndSettle();

      final at = _attributesAt(controller, 0);
      expect(at['link'], 'ref:Character:7');
      expect(at['bold'], isTrue, reason: 'MS-011 says preserve whatever was '
          'actually there, not just the link');
    });
  });

  group('MS-011 - replacing part of an attributed span', () {
    // The judgment call, stated here and in the log: the attribute set of the
    // *matched range* is what the replacement gets. Replacing a strict
    // sub-span of a mention therefore keeps the mention alive on the
    // remainder plus the new text, because a user editing the middle of a
    // mention name is still referring to that entity.
    testWidgets('a sub-span of a mention keeps the mention', (
      tester,
    ) async {
      final controller = _ctl(_mentionDoc());

      // "yll" = offsets 2..5, strictly inside the linked run.
      _select(controller, 2, 3);
      await _replaceVia(tester, controller, 'yll', 'z');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'Erz walked home\n');
      expect(
        _attributesAt(controller, 0)['link'],
        'ref:Character:7',
        reason: 'replacing inside an attributed span preserves the attribute',
      );
      // The replacement itself is inside the mention, so it is attributed.
      expect(_attributesAt(controller, 2)['link'], 'ref:Character:7');
      // The plain run after the mention stays plain.
      expect(
        _attributesAt(controller, 4),
        isEmpty,
        reason: 'the plain run after the mention must not be swept up',
      );
    });

    testWidgets('a match that straddles a formatting boundary does NOT '
        'inherit the leading run attributes', (tester) async {
      // This is the case the B5 trace missed in the other direction: Quill's
      // insert inherits the attributes of the character at the start index,
      // so a match spanning "ll wa" silently extended the mention's link onto
      // the new text.
      final controller = _ctl(_mentionDoc());

      // "Eryll walked home\n" - offsets 3..8 are "ll wa", which spans the
      // linked run and the plain run.
      _select(controller, 3, 5);
      await _replaceVia(tester, controller, 'll wa', 'X');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'EryXlked home\n');
      expect(
        _attributesAt(controller, 3),
        isEmpty,
        reason: 'the matched range was not uniformly attributed, so the '
            'replacement must be plain rather than inherit the link',
      );
      expect(
        _attributesAt(controller, 0)['link'],
        'ref:Character:7',
        reason: 'the surviving part of the mention is still a mention',
      );
    });
  });

  group('MS-011 - a run that is not a mention is treated the same way', () {
    testWidgets('straddling a bold boundary does not inherit bold', (
      tester,
    ) async {
      final doc = Document.fromDelta(
        Delta()
          ..insert('loud ', {'bold': true})
          ..insert('quiet home\n'),
      );
      final controller = _ctl(doc);

      // Offsets 2..6 = "ud q", spanning bold and plain.
      _select(controller, 2, 4);
      await _replaceVia(tester, controller, 'ud q', 'X');
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'loXuiet home\n');
      expect(
        _attributesAt(controller, 2),
        isEmpty,
        reason: 'the matched range was mixed, so bold must not leak',
      );
      expect(_attributesAt(controller, 0)['bold'], isTrue);
    });
  });
}
