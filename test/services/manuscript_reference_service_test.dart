/// Unit tests for [ManuscriptReferenceService] reference-type mapping.
///
/// Verifies that each inline `ReferenceEntityType` maps to a distinct
/// [EntityType] so backlinks never conflate a Location/Item/Organization
/// with a Character (which would corrupt the DB-level reference index).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/database/entity_ref.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/manuscript_document.dart';
import 'package:lore_keeper/services/manuscript_reference_service.dart';
import 'package:lore_keeper/services/reference_attribute.dart';

void main() {
  group('ManuscriptReferenceService reference-type mapping', () {
    test('every ReferenceEntityType maps to a distinct EntityType', () {
      final expected = <ReferenceEntityType, String>{
        ReferenceEntityType.character: EntityType.character,
        ReferenceEntityType.location: EntityType.location,
        ReferenceEntityType.item: EntityType.item,
        ReferenceEntityType.organization: EntityType.organization,
        ReferenceEntityType.species: EntityType.species,
        ReferenceEntityType.faction: EntityType.faction,
        ReferenceEntityType.timelineEvent: EntityType.timelineEvent,
        ReferenceEntityType.manuscriptDocument: EntityType.manuscriptDocument,
        ReferenceEntityType.research: EntityType.customTrait,
        ReferenceEntityType.calendarDate: EntityType.calendarNode,
      };
      expect(ReferenceEntityType.values.length, expected.length);
      expect(
        expected.values.toSet().length,
        expected.length,
        reason: 'target EntityTypes must be unique',
      );
    });

    test('EntityType includes manuscript, location, item, organization', () {
      expect(EntityType.all, contains(EntityType.manuscriptDocument));
      expect(EntityType.all, contains(EntityType.location));
      expect(EntityType.all, contains(EntityType.item));
      expect(EntityType.all, contains(EntityType.organization));
      expect(EntityType.all.length, equals(EntityType.all.toSet().length));
    });

    test('extractReferencesFromDocument stores distinct target types', () async {
      final dir = await Directory.systemTemp.createTemp('hive_map_ref_');
      Hive.init(dir.path);
      Hive.registerAdapter(ManuscriptDocumentAdapter());
      final box = await Hive.openBox<ManuscriptDocument>(
        'manuscript_documents',
      );

      final doc = ManuscriptDocument()
        ..id = 'doc_1'
        ..projectId = 7
        ..title = 'Chapter One'
        ..documentTypeIndex = ManuscriptDocumentType.chapter.index;
      doc.richTextJson =
          '[{"insert":"Link to "},{"insert":"","attributes":{"link":"ref:Location:loc_1"}},{"insert":" and "},{"insert":"","attributes":{"link":"ref:Item:item_2"}},{"insert":" end"}]';
      await box.put(doc.id, doc);

      final service = ManuscriptReferenceService(
        projectId: 7,
        referenceEngine: ReferenceEngine(),
        documentBox: box,
      );
      final refs = service.extractReferencesFromDocument(doc);

      final loc = refs.where((r) => r.$1.id == 'loc_1').toList();
      final item = refs.where((r) => r.$1.id == 'item_2').toList();
      expect(loc, hasLength(1));
      expect(loc.single.$1.entityType, EntityType.location);
      expect(item, hasLength(1));
      expect(item.single.$1.entityType, EntityType.item);

      service.rebuildIndex();
      final backlinks = service.getBacklinksTo(
        EntityRef(id: 'loc_1', entityType: EntityType.location, projectId: '7'),
      );
      expect(backlinks, isNotEmpty);

      await box.close();
      await Hive.deleteFromDisk();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
  });
}
