// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_system.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarSystemAdapter extends TypeAdapter<CalendarSystem> {
  @override
  final int typeId = 26;

  @override
  CalendarSystem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarSystem(
      name: fields[0] as String,
      projectId: fields[1] as int,
      rootNodeId: fields[2] as String,
      lastSelectedNodeId: fields[3] as String?,
      isConfigured: fields[4] as bool,
      createdAt: fields[5] as int?,
      updatedAt: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarSystem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.rootNodeId)
      ..writeByte(3)
      ..write(obj.lastSelectedNodeId)
      ..writeByte(4)
      ..write(obj.isConfigured)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarSystemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
