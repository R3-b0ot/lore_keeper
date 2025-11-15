// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChapterAdapter extends TypeAdapter<Chapter> {
  @override
  final int typeId = 2;

  @override
  Chapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chapter()
      ..title = fields[0] as String
      ..parentSectionKey = fields[1] as int
      ..parentProjectId = fields[2] as int
      ..orderIndex = fields[3] as int
      ..richTextJson = fields[4] as String?;
  }

  @override
  void write(BinaryWriter writer, Chapter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.parentSectionKey)
      ..writeByte(2)
      ..write(obj.parentProjectId)
      ..writeByte(3)
      ..write(obj.orderIndex)
      ..writeByte(4)
      ..write(obj.richTextJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
