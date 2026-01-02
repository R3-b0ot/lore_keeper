// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapModelAdapter extends TypeAdapter<MapModel> {
  @override
  final int typeId = 22;

  @override
  MapModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapModel(
      id: fields[0] as dynamic,
      name: fields[1] as dynamic,
      projectId: fields[2] as dynamic,
      style: fields[3] as dynamic,
      resolution: fields[4] as dynamic,
      aspectRatio: fields[5] as dynamic,
      gridType: fields[6] as dynamic,
      created: fields[7] as DateTime?,
      lastModified: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MapModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.projectId)
      ..writeByte(3)
      ..write(obj.style)
      ..writeByte(4)
      ..write(obj.resolution)
      ..writeByte(5)
      ..write(obj.aspectRatio)
      ..writeByte(6)
      ..write(obj.gridType)
      ..writeByte(7)
      ..write(obj.created)
      ..writeByte(8)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
