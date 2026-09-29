/// Unit tests for [FindReplaceEngine] - the pure-Dart half of find & replace.
///
/// Cycle 5. The dialog widget owns only the Quill mutation; every offset,
/// every match list and the order the edits are applied in are decided here
/// and are directly assertable without a widget or a document.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/services/manuscript_find_replace.dart';

void main() {
  const engine = FindReplaceEngine();

  group('findMatches', () {
    test('matches literal substrings, not whole words (MS-012 decision)', () {
      // Every literal "a", including the ones inside "cat" and "and".
      expect(
        engine
            .findMatches('a cat and a dog', 'a')
            .map((m) => m.offset),
        [0, 3, 6, 10],
      );
    });

    test('match lengths are the query length', () {
      final matches = engine.findMatches('a cat and a dog', 'a');
      expect(matches.every((m) => m.length == 1), isTrue);
      expect(matches.last.end, 11);
    });

    test('a multi-character query', () {
      // "the cat the dog the bird" -> "the" at 0, 8 and 16. The MS-013
      // acceptance text says 17, which is off by one; the third match starts
      // at 16 ("t" of the final "the").
      expect(
        engine.findMatches('the cat the dog the bird', 'the').map((m) => m.offset),
        [0, 8, 16],
      );
    });

    test('matches never overlap', () {
      // "aa" occurs at 0 and 1; only one of them can be replaced without
      // rewriting text the same run just produced.
      expect(engine.findMatches('aaa', 'aa').map((m) => m.offset), [0]);
      expect(engine.findMatches('aaaa', 'aa').map((m) => m.offset), [0, 2]);
    });

    test('an empty query matches nothing', () {
      expect(engine.findMatches('a cat and a dog', ''), isEmpty);
    });

    test('an empty haystack matches nothing', () {
      expect(engine.findMatches('', 'a'), isEmpty);
    });

    test('a query longer than the haystack matches nothing', () {
      expect(engine.findMatches('cat', 'catalog'), isEmpty);
    });

    test('a query that is not present matches nothing', () {
      expect(engine.findMatches('a cat', 'zebra'), isEmpty);
    });

    test('case-insensitive by default', () {
      expect(
        engine.findMatches('The Cat THE cat', 'the').map((m) => m.offset),
        [0, 8],
      );
    });

    test('case-sensitive matching is exact', () {
      // "The" and "THE" are not "the", so nothing matches.
      expect(
        engine
            .findMatches('The Cat THE cat', 'the', caseSensitive: true)
            .map((m) => m.offset),
        isEmpty,
      );
      expect(
        engine
            .findMatches('The Cat THE cat', 'THE', caseSensitive: true)
            .map((m) => m.offset),
        [8],
      );
    });

    test('case-insensitive matching preserves the original match length', () {
      // A fold that changed length would make the offsets meaningless.
      final matches = engine.findMatches('İstanbul', 'i');
      expect(matches.every((m) => m.length == 1), isTrue);
    });
  });

  group('replaceAllPlan', () {
    test('is the match list in descending offset order (MS-012)', () {
      final plan = engine.replaceAllPlan('a cat and a dog', 'a');
      expect(plan.map((m) => m.offset), [10, 6, 3, 0]);
    });

    test('descending order is what makes a longer replacement safe', () {
      // Applying [10, 6, 3, 0] in that order never invalidates a pending
      // offset, because every edit happens to the right of the next one.
      final plan = engine.replaceAllPlan('a cat and a dog', 'a');
      final buffer = StringBuffer('a cat and a dog');
      for (final m in plan) {
        final current = buffer.toString();
        buffer
          ..clear()
          ..write(current.substring(0, m.offset))
          ..write('bbb')
          ..write(current.substring(m.end));
      }
      expect(buffer.toString(), 'bbb cbbbt bbbnd bbb dog');
    });

    test('the plan is empty when there is nothing to replace', () {
      expect(engine.replaceAllPlan('a cat', 'zebra'), isEmpty);
      expect(engine.replaceAllPlan('a cat', ''), isEmpty);
    });

    test('a single match is unchanged by the ordering', () {
      expect(engine.replaceAllPlan('the cat', 'cat').map((m) => m.offset), [4]);
    });
  });

  group('FindMatch', () {
    test('is a value type', () {
      expect(const FindMatch(3, 4), const FindMatch(3, 4));
      expect(const FindMatch(3, 4).hashCode, const FindMatch(3, 4).hashCode);
      expect(const FindMatch(3, 4), isNot(const FindMatch(4, 3)));
    });

    test('end is one past the last character', () {
      expect(const FindMatch(3, 4).end, 7);
    });
  });

  group('FindSession - MS-013 navigation', () {
    const text = 'the cat the dog the bird';

    FindSession start({int index = -1}) => FindSession(
          text: text,
          query: 'the',
          caseSensitive: false,
          currentIndex: index,
        );

    test('finds every occurrence up front', () {
      final s = start();
      expect(s.count, 3);
      expect(s.matches.map((m) => m.offset), [0, 8, 16]);
      expect(s.current, isNull, reason: 'nothing is selected yet');
    });

    test('the first Next selects the first match', () {
      expect(start().next().current!.offset, 0);
    });

    test('Next walks every match and wraps', () {
      var s = start();
      expect(s.countLabel, '3 results');
      s = s.next();
      expect(s.current!.offset, 0);
      expect(s.countLabel, '1 of 3');
      s = s.next();
      expect(s.current!.offset, 8);
      expect(s.countLabel, '2 of 3');
      s = s.next();
      expect(s.current!.offset, 16);
      expect(s.countLabel, '3 of 3');
      s = s.next();
      expect(
        s.current!.offset,
        0,
        reason: 'past the last match, wrap to the first',
      );
      expect(s.countLabel, '1 of 3');
    });

    test('Previous from the first match wraps to the last', () {
      final s = start().next().previous();
      expect(s.current!.offset, 16);
      expect(s.countLabel, '3 of 3');
    });

    test('Previous from the last match wraps to the first', () {
      final s = start().next().next().next().previous();
      expect(s.current!.offset, 8);
    });

    test('Previous with nothing selected selects the last match', () {
      final s = start().previous();
      expect(s.current!.offset, 16);
      expect(s.countLabel, '3 of 3');
    });

    test('a single match is its own next and its own previous', () {
      final s = FindSession(
        text: 'cat',
        query: 'cat',
        caseSensitive: false,
      ).next();
      expect(s.count, 1);
      expect(s.next().current!.offset, 0);
      expect(s.next().previous().current!.offset, 0);
    });

    test('navigating with no matches is a no-op, not a crash', () {
      final s = FindSession(
        text: text,
        query: 'zebra',
        caseSensitive: false,
      );
      expect(s.count, 0);
      expect(s.hasMatches, isFalse);
      expect(s.next().current, isNull);
      expect(s.next().previous().current, isNull);
      expect(s.countLabel, 'No results');
    });

    test('the label is empty until something is searched for', () {
      final s = FindSession(
        text: text,
        query: '',
        caseSensitive: false,
      );
      expect(s.countLabel, '');
      expect(s.count, 0);
    });

    test('the label is singular for one result', () {
      final s = FindSession(
        text: 'one cat',
        query: 'cat',
        caseSensitive: false,
      );
      expect(s.countLabel, '1 result');
      expect(s.next().countLabel, '1 of 1');
    });

    test('case sensitivity follows the flag the dialog exposes', () {
      final insensitive = FindSession(
        text: 'The cat THE',
        query: 'the',
        caseSensitive: false,
      );
      expect(insensitive.count, 2);
      final sensitive = FindSession(
        text: 'The cat THE',
        query: 'the',
        caseSensitive: true,
      );
      expect(sensitive.count, 0);
    });

    test('a session is a value and does not alias the caller\'s list', () {
      final a = start().next();
      final b = a.next();
      expect(a.current!.offset, 0, reason: 'a must be unaffected by b');
      expect(b.current!.offset, 8);
      expect(identical(a.matches, b.matches), isTrue,
          reason: 'the match list is immutable and shared, not recomputed');
    });
  });
}
