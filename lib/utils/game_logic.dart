import 'dart:math';
import '../models/hero_model.dart';
import '../models/quest_model.dart';
import '../models/item_model.dart';
import 'loot_factory.dart';

class GameLogic {
  static final Random _random = Random();

  // Returns success chance as a percentage (0-100)
  static double calculateSuccessChance(HeroModel hero, Quest quest) {
    // Base: 80% if levels are equal
    // +/- 10% per level difference
    int levelDiff = hero.level - quest.difficulty;
    double chance = 80.0 + (levelDiff * 10.0);

    // Strength Impact: Significant but not overpowering
    // Let's say +1% for every point of strength above the difficulty
    // (Assuming difficulty roughly maps to expected strength)
    // And -1% for every point below.
    // We can dampen it slightly, e.g., 0.5% per point.
    double strBonus = (hero.totalStr - quest.difficulty) * 0.5;
    chance += strBonus;

    // Clamp between 5% and 100%
    return chance.clamp(5.0, 100.0);
  }

  // Returns true if success based on calculated chance
  static bool calculateCombatSuccess(HeroModel hero, Quest quest) {
    double chance = calculateSuccessChance(hero, quest);
    return (_random.nextDouble() * 100) < chance;
  }

  // Returns percentage of Max HP to lose
  static int calculateHealthLossPercent(HeroModel hero, double successChance) {
    // Formula: 90 - (calculated % of success + defense stat)
    // Example: Success 80%, Def 5. 90 - 85 = 5% loss.
    // Example: Success 100%, Def 10. 90 - 110 = -20 (0% loss).
    // Example: Success 50%, Def 0. 90 - 50 = 40% loss.
    double loss = 90 - (successChance + hero.totalDef);

    // Early-game cushion (P1.1): the 90-(success+def) curve punishes low-level,
    // low-success heroes hardest — under-levelled early fights bleed 30%+ per
    // attempt. Subtract a flat cushion that fades from 15% at L1 to 0 by L11,
    // leaving the at-level and late-game curve untouched.
    final double earlyCushion = max(0.0, 15.0 - (hero.level - 1) * 1.5);
    loss -= earlyCushion;

    return max(0, loss.round());
  }

  static int calculateHealthLoss(HeroModel hero, Quest quest) {
    double chance = calculateSuccessChance(hero, quest);
    int lossPercent = calculateHealthLossPercent(hero, chance);
    return (hero.maxHp * (lossPercent / 100.0)).round();
  }

  static int calculateQuestDuration(
    HeroModel hero,
    Quest quest, {
    double durationMultiplier = 1.0,
  }) {
    // New Speed Logic: Time / (1 + Speed/100)
    // Example: Speed 100 => Time / 2. Speed 300 => Time / 4.
    // Protect against divide by zero (though speed is usually >= 0)
    double speedFactor = 1 + (hero.totalSpd / 100.0);
    if (speedFactor < 1.0) speedFactor = 1.0; // Minimum factor

    double reducedDuration = quest.durationSeconds / speedFactor;

    // Apply Tavern Multiplier
    double finalDurationDouble = reducedDuration / durationMultiplier;

    int finalDuration = finalDurationDouble.ceil();
    return finalDuration < 1 ? 1 : finalDuration;
  }

  static Item? generateLoot(int level, HeroModel hero) {
    // Base drop rate + Luck
    double chance = 0.1 + (hero.totalLuck * 0.01);
    if (_random.nextDouble() < chance) {
      return LootFactory.generate(level);
    }
    return null;
  }

  static int calculateXPGain(Quest quest, {double xpMultiplier = 1.0}) {
    return (quest.xpReward * xpMultiplier).floor();
  }
}
