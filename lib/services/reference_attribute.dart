/// Inline reference metadata for Quill document text.
///
/// Stores the target entity type and identity alongside visible text.
/// Encoded as a Quill [LinkAttribute] value with the `ref:` prefix
/// so the text renders as a hyperlink and carries metadata.
library;

/// Entity types that can be referenced inline.
enum ReferenceEntityType {
  character('Character'),
  location('Location'),
  item('Item'),
  organization('Organization'),
  species('Species'),
  faction('Faction'),
  timelineEvent('Timeline Event'),
  manuscriptDocument('Manuscript Document'),
  research('Research'),
  calendarDate('Calendar Date');

  const ReferenceEntityType(this.label);
  final String label;

  /// Parse from a label string, returning null if unknown.
  static ReferenceEntityType? fromLabel(String label) {
    for (final type in values) {
      if (type.label == label) return type;
    }
    return null;
  }

  /// Map from an [EntityType] constant string back to this inline-reference
  /// enum, or null when the type is not referenceable inline.
  ///
  /// The [EntityType] constants (`character`, `species`, ...) differ from the
  /// human [label] for a few types (`TimelineEvent` vs `Timeline Event`), so
  /// a naive [fromLabel] lookup would fail for those. This uses the canonical
  /// entity-type identity instead of the display label.
  static ReferenceEntityType? fromEntityType(String entityType) {
    return switch (entityType) {
      'Character' => ReferenceEntityType.character,
      'Location' => ReferenceEntityType.location,
      'Item' => ReferenceEntityType.item,
      'Organization' => ReferenceEntityType.organization,
      'Species' => ReferenceEntityType.species,
      'Faction' => ReferenceEntityType.faction,
      'TimelineEvent' => ReferenceEntityType.timelineEvent,
      'ManuscriptDocument' => ReferenceEntityType.manuscriptDocument,
      'CustomTrait' => ReferenceEntityType.research,
      'CalendarNode' => ReferenceEntityType.calendarDate,
      _ => null,
    };
  }
}

/// The target of an inline reference.
///
/// Separates the visible manuscript text from the entity identity.
/// Two references can display the same name but point to different entities.
class ReferenceTarget {
  /// The entity type (Character, Location, etc.).
  final ReferenceEntityType type;

  /// The entity's unique identity key (Hive key).
  final dynamic id;

  const ReferenceTarget({required this.type, required this.id});

  /// Encode as a string for storage in Quill link attributes.
  ///
  /// Format: `ref:TypeLabel:id`
  /// Example: `ref:Character:42`
  String encode() => 'ref:${type.label}:$id';

  /// Decode from an encoded string, returning null if malformed.
  static ReferenceTarget? decode(String value) {
    if (!value.startsWith('ref:')) return null;
    final rest = value.substring(4);
    final colonIndex = rest.indexOf(':');
    if (colonIndex == -1) return null;
    final typeLabel = rest.substring(0, colonIndex);
    final idString = rest.substring(colonIndex + 1);
    final type = ReferenceEntityType.fromLabel(typeLabel);
    if (type == null) return null;
    return ReferenceTarget(type: type, id: idString);
  }

  /// Whether this encoded value represents a reference link.
  static bool isReference(String value) => value.startsWith('ref:');

  @override
  String toString() => 'ReferenceTarget(${type.label}:$id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceTarget &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          id == other.id;

  @override
  int get hashCode => type.hashCode ^ id.hashCode;
}
