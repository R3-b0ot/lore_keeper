import 'package:lore_keeper/database/ai/ai_provider.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_index.dart';

/// Core Reference Engine.
///
/// The engine coordinates:
/// - a deterministic reference index (rebuilt from authoritative data)
/// - an optional AI provider (for semantic suggestions and embeddings)
///
/// The engine must work fully offline with no AI model installed.
/// AI enhances the engine; it does not replace it.
///
/// ## Architecture
///
/// ```text
///   Application Data (authoritative)
///         │
///         ▼
///   Reference Index (deterministic, rebuildable)
///         │
///         ├──► DeterministicReferenceProvider (always works)
///         │
///         └──► AIReferenceProvider (optional enhancement)
///                    │
///                    └──► LocalAIModel (optional)
/// ```
class ReferenceEngine {
  final AiProvider _aiProvider;

  /// The in-memory reference index.
  final List<ReferenceIndexEntry> _index = [];

  ReferenceEngine({AiProvider? aiProvider})
      : _aiProvider = aiProvider ?? const NullAiProvider();

  /// The AI provider backing this engine.
  AiProvider get aiProvider => _aiProvider;

  /// Whether the AI model is loaded and ready.
  bool get hasAi => _aiProvider.isReady;

  /// The current reference index. Read-only access.
  List<ReferenceIndexEntry> get index => List.unmodifiable(_index);

  /// Total number of entries in the index.
  int get length => _index.length;

  // ── Index Management ────────────────────────────────────────────────────

  /// Add a single entry to the index.
  void addEntry(ReferenceIndexEntry entry) {
    _index.add(entry);
  }

  /// Remove all index entries.
  void clear() {
    _index.clear();
  }

  /// Remove all index entries that match a predicate.
  void removeWhere(bool Function(ReferenceIndexEntry) test) {
    _index.removeWhere(test);
  }

  /// Rebuild the entire index from authoritative data.
  ///
  /// [extractReferences] is called once per entity type and should return
  /// all index entries that can be derived from the authoritative data of
  /// that entity kind.
  ///
  /// This is a full rebuild: the existing index is cleared first.
  Future<void> rebuildIndex({
    required Future<List<ReferenceIndexEntry>> Function(String entityType)
        extractReferences,
  }) async {
    _index.clear();
    for (final entityType in EntityType.all) {
      final entries = await extractReferences(entityType);
      _index.addAll(entries);
    }
  }

  // ── Query ───────────────────────────────────────────────────────────────

  /// All index entries originating from [source].
  List<ReferenceIndexEntry> referencesFrom(EntityRef source) =>
      _index.where((e) => e.source == source).toList();

  /// All index entries pointing to [target] (backlinks).
  List<ReferenceIndexEntry> backlinksTo(EntityRef target) =>
      _index.where((e) => e.target == target).toList();

  /// All index entries for entities inside [containerEntity].
  List<ReferenceIndexEntry> insideContainer(EntityRef containerEntity) =>
      _index.where((e) => e.containerEntity == containerEntity).toList();

  /// Search the index by token. Returns entries whose source, target, or
  /// kind match [query] (case-insensitive).
  List<ReferenceIndexEntry> search(String query) {
    final lower = query.toLowerCase();
    return _index
        .where((e) =>
            e.source.id.toLowerCase().contains(lower) ||
            e.target.id.toLowerCase().contains(lower) ||
            e.kind.toLowerCase().contains(lower) ||
            e.source.entityType.toLowerCase().contains(lower) ||
            e.target.entityType.toLowerCase().contains(lower))
        .toList();
  }

  /// Find all distinct entity types referenced by [entityRef].
  Set<String> referencedEntityTypes(EntityRef entityRef) =>
      _index
          .where((e) => e.source == entityRef || e.target == entityRef)
          .map((e) =>
              e.source == entityRef
                  ? e.target.entityType
                  : e.source.entityType)
          .toSet();

  // ── AI Integration ──────────────────────────────────────────────────────

  /// Delegate to the AI provider for semantic suggestions.
  /// Returns null when AI is unavailable.
  Future<List<AiSuggestion>?> aiSuggestRelated(EntityRef entityRef) async {
    if (!_aiProvider.isReady) return null;
    return _aiProvider.suggestRelated(entityRef);
  }

  /// Delegate to the AI provider for text embedding.
  /// Returns null when AI is unavailable.
  Future<List<double>?> aiEmbed(String text) async {
    if (!_aiProvider.isReady) return null;
    return _aiProvider.embed(text);
  }
}
