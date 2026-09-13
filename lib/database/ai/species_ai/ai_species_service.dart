import 'dart:convert';

import 'package:lore_keeper/database/ai/ai_provider.dart';

/// One rank in a species classification path (e.g. `kingdom` → `Animalia`).
class GeneratedClassificationStep {
  /// Canonical rank key: `category`, `lineage`, `kingdom`, `phylum`,
  /// `classRank`, `order`, `family`, `genus`, `species`, `subspecies`.
  final String rank;

  /// The node name written to the classification tree.
  final String name;

  /// Icon identifier passed to the classification node.
  final String iconKey;

  /// 32-bit ARGB accent color for the node, or the default indigo.
  final int colorValue;

  const GeneratedClassificationStep({
    required this.rank,
    required this.name,
    this.iconKey = 'folder',
    this.colorValue = 0xFF6366F1,
  });

  /// A copy with [name]/[iconKey]/[colorValue] replaced.
  GeneratedClassificationStep copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
  }) => GeneratedClassificationStep(
    rank: rank,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
  );
}

/// An AI-generated, user-reviewable species draft.
///
/// [path] is the proposed classification (existing nodes are merged, missing
/// nodes are created on save). The remaining fields are the scientific
/// breakdown written onto the leaf species/subspecies node.
class AiGeneratedSpecies {
  /// Ordered classification path from category down to species/subspecies.
  final List<GeneratedClassificationStep> path;

  final String? scientificName;
  final String status;
  final String? origin;
  final String averageLifespan;
  final String averageHeight;
  final String reproduction;
  final String diet;
  final String sentience;
  final String? population;
  final String physiology;

  /// Long-form encyclopedia entry (the wiki article body).
  final String content;

  const AiGeneratedSpecies({
    required this.path,
    this.scientificName,
    this.status = 'Extant',
    this.origin,
    this.averageLifespan = '',
    this.averageHeight = '',
    this.reproduction = '',
    this.diet = '',
    this.sentience = '',
    this.population,
    this.physiology = '',
    this.content = '',
  });

  /// A copy with the given scientific-breakdown fields replaced.
  AiGeneratedSpecies copyWith({
    List<GeneratedClassificationStep>? path,
    String? scientificName,
    String? status,
    String? origin,
    String? averageLifespan,
    String? averageHeight,
    String? reproduction,
    String? diet,
    String? sentience,
    String? population,
    String? physiology,
    String? content,
  }) => AiGeneratedSpecies(
    path: path ?? this.path,
    scientificName: scientificName ?? this.scientificName,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    averageLifespan: averageLifespan ?? this.averageLifespan,
    averageHeight: averageHeight ?? this.averageHeight,
    reproduction: reproduction ?? this.reproduction,
    diet: diet ?? this.diet,
    sentience: sentience ?? this.sentience,
    population: population ?? this.population,
    physiology: physiology ?? this.physiology,
    content: content ?? this.content,
  );
}

/// Generates and parses AI-assisted species drafts from an [AiProvider].
///
/// The provider is passed in (built from global settings) so the flow stays
/// independent of the app's shared Reference Engine instance. `load()` and
/// `chat()` are called through the [AiProvider] contract, and the model
/// download/token cost only happens when a provider can actually respond.
class AiSpeciesService {
  static const List<String> _canonicalRanks = [
    'category',
    'lineage',
    'kingdom',
    'phylum',
    'classRank',
    'order',
    'family',
    'genus',
    'species',
    'subspecies',
  ];

  static const Set<String> _validStatuses = {
    'Extant',
    'Extinct',
    'Endangered',
    'Mythical',
    'Unknown',
  };

  /// Temperature for the species draft (creative but still structured).
  static const double _temperature = 0.7;

  AiSpeciesService();

  /// Generates a species draft from a [commonName] and [description].
  ///
  /// Returns null when the provider is disabled/unavailable, fails to load,
  /// or returns text that cannot be parsed into a [AiGeneratedSpecies].
  Future<AiGeneratedSpecies?> generate({
    required AiProvider provider,
    required String commonName,
    required String description,
    int? maxTokens = 1500,
  }) async {
    final loaded = await provider.load();
    if (!loaded) return null;
    final raw = await provider.chat(
      systemPrompt: systemPrompt,
      userPrompt: _userPrompt(commonName: commonName, description: description),
      temperature: _temperature,
      maxTokens: maxTokens,
    );
    if (raw == null || raw.trim().isEmpty) return null;
    return parse(raw, commonName: commonName);
  }

  /// Parses the model's reply into an [AiGeneratedSpecies].
  ///
  /// Defensive by design: the reply may be wrapped in a markdown fence, have
  /// stray prose, use `class` instead of `classRank`, or guess a species name
  /// different from what the user typed — all of which is normalized here.
  AiGeneratedSpecies? parse(String raw, {required String commonName}) {
    final jsonText = _extractJson(raw);
    if (jsonText == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    final steps = _parsePath(decoded['path']);
    _normalizePath(steps, commonName);

    return AiGeneratedSpecies(
      path: steps,
      scientificName: _nullableString(decoded['scientificName']),
      status: _statusOf(decoded['status']),
      origin: _nullableString(decoded['origin']),
      averageLifespan: _emptyString(decoded['averageLifespan']),
      averageHeight: _emptyString(decoded['averageHeight']),
      reproduction: _emptyString(decoded['reproduction']),
      diet: _emptyString(decoded['diet']),
      sentience: _emptyString(decoded['sentience']),
      population: _nullableString(decoded['population']),
      physiology: _emptyString(decoded['physiology']),
      content: _emptyString(decoded['content']),
    );
  }

  static String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  static List<GeneratedClassificationStep> _parsePath(Object? aiPath) {
    final steps = <GeneratedClassificationStep>[];
    if (aiPath is! List) return steps;
    for (final entry in aiPath) {
      if (entry is! Map<String, dynamic>) continue;
      final rank = _normalizeRank(entry['rank']);
      if (rank == null) continue;
      final name = entry['name'] is String
          ? (entry['name'] as String).trim()
          : '';
      if (name.isEmpty) continue;
      steps.add(GeneratedClassificationStep(rank: rank, name: name));
    }
    return steps;
  }

  static String? _normalizeRank(Object? value) {
    if (value is! String) return null;
    final rank = switch (value.trim().toLowerCase()) {
      'class' => 'classRank',
      var other => other,
    };
    return _canonicalRanks.contains(rank) ? rank : null;
  }

  static void _normalizePath(
    List<GeneratedClassificationStep> steps,
    String commonName,
  ) {
    // De-duplicate ranks (first occurrence wins) and reorder canonically so
    // a sloppy reply cannot produce an invalid tree (e.g. genus above kingdom).
    final byRank = <String, GeneratedClassificationStep>{};
    for (final step in steps) {
      byRank.putIfAbsent(step.rank, () => step);
    }
    steps
      ..clear()
      ..addAll([
        for (final rank in _canonicalRanks)
          if (byRank[rank] != null) byRank[rank]!,
      ]);

    // Category must be one of the two root categories the app enforces.
    if (steps.isEmpty || steps.first.rank != 'category') {
      steps.insert(
        0,
        const GeneratedClassificationStep(rank: 'category', name: 'Fauna'),
      );
    } else if (steps.first.name.toLowerCase() != 'fauna' &&
        steps.first.name.toLowerCase() != 'flora') {
      steps[0] = steps[0].copyWith(name: 'Fauna');
    }

    // The species step is the wiki node name: it must mirror the common name
    // the user typed, so the resulting tree entry is predictable.
    final speciesIndex = steps.indexWhere((s) => s.rank == 'species');
    if (speciesIndex < 0) {
      steps.add(GeneratedClassificationStep(rank: 'species', name: commonName));
    } else {
      steps[speciesIndex] = steps[speciesIndex].copyWith(name: commonName);
    }
  }

  static String? _nullableString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _emptyString(Object? value) {
    if (value is! String) return '';
    return value.trim();
  }

  static String _statusOf(Object? value) {
    if (value is String) {
      final match = _validStatuses
          .where((s) => s.toLowerCase() == value.trim().toLowerCase())
          .firstOrNull;
      if (match != null) return match;
    }
    return 'Extant';
  }

  static const String systemPrompt = '''
You are a scientific worldbuilding assistant for a fantasy or science-fiction novel. Given a common name and a short description of a fictional creature, produce a complete biological classification and species profile so the author can reference it consistently across the story.

Return ONLY a single JSON object. No markdown fences, no commentary. Use this exact schema:

{
  "path": [
    {"rank": "category", "name": "Fauna | Flora"},
    {"rank": "lineage", "name": "..."},
    {"rank": "kingdom", "name": "..."},
    {"rank": "phylum", "name": "..."},
    {"rank": "classRank", "name": "..."},
    {"rank": "order", "name": "..."},
    {"rank": "family", "name": "..."},
    {"rank": "genus", "name": "..."},
    {"rank": "species", "name": "<the user's common name exactly>"}
  ],
  "scientificName": "Genus species",
  "status": "Extant",
  "origin": "homeworld or region or null",
  "averageLifespan": "e.g. 40-60 years",
  "averageHeight": "e.g. 180-220 cm",
  "reproduction": "e.g. Sexual, 8 month gestation",
  "diet": "e.g. Omnivorous",
  "sentience": "e.g. Sapient",
  "population": "estimate or null",
  "physiology": "2-4 sentence physiological description",
  "content": "A 2-3 paragraph encyclopedia entry covering biology, behavior, habitat, and culture if the species is sentient"
}

Rules:
- The path walks ranks in order. Use the exact rank keys; note "classRank", never "class". Skip any rank that does not apply to a species.
- "category" must be exactly "Fauna" or "Flora".
- The final "species" step name MUST equal the user-provided common name verbatim.
- For alien worlds, invent plausible fictional taxa (e.g. lineage "Xylorian Life") instead of forcing real-life kingdoms and phyla when the description implies a non-terrestrial origin.
- All numeric values are strings. Any field that does not apply must be null or an empty string.
''';

  static String _userPrompt({
    required String commonName,
    required String description,
  }) =>
      '''
Common name: $commonName
Description: $description
''';
}
