// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manuscript_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManuscriptDocumentAdapter extends TypeAdapter<ManuscriptDocument> {
  @override
  final int typeId = 40;

  @override
  ManuscriptDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManuscriptDocument()
      ..id = fields[0] as String
      ..projectId = fields[1] as int
      ..title = fields[2] as String
      ..documentTypeIndex = fields[3] as int
      ..parentId = fields[4] as String?
      ..orderIndex = fields[5] as int
      ..richTextJson = fields[6] as String?
      ..statusIndex = fields[7] as int
      ..summary = fields[8] as String?
      ..povCharacterId = fields[9] as String?
      ..locationId = fields[10] as String?
      ..timelineEventId = fields[11] as String?
      ..plotline = fields[12] as String?
      ..characterIds = (fields[13] as List?)?.cast<String>() ?? []
      ..tagIds = (fields[14] as List?)?.cast<String>() ?? []
      ..isExpanded = fields[15] as bool
      ..createdAt = fields[16] as DateTime?
      ..modifiedAt = fields[17] as DateTime?
      ..wordCount = fields[18] as int
      ..characterCount = fields[19] as int
      ..purpose = fields[20] as String?
      ..isFavorite = fields[21] as bool? ?? false
      ..calendarDateSystemKey = fields[22] as int? ?? 0
      ..calendarDateYear = fields[23] as int? ?? 0
      ..calendarDateDayOfYear = fields[24] as int? ?? 0;
  }

  @override
  void write(BinaryWriter writer, ManuscriptDocument obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.documentTypeIndex)
      ..writeByte(4)
      ..write(obj.parentId)
      ..writeByte(5)
      ..write(obj.orderIndex)
      ..writeByte(6)
      ..write(obj.richTextJson)
      ..writeByte(7)
      ..write(obj.statusIndex)
      ..writeByte(8)
      ..write(obj.summary)
      ..writeByte(9)
      ..write(obj.povCharacterId)
      ..writeByte(10)
      ..write(obj.locationId)
      ..writeByte(11)
      ..write(obj.timelineEventId)
      ..writeByte(12)
      ..write(obj.plotline)
      ..writeByte(13)
      ..write(obj.characterIds)
      ..writeByte(14)
      ..write(obj.tagIds)
      ..writeByte(15)
      ..write(obj.isExpanded)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.modifiedAt)
      ..writeByte(18)
      ..write(obj.wordCount)
      ..writeByte(19)
      ..write(obj.characterCount)
      ..writeByte(20)
      ..write(obj.purpose)
      ..writeByte(21)
      ..write(obj.isFavorite)
      ..writeByte(22)
      ..write(obj.calendarDateSystemKey)
      ..writeByte(23)
      ..write(obj.calendarDateYear)
      ..writeByte(24)
      ..write(obj.calendarDateDayOfYear);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManuscriptDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
