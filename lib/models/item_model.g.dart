// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 3;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      strengthBonus: fields[3] as int,
      defenseBonus: fields[4] as int,
      rarity: fields[5] as ItemRarity,
      slot: fields[6] as ItemSlot,
      bonusSpd: fields[7] as int,
      bonusLuck: fields[8] as int,
      value: fields[9] as int,
      imagePath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.strengthBonus)
      ..writeByte(4)
      ..write(obj.defenseBonus)
      ..writeByte(5)
      ..write(obj.rarity)
      ..writeByte(6)
      ..write(obj.slot)
      ..writeByte(7)
      ..write(obj.bonusSpd)
      ..writeByte(8)
      ..write(obj.bonusLuck)
      ..writeByte(9)
      ..write(obj.value)
      ..writeByte(10)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemRarityAdapter extends TypeAdapter<ItemRarity> {
  @override
  final int typeId = 6;

  @override
  ItemRarity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemRarity.common;
      case 1:
        return ItemRarity.rare;
      case 2:
        return ItemRarity.epic;
      case 3:
        return ItemRarity.legendary;
      case 4:
        return ItemRarity.quest;
      default:
        return ItemRarity.common;
    }
  }

  @override
  void write(BinaryWriter writer, ItemRarity obj) {
    switch (obj) {
      case ItemRarity.common:
        writer.writeByte(0);
        break;
      case ItemRarity.rare:
        writer.writeByte(1);
        break;
      case ItemRarity.epic:
        writer.writeByte(2);
        break;
      case ItemRarity.legendary:
        writer.writeByte(3);
        break;
      case ItemRarity.quest:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemRarityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ItemSlotAdapter extends TypeAdapter<ItemSlot> {
  @override
  final int typeId = 7;

  @override
  ItemSlot read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ItemSlot.mainHand;
      case 1:
        return ItemSlot.offHand;
      case 2:
        return ItemSlot.armor;
      case 3:
        return ItemSlot.accessory;
      case 4:
        return ItemSlot.trophy;
      default:
        return ItemSlot.mainHand;
    }
  }

  @override
  void write(BinaryWriter writer, ItemSlot obj) {
    switch (obj) {
      case ItemSlot.mainHand:
        writer.writeByte(0);
        break;
      case ItemSlot.offHand:
        writer.writeByte(1);
        break;
      case ItemSlot.armor:
        writer.writeByte(2);
        break;
      case ItemSlot.accessory:
        writer.writeByte(3);
        break;
      case ItemSlot.trophy:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSlotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
