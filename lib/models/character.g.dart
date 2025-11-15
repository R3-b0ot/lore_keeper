// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CharacterIterationAdapter extends TypeAdapter<CharacterIteration> {
  @override
  final int typeId = 10;

  @override
  CharacterIteration read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterIteration(
      iterationName: fields[0] as String,
      name: fields[1] as String?,
      aliases: (fields[2] as List?)?.cast<String>(),
      occupation: fields[3] as String?,
      gender: fields[4] as String?,
      customGender: fields[5] as String?,
      bio: fields[6] as String?,
      personalityTraits: (fields[7] as List?)?.cast<String>(),
      statistics: (fields[8] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, String>())
          ?.toList(),
      physicalTraits: (fields[9] as List?)
          ?.map((dynamic e) => (e as Map).cast<String, String>())
          ?.toList(),
      originCountry: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterIteration obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.iterationName)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.aliases)
      ..writeByte(3)
      ..write(obj.occupation)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.customGender)
      ..writeByte(6)
      ..write(obj.bio)
      ..writeByte(7)
      ..write(obj.personalityTraits)
      ..writeByte(8)
      ..write(obj.statistics)
      ..writeByte(9)
      ..write(obj.physicalTraits)
      ..writeByte(10)
      ..write(obj.originCountry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterIterationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CharacterAdapter extends TypeAdapter<Character> {
  @override
  final int typeId = 4;

  @override
  Character read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Character(
      name: fields[0] as String,
      parentProjectId: fields[1] as int,
      aliases: (fields[2] as List?)?.cast<String>(),
      species: fields[3] as String?,
      relationWebLayout: (fields[15] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as dynamic, (v as Map).cast<String, double>())),
      createdAt: fields[17] as DateTime?,
    )
      ..gender = fields[4] as String?
      ..customGender = fields[5] as String?
      ..residence = fields[7] as String?
      ..occupation = fields[8] as String?
      ..religion = fields[9] as String?
      ..affiliation = fields[10] as String?
      ..bio = fields[11] as String?
      ..iterations = (fields[16] as List).cast<CharacterIteration>();
  }

  @override
  void write(BinaryWriter writer, Character obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.parentProjectId)
      ..writeByte(2)
      ..write(obj.aliases)
      ..writeByte(3)
      ..write(obj.species)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.customGender)
      ..writeByte(7)
      ..write(obj.residence)
      ..writeByte(8)
      ..write(obj.occupation)
      ..writeByte(9)
      ..write(obj.religion)
      ..writeByte(10)
      ..write(obj.affiliation)
      ..writeByte(11)
      ..write(obj.bio)
      ..writeByte(15)
      ..write(obj.relationWebLayout)
      ..writeByte(16)
      ..write(obj.iterations)
      ..writeByte(17)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
