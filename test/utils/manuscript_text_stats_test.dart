import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/utils/manuscript_text_stats.dart';

/// MS-009 + MS-010: canonical word/character counting.
///
/// Decision (recorded in the class docs and Cycle 2 log): the single
/// structural trailing `\n` that Quill's Delta format appends per line is
/// EXCLUDED from every measurement. `"Hello world\n"` → 2 words, 11 chars.
void main() {
  group('ManuscriptTextStats word count (MS-009)', () {
    test('Hebrew fixture "Hello world\\n" counts 2 words via plain text', () {
      expect(ManuscriptTextStats.wordCount('Hello world\n'), 2);
    });

    test('the fixture counts 2 words through the Delta-JSON adapter', () {
      const json = '{"ops":[{"insert":"Hello world\\n"}]}';
      expect(ManuscriptTextStats.plainTextOfDeltaJson(json), 'Hello world\n');
      expect(ManuscriptTextStats.wordCountOfJson(json), 2);
    });

    test('empty or whitespace-only strings count 0 words', () {
      expect(ManuscriptTextStats.wordCount(''), 0);
      expect(ManuscriptTextStats.wordCount('   \n\t  '), 0);
      expect(ManuscriptTextStats.wordCountOfJson(null), 0);
      expect(ManuscriptTextStats.wordCountOfJson(''), 0);
      expect(
        ManuscriptTextStats.wordCountOfJson('{"ops":[{"insert":"\\n"}]}'),
        0,
      );
    });

    test('multiple consecutive spaces still yield 2 words', () {
      expect(ManuscriptTextStats.wordCount('A  B\n'), 2);
    });

    test('a ref-linked mention counts its visible name as a word', () {
      const json =
          '{"ops":[{"insert":"Eryll\\n","attributes":{"link":"ref:Character:42"}}]}';
      expect(ManuscriptTextStats.plainTextOfDeltaJson(json), 'Eryll\n');
      expect(ManuscriptTextStats.wordCountOfJson(json), 1);
    });

    test('an image/embed op contributes one replacement character (1 unit)', () {
      const json =
          '{"ops":[{"insert":{"image":"data:image/png;base64,QUJD"}},{"insert":"\\n"}]}';
      expect(ManuscriptTextStats.plainTextOfDeltaJson(json), '\uFFFC\n');
      expect(ManuscriptTextStats.wordCountOfJson(json), 1);
    });

    test('a bare ops array (legacy V2 shape) is counted the same way', () {
      const json = '[{"insert":"Hello world\\n"}]';
      expect(ManuscriptTextStats.wordCountOfJson(json), 2);
    });

    test('malformed JSON yields 0 words, never a crash', () {
      expect(ManuscriptTextStats.wordCountOfJson('not json'), 0);
      expect(ManuscriptTextStats.wordCountOfJson('{"ops":'), 0);
    });
  });

  group('ManuscriptTextStats character count (MS-010)', () {
    test(
      // DECISION ENCODED: the single structural trailing "\n" that Quill's
      // Delta format always appends is EXCLUDED, so "Hello world\n"
      // measures 11 characters (12 if the newline were counted).
      '"Hello world\\n" counts exactly 11 characters',
      () {
        expect(ManuscriptTextStats.characterCount('Hello world\n'), 11);
        const json = '{"ops":[{"insert":"Hello world\\n"}]}';
        expect(ManuscriptTextStats.characterCountOfJson(json), 11);
      },
    );

    test('an empty document counts 0 characters', () {
      expect(ManuscriptTextStats.characterCount(''), 0);
      expect(ManuscriptTextStats.characterCount('\n'), 0);
      expect(ManuscriptTextStats.characterCountOfJson(null), 0);
      expect(ManuscriptTextStats.characterCountOfJson(''), 0);
      expect(
        ManuscriptTextStats.characterCountOfJson('{"ops":[{"insert":"\\n"}]}'),
        0,
      );
    });

    test(
      'interior newlines are preserved, only one trailing \\n is dropped',
      () {
        // Two lines: "a\nb\n" -> drop one trailing \n -> "a\nb" = 3 chars.
        expect(ManuscriptTextStats.characterCount('a\nb\n'), 3);
      },
    );

    test('an embed op contributes exactly one character', () {
      const json =
          '{"ops":[{"insert":{"image":"data:image/png;base64,QUJD"}},{"insert":"\\n"}]}';
      expect(ManuscriptTextStats.characterCountOfJson(json), 1);
    });
  });
}
