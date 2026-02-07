import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'character.g.dart';

List<dynamic> _coerceList(dynamic value) {
  if (value is List) return value;
  if (value is Map) return value.values.toList();
  return const [];
}

Map<String, int> _coerceStringIntMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), (val as num).toInt()),
    );
  }
  return {};
}

Map<String, String> _coerceStringStringMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }
  return {};
}

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

@HiveType(typeId: 13)
class CharacterImage extends HiveObject {
  @HiveField(0)
  Uint8List imageData;

  @HiveField(1)
  String caption;

  @HiveField(2)
  String imageIteration;

  @HiveField(3)
  int characterIteration;

  @HiveField(4)
  double? aspectRatio;

  CharacterImage({
    required this.imageData,
    required this.caption,
    required this.imageIteration,
    required this.characterIteration,
    this.aspectRatio,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageData': base64Encode(imageData),
      'caption': caption,
      'imageIteration': imageIteration,
      'characterIteration': characterIteration,
      'aspectRatio': aspectRatio ?? 1.0,
    };
  }

  factory CharacterImage.fromJson(Map<String, dynamic> json) {
    return CharacterImage(
      imageData: base64Decode(json['imageData'] as String),
      caption: json['caption'] as String? ?? '',
      imageIteration: json['imageIteration'] as String? ?? '',
      characterIteration: json['characterIteration'] as int? ?? 0,
      aspectRatio: (json['aspectRatio'] as num?)?.toDouble(),
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

  @HiveField(15)
  List<CharacterImage>? _images;

  List<CharacterImage> get images {
    _images ??= [];
    return _images!;
  }

  set images(List<CharacterImage> value) {
    _images = List<CharacterImage>.from(value);
  }

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
    List<CharacterImage>? images,
  }) : congenitalTraits = congenitalTraits is Set<String>
           ? congenitalTraits
           : Set<String>.from(congenitalTraits?.cast<String>() ?? []),
       leveledTraits = leveledTraits ?? {},
       personalityTraits = personalityTraits ?? {},
       _customFieldValues = customFieldValues ?? {},
       _customPanels = customPanels ?? [],
       _images = List<CharacterImage>.from(images ?? []);

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
      'images': images.map((i) => i.toJson()).toList(),
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
      final oldFields = _coerceList(
        json['customFields'],
      ).map((f) => CustomField.fromJson(f as Map<String, dynamic>)).toList();
      for (final field in oldFields) {
        customFieldValues[field.name] = field.value;
      }
    }

    return CharacterIteration(
        iterationName: json['iterationName'],
        name: json['name'],
        bio: json['bio'],
        aliases: _coerceList(json['aliases']).cast<String>(),
        occupation: json['occupation'],
        gender: json['gender'],
        customGender: json['customGender'],
        originCountry: json['originCountry'],
        traits: _coerceList(json['traits']).cast<String>(),
        congenitalTraits: Set<String>.from(
          _coerceList(json['congenitalTraits']),
        ),
        leveledTraits: Map<String, int>.from(
          json['leveledTraits'] as Map<dynamic, dynamic>? ?? {},
        ),
        personalityTraits: Map<String, int>.from(
          json['personalityTraits'] as Map<dynamic, dynamic>? ?? {},
        ),
        customFieldValues: customFieldValues,
        customPanels: _coerceList(
          json['customPanels'],
        ).map((p) => CustomPanel.fromJson(p as Map<String, dynamic>)).toList(),
        images: _coerceList(json['images'])
            .map((i) => CharacterImage.fromJson(i as Map<String, dynamic>))
            .toList(),
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
        aliases: _coerceList(json['aliases']).cast<String>(),
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
      ..iterations = _coerceList(json['iterations'])
          .map((i) => CharacterIteration.fromJson(i as Map<String, dynamic>))
          .toList();
  }
}

class CharacterIterationSafeAdapter extends TypeAdapter<CharacterIteration> {
  @override
  final int typeId = 10;

  @override
  CharacterIteration read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final iteration = CharacterIteration(
      iterationName: fields[0] as String,
      name: fields[1] as String?,
      aliases: _coerceList(fields[2]).cast<String>(),
      occupation: fields[3] as String?,
      gender: fields[4] as String?,
      customGender: fields[5] as String?,
      bio: fields[6] as String?,
      originCountry: fields[7] as String?,
      traits: _coerceList(fields[8]).cast<String>(),
      congenitalTraits: fields[9] as dynamic,
      leveledTraits: _coerceStringIntMap(fields[10]),
      personalityTraits: _coerceStringIntMap(fields[11]),
      customFieldValues: _coerceStringStringMap(fields[12]),
      customPanels: _coerceList(fields[13]).cast<CustomPanel>(),
      images: _coerceList(fields[15]).cast<CharacterImage>(),
    );

    iteration
      .._customFieldValues = _coerceStringStringMap(fields[12])
      .._customPanels = _coerceList(fields[13]).cast<CustomPanel>()
      .._panelOrders = _coerceStringIntMap(fields[14])
      .._images = _coerceList(fields[15]).cast<CharacterImage>();

    return iteration;
  }

  @override
  void write(BinaryWriter writer, CharacterIteration obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.iterationName)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.aliases)
      ..writeByte(3)
      ..write(obj.occupation)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.customGender)
      ..writeByte(6)
      ..write(obj.bio)
      ..writeByte(7)
      ..write(obj.originCountry)
      ..writeByte(8)
      ..write(obj.traits)
      ..writeByte(9)
      ..write(obj.congenitalTraits.toList())
      ..writeByte(10)
      ..write(obj.leveledTraits)
      ..writeByte(11)
      ..write(obj.personalityTraits)
      ..writeByte(12)
      ..write(obj._customFieldValues)
      ..writeByte(13)
      ..write(obj._customPanels)
      ..writeByte(14)
      ..write(obj._panelOrders)
      ..writeByte(15)
      ..write(obj._images);
  }
}
