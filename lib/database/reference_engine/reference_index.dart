import 'package:lore_keeper/database/entity_ref.dart';

/// A single entry in the reference index.
///
/// Each entry records one directed reference from [source] to [target],
/// optionally scoped to a [containerEntity] (e.g. a chapter, scene, or
/// timeline event that contains the reference).
class ReferenceIndexEntry {
  /// The entity that contains the reference.
  final EntityRef source;

  /// The entity being referenced.
  final EntityRef target;

  /// The kind of reference (e.g. 'mentions', 'appears_in', 'linked_to').
  final String kind;

  /// The container that scopes this reference, if any.
  /// For example: the chapter where a character mentions another character.
  final EntityRef? containerEntity;

  /// When this index entry was last computed.
  final DateTime computedAt;

  const ReferenceIndexEntry({
    required this.source,
    required this.target,
    required this.kind,
    this.containerEntity,
    required this.computedAt,
  });

  Map<String, dynamic> toJson() => {
        'source': source.toJson(),
        'target': target.toJson(),
        'kind': kind,
        'containerEntity': containerEntity?.toJson(),
        'computedAt': computedAt.toIso8601String(),
      };

  factory ReferenceIndexEntry.fromJson(Map<String, dynamic> json) =>
      ReferenceIndexEntry(
        source: EntityRef.fromJson(json['source'] as Map<String, dynamic>),
        target: EntityRef.fromJson(json['target'] as Map<String, dynamic>),
        kind: json['kind'] as String,
        containerEntity: json['containerEntity'] != null
            ? EntityRef.fromJson(
                json['containerEntity'] as Map<String, dynamic>)
            : null,
        computedAt: DateTime.parse(json['computedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceIndexEntry &&
          source == other.source &&
          target == other.target &&
          kind == other.kind &&
          containerEntity == other.containerEntity;

  @override
  int get hashCode =>
      source.hashCode ^ target.hashCode ^ kind.hashCode ^ containerEntity.hashCode;
}
