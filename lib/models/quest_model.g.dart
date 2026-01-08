// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestAdapter extends TypeAdapter<Quest> {
  @override
  final int typeId = 2;

  @override
  Quest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quest(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[7] as String,
      difficulty: fields[2] as int,
      durationSeconds: fields[3] as int,
      goldReward: fields[4] as int,
      xpReward: fields[5] as int,
      dropRate: fields[6] as double,
      isMainQuest: fields[8] as bool,
      requiredQuestId: fields[9] as String?,
      mapX: fields[10] as double,
      mapY: fields[11] as double,
      lore: (fields[12] as List).cast<String>(),
      nextQuestId: fields[13] as String?,
      isReplayable: fields[14] as bool,
      specialItemReward: fields[15] as String?,
      repeatGoldReward: fields[16] as int?,
      repeatXpReward: fields[17] as int?,
      specialItemDescription: fields[18] as String?,
      requiredHints: fields[19] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Quest obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.difficulty)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.goldReward)
      ..writeByte(5)
      ..write(obj.xpReward)
      ..writeByte(6)
      ..write(obj.dropRate)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.isMainQuest)
      ..writeByte(9)
      ..write(obj.requiredQuestId)
      ..writeByte(10)
      ..write(obj.mapX)
      ..writeByte(11)
      ..write(obj.mapY)
      ..writeByte(12)
      ..write(obj.lore)
      ..writeByte(13)
      ..write(obj.nextQuestId)
      ..writeByte(14)
      ..write(obj.isReplayable)
      ..writeByte(15)
      ..write(obj.specialItemReward)
      ..writeByte(16)
      ..write(obj.repeatGoldReward)
      ..writeByte(17)
      ..write(obj.repeatXpReward)
      ..writeByte(18)
      ..write(obj.specialItemDescription)
      ..writeByte(19)
      ..write(obj.requiredHints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
