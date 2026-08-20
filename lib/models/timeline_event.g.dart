// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimelineEventAdapter extends TypeAdapter<TimelineEvent> {
  @override
  final int typeId = 29;

  @override
  TimelineEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineEvent(
      id: fields[0] as String,
      projectId: fields[1] as int,
      name: fields[2] as String,
      tier: fields[3] as String,
      absoluteYear: fields[4] as int,
      absoluteDayOfYear: fields[5] as int,
      iconKey: fields[6] as String,
      colorValue: fields[7] as int,
      lore: fields[8] as String,
      createdAt: fields[9] as int?,
      updatedAt: fields[10] as int?,
      calendarSystemKey: fields[11] as int? ?? 0,
      durationDays: fields[12] as int? ?? 0,
      linkedCharacterIds: (fields[13] as List?)?.cast<String>() ?? const <String>[],
      linkedLocationIds: (fields[14] as List?)?.cast<String>() ?? const <String>[],
    );
  }

  @override
  void write(BinaryWriter writer, TimelineEvent obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.tier)
      ..writeByte(4)
      ..write(obj.absoluteYear)
      ..writeByte(5)
      ..write(obj.absoluteDayOfYear)
      ..writeByte(6)
      ..write(obj.iconKey)
      ..writeByte(7)
      ..write(obj.colorValue)
      ..writeByte(8)
      ..write(obj.lore)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.calendarSystemKey)
      ..writeByte(12)
      ..write(obj.durationDays)
      ..writeByte(13)
      ..write(obj.linkedCharacterIds)
      ..writeByte(14)
      ..write(obj.linkedLocationIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
