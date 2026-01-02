import 'package:hive/hive.dart';

part 'character.g.dart';

@HiveType(typeId: 20)
class CustomField {
  @HiveField(0)
  String name;

  @HiveField(1)
  String type; // 'text', 'number', 'float', 'large_text', 'calendar'

  @HiveField(2)
  String value;

  @HiveField(3)
  bool visible;

  CustomField({
    required this.name,
    required this.type,
    this.value = '',
    this.visible = true,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type, 'value': value, 'visible': visible};
  }

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      name: json['name'],
      type: json['type'],
      value: json['value'],
      visible: json['visible'] ?? true,
    );
  }
}

@HiveType(typeId: 21)
class CustomPanel {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String type; // 'large_text', 'item_lister'

  @HiveField(3)
  String content; // For large_text

  @HiveField(4)
  List<String> items; // For item_lister

  @HiveField(5)
  int order;

  @HiveField(6)
  String column;

  CustomPanel({
    required this.id,
    required this.name,
    required this.type,
    this.content = '',
    List<String>? items,
    this.order = 0,
    this.column = 'right',
  }) : items = items ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'content': content,
      'items': items,
      'order': order,
      'column': column,
    };
  }

  factory CustomPanel.fromJson(Map<String, dynamic> json) {
    return CustomPanel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      content: json['content'] ?? '',
      items: List<String>.from(json['items'] ?? []),
      order: json['order'] ?? 0,
      column: json['column'] ?? 'right',
    );
  }
}

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
  String? originCountry;

  @HiveField(8)
  List<String>? traits;

  @HiveField(9)
  Set<String> congenitalTraits;

  @HiveField(10)
  Map<String, int> leveledTraits;

  @HiveField(11)
  Map<String, int> personalityTraits;

  @HiveField(12)
  Map<String, String>? _customFieldValues;

  Map<String, String> get customFieldValues {
    return _customFieldValues ??= {};
  }

  @HiveField(13)
  List<CustomPanel>? _customPanels;

  List<CustomPanel> get customPanels {
    _customPanels ??= [];
    return _customPanels!;
  }

  set customPanels(List<CustomPanel> value) {
    _customPanels = value;
  }

  @HiveField(14)
  Map<String, int>? _panelOrders;

  Map<String, int> get panelOrders {
    _panelOrders ??= {'bio': 0, 'links': 1, 'image': 2, 'traits': 3};
    return _panelOrders!;
  }

  set panelOrders(Map<String, int> value) {
    _panelOrders = value;
  }

  CharacterIteration({
    required this.iterationName,
    this.name,
    this.aliases,
    this.occupation,
    this.gender,
    this.customGender,
    this.bio,
    this.originCountry,
    this.traits,
    dynamic congenitalTraits, // Can be Set<String> or List<dynamic> from Hive
    Map<String, int>? leveledTraits,
    Map<String, int>? personalityTraits,
    Map<String, String>? customFieldValues,
    List<CustomPanel>? customPanels,
  }) : congenitalTraits = congenitalTraits is Set<String>
           ? congenitalTraits
           : Set<String>.from(congenitalTraits?.cast<String>() ?? []),
       leveledTraits = leveledTraits ?? {},
       personalityTraits = personalityTraits ?? {},
       _customFieldValues = customFieldValues ?? {},
       _customPanels = customPanels ?? [];

  Map<String, dynamic> toJson() {
    return {
      'iterationName': iterationName,
      'name': name,
      'bio': bio,
      'aliases': aliases,
      'occupation': occupation,
      'gender': gender,
      'customGender': customGender,
      'originCountry': originCountry,
      'traits': traits,
      'congenitalTraits': congenitalTraits.toList(),
      'leveledTraits': leveledTraits,
      'personalityTraits': personalityTraits,
      'customFieldValues': customFieldValues,
      'customPanels': customPanels.map((p) => p.toJson()).toList(),
      'panelOrders': panelOrders,
    };
  }

  factory CharacterIteration.fromJson(Map<String, dynamic> json) {
    // Handle migration from old customFields to new customFieldValues
    Map<String, String> customFieldValues = {};
    if (json.containsKey('customFieldValues')) {
      customFieldValues = Map<String, String>.from(
        json['customFieldValues'] as Map<dynamic, dynamic>? ?? {},
      );
    } else if (json.containsKey('customFields')) {
      // Migrate old customFields
      final oldFields =
          (json['customFields'] as List<dynamic>?)
              ?.map((f) => CustomField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [];
      for (final field in oldFields) {
        customFieldValues[field.name] = field.value;
      }
    }

    return CharacterIteration(
        iterationName: json['iterationName'],
        name: json['name'],
        bio: json['bio'],
        aliases: (json['aliases'] as List<dynamic>?)?.cast<String>(),
        occupation: json['occupation'],
        gender: json['gender'],
        customGender: json['customGender'],
        originCountry: json['originCountry'],
        traits: (json['traits'] as List<dynamic>?)?.cast<String>(),
        congenitalTraits: Set<String>.from(
          json['congenitalTraits'] as List<dynamic>? ?? [],
        ),
        leveledTraits: Map<String, int>.from(
          json['leveledTraits'] as Map<dynamic, dynamic>? ?? {},
        ),
        personalityTraits: Map<String, int>.from(
          json['personalityTraits'] as Map<dynamic, dynamic>? ?? {},
        ),
        customFieldValues: customFieldValues,
        customPanels:
            (json['customPanels'] as List<dynamic>?)
                ?.map((p) => CustomPanel.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      )
      .._customFieldValues = customFieldValues
      .._panelOrders = Map<String, int>.from(
        json['panelOrders'] as Map<dynamic, dynamic>? ??
            {'bio': 0, 'links': 1, 'image': 2, 'traits': 3},
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
