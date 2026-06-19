import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/hero_model.dart';
import '../../models/item_model.dart';
import '../../providers/hero_provider.dart';
import '../../providers/game_provider.dart';
import 'retro_widgets.dart';

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

    return RetroPanel(
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: const Color(0xFF1E1E1E),
      borderWidth: 3,
      bevelWidth: 3,
      padding: EdgeInsets.zero,
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
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Image.asset(currentHero.imagePath!, fit: BoxFit.cover),
                  ),
                ),
              Column(
                children: [
                  Text(
                    currentHero.name.toUpperCase(),
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "LEVEL ${currentHero.level} ${currentHero.classType.toUpperCase()}",
                    style: GoogleFonts.pixelifySans(color: Colors.grey, fontSize: 12),
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
            label: Text(
              "DISMISS HERO",
              style: GoogleFonts.vt323(color: Colors.redAccent, fontSize: 16),
            ),
          ),
          const RetroDivider(color: Colors.black, height: 16, thickness: 2),

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
                            "POINTS: ${currentHero.upgradePoints}",
                            style: GoogleFonts.vt323(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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

          const RetroDivider(color: Colors.black, height: 16, thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "INVENTORY",
                    style: GoogleFonts.vt323(color: Colors.amber, fontSize: 22, letterSpacing: 1.0),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final gameState = ref.watch(gameProvider);
                      return Text(
                        "${gameState.inventory.length}/${gameState.inventoryLimit}",
                        style: GoogleFonts.pixelifySans(
                          color:
                              gameState.inventory.length >=
                                  gameState.inventoryLimit
                              ? Colors.red
                              : Colors.grey,
                          fontSize: 14,
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
                      child: RetroPanel(
                        padding: const EdgeInsets.all(8),
                        backgroundColor: Colors.grey[900],
                        borderWidth: 2,
                        bevelWidth: 2,
                        outlineColor: Colors.black,
                        highlightColor: _getRarityColor(item.rarity).withValues(alpha: 0.3),
                        shadowColor: Colors.black54,
                        child: Row(
                          children: [
                            // Icon/Image
                            RetroPanel(
                              width: 48,
                              height: 48,
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.black54,
                              borderWidth: 1.5,
                              bevelWidth: 1.5,
                              outlineColor: Colors.black,
                              highlightColor: _getRarityColor(item.rarity).withValues(alpha: 0.3),
                              child: Center(
                                child: item.imagePath != null
                                    ? Image.asset(
                                        item.imagePath!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Icon(
                                        _getIconForSlot(item.slot),
                                        color: _getRarityColor(item.rarity),
                                        size: 20,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Name and Stats
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name.toUpperCase(),
                                    style: GoogleFonts.vt323(
                                      color: _getRarityColor(item.rarity),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _buildStatString(item).toUpperCase(),
                                    style: GoogleFonts.pixelifySans(
                                      color: Colors.grey[400],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RetroButton(
                                  backgroundColor: Colors.green[700]!,
                                  padding: const EdgeInsets.all(8),
                                  borderWidth: 1.5,
                                  bevelWidth: 1.5,
                                  onPressed: () => _equipItem(ref, currentHero, item),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                RetroButton(
                                  backgroundColor: Colors.amber[700]!,
                                  padding: const EdgeInsets.all(8),
                                  borderWidth: 1.5,
                                  bevelWidth: 1.5,
                                  onPressed: () => _sellItem(context, ref, item),
                                  child: const Icon(
                                    FontAwesomeIcons.coins,
                                    color: Colors.black,
                                    size: 12,
                                  ),
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
    final color = item != null
        ? _getRarityColor(item.rarity)
        : Colors.grey.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: item != null ? () => _unequipItem(ref, hero, item) : null,
      child: RetroPanel(
        width: 60,
        height: 60,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.black54,
        borderWidth: 2,
        bevelWidth: 2,
        outlineColor: Colors.black,
        highlightColor: color.withValues(alpha: 0.4),
        shadowColor: Colors.black,
        child: Center(
          child: item?.imagePath != null
              ? Image.asset(
                  item!.imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Icon(
                  _getIconForSlot(slot),
                  color: color,
                  size: 20,
                ),
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
            child: Text(
              "$label: ",
              style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 13),
            ),
          ),
          Text(
            "$total",
            style: GoogleFonts.pixelifySans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (bonus > 0)
            Text(
              " (+$bonus)",
              style: GoogleFonts.pixelifySans(color: Colors.green, fontSize: 11),
            ),
          if (onUpgrade != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: RetroButton(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.all(4),
                borderWidth: 1,
                bevelWidth: 1,
                onPressed: onUpgrade,
                child: const Icon(Icons.add, size: 10, color: Colors.black),
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
        title: Text(
          "DISMISS ${hero.name.toUpperCase()}?",
          style: GoogleFonts.vt323(color: Colors.white, fontSize: 24),
        ),
        content: Text(
          "ARE YOU SURE YOU WANT TO DISMISS THIS HERO? THIS ACTION CANNOT BE UNDONE.",
          style: GoogleFonts.pixelifySans(color: Colors.grey, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.vt323(color: Colors.grey, fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              ref.read(heroProvider.notifier).dismissHero(hero);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: Text(
              "DISMISS",
              style: GoogleFonts.vt323(color: Colors.redAccent, fontSize: 18),
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
        title: Text(
          "SELL ${item.name.toUpperCase()}?",
          style: GoogleFonts.vt323(color: Colors.white, fontSize: 24),
        ),
        content: Text(
          "SELL THIS ITEM FOR ${10 + (item.rarity.index * 10)} GOLD?",
          style: GoogleFonts.pixelifySans(color: Colors.grey, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CANCEL", style: GoogleFonts.vt323(color: Colors.grey, fontSize: 18)),
          ),
          TextButton(
            onPressed: () {
              ref.read(gameProvider.notifier).sellItem(item);
              Navigator.pop(context);
            },
            child: Text("SELL", style: GoogleFonts.vt323(color: Colors.amber, fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
