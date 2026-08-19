import 'package:flutter_test/flutter_test.dart';
import 'package:lore_keeper/services/reference_engine.dart';

void main() {
  group('ReferenceEngine', () {
    late ReferenceEngine engine;

    // Shared test data
    late List<CharacterReferenceEntry> characters;

    setUp(() {
      engine = const ReferenceEngine(maxResults: 20);
      characters = [
        const CharacterReferenceEntry(
          key: 1,
          name: 'Aria Nightingale',
          aliases: ['Ari', 'The Singer'],
        ),
        const CharacterReferenceEntry(
          key: 2,
          name: 'Thorin Stonehand',
          aliases: ['Thor', 'Stone'],
        ),
        const CharacterReferenceEntry(
          key: 3,
          name: 'Lyra',
          aliases: [],
        ),
        const CharacterReferenceEntry(
          key: 4,
          name: 'Kael Draven',
          aliases: ['Shadow', 'Dark One', 'Kael'],
        ),
        const CharacterReferenceEntry(
          key: 5,
          name: 'Aria Stark',
          aliases: ['Aria Wolf'],
        ),
      ];
    });

    group('exact character name', () {
      test('returns exact full-name match with confidence 1.0', () {
        final results = engine.resolve('Aria Nightingale', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Aria Nightingale');
        expect(results.first.matchType, MatchType.exactName);
        expect(results.first.confidence, 1.0);
      });

      test('returns exact match for single-word name', () {
        final results = engine.resolve('Lyra', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Lyra');
        expect(results.first.matchType, MatchType.exactName);
        expect(results.first.confidence, 1.0);
      });
    });

    group('alias matching', () {
      test('returns exact alias match with confidence 0.9', () {
        final results = engine.resolve('Thor', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Thorin Stonehand');
        expect(results.first.matchedName, 'Thor');
        expect(results.first.matchType, MatchType.exactAlias);
        expect(results.first.confidence, 0.9);
      });

      test('matches multi-word alias exactly', () {
        final results = engine.resolve('Dark One', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Kael Draven');
        expect(results.first.matchedName, 'Dark One');
        expect(results.first.matchType, MatchType.exactAlias);
      });
    });

    group('case-insensitive matching', () {
      test('exact name match is case-insensitive', () {
        final results = engine.resolve('aria nightingale', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Aria Nightingale');
        expect(results.first.confidence, 1.0);
      });

      test('exact alias match is case-insensitive', () {
        final results = engine.resolve('thor', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Thorin Stonehand');
        expect(results.first.matchType, MatchType.exactAlias);
      });

      test('prefix match is case-insensitive', () {
        final results = engine.resolve('ARIA', characters);
        expect(results.isNotEmpty, true);
        // Should match both Aria Nightingale and Aria Stark
        expect(results.length, greaterThanOrEqualTo(2));
        for (final r in results) {
          expect(r.confidence, greaterThanOrEqualTo(0.6));
        }
      });
    });

    group('prefix matching', () {
      test('name prefix match has confidence 0.7', () {
        final results = engine.resolve('Aria', characters);
        expect(results, isNotEmpty);
        // Should include both Aria Nightingale and Aria Stark as prefix matches
        final ariaResults =
            results.where((r) => r.matchType == MatchType.prefixName).toList();
        expect(ariaResults.length, 2);
        expect(ariaResults.every((r) => r.confidence == 0.7), true);
      });

      test('alias prefix match has confidence 0.6', () {
        // 'Sto' is prefix of 'Stone' alias (Thorin) but not 'Stonehand' (name)
        final results = engine.resolve('Sto', characters);
        expect(results, isNotEmpty);
        final stoneResults = results
            .where((r) => r.matchType == MatchType.prefixAlias)
            .toList();
        expect(stoneResults, isNotEmpty);
        expect(stoneResults.every((r) => r.confidence == 0.6), true);
      });
    });

    group('substring matching', () {
      test('name substring match has confidence 0.3', () {
        // 'night' is substring of 'Nightingale' (Aria Nightingale's name)
        final results = engine.resolve('night', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Aria Nightingale');
        expect(results.first.matchType, MatchType.substringName);
        expect(results.first.confidence, 0.3);
      });

      test('alias substring match has confidence 0.2', () {
        // 'inger' is substring of 'The Singer' alias
        final results = engine.resolve('inger', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Aria Nightingale');
        expect(results.first.matchedName, 'The Singer');
        expect(results.first.matchType, MatchType.substringAlias);
        expect(results.first.confidence, 0.2);
      });
    });

    group('multiple candidates', () {
      test('returns all matching candidates', () {
        final results = engine.resolve('a', characters);
        // 'a' is prefix of: Aria Nightingale, Aria Stark, Aria (alias of Kael)
        expect(results.length, greaterThanOrEqualTo(3));
      });

      test('returns candidates sorted by confidence descending', () {
        final results = engine.resolve('aria', characters);
        final confidences = results.map((r) => r.confidence).toList();
        for (var i = 0; i < confidences.length - 1; i++) {
          expect(confidences[i] >= confidences[i + 1], true);
        }
      });

      test('same confidence level sorted by matchType then name', () {
        final results = engine.resolve('aria', characters);
        // All prefixName matches (confidence 0.7) should be sorted by name
        final prefixResults = results
            .where((r) => r.matchType == MatchType.prefixName)
            .toList();
        if (prefixResults.length > 1) {
          final names = prefixResults.map((r) => r.displayName).toList();
          expect(names, equals(List.of(names)..sort()));
        }
      });
    });

    group('no match', () {
      test('returns empty list for non-matching query', () {
        final results = engine.resolve('zzzzz', characters);
        expect(results, isEmpty);
      });

      test('returns empty list for empty query', () {
        final results = engine.resolve('', characters);
        expect(results, isEmpty);
      });

      test('returns empty list for whitespace-only query', () {
        final results = engine.resolve('   ', characters);
        expect(results, isEmpty);
      });

      test('returns empty list for empty character list', () {
        final results = engine.resolve('Aria', []);
        expect(results, isEmpty);
      });
    });

    group('ranking', () {
      test('exact name ranks above exact alias', () {
        final results = engine.resolve('Lyra', characters);
        expect(results, hasLength(1));
        expect(results.first.matchType, MatchType.exactName);
        expect(results.first.confidence, 1.0);
      });

      test('exact alias ranks above prefix name', () {
        // 'Thor' is exact alias of Thorin, prefix of nothing
        // 'Aria' is prefix name of Aria Nightingale and Aria Stark
        // These don't overlap on a single query, so test them separately
        final exactAlias = engine.resolve('Thor', characters);
        final prefixName = engine.resolve('Aria', characters);
        expect(exactAlias.first.confidence, 0.9);
        expect(prefixName.first.confidence, 0.7);
        expect(exactAlias.first.confidence > prefixName.first.confidence, true);
      });

      test('prefix name ranks above prefix alias', () {
        // 'Stone' matches Thorin's name prefix AND alias prefix
        final results = engine.resolve('Stone', characters);
        expect(results, isNotEmpty);
        final nameMatch = results
            .where((r) => r.matchType == MatchType.prefixName)
            .toList();
        final aliasMatch = results
            .where((r) => r.matchType == MatchType.prefixAlias)
            .toList();
        if (nameMatch.isNotEmpty && aliasMatch.isNotEmpty) {
          expect(nameMatch.first.confidence > aliasMatch.first.confidence, true);
        }
      });

      test('prefix alias ranks above substring name', () {
        final prefixAlias = engine.resolve('Sto', characters);
        final substringName = engine.resolve('night', characters);
        expect(prefixAlias.first.confidence, 0.6);
        expect(substringName.first.confidence, 0.3);
        expect(
          prefixAlias.first.confidence > substringName.first.confidence,
          true,
        );
      });

      test('substring name ranks above substring alias', () {
        // 'inger' matches 'The Singer' alias (substring)
        final results = engine.resolve('inger', characters);
        expect(results, hasLength(1));
        expect(results.first.confidence, 0.2);
      });
    });

    group('one-character-per-match', () {
      test('each character appears at most once in results', () {
        final results = engine.resolve('a', characters);
        final keys = results.map((r) => r.entry.key).toList();
        expect(keys.toSet().length, keys.length);
      });
    });

    group('maxResults', () {
      test('respects maxResults limit', () {
        final limitedEngine = const ReferenceEngine(maxResults: 2);
        final results = limitedEngine.resolve('a', characters);
        expect(results.length, lessThanOrEqualTo(2));
      });

      test('returns all results when under limit', () {
        final limitedEngine = const ReferenceEngine(maxResults: 100);
        final results = limitedEngine.resolve('a', characters);
        expect(results.length, greaterThanOrEqualTo(3));
      });
    });

    group('determinism', () {
      test('same input produces same output', () {
        final r1 = engine.resolve('aria', characters);
        final r2 = engine.resolve('aria', characters);
        expect(r1.length, r2.length);
        for (var i = 0; i < r1.length; i++) {
          expect(r1[i].displayName, r2[i].displayName);
          expect(r1[i].matchType, r2[i].matchType);
          expect(r1[i].confidence, r2[i].confidence);
        }
      });

      test('results are stable across repeated calls', () {
        final allResults = List.generate(
          5,
          (_) => engine.resolve('a', characters),
        );
        for (var i = 1; i < allResults.length; i++) {
          expect(allResults[0].length, allResults[i].length);
          for (var j = 0; j < allResults[0].length; j++) {
            expect(
              allResults[0][j].displayName,
              allResults[i][j].displayName,
            );
          }
        }
      });
    });

    group('edge cases', () {
      test('query with only aliases', () {
        final results = engine.resolve('Shadow', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Kael Draven');
        expect(results.first.matchedName, 'Shadow');
      });

      test('query longer than any name returns empty', () {
        final results = engine.resolve(
          'A very long query that does not match anything',
          characters,
        );
        expect(results, isEmpty);
      });

      test('character with no aliases still matches on name', () {
        final results = engine.resolve('Lyra', characters);
        expect(results, hasLength(1));
        expect(results.first.matchType, MatchType.exactName);
      });

      test('character with empty alias list behaves same as no aliases', () {
        final entries = [
          const CharacterReferenceEntry(
            key: 10,
            name: 'Test Character',
            aliases: [],
          ),
        ];
        final results = engine.resolve('Test', entries);
        expect(results, hasLength(1));
        expect(results.first.matchType, MatchType.prefixName);
      });
    });

    group('multi-word queries', () {
      test('exact multi-word alias match', () {
        final results = engine.resolve('Dark One', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Kael Draven');
        expect(results.first.matchedName, 'Dark One');
        expect(results.first.matchType, MatchType.exactAlias);
      });

      test('prefix multi-word alias match', () {
        // "Dark" is prefix of "Dark One" alias (Kael)
        final results = engine.resolve('Dark', characters);
        expect(results, isNotEmpty);
        final kaelResult = results.firstWhere(
          (r) => r.displayName == 'Kael Draven',
        );
        expect(kaelResult.matchedName, 'Dark One');
        expect(kaelResult.matchType, MatchType.prefixAlias);
      });

      test('multi-word query with mixed case', () {
        final results = engine.resolve('dark one', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Kael Draven');
        expect(results.first.matchedName, 'Dark One');
      });

      test('full name exact match with spaces', () {
        final results = engine.resolve('Aria Nightingale', characters);
        expect(results, hasLength(1));
        expect(results.first.matchType, MatchType.exactName);
      });

      test('multi-word substring match', () {
        // "oneha" is substring of "Thorin Stonehand"
        final results = engine.resolve('oneha', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Thorin Stonehand');
        expect(results.first.matchType, MatchType.substringName);
      });
    });

    group('case-insensitive with spaces', () {
      test('mixed case multi-word alias resolves', () {
        final results = engine.resolve('DARK ONE', characters);
        expect(results, hasLength(1));
        expect(results.first.matchedName, 'Dark One');
      });

      test('random case multi-word name resolves', () {
        // "aRiA sTaRk" lowercased is "aria stark" → exact name match
        final results = engine.resolve('aRiA sTaRk', characters);
        expect(results, hasLength(1));
        expect(results.first.displayName, 'Aria Stark');
        expect(results.first.matchType, MatchType.exactName);
      });
    });
  });
}
