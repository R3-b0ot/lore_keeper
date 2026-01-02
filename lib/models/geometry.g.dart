// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Edge _$EdgeFromJson(Map<String, dynamic> json) => Edge(
      start: const PointConverter()
          .fromJson(json['start'] as Map<String, dynamic>),
      end: const PointConverter().fromJson(json['end'] as Map<String, dynamic>),
      leftCellIndex: (json['leftCellIndex'] as num).toInt(),
      rightCellIndex: (json['rightCellIndex'] as num).toInt(),
    );

Map<String, dynamic> _$EdgeToJson(Edge instance) => <String, dynamic>{
      'start': const PointConverter().toJson(instance.start),
      'end': const PointConverter().toJson(instance.end),
      'leftCellIndex': instance.leftCellIndex,
      'rightCellIndex': instance.rightCellIndex,
    };

GeneratedMap _$GeneratedMapFromJson(Map<String, dynamic> json) => GeneratedMap(
      cells: (json['cells'] as List<dynamic>)
          .map((e) => Cell.fromJson(e as Map<String, dynamic>))
          .toList(),
      rivers: json['rivers'] as List<dynamic>?,
      civilizations: json['civilizations'] as List<dynamic>?,
    );

Map<String, dynamic> _$GeneratedMapToJson(GeneratedMap instance) =>
    <String, dynamic>{
      'cells': instance.cells.map((e) => e.toJson()).toList(),
      'rivers': instance.rivers,
      'civilizations': instance.civilizations,
    };

Cell _$CellFromJson(Map<String, dynamic> json) => Cell(
      index: (json['index'] as num).toInt(),
      site:
          const PointConverter().fromJson(json['site'] as Map<String, dynamic>),
      vertices: _pointsFromJson(json['vertices'] as List),
      height: (json['height'] as num?)?.toInt() ?? 20,
      temperature: (json['temperature'] as num?)?.toInt() ?? 0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0,
      biome: $enumDecodeNullable(_$BiomeEnumMap, json['biome']) ?? Biome.ocean,
      type: (json['type'] as num?)?.toInt() ?? -1,
      feature: (json['feature'] as num?)?.toInt() ?? 0,
      culture: (json['culture'] as num?)?.toInt() ?? 0,
      state: (json['state'] as num?)?.toInt() ?? 0,
      province: (json['province'] as num?)?.toInt() ?? 0,
      burg: (json['burg'] as num?)?.toInt() ?? 0,
      religion: (json['religion'] as num?)?.toInt() ?? 0,
      flux: (json['flux'] as num?)?.toDouble() ?? 0.0,
      confluence: (json['confluence'] as num?)?.toDouble() ?? 0.0,
      suitability: (json['suitability'] as num?)?.toInt() ?? 0,
      population: (json['population'] as num?)?.toDouble() ?? 0.0,
      hospitability: (json['hospitability'] as num?)?.toDouble() ?? 0.0,
      harbor: (json['harbor'] as num?)?.toInt() ?? 0,
      isCoast: json['isCoast'] as bool? ?? false,
      isBorder: json['isBorder'] as bool? ?? false,
    );

Map<String, dynamic> _$CellToJson(Cell instance) => <String, dynamic>{
      'index': instance.index,
      'site': const PointConverter().toJson(instance.site),
      'vertices': _pointsToJson(instance.vertices),
      'height': instance.height,
      'temperature': instance.temperature,
      'precipitation': instance.precipitation,
      'biome': _$BiomeEnumMap[instance.biome]!,
      'type': instance.type,
      'feature': instance.feature,
      'culture': instance.culture,
      'state': instance.state,
      'province': instance.province,
      'burg': instance.burg,
      'religion': instance.religion,
      'flux': instance.flux,
      'confluence': instance.confluence,
      'suitability': instance.suitability,
      'population': instance.population,
      'hospitability': instance.hospitability,
      'harbor': instance.harbor,
      'isCoast': instance.isCoast,
      'isBorder': instance.isBorder,
    };

const _$BiomeEnumMap = {
  Biome.ocean: 'ocean',
  Biome.lake: 'lake',
  Biome.freshwater: 'freshwater',
  Biome.salt: 'salt',
  Biome.frozen: 'frozen',
  Biome.dry: 'dry',
  Biome.desert: 'desert',
  Biome.grassland: 'grassland',
  Biome.forest: 'forest',
  Biome.taiga: 'taiga',
  Biome.tundra: 'tundra',
  Biome.mountain: 'mountain',
  Biome.swamp: 'swamp',
  Biome.jungle: 'jungle',
  Biome.savanna: 'savanna',
  Biome.steppe: 'steppe',
  Biome.badlands: 'badlands',
  Biome.volcanic: 'volcanic',
};
