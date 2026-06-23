import '../models/hero_model.dart';
import '../models/quest_model.dart';
import '../models/item_model.dart';
import '../models/artifact.dart';
import '../models/hero_class.dart';
import '../data/museum_items.dart';
import '../utils/game_logic.dart';

/// Pure, Flutter-free result of resolving one quest attempt.
///
/// [QuestResolver.resolve] computes everything that happens when a quest timer
/// finishes — success roll, rewards, loot, leveling, damage, and survival —
/// and returns it as plain data. The *caller* is responsible for applying the
/// side effects (adding gold/items, persisting completion, logging, feedback,
/// audio). This keeps the math identical between the live game
/// (`TickerService`) and the headless balance simulator (`sim/`).
class QuestOutcome {
  /// Did the combat roll succeed?
  final bool success;

  /// The hero after XP/leveling/damage/status have been applied. The caller
  /// should persist this (it already has [HeroModel.questCompletesAt] and
  /// [HeroModel.activeQuestId] cleared).
  final HeroModel updatedHero;

  /// Base gold to award (BEFORE any gold-multiplier artifact such as the
  /// Greed Coin — that is applied by the caller's `addGold`, exactly as the
  /// live game does). Zero on failure.
  final int goldGained;

  /// XP actually granted (0 on failure). Already folded into [updatedHero].
  final int xpGained;

  /// HP lost this attempt (applied on success AND failure), already folded
  /// into [updatedHero].
  final int damage;

  /// How many levels the hero gained this attempt.
  final int levelsGained;

  /// Random loot drop to add to inventory, or null.
  final Item? loot;

  /// First-time special reward that is a real equippable item (legendary).
  final Item? specialInventoryItem;

  /// First-time special reward that is a museum-only trophy (id + name).
  final String? specialMuseumItemId;
  final String? specialMuseumItemName;

  /// The `nextQuestId` to discover on success, or null.
  final String? discoveredQuestId;

  /// Artifact consumed to cheat death (e.g. Phoenix Feather), or null.
  final String? consumedArtifactId;

  /// True if an artifact saved the hero from death this attempt.
  final bool cheatedDeath;

  /// True if the hero was downed and entered [HeroStatus.recovering].
  final bool downed;

  const QuestOutcome({
    required this.success,
    required this.updatedHero,
    required this.goldGained,
    required this.xpGained,
    required this.damage,
    required this.levelsGained,
    this.loot,
    this.specialInventoryItem,
    this.specialMuseumItemId,
    this.specialMuseumItemName,
    this.discoveredQuestId,
    this.consumedArtifactId,
    this.cheatedDeath = false,
    this.downed = false,
  });
}

class QuestResolver {
  /// Resolve a finished quest. [quest] must already be the difficulty/reward
  /// adjusted quest (run it through `QuestLogic.getAdjustedQuest` with the
  /// completion count first, exactly as the live game does).
  ///
  /// [alreadyCompleted] = whether this quest id is in the player's completed
  /// set (drives first-time vs replay rewards and special-item drops).
  /// [activeArtifacts] is used only to cheat death.
  static QuestOutcome resolve(
    HeroModel hero,
    Quest quest, {
    required bool alreadyCompleted,
    List<Artifact> activeArtifacts = const [],
    int sameQuestStreak = 0,
    int questsSinceDrop = 0,
    double xpMultiplier = 1.0,
    double dropBonus = 0.0,
  }) {
    final success = GameLogic.calculateCombatSuccess(hero, quest);

    int xpGained = 0;
    int goldGained = 0;
    Item? loot;
    Item? specialInventoryItem;
    String? specialMuseumItemId;
    String? specialMuseumItemName;
    String? discoveredQuestId;

    final bool isFirstTime = !alreadyCompleted;

    if (success) {
      int goldReward = quest.goldReward;
      int xpReward = quest.xpReward;

      // Replays of an already-completed, replayable quest pay reduced rewards.
      if (!isFirstTime && quest.isReplayable) {
        goldReward = quest.repeatGoldReward ?? (quest.goldReward ~/ 2);
        xpReward = quest.repeatXpReward ?? (quest.xpReward ~/ 2);
      }

      // Catch-up XP (P1.2): a hero taking on a quest above their level earns
      // bonus XP that scales with how far under the quest's difficulty they
      // are (up to +100% at 10+ levels under). This closes early walls — e.g.
      // the 5->10 defend_village gap — faster, while at-or-above-level rewards
      // are untouched.
      final int underLevelled = quest.difficulty - hero.level;
      double catchUpMult = 1.0;
      if (underLevelled > 0) {
        catchUpMult += (underLevelled * 0.1).clamp(0.0, 1.0);
      }

      // Anti-repetition (P1.3): rewards taper when the SAME quest is run
      // back-to-back, nudging the player to rotate nodes instead of spamming
      // one. Switching to a different quest resets the streak (full rewards).
      final double varietyMult = (1.0 - sameQuestStreak * 0.05).clamp(0.5, 1.0);

      // Class passive (P3.4): Thief earns more gold, Mage more XP, Ranger more
      // loot. Neutral for unknown classes (e.g. the sim's 'Mercenary').
      final cls = HeroClasses.of(hero.classType);

      // xpMultiplier / dropBonus carry the Scholar / Fortune meta upgrades
      // (P3.1); they default to neutral so the sim and tests are unaffected.
      goldGained = (goldReward * varietyMult * cls.goldMult).round();
      xpGained =
          (xpReward * catchUpMult * varietyMult * xpMultiplier * cls.xpMult)
              .round();

      loot = GameLogic.generateLoot(
        hero.level,
        hero,
        questsSinceDrop: questsSinceDrop,
        dropBonus: dropBonus + cls.dropBonus,
      );

      // First-time special reward.
      if (isFirstTime && quest.specialItemReward != null) {
        final museumItem = MuseumItems.getByName(quest.specialItemReward!);
        if (museumItem != null) {
          if (museumItem.slot == ItemSlot.trophy ||
              museumItem.rarity == ItemRarity.quest) {
            specialMuseumItemId = museumItem.id;
            specialMuseumItemName = museumItem.name;
          } else {
            specialInventoryItem = museumItem;
          }
        } else {
          // Fallback for legacy/missing items (mirrors TickerService).
          specialInventoryItem = Item(
            id: 'special_${quest.id}',
            name: quest.specialItemReward!,
            description:
                quest.specialItemDescription ??
                'A unique reward from ${quest.title}',
            rarity: ItemRarity.legendary,
            slot: ItemSlot.accessory,
            bonusLuck: 5,
            value: 500,
            imagePath: 'assets/images/items/ring_legendary.png',
          );
        }
      }

      if (quest.nextQuestId != null) {
        discoveredQuestId = quest.nextQuestId;
      }
    }

    // Damage is applied on success AND failure.
    final int damage = GameLogic.calculateHealthLoss(hero, quest);

    // Leveling.
    int newXp = hero.xp + xpGained;
    int newLevel = hero.level;
    int newUpgradePoints = hero.upgradePoints ?? 0;
    while (newLevel < 50 && newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
      newUpgradePoints++;
    }
    final int levelsGained = newLevel - hero.level;

    // Survival.
    int finalHp = hero.hp - damage;
    HeroStatus finalStatus = HeroStatus.idle;
    String? consumedArtifactId;
    bool cheatedDeath = false;
    bool downed = false;

    if (finalHp <= 0) {
      for (final artifact in activeArtifacts) {
        if (artifact.preventDeath(hero)) {
          consumedArtifactId = artifact.id;
          break;
        }
      }
      if (consumedArtifactId != null) {
        finalHp = 1;
        finalStatus = HeroStatus.idle;
        cheatedDeath = true;
      } else {
        finalHp = 1;
        finalStatus = HeroStatus.recovering;
        downed = true;
      }
    }

    final updatedHero = hero.copyWith(
      xp: newXp,
      level: newLevel,
      upgradePoints: newUpgradePoints,
      status: finalStatus,
      questCompletesAt: null,
      activeQuestId: null,
      hp: finalHp,
    );

    return QuestOutcome(
      success: success,
      updatedHero: updatedHero,
      goldGained: goldGained,
      xpGained: xpGained,
      damage: damage,
      levelsGained: levelsGained,
      loot: loot,
      specialInventoryItem: specialInventoryItem,
      specialMuseumItemId: specialMuseumItemId,
      specialMuseumItemName: specialMuseumItemName,
      discoveredQuestId: discoveredQuestId,
      consumedArtifactId: consumedArtifactId,
      cheatedDeath: cheatedDeath,
      downed: downed,
    );
  }
}
