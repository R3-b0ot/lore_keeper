// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarNodeAdapter extends TypeAdapter<CalendarNode> {
  @override
  final int typeId = 27;

  @override
  CalendarNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarNode(
      id: fields[0] as String,
      systemKey: fields[1] as int,
      parentId: fields[2] as String?,
      type: fields[3] as String,
      title: fields[4] as String,
      iconKey: fields[5] as String,
      colorValue: fields[6] as int,
      content: fields[7] as String,
      attributes: (fields[8] as List).cast<CalendarAttribute>(),
      childrenOrder: (fields[9] as List).cast<String>(),
      createdAt: fields[10] as int?,
      updatedAt: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarNode obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalendarAttributeAdapter extends TypeAdapter<CalendarAttribute> {
  @override
  final int typeId = 28;

  @override
  CalendarAttribute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarAttribute(
      label: fields[0] as String,
      value: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarAttribute obj) {
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
      other is CalendarAttributeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
