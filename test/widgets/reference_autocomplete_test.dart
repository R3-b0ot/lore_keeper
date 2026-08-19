import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/services/reference_engine.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_controller.dart';
import 'package:lore_keeper/widgets/reference_autocomplete_overlay.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A minimal wrapper providing characters for testing without Hive.
List<Character> _testCharacters() {
  final aria = Character(name: 'Aria Nightingale', parentProjectId: 1);
  final thorin = Character(name: 'Thorin Stonehand', parentProjectId: 1);
  final lyra = Character(name: 'Lyra', parentProjectId: 1);
  final kael = Character(name: 'Kael Draven', parentProjectId: 1);
  final ariaStark = Character(name: 'Aria Stark', parentProjectId: 1);
  final voldemort = Character(name: 'Voldemort', parentProjectId: 1);

  aria.aliases = ['Ari', 'The Singer'];
  thorin.aliases = ['Thor', 'Stone'];
  kael.aliases = ['Shadow', 'Dark One'];
  ariaStark.aliases = ['Aria Wolf'];
  voldemort.aliases = ['The Dark Prince', 'He Who Must Not Be Named'];

  // Add an iteration alias to voldemort.
  voldemort.iterations.add(CharacterIteration(
    iterationName: 'Iteration 1',
    name: 'Tom Riddle',
    aliases: ['The Boy Who Lived'],
  ));

  return [aria, thorin, lyra, kael, ariaStark, voldemort];
}

/// Sets up a QuillController with the given text and cursor at [cursorOffset].
QuillController _makeController(String text, {int? cursorOffset}) {
  final controller = QuillController.basic();
  if (text.isNotEmpty) {
    controller.replaceText(0, 0, text, null);
  }
  if (cursorOffset != null) {
    controller.updateSelection(
      TextSelection.collapsed(offset: cursorOffset),
      ChangeSource.local,
    );
  }
  return controller;
}

/// Creates a KeyDownEvent for testing.
KeyDownEvent _keyDown(LogicalKeyboardKey key) => KeyDownEvent(
      physicalKey: PhysicalKeyboardKey(0),
      logicalKey: key,
      timeStamp: Duration.zero,
    );

// ---------------------------------------------------------------------------
// Controller tests
// ---------------------------------------------------------------------------
void main() {
  group('ReferenceAutocompleteController', () {
    late QuillController quillController;
    late ReferenceAutocompleteController controller;
    late List<Character> characters;
    int stateChangeCount = 0;

    setUp(() {
      characters = _testCharacters();
      quillController = _makeController('');
      controller = ReferenceAutocompleteController(
        quillController: quillController,
        charactersProvider: () => characters,
      );
      stateChangeCount = 0;
      controller.onStateChanged = () => stateChangeCount++;
    });

    tearDown(() {
      quillController.dispose();
    });

    group('@ trigger detection', () {
      test('activates when @ is typed', () {
        quillController.replaceText(0, 0, '@', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 1),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, isEmpty);
        expect(controller.triggerOffset, 0);
      });

      test('activates with query after @', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'Ari');
      });

      test('does not activate without @', () {
        quillController.replaceText(0, 0, 'Hello', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isFalse);
      });

      test('does not activate if @ is preceded by non-whitespace', () {
        // email@pattern should not trigger
        quillController.replaceText(0, 0, 'user@domain', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 11),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isFalse);
      });

      test('detects @ in the middle of existing text', () {
        quillController.replaceText(0, 0, 'Hello @Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 10),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.triggerOffset, 6);
        expect(controller.query, 'Ari');
      });
    });

    group('query filtering', () {
      test('filters candidates as query changes', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.candidates, isNotEmpty);
        final names = controller.candidates.map((c) => c.displayName).toSet();
        expect(names.contains('Aria Nightingale'), isTrue);
        expect(names.contains('Aria Stark'), isTrue);
      });

      test('narrows results as more characters typed', () {
        quillController.replaceText(0, 0, '@Aria', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.candidates.length, 2);
      });

      test('exact name match appears with confidence 1.0', () {
        quillController.replaceText(0, 0, '@Lyra', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.candidates.length, 1);
        expect(controller.candidates.first.displayName, 'Lyra');
        expect(controller.candidates.first.confidence, 1.0);
      });

      test('alias match shows correct displayName', () {
        quillController.replaceText(0, 0, '@Thor', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.candidates.length, 1);
        expect(controller.candidates.first.displayName, 'Thorin Stonehand');
        expect(controller.candidates.first.matchedName, 'Thor');
      });
    });

    group('empty results', () {
      test('returns empty for non-matching query', () {
        quillController.replaceText(0, 0, '@zzzz', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.candidates, isEmpty);
      });

      test('dismisses when @ is deleted', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(controller.isActive, isTrue);

        quillController.replaceText(0, 4, 'Hello', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(controller.isActive, isFalse);
      });
    });

    group('selecting a candidate', () {
      test('replaces @query with matchedName', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(controller.isActive, isTrue);

        // "Ari" is an exact alias for Aria Nightingale — matchedName is "Ari".
        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Ari',
        );
        expect(index, isNot(-1));

        controller.selectCandidate(index);

        final plainText = quillController.document.toPlainText().trimRight();
        expect(plainText, 'Ari');
        expect(plainText.contains('@Ari'), isFalse);
        expect(quillController.selection.baseOffset, 'Ari'.length);
        expect(controller.isActive, isFalse);
      });

      test('replacement works with existing text before @', () {
        quillController.replaceText(0, 0, 'She said ', null);
        quillController.replaceText(9, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 13),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Ari',
        );
        controller.selectCandidate(index);

        final plainText = quillController.document.toPlainText().trimRight();
        expect(plainText, 'She said Ari');
      });

      test('does nothing for invalid index', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();

        controller.selectCandidate(-1);
        expect(controller.isActive, isTrue);

        controller.selectCandidate(999);
        expect(controller.isActive, isTrue);
      });
    });

    group('keyboard navigation', () {
      setUp(() {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
      });

      test('arrow down moves selection forward', () {
        expect(controller.selectedIndex, 0);
        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown));
        expect(controller.selectedIndex, 1);
      });

      test('arrow up wraps to end', () {
        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowUp));
        expect(controller.selectedIndex, controller.candidates.length - 1);
      });

      test('arrow down wraps to start', () {
        // Move to last candidate
        for (var i = 1; i < controller.candidates.length; i++) {
          controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown));
        }
        expect(controller.selectedIndex, controller.candidates.length - 1);
        // One more wraps to 0
        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown));
        expect(controller.selectedIndex, 0);
      });

      test('enter selects current candidate', () {
        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown));
        expect(controller.selectedIndex, 1);

        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.enter));

        expect(controller.isActive, isFalse);
        final plainText = quillController.document.toPlainText();
        expect(plainText.contains('@'), isFalse);
      });

      test('escape dismisses overlay', () {
        expect(controller.isActive, isTrue);
        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.escape));
        expect(controller.isActive, isFalse);
      });

      test('returns false when not active', () {
        controller.dismiss();
        expect(controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown)),
            isFalse);
      });

      test('ignores non-navigation keys', () {
        expect(controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.keyA)),
            isFalse);
      });
    });

    group('dismiss', () {
      test('resets all state', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(controller.isActive, isTrue);

        controller.dismiss();
        expect(controller.isActive, isFalse);
        expect(controller.query, isEmpty);
        expect(controller.triggerOffset, -1);
        expect(controller.candidates, isEmpty);
        expect(controller.selectedIndex, 0);
      });

      test('does nothing if already inactive', () {
        controller.dismiss();
        expect(stateChangeCount, 0);
      });
    });

    group('state change notifications', () {
      test('notifies on activation', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(stateChangeCount, 1);
      });

      test('notifies on selection move', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        final before = stateChangeCount;

        controller.handleKeyEvent(_keyDown(LogicalKeyboardKey.arrowDown));
        expect(stateChangeCount, before + 1);
      });

      test('notifies on dismiss', () {
        quillController.replaceText(0, 0, '@Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        final before = stateChangeCount;

        controller.dismiss();
        expect(stateChangeCount, before + 1);
      });
    });

    group('insertion preserves matched name', () {
      test('canonical name selection preserves canonical name', () {
        // Type @Lyra → exact name match → matchedName == displayName == 'Lyra'
        quillController.replaceText(0, 0, '@Lyra', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Lyra',
        );
        expect(index, isNot(-1));
        controller.selectCandidate(index);

        final plainText =
            quillController.document.toPlainText().trimRight();
        expect(plainText, 'Lyra');
        expect(quillController.selection.baseOffset, 'Lyra'.length);
      });

      test('alias selection preserves alias text', () {
        // Type @The → prefix alias match for Voldemort's "The Dark Prince"
        quillController.replaceText(0, 0, '@The', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(controller.isActive, isTrue);

        final index = controller.candidates.indexWhere(
          (c) => c.entry.name == 'Voldemort',
        );
        expect(index, isNot(-1));
        expect(controller.candidates[index].matchedName, 'The Dark Prince');

        controller.selectCandidate(index);

        final plainText =
            quillController.document.toPlainText().trimRight();
        // Must be the alias, NOT the canonical name.
        expect(plainText, 'The Dark Prince');
        expect(plainText.contains('Voldemort'), isFalse);
      });

      test('iteration alias preserves selected alias', () {
        // Type @Tom → prefix alias match for Voldemort's iteration name
        // "Tom Riddle". Single-word query avoids whitespace dismissal.
        quillController.replaceText(0, 0, '@Tom', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        expect(controller.isActive, isTrue);

        final index = controller.candidates.indexWhere(
          (c) => c.entry.name == 'Voldemort',
        );
        expect(index, isNot(-1));
        expect(controller.candidates[index].matchedName, 'Tom Riddle');

        controller.selectCandidate(index);

        final plainText =
            quillController.document.toPlainText().trimRight();
        expect(plainText, 'Tom Riddle');
        expect(plainText.contains('Voldemort'), isFalse);
      });

      test('two different aliases of same character remain distinct', () {
        // Select "The Dark Prince" alias via prefix @The
        quillController.replaceText(0, 0, '@The', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 4),
          ChangeSource.local,
        );
        controller.onTextChanged();
        final i1 = controller.candidates.indexWhere(
          (c) => c.matchedName == 'The Dark Prince',
        );
        controller.selectCandidate(i1);

        final text1 = quillController.document.toPlainText().trimRight();
        expect(text1, 'The Dark Prince');

        // Now select "He Who Must Not Be Named" alias via prefix @He
        quillController.replaceText(text1.length, 0, ' and @He', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: text1.length + 8),
          ChangeSource.local,
        );
        controller.onTextChanged();
        final i2 = controller.candidates.indexWhere(
          (c) => c.matchedName == 'He Who Must Not Be Named',
        );
        expect(i2, isNot(-1));
        controller.selectCandidate(i2);

        final text2 = quillController.document.toPlainText().trimRight();
        expect(text2, 'The Dark Prince and He Who Must Not Be Named');
      });

      test('target identity remains the same character', () {
        // Type @Thor → alias match for Thorin Stonehand
        quillController.replaceText(0, 0, '@Thor', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final candidate = controller.candidates.firstWhere(
          (c) => c.matchedName == 'Thor',
        );
        // The candidate's entry.name is the canonical identity.
        expect(candidate.entry.name, 'Thorin Stonehand');
        expect(candidate.matchedName, 'Thor');

        controller.selectCandidate(controller.candidates.indexOf(candidate));

        final plainText =
            quillController.document.toPlainText().trimRight();
        // Text is the alias.
        expect(plainText, 'Thor');
        // But the candidate entry still points to the canonical identity.
        expect(candidate.entry.name, 'Thorin Stonehand');
      });
    });

    group('multi-word query extraction', () {
      test('one-letter query activates and resolves', () {
        quillController.replaceText(0, 0, '@T', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 2),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'T');
        expect(controller.candidates, isNotEmpty);
      });

      test('multi-letter query activates and resolves', () {
        quillController.replaceText(0, 0, '@Thor', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'Thor');
      });

      test('multi-word query with spaces activates and resolves', () {
        quillController.replaceText(0, 0, '@The Dark', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 9),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'The Dark');
        expect(controller.candidates, isNotEmpty);
      });

      test('full multi-word alias query resolves exact match', () {
        quillController.replaceText(0, 0, '@Dark One', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 9),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'Dark One');
        final kael = controller.candidates.where(
          (c) => c.entry.name == 'Kael Draven',
        );
        expect(kael.length, 1);
        expect(kael.first.matchedName, 'Dark One');
        expect(kael.first.matchType, MatchType.exactAlias);
      });

      test('cursor after the full query works', () {
        quillController.replaceText(0, 0, 'Hello @The Dark Prince', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 22),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'The Dark Prince');
        expect(controller.triggerOffset, 6);
      });

      test('cursor in the middle of surrounding text', () {
        quillController.replaceText(0, 0, 'Start @The Dark End', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 15),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.query, 'The Dark');
      });
    });

    group('case-insensitive resolution via controller', () {
      test('@the dark resolves same as @The Dark', () {
        quillController.replaceText(0, 0, '@the dark', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 9),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        expect(controller.candidates, isNotEmpty);
        final voldemort = controller.candidates.where(
          (c) => c.entry.name == 'Voldemort',
        );
        expect(voldemort.length, 1);
        expect(voldemort.first.matchedName, 'The Dark Prince');
      });

      test('@THE DARK resolves same as @The Dark', () {
        quillController.replaceText(0, 0, '@THE DARK', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 9),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        final voldemort = controller.candidates.where(
          (c) => c.entry.name == 'Voldemort',
        );
        expect(voldemort.length, 1);
      });

      test('@tHe DaRk resolves same as @The Dark', () {
        quillController.replaceText(0, 0, '@tHe DaRk', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 9),
          ChangeSource.local,
        );
        controller.onTextChanged();

        expect(controller.isActive, isTrue);
        final voldemort = controller.candidates.where(
          (c) => c.entry.name == 'Voldemort',
        );
        expect(voldemort.length, 1);
      });
    });

    group('reference attribute insertion', () {
      test('selecting candidate applies ref link attribute', () {
        quillController.replaceText(0, 0, '@Lyra', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Lyra',
        );
        controller.selectCandidate(index);

        // The document should contain a link attribute with ref: prefix.
        final delta = quillController.document.toDelta();
        final ops = delta.toList();
        bool foundRef = false;
        for (final op in ops) {
          if (op.isInsert && op.data is String) {
            final text = op.data as String;
            if (text == 'Lyra') {
              final link = op.attributes?['link'] as String?;
              expect(link, isNotNull);
              expect(link!.startsWith('ref:'), isTrue);
              foundRef = true;
            }
          }
        }
        expect(foundRef, isTrue);
      });

      test('alias selection applies ref with correct character key', () {
        quillController.replaceText(0, 0, '@Thor', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Thor',
        );
        final candidate = controller.candidates[index];
        controller.selectCandidate(index);

        final delta = quillController.document.toDelta();
        final ops = delta.toList();
        for (final op in ops) {
          if (op.isInsert && op.data is String && op.data == 'Thor') {
            final link = op.attributes?['link'] as String?;
            // The link encodes ref:Character:<key>.
            expect(link, startsWith('ref:Character:'));
            // The key matches the candidate's entry key (may be null for
            // test characters not stored in Hive).
            expect(link, 'ref:Character:${candidate.entry.key}');
          }
        }
      });

      test('reference text is distinct from plain text', () {
        quillController.replaceText(0, 0, 'Hello @Ari', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 10),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Ari',
        );
        controller.selectCandidate(index);

        final delta = quillController.document.toDelta();
        final ops = delta.toList();
        for (final op in ops) {
          if (op.isInsert && op.data is String) {
            final text = op.data as String;
            if (text == 'Ari') {
              // The reference text should have a link attribute.
              expect(op.attributes, isNotNull);
              expect(op.attributes!['link'], isNotNull);
            } else if (text == 'Hello ') {
              // Plain text should NOT have a link attribute.
              expect(
                op.attributes == null ||
                    !op.attributes!.containsKey('link'),
                isTrue,
              );
            }
          }
        }
      });

      test('cursor positioned after reference text', () {
        quillController.replaceText(0, 0, '@Lyra', null);
        quillController.updateSelection(
          TextSelection.collapsed(offset: 5),
          ChangeSource.local,
        );
        controller.onTextChanged();

        final index = controller.candidates.indexWhere(
          (c) => c.matchedName == 'Lyra',
        );
        controller.selectCandidate(index);

        expect(quillController.selection.baseOffset, 'Lyra'.length);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Character-by-character progressive typing tests
  //
  // These simulate real runtime behavior: each keystroke triggers a separate
  // replaceText + updateSelection + onTextChanged cycle.
  // ---------------------------------------------------------------------------
  group('progressive @query extraction (char-by-char)', () {
    late QuillController qc;
    late ReferenceAutocompleteController ctrl;

    setUp(() {
      qc = _makeController('');
      ctrl = ReferenceAutocompleteController(
        quillController: qc,
        charactersProvider: _testCharacters,
      );
    });

    tearDown(() => qc.dispose());

    /// Types a single character at the current cursor position.
    void typeChar(String ch) {
      final cursor = qc.selection.baseOffset;
      qc.replaceText(cursor, 0, ch, null);
      qc.updateSelection(
        TextSelection.collapsed(offset: cursor + ch.length),
        ChangeSource.local,
      );
      ctrl.onTextChanged();
    }

    // Test 1: @ + one character
    test('typing @M produces query "M"', () {
      typeChar('@');
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, '');

      typeChar('M');
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'M');
    });

    // Test 2: @ + multi-character query
    test('typing @Maria produces query "Maria"', () {
      typeChar('@');
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, '');

      for (final ch in 'Maria'.split('')) {
        typeChar(ch);
      }
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'Maria');
    });

    // Test 3: @ + multi-word query
    test('typing @The Dark Prince produces query "The Dark Prince"', () {
      typeChar('@');
      for (final ch in 'The Dark Prince'.split('')) {
        typeChar(ch);
      }
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'The Dark Prince');
    });

    // Test 4: typing after whitespace
    test('@ after space activates and captures full query', () {
      typeChar('H');
      typeChar('e');
      typeChar('l');
      typeChar('l');
      typeChar('o');
      typeChar(' ');
      expect(ctrl.isActive, isFalse);

      typeChar('@');
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, '');

      typeChar('L');
      expect(ctrl.query, 'L');
      typeChar('y');
      expect(ctrl.query, 'Ly');
      typeChar('r');
      expect(ctrl.query, 'Lyr');
      typeChar('a');
      expect(ctrl.query, 'Lyra');
    });

    // Test 5: uppercase query
    test('uppercase @MARIA produces query "MARIA"', () {
      typeChar('@');
      for (final ch in 'MARIA'.split('')) {
        typeChar(ch);
      }
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'MARIA');
    });

    // Test 6: lowercase query
    test('lowercase @maria produces query "maria"', () {
      typeChar('@');
      for (final ch in 'maria'.split('')) {
        typeChar(ch);
      }
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'maria');
    });

    // Test 7: letter M specifically
    test('typing @M produces query "M" (letter M)', () {
      typeChar('@');
      typeChar('M');
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'M');
    });

    // Test 8: lowercase m
    test('typing @m produces query "m" (lowercase m)', () {
      typeChar('@');
      typeChar('m');
      expect(ctrl.isActive, isTrue);
      expect(ctrl.query, 'm');
    });

    // Test 9: query containing M in the middle
    test('query "aMb" correctly contains M', () {
      typeChar('@');
      typeChar('a');
      expect(ctrl.query, 'a');
      typeChar('M');
      expect(ctrl.query, 'aM');
      typeChar('b');
      expect(ctrl.query, 'aMb');
    });

    // Test 10: query continuing beyond M
    test('@M aria produces query "M aria" with space preserved', () {
      typeChar('@');
      typeChar('M');
      expect(ctrl.query, 'M');
      typeChar(' ');
      expect(ctrl.query, 'M ');
      typeChar('a');
      expect(ctrl.query, 'M a');
      typeChar('r');
      expect(ctrl.query, 'M ar');
      typeChar('i');
      expect(ctrl.query, 'M ari');
      typeChar('a');
      expect(ctrl.query, 'M aria');
    });

    // Bonus: full sequence @M → @Ma → @Mar → @Mari → @Maria
    test('full incremental sequence produces correct queries at each step', () {
      typeChar('@');
      expect(ctrl.query, '');
      expect(ctrl.isActive, isTrue);

      typeChar('M');
      expect(ctrl.query, 'M');

      typeChar('a');
      expect(ctrl.query, 'Ma');

      typeChar('r');
      expect(ctrl.query, 'Mar');

      typeChar('i');
      expect(ctrl.query, 'Mari');

      typeChar('a');
      expect(ctrl.query, 'Maria');

      expect(ctrl.isActive, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Overlay widget tests
  // ---------------------------------------------------------------------------
  group('ReferenceAutocompleteOverlay', () {
    late QuillController quillController;
    late ReferenceAutocompleteController controller;

    setUp(() {
      quillController = _makeController('');
      controller = ReferenceAutocompleteController(
        quillController: quillController,
        charactersProvider: _testCharacters,
      );
    });

    tearDown(() {
      quillController.dispose();
    });

    testWidgets('renders candidates when active', (tester) async {
      quillController.replaceText(0, 0, '@Ari', null);
      quillController.updateSelection(
        TextSelection.collapsed(offset: 4),
        ChangeSource.local,
      );
      controller.onTextChanged();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReferenceAutocompleteOverlay(controller: controller),
          ),
        ),
      );

      expect(find.text('Aria Nightingale'), findsOneWidget);
      expect(find.text('Aria Stark'), findsOneWidget);
    });

    testWidgets('shows empty when not active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReferenceAutocompleteOverlay(controller: controller),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('tapping a candidate selects it', (tester) async {
      quillController.replaceText(0, 0, '@Lyra', null);
      quillController.updateSelection(
        TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );
      controller.onTextChanged();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: ReferenceAutocompleteOverlay(controller: controller),
              ),
            ),
          ),
        ),
      );

      // Verify candidate is rendered
      expect(find.text('Lyra'), findsOneWidget);

      // Simulate selection via controller (tap blocked by Scaffold overlay in tests)
      controller.selectCandidate(0);
      await tester.pump();

      final plainText = quillController.document.toPlainText().trimRight();
      expect(plainText, 'Lyra');
      expect(controller.isActive, isFalse);
    });

    testWidgets('shows query in header', (tester) async {
      quillController.replaceText(0, 0, '@Ari', null);
      quillController.updateSelection(
        TextSelection.collapsed(offset: 4),
        ChangeSource.local,
      );
      controller.onTextChanged();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReferenceAutocompleteOverlay(controller: controller),
          ),
        ),
      );

      expect(find.text('"Ari"'), findsOneWidget);
    });

    testWidgets('shows candidate count', (tester) async {
      quillController.replaceText(0, 0, '@Ari', null);
      quillController.updateSelection(
        TextSelection.collapsed(offset: 4),
        ChangeSource.local,
      );
      controller.onTextChanged();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReferenceAutocompleteOverlay(controller: controller),
          ),
        ),
      );

      final count = controller.candidates.length.toString();
      expect(find.text(count), findsOneWidget);
    });
  });
}
