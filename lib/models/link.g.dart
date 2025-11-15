// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LinkAdapter extends TypeAdapter<Link> {
  @override
  final int typeId = 5;

  @override
  Link read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Link()
      ..entity1Type = fields[0] as String
      ..entity1Key = fields[1] as dynamic
      ..entity2Type = fields[2] as String
      ..entity2Key = fields[3] as dynamic
      ..description = fields[4] as String
      ..date = fields[5] as String?
      ..entity1IterationIndex = fields[6] as int?
      ..entity2IterationIndex = fields[7] as int?;
  }

  @override
  void write(BinaryWriter writer, Link obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.entity1Type)
      ..writeByte(1)
      ..write(obj.entity1Key)
      ..writeByte(2)
      ..write(obj.entity2Type)
      ..writeByte(3)
      ..write(obj.entity2Key)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.entity1IterationIndex)
      ..writeByte(7)
      ..write(obj.entity2IterationIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
