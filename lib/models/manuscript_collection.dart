// lib/models/manuscript_collection.dart

import 'package:hive/hive.dart';

import 'package:lore_keeper/models/manuscript_document.dart';

part 'manuscript_collection.g.dart';

/// A user-created, persistent Manuscript collection.
///
/// Custom collections filter the manuscript list by optional [type] and
/// [status] (either may be null to mean "any"). They are stored in Hive so
/// they survive restarts, and they are scoped to a single project via
/// [projectId] (spec §10: "Custom Collections must be user-created,
/// persistent, searchable/filterable").
@HiveType(typeId: 41)
class ManuscriptCollection extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int projectId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  int? documentTypeIndex;

  @HiveField(4)
  int? statusIndex;

  @HiveField(5)
  int createdAt;

  ManuscriptCollection({
    required this.id,
    required this.projectId,
    required this.name,
    this.documentTypeIndex,
    this.statusIndex,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  ManuscriptDocumentType? get documentType => documentTypeIndex != null
      ? ManuscriptDocumentType.values[documentTypeIndex!]
      : null;

  set documentType(ManuscriptDocumentType? type) =>
      documentTypeIndex = type?.index;

  ManuscriptDocumentStatus? get status => statusIndex != null
      ? ManuscriptDocumentStatus.values[statusIndex!]
      : null;

  set status(ManuscriptDocumentStatus? s) => statusIndex = s?.index;
}
