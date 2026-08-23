import 'package:lore_keeper/database/entity_ref.dart';

/// Contract for an optional local AI model that augments the Reference Engine.
///
/// The AI provider is **never required** for the application to function.
/// When no model is installed, the device is insufficient, or loading fails,
/// the Reference Engine operates deterministically using its built-in index.
///
/// Implementations:
/// - must not overwrite authoritative user data directly
/// - should produce [AiMetadataEntry]-compatible results
/// - must report their model ID and version for staleness tracking
abstract class AiProvider {
  /// Human-readable name of this provider (e.g. 'local_embedding_model').
  String get name;

  /// Model identifier (e.g. 'nomic-embed-text').
  String get modelId;

  /// Model version string (e.g. '1.0.0').
  String get modelVersion;

  /// Whether the model is currently loaded and ready.
  bool get isReady;

  /// Attempt to load the model. Returns true if the model loaded successfully.
  Future<bool> load();

  /// Release model resources.
  Future<void> unload();

  /// Generate an embedding vector for the given [text].
  /// Returns null if the model cannot produce embeddings.
  Future<List<double>?> embed(String text);

  /// Suggest related entities for the given [entityRef].
  /// Returns a list of suggested [EntityRef]s ranked by relevance.
  /// Returns null if suggestions cannot be generated.
  Future<List<AiSuggestion>?> suggestRelated(EntityRef entityRef);
}

/// A single AI-generated suggestion.
class AiSuggestion {
  /// The suggested entity.
  final EntityRef target;

  /// Confidence score between 0.0 and 1.0.
  final double confidence;

  /// Human-readable reason for the suggestion (e.g. 'semantic_similarity').
  final String reason;

  const AiSuggestion({
    required this.target,
    required this.confidence,
    required this.reason,
  });
}

/// A no-op AI provider used when no model is available.
class NullAiProvider implements AiProvider {
  const NullAiProvider();

  @override
  String get name => 'null';

  @override
  String get modelId => '';

  @override
  String get modelVersion => '';

  @override
  bool get isReady => false;

  @override
  Future<bool> load() async => false;

  @override
  Future<void> unload() async {}

  @override
  Future<List<double>?> embed(String text) async => null;

  @override
  Future<List<AiSuggestion>?> suggestRelated(EntityRef entityRef) async => null;
}
