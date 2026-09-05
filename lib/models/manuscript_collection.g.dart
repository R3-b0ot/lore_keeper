// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manuscript_collection.dart';

// Hand-written Hive adapter for [ManuscriptCollection].
//
// Normally produced by build_runner + hive_generator, but this project
// hand-writes adapters (see DatabaseMetadataAdapter).

class ManuscriptCollectionAdapter extends TypeAdapter<ManuscriptCollection> {
  @override
  final int typeId = 41;

  @override
  ManuscriptCollection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManuscriptCollection(
      id: fields[0] as String,
      projectId: fields[1] as int,
      name: fields[2] as String,
      documentTypeIndex: fields[3] as int?,
      statusIndex: fields[4] as int?,
      createdAt: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ManuscriptCollection obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.documentTypeIndex)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManuscriptCollectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
