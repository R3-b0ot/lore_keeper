/// Storage contract for AI-derived metadata attached to authoritative entities.
///
/// AI metadata is always **derived** and **rebuildable**. If deleted, the
/// application continues to function normally. AI metadata never overwrites
/// user-authored data.
///
/// Examples of AI metadata:
/// - suggested entity links
/// - detected aliases
/// - semantic similarity scores
/// - embeddings
/// - classifications
/// - suggested tags
class AiMetadataEntry {
  /// The entity this metadata is about.
  final String entityId;

  /// Entity type of the subject.
  final String entityType;

  /// Kind of AI-derived information (e.g. 'suggested_link', 'alias', 'embedding').
  final String kind;

  /// The AI model identifier that produced this entry.
  final String modelId;

  /// Version of the AI model.
  final String modelVersion;

  /// When this entry was generated.
  final DateTime generatedAt;

  /// Confidence score between 0.0 and 1.0, where applicable.
  /// Null when confidence is not meaningful for this kind.
  final double? confidence;

  /// The payload of the AI-derived data. Structure depends on [kind].
  final Map<String, dynamic> payload;

  const AiMetadataEntry({
    required this.entityId,
    required this.entityType,
    required this.kind,
    required this.modelId,
    required this.modelVersion,
    required this.generatedAt,
    this.confidence,
    required this.payload,
  });

  /// Returns true if this entry was produced by a different model/version
  /// than [currentModelId]/[currentModelVersion], meaning it should be
  /// invalidated and regenerated.
  bool isStale(String currentModelId, String currentModelVersion) =>
      modelId != currentModelId || modelVersion != currentModelVersion;

  Map<String, dynamic> toJson() => {
        'entityId': entityId,
        'entityType': entityType,
        'kind': kind,
        'modelId': modelId,
        'modelVersion': modelVersion,
        'generatedAt': generatedAt.toIso8601String(),
        'confidence': confidence,
        'payload': payload,
      };

  factory AiMetadataEntry.fromJson(Map<String, dynamic> json) =>
      AiMetadataEntry(
        entityId: json['entityId'] as String,
        entityType: json['entityType'] as String,
        kind: json['kind'] as String,
        modelId: json['modelId'] as String,
        modelVersion: json['modelVersion'] as String,
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        confidence: (json['confidence'] as num?)?.toDouble(),
        payload: Map<String, dynamic>.from(
            json['payload'] as Map? ?? {}),
      );
}
