// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapDataAdapter extends TypeAdapter<MapData> {
  @override
  final int typeId = 30;

  @override
  MapData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapData(
      parentProjectId: fields[0] as int,
      title: fields[1] as String,
      width: fields[2] as double,
      height: fields[3] as double,
      layers: (fields[4] as List?)?.cast<MapLayer>(),
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MapData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.parentProjectId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.layers)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MapLayerAdapter extends TypeAdapter<MapLayer> {
  @override
  final int typeId = 31;

  @override
  MapLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapLayer(
      id: fields[0] as String,
      name: fields[1] as String,
      isVisible: fields[2] as bool,
      isLocked: fields[3] as bool,
      stamps: (fields[4] as List?)?.cast<MapStamp>(),
      paths: (fields[5] as List?)?.cast<MapPath>(),
      polygons: (fields[6] as List?)?.cast<MapPolygon>(),
    );
  }

  @override
  void write(BinaryWriter writer, MapLayer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isVisible)
      ..writeByte(3)
      ..write(obj.isLocked)
      ..writeByte(4)
      ..write(obj.stamps)
      ..writeByte(5)
      ..write(obj.paths)
      ..writeByte(6)
      ..write(obj.polygons);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MapStampAdapter extends TypeAdapter<MapStamp> {
  @override
  final int typeId = 32;

  @override
  MapStamp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapStamp(
      id: fields[0] as String,
      assetPath: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      scale: fields[4] as double,
      rotation: fields[5] as double,
      isCustom: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MapStamp obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetPath)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.scale)
      ..writeByte(5)
      ..write(obj.rotation)
      ..writeByte(6)
      ..write(obj.isCustom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapStampAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MapPathAdapter extends TypeAdapter<MapPath> {
  @override
  final int typeId = 33;

  @override
  MapPath read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapPath(
      id: fields[0] as String,
      controlPoints: (fields[1] as List).cast<OffsetData>(),
      strokeWidth: fields[2] as double,
      colorValue: fields[3] as int,
      isClosed: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MapPath obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.controlPoints)
      ..writeByte(2)
      ..write(obj.strokeWidth)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isClosed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPathAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MapPolygonAdapter extends TypeAdapter<MapPolygon> {
  @override
  final int typeId = 34;

  @override
  MapPolygon read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapPolygon(
      id: fields[0] as String,
      points: (fields[1] as List).cast<OffsetData>(),
      textureAssetPath: fields[2] as String,
      textureScale: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MapPolygon obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.points)
      ..writeByte(2)
      ..write(obj.textureAssetPath)
      ..writeByte(3)
      ..write(obj.textureScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPolygonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OffsetDataAdapter extends TypeAdapter<OffsetData> {
  @override
  final int typeId = 35;

  @override
  OffsetData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OffsetData(
      fields[0] as double,
      fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, OffsetData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dx)
      ..writeByte(1)
      ..write(obj.dy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OffsetDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
