// lib/services/entity_reference_entries.dart

import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/services/reference_engine.dart';

/// Builders that project domain entities onto the uniform [EntityReferenceEntry]
/// shape consumed by the @mention autocomplete engine.
///
/// Keeping these mappings here (rather than in the widgets) keeps candidate
/// construction free of UI logic and reusable across the editor, tests, and any
/// future callers, while preserving a single canonical name source per entity.
extension CharacterReferenceEntry on Character {
  /// Produce the autocomplete entry for a [Character], folding aliases and
  /// iteration names into the searchable alias list.
  EntityReferenceEntry toReferenceEntry() {
    final aliasesList = <String>[if (aliases != null) ...aliases!];
    for (final it in iterations) {
      if (it.name != null) aliasesList.add(it.name!);
      if (it.aliases != null) aliasesList.addAll(it.aliases!);
    }
    return EntityReferenceEntry(
      key: key,
      name: name,
      aliases: aliasesList,
      entityType: EntityType.character,
    );
  }
}

/// Species are modeled as [ClassificationNode]s. Only leaf/visible entries with
/// a stable id are referenceable; the node's [name] is the canonical label.
extension SpeciesReferenceEntry on ClassificationNode {
  EntityReferenceEntry toReferenceEntry() {
    return EntityReferenceEntry(
      key: id,
      name: name,
      aliases: const [],
      entityType: EntityType.species,
    );
  }
}

extension TimelineEventReferenceEntry on TimelineEvent {
  EntityReferenceEntry toReferenceEntry() {
    return EntityReferenceEntry(
      key: id,
      name: name,
      aliases: const [],
      entityType: EntityType.timelineEvent,
    );
  }
}

extension ManuscriptDocumentReferenceEntry on ManuscriptDocument {
  EntityReferenceEntry toReferenceEntry() {
    return EntityReferenceEntry(
      key: id,
      name: title,
      aliases: const [],
      entityType: EntityType.manuscriptDocument,
    );
  }
}
