// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magic_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MagicNodeAdapter extends TypeAdapter<MagicNode> {
  @override
  final int typeId = 8;

  @override
  MagicNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MagicNode(
      id: fields[0] as String,
      systemKey: fields[1] as int,
      parentId: fields[2] as String?,
      type: fields[3] as String,
      title: fields[4] as String,
      iconKey: fields[5] as String,
      colorValue: fields[6] as int,
      content: fields[7] as String,
      attributes: (fields[8] as List).cast<MagicAttribute>(),
      childrenOrder: (fields[9] as List).cast<String>(),
      createdAt: fields[10] as int?,
      updatedAt: fields[11] as int?,
    ).._images = (fields[12] as List?)?.cast<MagicImage>();
  }

  @override
  void write(BinaryWriter writer, MagicNode obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.systemKey)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.iconKey)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.content)
      ..writeByte(8)
      ..write(obj.attributes)
      ..writeByte(9)
      ..write(obj.childrenOrder)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj._images);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MagicNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MagicImageAdapter extends TypeAdapter<MagicImage> {
  @override
  final int typeId = 22;

  @override
  MagicImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MagicImage(
      imageData: fields[0] as Uint8List,
      caption: fields[1] as String,
      state: fields[2] as String,
      aspectRatio: fields[3] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, MagicImage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.imageData)
      ..writeByte(1)
      ..write(obj.caption)
      ..writeByte(2)
      ..write(obj.state)
      ..writeByte(3)
      ..write(obj.aspectRatio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MagicImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MagicAttributeAdapter extends TypeAdapter<MagicAttribute> {
  @override
  final int typeId = 9;

  @override
  MagicAttribute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MagicAttribute(
      label: fields[0] as String,
      value: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MagicAttribute obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MagicAttributeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
