import 'dart:math' show Point;
import 'package:json_annotation/json_annotation.dart';

part 'geometry.g.dart';

class PointConverter
    extends JsonConverter<Point<double>, Map<String, dynamic>> {
  const PointConverter();

  @override
  Point<double> fromJson(Map<String, dynamic> json) {
    return Point(json['x'] as double, json['y'] as double);
  }

  @override
  Map<String, dynamic> toJson(Point<double> point) {
    return {'x': point.x, 'y': point.y};
  }
}

/// Represents a biome type for map cells.
enum Biome {
  ocean,
  lake,
  freshwater,
  salt,
  frozen,
  dry,
  desert,
  grassland,
  forest,
  taiga,
  tundra,
  mountain,
  swamp,
  jungle,
  savanna,
  steppe,
  badlands,
  volcanic,
}

/// Represents an edge in the Voronoi diagram.
///
/// An edge is a line segment that separates two cells.
@JsonSerializable()
class Edge {
  /// The starting vertex of the edge.
  @PointConverter()
  final Point<double> start;

  /// The ending vertex of the edge.
  @PointConverter()
  final Point<double> end;

  /// The index of the cell on the left side of the edge (from start to end).
  final int leftCellIndex;

  /// The index of the cell on the right side of the edge. A value of -1
  /// indicates that this is a border edge with no cell on the right.
  final int rightCellIndex;

  Edge({
    required this.start,
    required this.end,
    required this.leftCellIndex,
    required this.rightCellIndex,
  });

  /// A flag to indicate if this edge is on the boundary of the map.
  bool get isBorderEdge => rightCellIndex == -1;

  /// Factory constructor for creating an Edge from JSON
  factory Edge.fromJson(Map<String, dynamic> json) => _$EdgeFromJson(json);

  /// Method for converting an Edge to JSON
  Map<String, dynamic> toJson() => _$EdgeToJson(this);

  @override
  String toString() => 'Edge(from: $start, to: $end)';
}

/// Represents the fully generated map data, ready for serialization or rendering.
///
/// This class will be the final output of the generation process running in an
/// isolate. It contains all the geometric and procedural data needed to
/// display and interact with the map.
@JsonSerializable(explicitToJson: true)
class GeneratedMap {
  final List<Cell> cells;
  final List<dynamic>? rivers;
  final List<dynamic>? civilizations;

  GeneratedMap({required this.cells, this.rivers, this.civilizations});

  /// Factory constructor for creating a GeneratedMap from JSON
  factory GeneratedMap.fromJson(Map<String, Object?> json) =>
      _$GeneratedMapFromJson(json);

  /// Method for converting a GeneratedMap to JSON
  Map<String, Object?> toJson() => _$GeneratedMapToJson(this);
}

/// Represents a Voronoi cell, which is a polygon on the map.
///
/// This class holds all the generated data for a specific region,
/// matching the Fantasy Map Generator's data structure.
@JsonSerializable(explicitToJson: true)
class Cell {
  /// The unique identifier for this cell.
  final int index;

  /// The seed point (`site`) for this Voronoi cell.
  @PointConverter()
  final Point<double> site;

  /// The vertices that form the polygon of the cell, in clockwise order.
  @JsonKey(toJson: _pointsToJson, fromJson: _pointsFromJson)
  final List<Point<double>> vertices;

  /// A list of edges that form the boundary of this cell.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<Edge> edges = [];

  /// A list of neighboring cells, determined by shared edges.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<Cell> neighbors = [];

  /// Height value (0-100, where 20 is sea level)
  int height;

  /// Temperature value (-128 to 127)
  int temperature;

  /// Precipitation value (0-255)
  double precipitation;

  /// Biome type
  Biome biome;

  /// Cell type: -1 = water, 0 = land, 1 = coastline, 2 = border
  int type;

  /// Feature index (for lakes, etc.)
  int feature;

  /// Culture index
  int culture;

  /// State index
  int state;

  /// Province index
  int province;

  /// Burg (settlement) index
  int burg;

  /// Religion index
  int religion;

  /// River flux (water flow)
  double flux;

  /// River confluence
  double confluence;

  /// Population suitability
  int suitability;

  /// Population
  double population;

  /// Hospitability score (for world generation)
  double hospitability;

  /// Harbor type (0 = none, 1 = safe)
  int harbor;

  /// Coastal cell flag
  bool isCoast;

  /// Border cell flag
  bool isBorder;

  Cell({
    required this.index,
    required this.site,
    required this.vertices,
    this.height = 20,
    this.temperature = 0,
    this.precipitation = 0,
    this.biome = Biome.ocean,
    this.type = -1,
    this.feature = 0,
    this.culture = 0,
    this.state = 0,
    this.province = 0,
    this.burg = 0,
    this.religion = 0,
    this.flux = 0.0,
    this.confluence = 0.0,
    this.suitability = 0,
    this.population = 0.0,
    this.hospitability = 0.0,
    this.harbor = 0,
    this.isCoast = false,
    this.isBorder = false,
  });

  /// A flag to indicate if this cell is on the border of the map.
  bool get isBorderCell => edges.any((edge) => edge.isBorderEdge);

  factory Cell.fromJson(Map<String, Object?> json) => _$CellFromJson(json);
  Map<String, Object?> toJson() => _$CellToJson(this);

  @override
  String toString() => 'Cell $index at $site (height: $height, biome: $biome)';
}

List<Map<String, dynamic>> _pointsToJson(List<Point<double>> points) {
  const converter = PointConverter();
  return points.map((p) => converter.toJson(p)).toList();
}

List<Point<double>> _pointsFromJson(List<dynamic> json) {
  const converter = PointConverter();
  return json
      .map((e) => converter.fromJson(e as Map<String, dynamic>))
      .toList();
}
