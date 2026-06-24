// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hero_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HeroModelAdapter extends TypeAdapter<HeroModel> {
  @override
  final int typeId = 1;

  @override
  HeroModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HeroModel(
      id: fields[0] as String,
      name: fields[1] as String,
      classType: fields[2] as String,
      level: fields[3] as int,
      xp: fields[4] as int,
      strength: fields[5] as int,
      speed: fields[6] as int,
      hp: fields[7] as int,
      maxHp: fields[8] as int,
      status: fields[9] as HeroStatus,
      questCompletesAt: fields[10] as DateTime?,
      inventory: (fields[11] as List?)?.cast<Item>(),
      mainHand: fields[12] as Item?,
      offHand: fields[13] as Item?,
      armor: fields[14] as Item?,
      accessory: fields[15] as Item?,
      upgradePoints: fields[16] as int?,
      luck: fields[17] as int?,
      activeQuestId: fields[18] as String?,
      imagePath: fields[19] as String?,
      activeQuestActualDuration: fields[20] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, HeroModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.classType)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.xp)
      ..writeByte(5)
      ..write(obj.strength)
      ..writeByte(6)
      ..write(obj.speed)
      ..writeByte(7)
      ..write(obj.hp)
      ..writeByte(8)
      ..write(obj.maxHp)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.questCompletesAt)
      ..writeByte(11)
      ..write(obj.inventory)
      ..writeByte(12)
      ..write(obj.mainHand)
      ..writeByte(13)
      ..write(obj.offHand)
      ..writeByte(14)
      ..write(obj.armor)
      ..writeByte(15)
      ..write(obj.accessory)
      ..writeByte(16)
      ..write(obj.upgradePoints)
      ..writeByte(17)
      ..write(obj.luck)
      ..writeByte(18)
      ..write(obj.activeQuestId)
      ..writeByte(19)
      ..write(obj.imagePath)
      ..writeByte(20)
      ..write(obj.activeQuestActualDuration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeroModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HeroStatusAdapter extends TypeAdapter<HeroStatus> {
  @override
  final int typeId = 0;

  @override
  HeroStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HeroStatus.idle;
      case 1:
        return HeroStatus.questing;
      case 2:
        return HeroStatus.dead;
      case 3:
        return HeroStatus.recovering;
      default:
        return HeroStatus.idle;
    }
  }

  @override
  void write(BinaryWriter writer, HeroStatus obj) {
    switch (obj) {
      case HeroStatus.idle:
        writer.writeByte(0);
        break;
      case HeroStatus.questing:
        writer.writeByte(1);
        break;
      case HeroStatus.dead:
        writer.writeByte(2);
        break;
      case HeroStatus.recovering:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeroStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
