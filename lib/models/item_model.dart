import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 6)
enum ItemRarity {
  @HiveField(0)
  common,
  @HiveField(1)
  rare,
  @HiveField(2)
  epic,
  @HiveField(3)
  legendary,
  @HiveField(4)
  quest,
}

@HiveType(typeId: 7)
enum ItemSlot {
  @HiveField(0)
  mainHand,
  @HiveField(1)
  offHand,
  @HiveField(2)
  armor,
  @HiveField(3)
  accessory,
  @HiveField(4)
  trophy,
}

@HiveType(typeId: 3)
class Item {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int strengthBonus; // Renamed from bonusStr to match old field but keeping logic

  @HiveField(4)
  final int defenseBonus;

  @HiveField(5)
  final ItemRarity rarity;

  @HiveField(6)
  final ItemSlot slot;

  @HiveField(7)
  final int bonusSpd;

  @HiveField(8)
  final int bonusLuck;

  @HiveField(9)
  final int value;

  @HiveField(10)
  final String? imagePath;

  Item({
    required this.id,
    required this.name,
    required this.description,
    this.strengthBonus = 0,
    this.defenseBonus = 0,
    this.rarity = ItemRarity.common,
    this.slot = ItemSlot.mainHand,
    this.bonusSpd = 0,
    this.bonusLuck = 0,
    this.value = 0,
    this.imagePath,
  });
}
