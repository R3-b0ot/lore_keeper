import 'package:hive/hive.dart';

enum ClassificationRank {
  category,
  lineage,
  kingdom,
  phylum,
  classRank,
  order,
  family,
  genus,
  species,
  subspecies;

  static ClassificationRank fromString(String value) => values.firstWhere(
    (rank) => rank.name == value,
    orElse: () => throw ArgumentError('Invalid rank: $value'),
  );

  int get rankOrder => index;

  ClassificationRank? get nextRank =>
      index + 1 < values.length ? values[index + 1] : null;

  String get displayName => switch (this) {
    ClassificationRank.category => 'Category',
    ClassificationRank.lineage => 'Lineage',
    ClassificationRank.kingdom => 'Kingdom',
    ClassificationRank.phylum => 'Phylum',
    ClassificationRank.classRank => 'Class',
    ClassificationRank.order => 'Order',
    ClassificationRank.family => 'Family',
    ClassificationRank.genus => 'Genus',
    ClassificationRank.species => 'Species',
    ClassificationRank.subspecies => 'Subspecies',
  };
}

@HiveType(typeId: 36)
class ClassificationNode extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  int projectId;
  @HiveField(2)
  String? parentId;
  @HiveField(3)
  String rank;
  @HiveField(4)
  String name;
  @HiveField(5)
  String normalizedName;
  @HiveField(6)
  String content;
  @HiveField(7)
  String iconKey;
  @HiveField(8)
  int colorValue;
  @HiveField(9)
  List<String> childrenOrder;
  @HiveField(10)
  int createdAt;
  @HiveField(11)
  int updatedAt;
  @HiveField(12)
  String? scientificName;
  @HiveField(13)
  String status;
  @HiveField(14)
  String? origin;
  @HiveField(15)
  String averageLifespan;
  @HiveField(16)
  String averageHeight;
  @HiveField(17)
  String reproduction;
  @HiveField(18)
  String diet;
  @HiveField(19)
  String sentience;
  @HiveField(20)
  String? population;
  @HiveField(21)
  String physiology;

  ClassificationNode({
    required this.id,
    required this.projectId,
    this.parentId,
    required this.rank,
    required this.name,
    required this.normalizedName,
    this.content = '',
    this.iconKey = 'folder',
    this.colorValue = 0xFF6366F1,
    List<String>? childrenOrder,
    int? createdAt,
    int? updatedAt,
    this.scientificName,
    this.status = 'Extant',
    this.origin,
    this.averageLifespan = '',
    this.averageHeight = '',
    this.reproduction = '',
    this.diet = '',
    this.sentience = '',
    this.population,
    this.physiology = '',
  }) : childrenOrder = childrenOrder ?? <String>[],
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  ClassificationRank get rankEnum => ClassificationRank.fromString(rank);

  bool get isSpeciesOrSubspecies =>
      rank == ClassificationRank.species.name ||
      rank == ClassificationRank.subspecies.name;

  bool get hasArticleContent => content.isNotEmpty;

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  static String normalizeName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static String normalize(String name) => normalizeName(name);
}

@HiveType(typeId: 37)
class ClassificationArticle extends HiveObject {
  @HiveField(0)
  String nodeId;
  @HiveField(1)
  int projectId;
  @HiveField(2)
  String content;
  @HiveField(3)
  int updatedAt;

  ClassificationArticle({
    required this.nodeId,
    required this.projectId,
    this.content = '',
    int? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  void updateTimestamp() {
    updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
