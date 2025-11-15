import 'package:hive/hive.dart';

part 'character.g.dart';

@HiveType(typeId: 10) // Use a new, unused typeId
class CharacterIteration extends HiveObject {
  @HiveField(0)
  String iterationName;

  @HiveField(1)
  String? name;

  @HiveField(2)
  List<String>? aliases;

  @HiveField(3)
  String? occupation;

  @HiveField(4)
  String? gender;

  @HiveField(5)
  String? customGender;

  @HiveField(6)
  String? bio;

  @HiveField(7)
  List<String>? personalityTraits;

  @HiveField(8)
  List<Map<String, String>>? statistics;

  @HiveField(9)
  List<Map<String, String>>? physicalTraits;

  @HiveField(10)
  String? originCountry;

  CharacterIteration({
    required this.iterationName,
    this.name,
    this.aliases,
    this.occupation,
    this.gender,
    this.customGender,
    this.bio,
    this.personalityTraits,
    this.statistics,
    this.physicalTraits,
    this.originCountry,
  });

  Map<String, dynamic> toJson() {
    return {
      'iterationName': iterationName,
      'name': name,
      'bio': bio,
      'aliases': aliases,
      'occupation': occupation,
      'gender': gender,
      'customGender': customGender,
      'personalityTraits': personalityTraits,
      'statistics': statistics,
      'physicalTraits': physicalTraits,
      'originCountry': originCountry,
    };
  }

  factory CharacterIteration.fromJson(Map<String, dynamic> json) {
    return CharacterIteration(
      iterationName: json['iterationName'],
      name: json['name'],
      bio: json['bio'],
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>(),
      occupation: json['occupation'],
      gender: json['gender'],
      customGender: json['customGender'],
      personalityTraits: (json['personalityTraits'] as List<dynamic>?)
          ?.cast<String>(),
      statistics: (json['statistics'] as List<dynamic>?)
          ?.map((s) => (s as Map).cast<String, String>())
          .toList(),
      physicalTraits: (json['physicalTraits'] as List<dynamic>?)
          ?.map((p) => (p as Map).cast<String, String>())
          .toList(),
      originCountry: json['originCountry'],
    );
  }
}

@HiveType(typeId: 4) // Ensure this typeId is unique
class Character extends HiveObject {
  @HiveField(0)
  late String name; // Used for Full Name

  @HiveField(1)
  late int parentProjectId;

  @HiveField(2) // Make aliases non-nullable, but initialize in constructor
  List<String>? aliases;

  @HiveField(3)
  String? species;

  @HiveField(4)
  String? gender;

  @HiveField(5)
  String? customGender;

  @HiveField(7)
  String? residence;

  @HiveField(8)
  String? occupation;

  @HiveField(9)
  String? religion;

  @HiveField(10)
  String? affiliation;

  @HiveField(11)
  String? bio;

  // Stores the layout of other characters when this character is the center of a web.
  @HiveField(15)
  Map<dynamic, Map<String, double>>? relationWebLayout;

  @HiveField(16)
  List<CharacterIteration> iterations = [];

  @HiveField(17)
  late DateTime createdAt;

  // Explicit constructor to allow named parameters and proper initialization
  Character({
    required this.name, // 'name' is a required named parameter
    required this.parentProjectId, // 'parentProjectId' is a required named parameter
    List<String>? aliases, // 'aliases' is an optional named parameter
    this.species,
    this.relationWebLayout,
    DateTime? createdAt,
  }) : aliases = aliases ?? [],
       createdAt = createdAt ?? DateTime.now();

  // Method to convert a Character instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'parentProjectId': parentProjectId,
      'name': name,
      'bio': bio,
      'aliases': aliases,
      'occupation': occupation,
      'gender': gender,
      'customGender': customGender,
      'createdAt': createdAt.toIso8601String(),
      'iterations': iterations.map((i) => i.toJson()).toList(),
      // Convert map keys to strings for JSON compatibility.
      'relationWebLayout': relationWebLayout?.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'species': species,
      'residence': residence,
      'religion': religion,
      'affiliation': affiliation,
    };
  }

  // Factory constructor to create a Character from a JSON map.
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
        name: json['name'],
        parentProjectId: json['parentProjectId'],
        aliases: List<String>.from(json['aliases'] ?? []),
        species: json['species'],
        relationWebLayout: (json['relationWebLayout'] as Map<String, dynamic>?)
            ?.map(
              (key, value) => MapEntry(
                // Parse the string key back to an integer for Hive compatibility.
                int.tryParse(key) ?? key,
                (value as Map<String, dynamic>).map(
                  (k, v) => MapEntry(k, v.toDouble()),
                ),
              ),
            ),
        createdAt: DateTime.parse(json['createdAt']),
      )
      ..bio = json['bio']
      // Create deep copies of iterations to avoid HiveError when reverting.
      // Each iteration is a HiveObject and cannot be in two places at once.
      ..iterations =
          (json['iterations'] as List<dynamic>?)
              ?.map(
                (i) => CharacterIteration.fromJson(i as Map<String, dynamic>),
              )
              .toList() ??
          [];
  }
}
