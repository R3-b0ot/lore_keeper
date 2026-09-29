/// Find/replace coordinate math for the manuscript editor.
///
/// Cycle 5 (MS-011/MS-012/MS-013). This is the single place that answers
/// "where does the query occur?" and "in what order do the edits have to be
/// applied?", so the dialog widget carries no arithmetic of its own.
///
/// Deliberately pure Dart - no Flutter UI imports, no Quill, no Hive, no
/// `dart:io`, and no clock. Matching is decided against a plain `String`
/// snapshot supplied by the caller, which is what makes every offset here
/// directly assertable in a unit test.
///
/// **Matching is literal substring, not whole-word.** Every case-sensitive (or
/// case-folded, when the toggle is off) occurrence of the query is a match,
/// including occurrences inside a longer word. `"a cat and a dog"` with query
/// `"a"` therefore matches at 0, 3, 6 and 10 - the `a` in `cat` and in `and`
/// count. This was decided for MS-012 and is deliberately *not* word-bounded;
/// a whole-word variant of this requirement appeared in an earlier revision of
/// the requirements doc and is superseded.
///
/// **Matches never overlap.** Scanning resumes past the end of each hit, so a
/// query of `"aa"` in `"aaa"` yields one match at 0, not two. That keeps
/// replace-all from rewriting text it just produced.
library;

/// One non-overlapping occurrence of a query within a text snapshot.
class FindMatch {
  /// Creates a match covering `[offset, offset + length)`.
  const FindMatch(this.offset, this.length);

  /// Index of the first character of the match.
  final int offset;

  /// Number of characters covered by the match.
  final int length;

  /// Index one past the last character of the match.
  int get end => offset + length;

  @override
  bool operator ==(Object other) =>
      other is FindMatch && other.offset == offset && other.length == length;

  @override
  int get hashCode => Object.hash(offset, length);

  @override
  String toString() => 'FindMatch($offset, $length)';
}

/// Finds literal occurrences of a query in a plain-text snapshot.
class FindReplaceEngine {
  const FindReplaceEngine();

  /// Every non-overlapping occurrence of [query] in [text], left to right.
  ///
  /// An empty [query] yields no matches rather than matching everywhere: a
  /// zero-length query would make every offset ambiguous and would turn
  /// replace-all into an infinite loop.
  List<FindMatch> findMatches(
    String text,
    String query, {
    bool caseSensitive = false,
  }) {
    if (query.isEmpty || text.isEmpty) return const <FindMatch>[];

    final needle = caseSensitive ? query : query.toLowerCase();
    final haystack = caseSensitive ? text : text.toLowerCase();

    final matches = <FindMatch>[];
    var from = 0;
    while (from <= haystack.length - needle.length) {
      final at = haystack.indexOf(needle, from);
      if (at == -1) break;
      matches.add(FindMatch(at, query.length));
      // Resume past the hit so matches never overlap.
      from = at + query.length;
    }
    return matches;
  }

  /// The matches of a replace-all run, ordered **highest offset first**.
  ///
  /// MS-012. Applying edits in ascending offset order invalidates the
  /// coordinates of every not-yet-applied match as soon as the replacement is
  /// a different length from the query, because each edit shifts the tail of
  /// the document. Walking the plan backwards means every range is still at
  /// its original offset when it is applied, so the result is correct whether
  /// the replacement is shorter, longer, or the same length as the query - and
  /// an empty replacement (pure deletion) is just a zero-length insert.
  List<FindMatch> replaceAllPlan(
    String text,
    String query, {
    bool caseSensitive = false,
  }) {
    final matches = findMatches(
      text,
      query,
      caseSensitive: caseSensitive,
    );
    return matches.reversed.toList(growable: false);
  }
}

/// The state of a find session: what is being searched, where the matches are,
/// and which one is currently selected.
///
/// MS-013. This is a plain immutable value - constructing one never touches a
/// document, so the whole navigation model (including the wrap at either end)
/// is testable without a widget, a `QuillController`, or a clock.
///
/// Navigation is *cyclic*: with three matches, three Next presses land on the
/// first match again rather than stalling on the last one. With nothing
/// selected yet, Next selects the first match and Previous selects the last,
/// so both controls do something sensible on their first press.
class FindSession {
  /// Creates a session over [text].
  ///
  /// [currentIndex] is an index into the match list, or a negative value when
  /// no match is selected. Pass [matches] to reuse a previously computed list
  /// instead of rescanning [text].
  FindSession({
    required this.text,
    required this.query,
    required this.caseSensitive,
    this.currentIndex = -1,
    List<FindMatch>? matches,
  }) : matches = matches ??
            const FindReplaceEngine().findMatches(
              text,
              query,
              caseSensitive: caseSensitive,
            );

  /// The plain-text snapshot the matches were computed against.
  final String text;

  /// The literal substring being searched for.
  final String query;

  /// Whether matching is case-sensitive.
  final bool caseSensitive;

  /// Index of the selected match, or a negative value when none is selected.
  final int currentIndex;

  /// Every non-overlapping occurrence of [query] in [text].
  final List<FindMatch> matches;

  /// How many matches there are.
  int get count => matches.length;

  /// The currently selected match, or `null` when none is selected.
  FindMatch? get current {
    if (currentIndex < 0 || currentIndex >= matches.length) return null;
    return matches[currentIndex];
  }

  /// Whether there is at least one match.
  bool get hasMatches => matches.isNotEmpty;

  /// Selects the next match, wrapping past the end back to the first.
  FindSession next() {
    if (!hasMatches) return this;
    return _withIndex(currentIndex < 0 ? 0 : (currentIndex + 1) % count);
  }

  /// Selects the previous match, wrapping before the start to the last.
  FindSession previous() {
    if (!hasMatches) return this;
    return _withIndex(
      currentIndex < 0 ? count - 1 : (currentIndex - 1 + count) % count,
    );
  }

  /// The count shown next to the query field.
  ///
  /// Empty while there is no query, so the field is not decorated before the
  /// user has typed anything.
  String get countLabel {
    if (query.isEmpty) return '';
    if (matches.isEmpty) return 'No results';
    if (currentIndex < 0) return count == 1 ? '1 result' : '$count results';
    return '${currentIndex + 1} of $count';
  }

  /// A copy of this session pointed at a different match.
  FindSession _withIndex(int index) => FindSession(
        text: text,
        query: query,
        caseSensitive: caseSensitive,
        currentIndex: index,
        matches: matches,
      );
}
