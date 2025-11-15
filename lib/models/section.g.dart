// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'section.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SectionAdapter extends TypeAdapter<Section> {
  @override
  final int typeId = 3;

  @override
  Section read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Section()
      ..title = fields[0] as String
      ..orderIndex = fields[1] as int
      ..parentProjectId = fields[2] as int
      ..isExpanded = fields[3] as bool
      ..parentSectionKey = fields[4] as int?;
  }

  @override
  void write(BinaryWriter writer, Section obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.orderIndex)
      ..writeByte(2)
      ..write(obj.parentProjectId)
      ..writeByte(3)
      ..write(obj.isExpanded)
      ..writeByte(4)
      ..write(obj.parentSectionKey);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
