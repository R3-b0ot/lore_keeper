/// Universal entity reference for the Lore Keeper persistence layer.
///
/// Every cross-module reference should eventually use [EntityRef] rather
/// than relying on raw Hive box keys. This decouples the logical identity
/// from the storage implementation and enables the Reference Engine to
/// discover and index relationships across the entire project.
///
/// [EntityRef] is intentionally immutable and lightweight. It does not hold
/// a reference to the entity object itself, only the information needed to
/// locate it.
class EntityRef {
  /// Stable application-level identifier for the entity.
  ///
  /// For entities that use Hive keys, this is the key cast to a string.
  /// For entities that define their own IDs (CalendarNode, TimelineEvent, etc.)
  /// this is that ID.
  final String id;

  /// Entity type discriminator.
  /// Use constants from [EntityType].
  final String entityType;

  /// The project this entity belongs to.
  /// Stored as a stringified Hive key.
  final String projectId;

  const EntityRef({
    required this.id,
    required this.entityType,
    required this.projectId,
  });

  /// Creates an [EntityRef] from a Hive box key for the given [entityType]
  /// within [projectId].
  EntityRef.fromKey({
    required dynamic key,
    required this.entityType,
    required this.projectId,
  }) : id = key.toString();

  /// Returns the Hive-compatible key (int or String) stored in [id].
  dynamic get asKey =>
      int.tryParse(id) ?? id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityRef &&
          id == other.id &&
          entityType == other.entityType &&
          projectId == other.projectId;

  @override
  int get hashCode => id.hashCode ^ entityType.hashCode ^ projectId.hashCode;

  @override
  String toString() => 'EntityRef($entityType:$id, project:$projectId)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'projectId': projectId,
      };

  factory EntityRef.fromJson(Map<String, dynamic> json) => EntityRef(
        id: json['id'] as String,
        entityType: json['entityType'] as String,
        projectId: json['projectId'] as String,
      );
}

/// Entity type constants.
///
/// Used by [EntityRef] and the Reference Engine to discriminate between
/// entity kinds without relying on runtime type checks.
abstract final class EntityType {
  static const String project = 'Project';
  static const String chapter = 'Chapter';
  static const String section = 'Section';
  static const String character = 'Character';
  static const String characterIteration = 'CharacterIteration';
  static const String link = 'Link';
  static const String historyEntry = 'HistoryEntry';
  static const String magicSystem = 'MagicSystem';
  static const String magicNode = 'MagicNode';
  static const String calendarSystem = 'CalendarSystem';
  static const String calendarNode = 'CalendarNode';
  static const String timelineEvent = 'TimelineEvent';
  static const String mapData = 'MapData';
  static const String mapLayer = 'MapLayer';
  static const String customTrait = 'CustomTrait';

  static const List<String> all = [
    project,
    chapter,
    section,
    character,
    characterIteration,
    link,
    historyEntry,
    magicSystem,
    magicNode,
    calendarSystem,
    calendarNode,
    timelineEvent,
    mapData,
    mapLayer,
    customTrait,
  ];
}
