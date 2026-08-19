import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'map_data.g.dart';

@HiveType(typeId: 30)
class MapData extends HiveObject {
  @HiveField(0)
  late int parentProjectId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late double width;

  @HiveField(3)
  late double height;

  @HiveField(4)
  late List<MapLayer> layers;

  @HiveField(5)
  late DateTime createdAt;

  MapData({
    required this.parentProjectId,
    required this.title,
    this.width = 4096,
    this.height = 4096,
    List<MapLayer>? layers,
    DateTime? createdAt,
  }) : layers = layers ?? [],
       createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 31)
class MapLayer extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late bool isVisible;

  @HiveField(3)
  late bool isLocked;

  @HiveField(4)
  late List<MapStamp> stamps;

  @HiveField(5)
  late List<MapPath> paths;

  @HiveField(6)
  late List<MapPolygon> polygons;

  MapLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    List<MapStamp>? stamps,
    List<MapPath>? paths,
    List<MapPolygon>? polygons,
  }) : stamps = stamps ?? [],
       paths = paths ?? [],
       polygons = polygons ?? [];
}

@HiveType(typeId: 32)
class MapStamp extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String assetPath;

  @HiveField(2)
  late double x;

  @HiveField(3)
  late double y;

  @HiveField(4)
  late double scale;

  @HiveField(5)
  late double rotation;

  @HiveField(6)
  late bool isCustom;

  MapStamp({
    required this.id,
    required this.assetPath,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isCustom = false,
  });
}

@HiveType(typeId: 33)
class MapPath extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late List<OffsetData> controlPoints;

  @HiveField(2)
  late double strokeWidth;

  @HiveField(3)
  late int colorValue;

  @HiveField(4)
  late bool isClosed;

  MapPath({
    required this.id,
    required this.controlPoints,
    this.strokeWidth = 2.0,
    this.colorValue = 0xFF000000,
    this.isClosed = false,
  });
}

@HiveType(typeId: 34)
class MapPolygon extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late List<OffsetData> points;

  @HiveField(2)
  late String textureAssetPath;

  @HiveField(3)
  late double textureScale;

  MapPolygon({
    required this.id,
    required this.points,
    required this.textureAssetPath,
    this.textureScale = 1.0,
  });
}

@HiveType(typeId: 35)
class OffsetData {
  @HiveField(0)
  final double dx;

  @HiveField(1)
  final double dy;

  OffsetData(this.dx, this.dy);

  Offset toOffset() => Offset(dx, dy);

  factory OffsetData.fromOffset(Offset offset) =>
      OffsetData(offset.dx, offset.dy);
}
