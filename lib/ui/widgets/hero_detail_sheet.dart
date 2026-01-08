import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/hero_model.dart';
import '../../models/item_model.dart';
import '../../providers/hero_provider.dart';
import '../../providers/game_provider.dart';

class HeroDetailSheet extends ConsumerWidget {
  final HeroModel hero;

  const HeroDetailSheet({super.key, required this.hero});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroes = ref.watch(heroProvider);
    // Get the latest version of the hero, or fall back to the passed hero if not found (e.g. just dismissed)
    final currentHero = heroes.firstWhere(
      (h) => h.id == hero.id,
      orElse: () => hero,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (currentHero.imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage(currentHero.imagePath!),
                  ),
                ),
              Column(
                children: [
                  Text(
                    currentHero.name,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Level ${currentHero.level} ${currentHero.classType}",
                    style: GoogleFonts.lato(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _confirmDismiss(context, ref, currentHero),
            icon: const Icon(
              FontAwesomeIcons.userXmark,
              size: 16,
              color: Colors.redAccent,
            ),
            label: const Text(
              "Dismiss Hero",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          const Divider(color: Colors.grey),

          // Paper Doll & Stats
          Expanded(
            child: Row(
              children: [
                // Paper Doll (Left)
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildEquipmentSlot(
                        context,
                        ref,
                        currentHero,
                        ItemSlot.mainHand,
                        currentHero.mainHand,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEquipmentSlot(
                            context,
                            ref,
                            currentHero,
                            ItemSlot.armor,
                            currentHero.armor,
                          ),
                          const SizedBox(width: 8),
                          _buildEquipmentSlot(
                            context,
                            ref,
                            currentHero,
                            ItemSlot.accessory,
                            currentHero.accessory,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildEquipmentSlot(
                        context,
                        ref,
                        currentHero,
                        ItemSlot.offHand,
                        currentHero.offHand,
                      ),
                    ],
                  ),
                ),

                // Stats (Right)
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((currentHero.upgradePoints ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            "Points: ${currentHero.upgradePoints}",
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      _buildStatRow(
                        "STR",
                        currentHero.totalStr,
                        currentHero.strength,
                        (currentHero.upgradePoints ?? 0) > 0
                            ? () => _upgradeStat(ref, currentHero, 'str')
                            : null,
                      ),
                      _buildStatRow("DEF", currentHero.totalDef, 0, null),
                      _buildStatRow(
                        "SPD",
                        currentHero.totalSpd,
                        currentHero.speed,
                        (currentHero.upgradePoints ?? 0) > 0
                            ? () => _upgradeStat(ref, currentHero, 'spd')
                            : null,
                      ),
                      _buildStatRow(
                        "HP",
                        currentHero.maxHp,
                        currentHero.maxHp,
                        (currentHero.upgradePoints ?? 0) > 0
                            ? () => _upgradeStat(ref, currentHero, 'hp')
                            : null,
                      ),
                      _buildStatRow(
                        "LUCK",
                        currentHero.totalLuck,
                        currentHero.luck ?? 0,
                        (currentHero.upgradePoints ?? 0) > 0
                            ? () => _upgradeStat(ref, currentHero, 'luck')
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Align(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "INVENTORY",
                    style: GoogleFonts.cinzel(color: Colors.amber),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final gameState = ref.watch(gameProvider);
                      return Text(
                        "${gameState.inventory.length}/${gameState.inventoryLimit}",
                        style: TextStyle(
                          color:
                              gameState.inventory.length >=
                                  gameState.inventoryLimit
                              ? Colors.red
                              : Colors.grey,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Inventory Grid
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final gameState = ref.watch(gameProvider);
                final inventory = gameState.inventory;

                if (inventory.isEmpty) {
                  return Center(
                    child: Text(
                      "Inventory Empty",
                      style: GoogleFonts.lato(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: inventory.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    return GestureDetector(
                      onTap: () => _equipItem(ref, currentHero, item),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border.all(
                            color: _getRarityColor(item.rarity),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Icon/Image
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                                image: item.imagePath != null
                                    ? DecorationImage(
                                        image: AssetImage(item.imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: item.imagePath == null
                                    ? Icon(
                                        _getIconForSlot(item.slot),
                                        color: _getRarityColor(item.rarity),
                                        size: 24,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name and Stats
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.cinzel(
                                      color: _getRarityColor(item.rarity),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _buildStatString(item),
                                    style: GoogleFonts.lato(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Equip Hint
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _equipItem(ref, currentHero, item),
                                  tooltip: "Equip",
                                ),
                                IconButton(
                                  icon: const Icon(
                                    FontAwesomeIcons.coins,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  onPressed: () =>
                                      _sellItem(context, ref, item),
                                  tooltip: "Sell",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlot(
    BuildContext context,
    WidgetRef ref,
    HeroModel hero,
    ItemSlot slot,
    Item? item,
  ) {
    return GestureDetector(
      onTap: item != null ? () => _unequipItem(ref, hero, item) : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black54,
          border: Border.all(
            color: item != null
                ? _getRarityColor(item.rarity)
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          image: item?.imagePath != null
              ? DecorationImage(
                  image: AssetImage(item!.imagePath!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Center(
          child: item?.imagePath == null
              ? Icon(
                  _getIconForSlot(slot),
                  color: item != null
                      ? _getRarityColor(item.rarity)
                      : Colors.grey.withOpacity(0.3),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    int total,
    int base, [
    VoidCallback? onUpgrade,
  ]) {
    final bonus = total - base;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text("$label: ", style: const TextStyle(color: Colors.grey)),
          ),
          Text(
            "$total",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (bonus > 0)
            Text(
              " (+$bonus)",
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
          if (onUpgrade != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: InkWell(
                onTap: onUpgrade,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 12, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blueAccent;
      case ItemRarity.epic:
        return Colors.purpleAccent;
      case ItemRarity.legendary:
        return Colors.amber;
      case ItemRarity.quest:
        return Colors.tealAccent;
    }
  }

  IconData _getIconForSlot(ItemSlot slot) {
    switch (slot) {
      case ItemSlot.mainHand:
        return FontAwesomeIcons.khanda;
      case ItemSlot.offHand:
        return FontAwesomeIcons.shieldHalved;
      case ItemSlot.armor:
        return FontAwesomeIcons.shirt;
      case ItemSlot.accessory:
        return FontAwesomeIcons.ring;
      case ItemSlot.trophy:
        return FontAwesomeIcons.trophy;
    }
  }

  void _upgradeStat(WidgetRef ref, HeroModel hero, String stat) {
    if ((hero.upgradePoints ?? 0) <= 0) return;

    int newStr = hero.strength;
    int newSpd = hero.speed;
    int newMaxHp = hero.maxHp;
    int newLuck = hero.luck ?? 0;

    switch (stat) {
      case 'str':
        newStr += 1;
        break;
      case 'spd':
        newSpd += 1;
        break;
      case 'hp':
        newMaxHp += 10; // +10 HP per point
        break;
      case 'luck':
        newLuck += 1;
        break;
    }

    final updatedHero = hero.copyWith(
      strength: newStr,
      speed: newSpd,
      maxHp: newMaxHp,
      luck: newLuck,
      upgradePoints: (hero.upgradePoints ?? 0) - 1,
      hp: hero.hp, // Keep current HP? Or heal the amount gained?
      // If maxHp increased, maybe increase current hp by same amount?
      // Let's keep it simple for now.
    );

    ref.read(heroProvider.notifier).updateHero(updatedHero);
  }

  void _equipItem(WidgetRef ref, HeroModel hero, Item item) {
    final gameNotifier = ref.read(gameProvider.notifier);

    // 1. Remove item from global inventory
    gameNotifier.removeItem(item);

    Item? oldItem;

    switch (item.slot) {
      case ItemSlot.mainHand:
        oldItem = hero.mainHand;
        break;
      case ItemSlot.offHand:
        oldItem = hero.offHand;
        break;
      case ItemSlot.armor:
        oldItem = hero.armor;
        break;
      case ItemSlot.accessory:
        oldItem = hero.accessory;
        break;
      case ItemSlot.trophy:
        // Trophies cannot be equipped
        return;
    }

    // 2. If slot has item, add that to global inventory
    if (oldItem != null) {
      gameNotifier.addItem(oldItem);
    }

    // 3. Update hero with new item
    final updatedHero = hero.copyWith(
      mainHand: item.slot == ItemSlot.mainHand ? item : hero.mainHand,
      offHand: item.slot == ItemSlot.offHand ? item : hero.offHand,
      armor: item.slot == ItemSlot.armor ? item : hero.armor,
      accessory: item.slot == ItemSlot.accessory ? item : hero.accessory,
    );

    ref.read(heroProvider.notifier).updateHero(updatedHero);
  }

  void _unequipItem(WidgetRef ref, HeroModel hero, Item item) {
    final gameNotifier = ref.read(gameProvider.notifier);

    // 1. Add item to global inventory
    gameNotifier.addItem(item);

    // 2. Update hero with null in slot
    // We need to explicitly pass null to copyWith for the slot we are clearing.
    // But copyWith usually ignores nulls if we don't handle them specially.
    // Let's check my copyWith implementation.
    // "mainHand: mainHand ?? this.mainHand"
    // If I pass null, it uses this.mainHand. So I can't clear it with copyWith as implemented!
    // I need to fix copyWith or use a different approach.
    // Ah, the classic copyWith nullability problem.
    // I can use a sentinel value or just manually construct for unequip since I know what I'm doing,
    // OR I can modify copyWith to allow nullable updates (e.g. using a wrapper or explicit checks).
    // Given I just added fields, manual construction is annoying.
    // I will use manual construction for unequip but include all fields.

    // Wait, I can just use the manual construction but include the new fields.
    // Or I can fix copyWith. Fixing copyWith is better for future.
    // But I can't easily change copyWith signature to distinguish "null" from "not provided" without a wrapper.
    // So I'll stick to manual construction for unequip, BUT I MUST INCLUDE THE NEW FIELDS.

    final updatedHero = HeroModel(
      id: hero.id,
      name: hero.name,
      classType: hero.classType,
      level: hero.level,
      xp: hero.xp,
      strength: hero.strength,
      speed: hero.speed,
      hp: hero.hp,
      maxHp: hero.maxHp,
      status: hero.status,
      questCompletesAt: hero.questCompletesAt,
      inventory: hero.inventory,
      mainHand: item.slot == ItemSlot.mainHand ? null : hero.mainHand,
      offHand: item.slot == ItemSlot.offHand ? null : hero.offHand,
      armor: item.slot == ItemSlot.armor ? null : hero.armor,
      accessory: item.slot == ItemSlot.accessory ? null : hero.accessory,
      upgradePoints: hero.upgradePoints,
      luck: hero.luck,
      activeQuestId: hero.activeQuestId,
      imagePath: hero.imagePath,
    );

    ref.read(heroProvider.notifier).updateHero(updatedHero);
  }

  void _confirmDismiss(BuildContext context, WidgetRef ref, HeroModel hero) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Dismiss ${hero.name}?",
          style: GoogleFonts.cinzel(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to dismiss this hero? This action cannot be undone.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(heroProvider.notifier).dismissHero(hero);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: const Text(
              "Dismiss",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  String _buildStatString(Item item) {
    final parts = <String>[];
    if (item.strengthBonus > 0) parts.add("+${item.strengthBonus} STR");
    if (item.defenseBonus > 0) parts.add("+${item.defenseBonus} DEF");
    if (item.bonusSpd > 0) parts.add("+${item.bonusSpd} SPD");
    if (item.bonusLuck > 0) parts.add("+${item.bonusLuck} LUCK");
    return parts.isEmpty ? "No stats" : parts.join(", ");
  }

  void _sellItem(BuildContext context, WidgetRef ref, Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "Sell ${item.name}?",
          style: GoogleFonts.cinzel(color: Colors.white),
        ),
        content: Text(
          "Sell this item for ${10 + (item.rarity.index * 10)} Gold?",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameProvider.notifier).sellItem(item);
              Navigator.pop(context);
            },
            child: const Text("Sell", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
