// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomFieldAdapter extends TypeAdapter<CustomField> {
  @override
  final int typeId = 20;

  @override
  CustomField read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomField(
      name: fields[0] as String,
      type: fields[1] as String,
      value: fields[2] as String,
      visible: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CustomField obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.value)
      ..writeByte(3)
      ..write(obj.visible);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomFieldAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomPanelAdapter extends TypeAdapter<CustomPanel> {
  @override
  final int typeId = 21;

  @override
  CustomPanel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomPanel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      content: fields[3] as String,
      items: (fields[4] as List?)?.cast<String>(),
      order: fields[5] as int,
      column: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CustomPanel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.items)
      ..writeByte(5)
      ..write(obj.order)
      ..writeByte(6)
      ..write(obj.column);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPanelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CharacterImageAdapter extends TypeAdapter<CharacterImage> {
  @override
  final int typeId = 13;

  @override
  CharacterImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CharacterImage(
      imageData: fields[0] as Uint8List,
      caption: fields[1] as String,
      imageIteration: fields[2] as String,
      characterIteration: fields[3] as int,
      aspectRatio: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CharacterImage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.imageData)
      ..writeByte(1)
      ..write(obj.caption)
      ..writeByte(2)
      ..write(obj.imageIteration)
      ..writeByte(3)
      ..write(obj.characterIteration)
      ..writeByte(4)
      ..write(obj.aspectRatio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CharacterImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
        originCountry: fields[7] as String?,
        traits: (fields[8] as List?)?.cast<String>(),
        congenitalTraits: fields[9] as dynamic,
        leveledTraits: (fields[10] as Map?)?.cast<String, int>(),
        personalityTraits: (fields[11] as Map?)?.cast<String, int>(),
      )
      .._customFieldValues = (fields[12] as Map?)?.cast<String, String>()
      .._customPanels = (fields[13] as List?)?.cast<CustomPanel>()
      .._panelOrders = (fields[14] as Map?)?.cast<String, int>()
      .._images = (fields[15] as List?)?.cast<CharacterImage>();
  }

  @override
  void write(BinaryWriter writer, CharacterIteration obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.originCountry)
      ..writeByte(8)
      ..write(obj.traits)
      ..writeByte(9)
      ..write(obj.congenitalTraits.toList())
      ..writeByte(10)
      ..write(obj.leveledTraits)
      ..writeByte(11)
      ..write(obj.personalityTraits)
      ..writeByte(12)
      ..write(obj._customFieldValues)
      ..writeByte(13)
      ..write(obj._customPanels)
      ..writeByte(14)
      ..write(obj._panelOrders)
      ..writeByte(15)
      ..write(obj._images);
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
        relationWebLayout: (fields[15] as Map?)?.map(
          (dynamic k, dynamic v) =>
              MapEntry(k as dynamic, (v as Map).cast<String, double>()),
        ),
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
