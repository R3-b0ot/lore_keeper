// lib/models/manuscript_document.dart

import 'package:hive_flutter/hive_flutter.dart';

part 'manuscript_document.g.dart';

enum ManuscriptDocumentType {
  manuscript('Manuscript'),
  part('Part'),
  chapter('Chapter'),
  scene('Scene'),
  section('Section'),
  note('Note'),
  research('Research'),
  frontMatter('Front Matter'),
  backMatter('Back Matter'),
  custom('Custom');

  const ManuscriptDocumentType(this.label);
  final String label;

  static ManuscriptDocumentType fromLabel(String label) {
    return values.firstWhere(
      (e) => e.label == label,
      orElse: () => ManuscriptDocumentType.custom,
    );
  }
}

enum ManuscriptDocumentStatus {
  idea('Idea'),
  outline('Outline'),
  draft('Draft'),
  revised('Revised'),
  complete('Complete'),
  archived('Archived');

  const ManuscriptDocumentStatus(this.label);
  final String label;

  static ManuscriptDocumentStatus fromLabel(String label) {
    return values.firstWhere(
      (e) => e.label == label,
      orElse: () => ManuscriptDocumentStatus.draft,
    );
  }
}

@HiveType(typeId: 40)
class ManuscriptDocument extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int projectId;

  @HiveField(2)
  late String title;

  @HiveField(3)
  int documentTypeIndex = ManuscriptDocumentType.chapter.index;

  @HiveField(4)
  String? parentId;

  @HiveField(5)
  int orderIndex = 0;

  @HiveField(6)
  String? richTextJson;

  @HiveField(7)
  int statusIndex = ManuscriptDocumentStatus.draft.index;

  @HiveField(8)
  String? summary;

  @HiveField(9)
  String? povCharacterId;

  @HiveField(10)
  String? locationId;

  @HiveField(11)
  String? timelineEventId;

  @HiveField(12)
  String? plotline;

  @HiveField(13)
  List<String> characterIds = [];

  @HiveField(14)
  List<String> tagIds = [];

  @HiveField(15)
  bool isExpanded = true;

  @HiveField(16)
  DateTime? createdAt;

  @HiveField(17)
  DateTime? modifiedAt;

  @HiveField(18)
  int wordCount = 0;

  @HiveField(19)
  int characterCount = 0;

  @HiveField(20)
  String? purpose;

  @HiveField(21)
  bool isFavorite = false;

  /// The calendar system the assigned scene date was chosen in (Hive key of
  /// CalendarSystem; 0 = unassigned). Kept so a re-selected date is rendered
  /// through the correct Chronology (§16).
  @HiveField(22)
  int calendarDateSystemKey = 0;

  /// Absolute year of the assigned scene date in its [calendarDateSystemKey].
  /// 0 = unassigned.
  @HiveField(23)
  int calendarDateYear = 0;

  /// Day-of-year (1-based) of the assigned scene date. 0 = unassigned.
  @HiveField(24)
  int calendarDateDayOfYear = 0;

  ManuscriptDocumentType get documentType =>
      ManuscriptDocumentType.values[documentTypeIndex];

  set documentType(ManuscriptDocumentType type) =>
      documentTypeIndex = type.index;

  ManuscriptDocumentStatus get status =>
      ManuscriptDocumentStatus.values[statusIndex];

  set status(ManuscriptDocumentStatus s) => statusIndex = s.index;

  bool get isContainer =>
      documentType == ManuscriptDocumentType.manuscript ||
      documentType == ManuscriptDocumentType.part ||
      documentType == ManuscriptDocumentType.chapter ||
      documentType == ManuscriptDocumentType.section;

  bool get isLeaf =>
      documentType == ManuscriptDocumentType.scene ||
      documentType == ManuscriptDocumentType.note ||
      documentType == ManuscriptDocumentType.research;

  /// Whether a calendar date has been assigned to this scene (§16).
  bool get hasCalendarDate => calendarDateYear > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'documentType': documentType.label,
      'parentId': parentId,
      'orderIndex': orderIndex,
      'richTextJson': richTextJson,
      'status': status.label,
      'summary': summary,
      'povCharacterId': povCharacterId,
      'locationId': locationId,
      'timelineEventId': timelineEventId,
      'plotline': plotline,
      'characterIds': characterIds,
      'tagIds': tagIds,
      'isExpanded': isExpanded,
      'createdAt': createdAt?.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'wordCount': wordCount,
      'characterCount': characterCount,
      'purpose': purpose,
      'isFavorite': isFavorite,
      'calendarDateSystemKey': calendarDateSystemKey,
      'calendarDateYear': calendarDateYear,
      'calendarDateDayOfYear': calendarDateDayOfYear,
    };
  }

  static ManuscriptDocument fromJson(Map<String, dynamic> json) {
    final doc = ManuscriptDocument()
      ..id = json['id'] as String
      ..projectId = json['projectId'] as int
      ..title = json['title'] as String
      ..documentType = ManuscriptDocumentType.fromLabel(
        json['documentType'] as String? ?? 'Chapter',
      )
      ..parentId = json['parentId'] as String?
      ..orderIndex = json['orderIndex'] as int? ?? 0
      ..richTextJson = json['richTextJson'] as String?
      ..status = ManuscriptDocumentStatus.fromLabel(
        json['status'] as String? ?? 'Draft',
      )
      ..summary = json['summary'] as String?
      ..povCharacterId = json['povCharacterId'] as String?
      ..locationId = json['locationId'] as String?
      ..timelineEventId = json['timelineEventId'] as String?
      ..plotline = json['plotline'] as String?
      ..characterIds = (json['characterIds'] as List?)?.cast<String>() ?? []
      ..tagIds = (json['tagIds'] as List?)?.cast<String>() ?? []
      ..isExpanded = json['isExpanded'] as bool? ?? true
      ..createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null
      ..modifiedAt = json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null
      ..wordCount = json['wordCount'] as int? ?? 0
      ..characterCount = json['characterCount'] as int? ?? 0
      ..purpose = json['purpose'] as String?
      ..isFavorite = json['isFavorite'] as bool? ?? false
      ..calendarDateSystemKey = json['calendarDateSystemKey'] as int? ?? 0
      ..calendarDateYear = json['calendarDateYear'] as int? ?? 0
      ..calendarDateDayOfYear = json['calendarDateDayOfYear'] as int? ?? 0;
    return doc;
  }
}
