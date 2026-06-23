import 'dart:math';

import '../../lib/models/hero_model.dart';
import '../../lib/models/item_model.dart';
import '../../lib/models/artifact.dart';

/// Mutable, Flutter-free mirror of the parts of game state the core
/// quest/level loop touches. Persistence/UI are intentionally absent.
class SimState {
  HeroModel hero;
  int gold;

  final Set<String> completedQuestIds = {};
  final Map<String, int> completionCounts = {};
  final Set<String> discoveredSideQuestIds = {};
  final Map<String, int> questHints = {};

  /// Game-level shared inventory (loot lives here, not on the hero — matches
  /// the live game where `gameNotifier.addItem` writes the shared inventory box).
  final List<Item> inventory = [];
  int inventoryLimit = 20;

  final List<Artifact> activeArtifacts = [];

  /// Virtual time accounting (seconds). Quests and healing both consume time;
  /// this is what makes "how long am I grinding" measurable.
  double questingSeconds = 0;
  double healingSeconds = 0;
  int shardsBought = 0;

  double get totalSeconds => questingSeconds + healingSeconds;

  SimState({required this.hero, this.gold = 100}) {
    // Defaults the live game seeds on boot.
    discoveredSideQuestIds.addAll(['daily_patrol', 'dungeon_delve', 'monster_hunt']);
  }

  bool get hasGreedCoin => activeArtifacts.any((a) => a is GreedCoin);

  /// Mirrors `GameNotifier.addGold` gold-multiplier artifact hook.
  void addGold(int amount) {
    double v = amount.toDouble();
    for (final a in activeArtifacts) {
      v = a.modifyGoldGain(v);
    }
    gold += v.toInt();
  }

  void spendGold(int amount) {
    if (gold >= amount) gold -= amount;
  }

  /// Add loot to inventory, auto-selling the cheapest item to make room when
  /// full (a reasonable-player behaviour; the raw game would simply drop it).
  /// Returns true if the item was kept.
  bool addItemToInventory(Item item) {
    if (inventory.length >= inventoryLimit) {
      // Sell cheapest to make room.
      inventory.sort((a, b) => a.value.compareTo(b.value));
      final cheapest = inventory.first;
      if (cheapest.value < item.value) {
        addGold(10 + cheapest.rarity.index * 10);
        inventory.removeAt(0);
      } else {
        // New item is the worst — sell it immediately.
        addGold(10 + item.rarity.index * 10);
        return false;
      }
    }
    inventory.add(item);
    return true;
  }

  void markCompleted(String questId) {
    completedQuestIds.add(questId);
    completionCounts[questId] = (completionCounts[questId] ?? 0) + 1;
  }

  /// Try to equip [item] if it beats the currently equipped item in its slot.
  /// If equipped, any displaced item is moved to inventory internally.
  /// Returns true iff [item] was equipped (caller should NOT keep it then).
  bool tryEquip(Item item) {
    int score(Item? it) => it == null
        ? -1
        : it.strengthBonus + it.defenseBonus + it.bonusSpd + it.bonusLuck;
    final newScore =
        item.strengthBonus + item.defenseBonus + item.bonusSpd + item.bonusLuck;
    Item? old;
    switch (item.slot) {
      case ItemSlot.mainHand:
        if (newScore <= score(hero.mainHand)) return false;
        old = hero.mainHand;
        hero = hero.copyWith(mainHand: item);
        break;
      case ItemSlot.offHand:
        if (newScore <= score(hero.offHand)) return false;
        old = hero.offHand;
        hero = hero.copyWith(offHand: item);
        break;
      case ItemSlot.armor:
        if (newScore <= score(hero.armor)) return false;
        old = hero.armor;
        hero = hero.copyWith(armor: item);
        break;
      case ItemSlot.accessory:
        if (newScore <= score(hero.accessory)) return false;
        old = hero.accessory;
        hero = hero.copyWith(accessory: item);
        break;
      case ItemSlot.trophy:
        return false;
    }
    if (old != null) addItemToInventory(old);
    return true;
  }

  /// Seconds to fully heal the hero from current HP, using the live game's
  /// passive-heal model: full HP in 3600s at base, scaled by Speed; ~3x faster
  /// while recovering (downed).
  double secondsToFullHeal() {
    if (hero.hp >= hero.maxHp) return 0;
    final speedFactor = 100.0 / (100.0 + hero.totalSpd);
    double timeToHealFull = 3600.0 * speedFactor; // for a full bar
    if (hero.status == HeroStatus.recovering) timeToHealFull /= 3.0;
    final missingFraction = (hero.maxHp - hero.hp) / hero.maxHp;
    return timeToHealFull * missingFraction;
  }

  /// Rest to full HP, advancing the virtual clock and clearing recovering.
  void restToFull() {
    final t = secondsToFullHeal();
    if (t > 0) healingSeconds += t;
    hero = hero.copyWith(hp: hero.maxHp, status: HeroStatus.idle);
  }

  int get reviveCost => 50 * hero.level;
}
