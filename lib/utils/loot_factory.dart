import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';

class LootFactory {
  static final Random _random = Random();

  static Item generate(int level, {int rarityBonus = 0}) {
    final rarity = _rollRarity(rarityBonus);
    final slot = _rollSlot();

    // Calculate stats based on level and rarity
    double multiplier = 1.0;
    switch (rarity) {
      case ItemRarity.common:
        multiplier = 1.0;
        break;
      case ItemRarity.rare:
        multiplier = 2.0;
        break;
      case ItemRarity.epic:
        multiplier = 3.0;
        break;
      case ItemRarity.legendary:
        multiplier = 5.0;
        break;
      case ItemRarity.quest:
        multiplier = 1.0; // Should not happen in random loot
        break;
    }

    int baseStat = (level * multiplier).round();
    if (baseStat < 1) baseStat = 1;

    // Determine primary stat based on slot
    int bonusStr = 0;
    int bonusDef = 0;
    int bonusSpd = 0;
    int bonusLuck = 0;

    String rootName = "";
    String? imagePath;

    // Special handling for Legendary items to use "Cool Names" and specific images
    if (rarity == ItemRarity.legendary) {
      return _generateLegendary(level, slot, baseStat);
    }

    switch (slot) {
      case ItemSlot.mainHand:
        bonusStr = baseStat;
        final weaponType = _pick(["Sword", "Axe", "Dagger", "Staff"]);
        rootName = weaponType;
        if (weaponType == "Sword") {
          imagePath = "assets/images/icons/simple_sword.png";
        } else if (weaponType == "Axe") {
          imagePath = _pick([
            "assets/images/icons/heavy_axe.png",
            "assets/images/icons/heavy_greataxe.png",
          ]);
        } else if (weaponType == "Dagger") {
          imagePath = "assets/images/icons/steel_dagger.png";
        } else if (weaponType == "Staff") {
          imagePath = "assets/images/icons/wooden_staff.png";
        }
        break;
      case ItemSlot.offHand:
        bonusDef = (baseStat * 0.8).round();
        rootName = _pick(["Shield", "Buckler", "Orb", "Tome"]);
        if (rootName == "Shield" || rootName == "Buckler") {
          imagePath = "assets/images/icons/steel_shield.png";
        }
        break;
      case ItemSlot.armor:
        bonusDef = baseStat;
        rootName = _pick(["Plate", "Mail", "Robes", "Tunic"]);
        if (rootName == "Tunic" || rootName == "Leather") {
          imagePath =
              "assets/images/icons/leather_helmet.png"; // Placeholder for armor
        }
        break;
      case ItemSlot.accessory:
        if (_random.nextBool()) {
          bonusSpd = (baseStat * 0.5).round();
        } else {
          bonusLuck = (baseStat * 0.5).round();
        }
        rootName = _pick(["Ring", "Amulet", "Charm", "Trinket"]);
        break;
      case ItemSlot.trophy:
        // Should not happen in random loot
        rootName = "Trophy";
        break;
    }

    // Generate Name
    String name;
    if (rarity == ItemRarity.common) {
      name = "Common $rootName";
    } else {
      final prefix = _pick([
        "Rusty",
        "Polished",
        "Vicious",
        "King's",
        "Ancient",
      ]);
      final suffix = _pick([
        "of Speed",
        "of Greed",
        "of the Mountain",
        "of the Bear",
        "of the Wolf",
      ]);
      name = "$prefix $rootName $suffix";
    }

    return Item(
      id: const Uuid().v4(),
      name: name,
      description: "A $rarity $rootName.",
      rarity: rarity,
      slot: slot,
      strengthBonus: bonusStr,
      defenseBonus: bonusDef,
      bonusSpd: bonusSpd,
      bonusLuck: bonusLuck,
      value: baseStat * 10,
      imagePath: imagePath,
    );
  }

  static Item _generateLegendary(int level, ItemSlot slot, int baseStat) {
    // Define Legendary Templates
    final swords = [
      {
        "name": "Blade of the Fallen King",
        "image":
            "assets/images/items/legendary/sword/blade_of_the_fallen_king.png",
      },
      {
        "name": "Sun-Forged Claymore",
        "image": "assets/images/items/legendary/sword/sun_forged_claymore.png",
      },
      {
        "name": "Void-Edge Katana",
        "image": "assets/images/items/legendary/sword/void_edge_katana.png",
      },
    ];

    final daggers = [
      {
        "name": "Whisper of the Night",
        "image":
            "assets/images/items/legendary/dagger/whisper_of_the_night.png",
      },
      {
        "name": "Venomous Fang",
        "image": "assets/images/items/legendary/dagger/venomous_fang.png",
      },
      {
        "name": "Shadow-Step Stiletto",
        "image":
            "assets/images/items/legendary/dagger/shadow_step_stiletto.png",
      },
    ];

    final staffs = [
      {
        "name": "Staff of the Cosmos",
        "image": "assets/images/items/legendary/staff/staff_of_the_cosmos.png",
      },
      {
        "name": "Arcane Spire",
        "image": "assets/images/items/legendary/staff/arcane_spire.png",
      },
      {
        "name": "Nebula's Grasp",
        "image": "assets/images/items/legendary/staff/nebulas_grasp.png",
      },
    ];

    String name;
    String imagePath;
    ItemSlot finalSlot = slot;

    // Force slot to match the legendary type if we pick one, or pick a random legendary type
    // For simplicity, let's pick a random legendary type and set the slot accordingly
    final typeRoll = _random.nextInt(3);
    Map<String, String> template;

    if (typeRoll == 0) {
      finalSlot = ItemSlot.mainHand; // Sword
      template = swords[_random.nextInt(swords.length)];
    } else if (typeRoll == 1) {
      finalSlot = ItemSlot.mainHand; // Dagger
      template = daggers[_random.nextInt(daggers.length)];
    } else {
      finalSlot =
          ItemSlot.mainHand; // Staff (could be offhand but usually main)
      template = staffs[_random.nextInt(staffs.length)];
    }

    // If the requested slot was Armor or Accessory, we might want to generate a generic legendary for those
    // or just override it to be a weapon for now since we only have weapon assets.
    // Let's override to weapon for these specific assets.

    name = template["name"]!;
    imagePath = template["image"]!;

    return Item(
      id: const Uuid().v4(),
      name: name,
      description: "A legendary artifact of immense power.",
      rarity: ItemRarity.legendary,
      slot: finalSlot,
      strengthBonus: baseStat, // Legendaries have high stats
      defenseBonus: (baseStat * 0.5).round(),
      bonusSpd: (baseStat * 0.2).round(),
      bonusLuck: (baseStat * 0.2).round(),
      value: baseStat * 50,
      imagePath: imagePath,
    );
  }

  static ItemRarity _rollRarity(int bonus) {
    final roll = _random.nextInt(100) + bonus;
    if (roll < 70) return ItemRarity.common;
    if (roll < 90) return ItemRarity.rare;
    if (roll < 99) return ItemRarity.epic;
    return ItemRarity.legendary;
  }

  static ItemSlot _rollSlot() {
    final values = ItemSlot.values.where((s) => s != ItemSlot.trophy).toList();
    return values[_random.nextInt(values.length)];
  }

  static String _pick(List<String> options) {
    return options[_random.nextInt(options.length)];
  }
}
