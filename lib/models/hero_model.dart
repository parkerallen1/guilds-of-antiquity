import 'package:hive/hive.dart';
import 'item_model.dart';

part 'hero_model.g.dart';

@HiveType(typeId: 0)
enum HeroStatus {
  @HiveField(0)
  idle,
  @HiveField(1)
  questing,
  @HiveField(2)
  dead,
  @HiveField(3)
  recovering,
}

@HiveType(typeId: 1)
class HeroModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String classType;

  @HiveField(3)
  int level;

  @HiveField(4)
  int xp;

  @HiveField(5)
  int strength;

  @HiveField(6)
  int speed;

  @HiveField(7)
  int hp;

  @HiveField(8)
  int maxHp;

  @HiveField(9)
  HeroStatus status;

  @HiveField(10)
  DateTime? questCompletesAt;

  @HiveField(11)
  List<Item> inventory;

  @HiveField(12)
  Item? mainHand;

  @HiveField(13)
  Item? offHand;

  @HiveField(14)
  Item? armor;

  @HiveField(15)
  Item? accessory;

  @HiveField(16)
  int? upgradePoints;

  @HiveField(17)
  int? luck;

  @HiveField(18)
  final String? activeQuestId;

  @HiveField(19)
  final String? imagePath;

  HeroModel({
    required this.id,
    required this.name,
    required this.classType,
    this.level = 1,
    this.xp = 0,
    required this.strength,
    required this.speed,
    required this.hp,
    required this.maxHp,
    this.status = HeroStatus.idle,
    this.questCompletesAt,
    List<Item>? inventory,
    this.mainHand,
    this.offHand,
    this.armor,
    this.accessory,
    this.upgradePoints = 0,
    this.luck = 0,
    this.activeQuestId,
    this.imagePath,
  }) : inventory = inventory ?? [];

  // Computed Stats
  int get totalStr {
    int bonus = 0;
    if (mainHand != null) bonus += mainHand!.strengthBonus;
    if (offHand != null) bonus += offHand!.strengthBonus;
    if (armor != null) bonus += armor!.strengthBonus;
    if (accessory != null) bonus += accessory!.strengthBonus;
    return strength + bonus;
  }

  int get totalDef {
    int bonus = 0;
    if (mainHand != null) bonus += mainHand!.defenseBonus;
    if (offHand != null) bonus += offHand!.defenseBonus;
    if (armor != null) bonus += armor!.defenseBonus;
    if (accessory != null) bonus += accessory!.defenseBonus;
    return bonus; // Base defense is 0 for now? Or maybe we add a baseDef field later.
  }

  int get totalSpd {
    int bonus = 0;
    if (mainHand != null) bonus += mainHand!.bonusSpd;
    if (offHand != null) bonus += offHand!.bonusSpd;
    if (armor != null) bonus += armor!.bonusSpd;
    if (accessory != null) bonus += accessory!.bonusSpd;
    return speed + bonus;
  }

  int get totalLuck {
    int bonus = 0;
    if (mainHand != null) bonus += mainHand!.bonusLuck;
    if (offHand != null) bonus += offHand!.bonusLuck;
    if (armor != null) bonus += armor!.bonusLuck;
    if (accessory != null) bonus += accessory!.bonusLuck;
    return (luck ?? 0) + bonus;
  }

  HeroModel copyWith({
    String? id,
    String? name,
    String? classType,
    int? level,
    int? xp,
    int? strength,
    int? speed,
    int? hp,
    int? maxHp,
    HeroStatus? status,
    DateTime? questCompletesAt,
    List<Item>? inventory,
    Item? mainHand,
    Item? offHand,
    Item? armor,
    Item? accessory,
    int? upgradePoints,
    int? luck,
    String? activeQuestId,
    String? imagePath,
  }) {
    return HeroModel(
      id: id ?? this.id,
      name: name ?? this.name,
      classType: classType ?? this.classType,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      strength: strength ?? this.strength,
      speed: speed ?? this.speed,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      status: status ?? this.status,
      questCompletesAt: questCompletesAt ?? this.questCompletesAt,
      inventory: inventory ?? this.inventory,
      mainHand: mainHand ?? this.mainHand,
      offHand: offHand ?? this.offHand,
      armor: armor ?? this.armor,
      accessory: accessory ?? this.accessory,
      upgradePoints: upgradePoints ?? this.upgradePoints,
      luck: luck ?? this.luck,
      activeQuestId: activeQuestId ?? this.activeQuestId,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
