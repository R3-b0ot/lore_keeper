// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MapModelAdapter extends TypeAdapter<MapModel> {
  @override
  final int typeId = 6;

  @override
  MapModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MapModel(
      name: fields[0] as String,
      description: fields[1] as String?,
      filePath: fields[2] as String,
      fileType: fields[3] as String,
      parentProjectId: fields[6] as int,
    )
      ..createdAt = fields[4] as DateTime
      ..updatedAt = fields[5] as DateTime;
  }

  @override
  void write(BinaryWriter writer, MapModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.fileType)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.parentProjectId);
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
