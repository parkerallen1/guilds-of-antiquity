import '../models/item_model.dart';

class MuseumItems {
  static final List<Item> allItems = [
    // ERA 1: Age of Iron
    Item(
      id: 'whispering_stone_fragment',
      name: 'Whispering Stone Fragment',
      description:
          'A piece of the stone that drove the scholar mad. It still hums.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/whispering_stone.png',
      value: 0,
    ),
    Item(
      id: 'corrupted_root',
      name: 'Corrupted Root',
      description:
          'A root from the heart of the forest, twisted by dark magic.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/corrupted_root.png',
      value: 0,
    ),
    Item(
      id: 'bandit_badge',
      name: 'Bandit Leader\'s Badge',
      description:
          'The insignia of the bandit leader who tried to siege the village.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/bandit_badge.png',
      value: 0,
    ),

    // ERA 2: Age of Shadows
    Item(
      id: 'frozen_heart',
      name: 'Frozen Troll Heart',
      description: 'Cold to the touch, it never melts even in the desert heat.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/frozen_heart.png',
      value: 0,
    ),
    Item(
      id: 'void_essence',
      name: 'Void Essence',
      description: 'A contained swirl of nothingness from the Cursed Temple.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/void_essence.png',
      value: 0,
    ),
    Item(
      id: 'ash_king_head',
      name: 'Head of the Ash-King',
      description:
          'The skull of the construct dragon. Smoke still pours from its nostrils.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/ash_king_head.png',
      value: 0,
    ),

    // ERA 3: Age of Arcanum
    Item(
      id: 'thrall_helmet',
      name: 'Thrall Helmet',
      description: 'A helmet from the silent army. It has no eye slits.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/thrall_helmet.png',
      value: 0,
    ),
    Item(
      id: 'crown_eclipse',
      name: 'Crown of the Eclipse',
      description: 'The crown worn by the King during the final eclipse.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/crown_eclipse.png',
      value: 0,
    ),
    Item(
      id: 'shard_reality',
      name: 'Shard of Reality',
      description: 'A fragment of the barrier between worlds.',
      rarity: ItemRarity.quest,
      slot: ItemSlot.trophy,
      imagePath: 'assets/images/items/quest/shard_reality.png',
      value: 0,
    ),

    // LEGENDARY ITEMS (Quest Rewards)
    Item(
      id: 'abdication_ring',
      name: 'The Abdication Ring',
      description: 'A royal ring with the crest filed off.',
      rarity: ItemRarity.legendary,
      slot: ItemSlot.accessory,
      imagePath: 'assets/images/items/legendary/abdication_ring.png',
      value: 1000,
      bonusLuck: 5,
    ),
    Item(
      id: 'tear_bride',
      name: 'Tear of the Bride',
      description: 'A gem that is always wet to the touch.',
      rarity: ItemRarity.legendary,
      slot: ItemSlot.accessory,
      imagePath: 'assets/images/items/legendary/tear_bride.png',
      value: 1000,
      bonusSpd: 5,
    ),
    Item(
      id: 'thorne_dagger',
      name: 'General Thorne\'s Dagger',
      description: 'A jagged blade that has seen better days.',
      rarity: ItemRarity.legendary,
      slot: ItemSlot.mainHand,
      imagePath: 'assets/images/items/legendary/thorne_dagger.png',
      value: 1500,
      strengthBonus: 20,
    ),
  ];

  static Item? getById(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  static Item? getByName(String name) {
    try {
      return allItems.firstWhere((item) => item.name == name);
    } catch (e) {
      return null;
    }
  }
}
