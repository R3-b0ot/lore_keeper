// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      title: fields[0] as String,
      createdAt: fields[2] as DateTime,
      description: fields[1] as String?,
      bookTitle: fields[3] as String?,
      lastEditedChapterKey: fields[4] as dynamic,
      genre: fields[5] as String?,
      authors: fields[6] as String?,
      lastModified: fields[8] as DateTime?,
      historyLimit: fields[9] as int?,
      coverImagePath: fields[10] as String?,
      showTitleOnCover: fields[11] as bool?,
      showAuthorOnCover: fields[12] as bool?,
      authorBio: fields[13] as String?,
      authorEmail: fields[14] as String?,
      authorWebsite: fields[15] as String?,
      authorTwitter: fields[16] as String?,
      authorInstagram: fields[17] as String?,
      authorFacebook: fields[18] as String?,
      ignoredWords: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.bookTitle)
      ..writeByte(4)
      ..write(obj.lastEditedChapterKey)
      ..writeByte(5)
      ..write(obj.genre)
      ..writeByte(6)
      ..write(obj.authors)
      ..writeByte(7)
      ..write(obj.ignoredWords)
      ..writeByte(8)
      ..write(obj.lastModified)
      ..writeByte(9)
      ..write(obj.historyLimit)
      ..writeByte(10)
      ..write(obj.coverImagePath)
      ..writeByte(11)
      ..write(obj.showTitleOnCover)
      ..writeByte(12)
      ..write(obj.showAuthorOnCover)
      ..writeByte(13)
      ..write(obj.authorBio)
      ..writeByte(14)
      ..write(obj.authorEmail)
      ..writeByte(15)
      ..write(obj.authorWebsite)
      ..writeByte(16)
      ..write(obj.authorTwitter)
      ..writeByte(17)
      ..write(obj.authorInstagram)
      ..writeByte(18)
      ..write(obj.authorFacebook);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
