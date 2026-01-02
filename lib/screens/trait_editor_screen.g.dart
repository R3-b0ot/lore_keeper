// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trait_editor_screen.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SimpleTraitAdapter extends TypeAdapter<SimpleTrait> {
  @override
  final int typeId = 9;

  @override
  SimpleTrait read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SimpleTrait(
      name: fields[0] as String,
      icon: fields[1] as String,
      explanation: fields[2] as String,
      type: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SimpleTrait obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.icon)
      ..writeByte(2)
      ..write(obj.explanation)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleTraitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
