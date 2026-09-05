/// Pure Dart reference-resolution layer for the @Name Reference Engine.
///
/// This engine resolves typed name queries against entity identities.
/// It operates on plain data — no Flutter widgets, BuildContext, Hive boxes,
/// Quill editors, or navigation dependencies.
///
/// The future Quill autocomplete layer will build [EntityReferenceEntry]
/// lists from Hive data and call [ReferenceEngine.resolve].
library;

/// Match quality classification.
enum MatchType {
  /// Query matches the entity's display name exactly.
  exactName,

  /// Query matches an alias exactly.
  exactAlias,

  /// Query is a prefix of the entity's display name.
  prefixName,

  /// Query is a prefix of an alias.
  prefixAlias,

  /// Query is a substring of the entity's display name.
  substringName,

  /// Query is a substring of an alias.
  substringAlias,
}

/// A flat representation of a referenceable entity identity.
///
/// This decouples the resolver from the specific Hive models.
/// The Quill autocomplete layer builds these from Hive data before calling
/// [ReferenceEngine.resolve].
class EntityReferenceEntry {
  /// The entity's unique identity key (Hive key or UUID).
  final dynamic key;

  /// The entity's primary display name.
  final String name;

  /// All alternate names (aliases, iterations, etc.).
  final List<String> aliases;

  /// The entity type (Character, Location, etc.) - maps to EntityType constants.
  final String entityType;

  /// Creates a reference entry.
  const EntityReferenceEntry({
    required this.key,
    required this.name,
    this.aliases = const [],
    required this.entityType,
  });
}

/// A single resolved candidate from the engine.
class ReferenceCandidate {
  /// The matched entity identity.
  final EntityReferenceEntry entry;

  /// The display name to show in autocomplete.
  final String displayName;

  /// The specific name or alias that matched the query.
  final String matchedName;

  /// Classification of the match.
  final MatchType matchType;

  /// Confidence score: 1.0 = best, 0.0 = worst.
  /// Exact full-name matches score highest.
  final double confidence;

  /// Creates a candidate.
  const ReferenceCandidate({
    required this.entry,
    required this.displayName,
    required this.matchedName,
    required this.matchType,
    required this.confidence,
  });

  @override
  String toString() =>
      'ReferenceCandidate(displayName: $displayName, matchedName: $matchedName, '
      'matchType: $matchType, confidence: $confidence)';
}

/// Pure Dart entity reference resolver.
///
/// Matches a typed query against entity names and aliases with a
/// deterministic ranking: exact name > exact alias > prefix name > prefix
/// alias > substring name > substring alias.
///
/// Usage:
/// ```dart
/// final engine = ReferenceEngine();
/// final entries = entities.map((e) => EntityReferenceEntry(
///   key: e.key,
///   name: e.name,
///   aliases: [...],
///   entityType: 'Character',
/// )).toList();
/// final results = engine.resolve('Ari', entries);
/// ```
class ReferenceEngine {
  /// Maximum number of candidates returned.
  final int maxResults;

  /// Creates a reference engine.
  const ReferenceEngine({this.maxResults = 20});

  /// Resolve a query against the given entity entries.
  ///
  /// Returns a list of [ReferenceCandidate] sorted by relevance:
  /// - Confidence descending (1.0 > 0.9 > 0.7 > 0.6 > 0.3 > 0.2)
  /// - MatchType ascending (exactName < exactAlias < prefixName < ...)
  /// - Alphabetical by displayName for stable ordering
  ///
  /// Returns an empty list if [query] is empty or no candidates match.
  List<ReferenceCandidate> resolve(
    String query,
    List<EntityReferenceEntry> entries,
  ) {
    if (query.isEmpty || entries.isEmpty) return const [];

    final q = query.toLowerCase();
    final results = <ReferenceCandidate>[];

    for (final entry in entries) {
      _matchEntry(q, entry, results);
    }

    results.sort(_compareCandidates);
    return results.length <= maxResults
        ? results
        : results.sublist(0, maxResults);
  }

  void _matchEntry(
    String q,
    EntityReferenceEntry entry,
    List<ReferenceCandidate> results,
  ) {
    final nameLower = entry.name.toLowerCase();

    // Exact full-name match
    if (nameLower == q) {
      results.add(
        ReferenceCandidate(
          entry: entry,
          displayName: entry.name,
          matchedName: entry.name,
          matchType: MatchType.exactName,
          confidence: 1.0,
        ),
      );
      return;
    }

    // Exact alias match
    for (final alias in entry.aliases) {
      if (alias.toLowerCase() == q) {
        results.add(
          ReferenceCandidate(
            entry: entry,
            displayName: entry.name,
            matchedName: alias,
            matchType: MatchType.exactAlias,
            confidence: 0.9,
          ),
        );
        return;
      }
    }

    // Prefix match on name
    if (nameLower.startsWith(q)) {
      results.add(
        ReferenceCandidate(
          entry: entry,
          displayName: entry.name,
          matchedName: entry.name,
          matchType: MatchType.prefixName,
          confidence: 0.7,
        ),
      );
      return;
    }

    // Prefix match on any alias
    for (final alias in entry.aliases) {
      if (alias.toLowerCase().startsWith(q)) {
        results.add(
          ReferenceCandidate(
            entry: entry,
            displayName: entry.name,
            matchedName: alias,
            matchType: MatchType.prefixAlias,
            confidence: 0.6,
          ),
        );
        return;
      }
    }

    // Substring match on name
    if (nameLower.contains(q)) {
      results.add(
        ReferenceCandidate(
          entry: entry,
          displayName: entry.name,
          matchedName: entry.name,
          matchType: MatchType.substringName,
          confidence: 0.3,
        ),
      );
      return;
    }

    // Substring match on any alias
    for (final alias in entry.aliases) {
      if (alias.toLowerCase().contains(q)) {
        results.add(
          ReferenceCandidate(
            entry: entry,
            displayName: entry.name,
            matchedName: alias,
            matchType: MatchType.substringAlias,
            confidence: 0.2,
          ),
        );
        return;
      }
    }
  }

  /// Deterministic comparison for candidate sorting.
  ///
  /// Priority: confidence descending → matchType ascending → displayName ascending.
  static int _compareCandidates(ReferenceCandidate a, ReferenceCandidate b) {
    final confCmp = b.confidence.compareTo(a.confidence);
    if (confCmp != 0) return confCmp;

    final typeCmp = a.matchType.index.compareTo(b.matchType.index);
    if (typeCmp != 0) return typeCmp;

    return a.displayName.compareTo(b.displayName);
  }
}
