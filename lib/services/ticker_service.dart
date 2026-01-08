import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hero_provider.dart';
import '../providers/game_provider.dart';
import '../providers/log_provider.dart';
import '../providers/quest_provider.dart';
import '../models/hero_model.dart';

import '../models/log_entry_model.dart';
import '../utils/game_logic.dart';
import '../utils/text_gen.dart';
import '../models/item_model.dart';
import 'feedback_service.dart';

import 'audio_service.dart';
import '../data/museum_items.dart';
import '../utils/quest_logic.dart';

class TickerService {
  final WidgetRef ref;
  Timer? _timer;
  final Random _random = Random();

  TickerService(this.ref);

  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tick();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void _tick() {
    final heroes = ref.read(heroProvider);
    final heroNotifier = ref.read(heroProvider.notifier);
    final gameNotifier = ref.read(gameProvider.notifier);
    final logNotifier = ref.read(logProvider.notifier);

    // 1. Check active quests
    final now = DateTime.now();
    for (final hero in heroes) {
      if (hero.status == HeroStatus.questing && hero.questCompletesAt != null) {
        if (now.isAfter(hero.questCompletesAt!)) {
          _completeQuest(hero, heroNotifier, gameNotifier, logNotifier);
        }
      }
    }

    // 2. Passive healing
    for (final hero in heroes) {
      if (hero.status == HeroStatus.idle && hero.hp < hero.maxHp) {
        // Heal to 100% in 1 hour (3600s) base.
        // Speed reduces this time.
        // Formula: Time = 3600 * (100 / (100 + Speed))
        // HealPerSec = MaxHP / Time
        double speedFactor = 100.0 / (100.0 + hero.totalSpd);
        double timeToHeal = 3600.0 * speedFactor;
        double healPerSec = hero.maxHp / timeToHeal;

        // Accumulate healing? Or just heal 1 HP if enough time passed?
        // Since we tick every second, we can add float and floor?
        // HeroModel HP is int.
        // Let's just add probability or accumulate.
        // Simple approach: Add 1 HP every X ticks.
        // X = 1 / healPerSec.
        // Example: MaxHP 100. Time 3600. HealPerSec = 0.027.
        // Need ~36 seconds for 1 HP.
        // Let's use a random chance to heal 1 HP to average it out.
        if (_random.nextDouble() < healPerSec) {
          int newHp = min(hero.maxHp, hero.hp + 1);
          heroNotifier.updateHero(hero.copyWith(hp: newHp));
        }
      }
    }

    // 3. Update UI state (Business Production)
    final gameState = ref.read(gameProvider);
    final activeBusiness = gameState.activeBusiness;

    if (activeBusiness != null && activeBusiness.productionFinishTime != null) {
      final now = DateTime.now();
      if (now.isAfter(activeBusiness.productionFinishTime!)) {
        // Production finished!
        // We could send a notification here if we haven't already.
        // For now, just let the UI show "Ready".
      }
    }

    // Force UI update for timers
    ref.read(tickProvider.notifier).state++;
  }

  void _completeQuest(
    HeroModel hero,
    HeroNotifier heroNotifier,
    GameNotifier gameNotifier,
    LogNotifier logNotifier,
  ) {
    if (hero.activeQuestId == null) {
      heroNotifier.updateHero(hero.copyWith(status: HeroStatus.idle));
      return;
    }

    final questService = ref.read(questServiceProvider);
    var quest = questService.getQuestById(hero.activeQuestId!);

    if (quest == null) {
      logNotifier.addLog(
        "Error: Quest data not found for ID ${hero.activeQuestId}",
        LogType.info,
      );
      heroNotifier.updateHero(
        hero.copyWith(status: HeroStatus.idle, activeQuestId: null),
      );
      return;
    }

    // Apply Quest Scaling
    final gameState = ref.read(gameProvider);
    final completionCount = gameState.questCompletionCounts[quest.id] ?? 0;
    quest = QuestLogic.getAdjustedQuest(quest, completionCount);

    final success = GameLogic.calculateCombatSuccess(hero, quest);

    int xpGained = 0;

    final feedback = ref.read(feedbackServiceProvider);
    final audio = ref.read(audioServiceProvider);

    Item? loot;

    if (success) {
      // Check if first time completion
      // We can check if completionCount is 0, but completedQuestIds is the source of truth for "first time" logic usually
      final isFirstTime = !gameState.completedQuestIds.contains(quest.id);

      // Determine Rewards
      int goldReward = quest.goldReward;
      int xpReward = quest.xpReward;

      if (!isFirstTime && quest.isReplayable) {
        goldReward = quest.repeatGoldReward ?? (quest.goldReward ~/ 2);
        xpReward = quest.repeatXpReward ?? (quest.xpReward ~/ 2);
      }

      gameNotifier.addGold(goldReward);
      audio.playCombatHit(); // Or success sound
      feedback.mediumImpact();

      logNotifier.addLog(
        TextGen.generateQuestSuccess(hero.name, quest.title),
        LogType.info,
      );

      logNotifier.addLog("Gained $goldReward Gold.", LogType.gold);

      // XP Calculation
      // Use the base reward for calculation logic if needed, or just use the fixed value?
      // GameLogic.calculateXPGain uses quest.xpReward. We should override it or update GameLogic.
      // Let's just use the calculated xpReward directly.
      // But GameLogic applies multipliers.
      // Let's assume multipliers apply to the base reward we chose.
      // So we can pass a modified quest object or just manually calculate.
      // GameLogic.calculateXPGain takes a Quest. Let's create a temporary quest object if needed,
      // or just trust the logic.
      // Actually, GameLogic.calculateXPGain does: (quest.xpReward * xpMultiplier).round();
      // So we should probably just calculate it manually here since we have the base value.

      xpGained = (xpReward * 1.0)
          .round(); // Apply multipliers if we had them (Library removed)

      logNotifier.addLog("Gained $xpGained XP.", LogType.info);
      feedback.showFloatingText('+$xpGained XP', FeedbackType.xp);

      loot = GameLogic.generateLoot(hero.level, hero);

      // Special Item Reward (First time only)
      if (isFirstTime && quest.specialItemReward != null) {
        // Look up item in MuseumItems
        final museumItem = MuseumItems.getByName(quest.specialItemReward!);

        if (museumItem != null) {
          if (museumItem.slot == ItemSlot.trophy ||
              museumItem.rarity == ItemRarity.quest) {
            // Unlock in Museum only
            gameNotifier.unlockMuseumItem(museumItem.id);
            logNotifier.addLog(
              "UNLOCKED MUSEUM ARTIFACT: ${museumItem.name}!",
              LogType.loot,
            );
            audio.playLegendaryDrop(); // Or specific sound
          } else {
            // Add to inventory (Legendary items)
            gameNotifier.addItem(museumItem);
            logNotifier.addLog(
              "OBTAINED LEGENDARY ITEM: ${museumItem.name}!",
              LogType.loot,
            );
            audio.playLegendaryDrop();
          }
        } else {
          // Fallback for legacy/missing items
          final specialItem = Item(
            id: 'special_${quest.id}', // Unique ID
            name: quest.specialItemReward!,
            description:
                quest.specialItemDescription ??
                "A unique reward from ${quest.title}",
            rarity: ItemRarity.legendary,
            slot: ItemSlot.accessory,
            bonusLuck: 5,
            value: 500,
            imagePath: 'assets/images/items/ring_legendary.png', // Placeholder
          );
          gameNotifier.addItem(specialItem);
          logNotifier.addLog(
            "OBTAINED SPECIAL ITEM: ${specialItem.name}!",
            LogType.loot,
          );
          audio.playLegendaryDrop();
        }
      }

      if (loot != null) {
        logNotifier.addLog(
          "FOUND: ${loot.name} (${loot!.rarity.name})!",
          LogType.loot,
        );

        // Add item to shared inventory
        gameNotifier.addItem(loot!);

        if (loot!.rarity == ItemRarity.legendary) {
          audio.playLegendaryDrop();
          feedback.vibrate();
        } else {
          feedback.lightImpact();
        }
        feedback.showFloatingText('Found ${loot!.name}!', FeedbackType.info);
      }

      // Update Quest Progress
      gameNotifier.completeQuest(quest.id);

      // Unlock Next Quest in Chain
      if (quest.nextQuestId != null) {
        gameNotifier.discoverSideQuest(quest.nextQuestId!);
        logNotifier.addLog("New Quest Unlocked!", LogType.info);
      }

      // Discover Side Quests Logic (Random chance to find a side quest)
      // TODO: Implement side quest discovery logic here if desired
      // For now, we can just rely on Shop or specific triggers.
      // Or maybe finding a map?
    } else {
      logNotifier.addLog(
        TextGen.generateQuestFailure(hero.name, quest.title),
        LogType.combat,
      );

      audio.playCombatHit();
      feedback.heavyImpact();
      feedback.triggerShake();
    }

    // Calculate Health Loss (happens regardless of success/failure)
    int damage = GameLogic.calculateHealthLoss(hero, quest);
    if (damage > 0) {
      int newHp = max(0, hero.hp - damage);
      heroNotifier.updateHero(
        hero.copyWith(hp: newHp),
      ); // Temporary update before final save

      logNotifier.addLog("${hero.name} lost $damage HP.", LogType.combat);
      feedback.showFloatingText('-$damage HP', FeedbackType.damage);
    } else {
      logNotifier.addLog("${hero.name} took no damage!", LogType.info);
    }

    // Leveling Logic
    int newXp = hero.xp + xpGained;
    int newLevel = hero.level;
    int newUpgradePoints = hero.upgradePoints ?? 0;

    // Max level 50
    while (newLevel < 50 && newXp >= newLevel * 100) {
      newXp -= newLevel * 100;
      newLevel++;
      newUpgradePoints++;
      logNotifier.addLog("${hero.name} reached Level $newLevel!", LogType.info);
      feedback.showFloatingText("Level Up!", FeedbackType.gold);
      audio.playGoldSound();
    }

    final updatedHero = hero.copyWith(
      xp: newXp,
      level: newLevel,
      upgradePoints: newUpgradePoints,
      status: HeroStatus.idle,
      questCompletesAt: null, // Clear the timestamp
      activeQuestId: null, // Clear active quest
      hp: max(0, hero.hp - damage), // Apply damage to final state
    );

    heroNotifier.updateHero(updatedHero);

    // Save Quest Result
    final result = QuestResult(
      success: success,
      goldGained: success
          ? (quest.repeatGoldReward ?? quest.goldReward)
          : 0, // Approximate
      xpGained: xpGained,
      itemsGained: loot != null ? [loot.name] : [],
      questTitle: quest.title,
      heroId: hero.id,
      timestamp: DateTime.now(),
    );

    ref
        .read(questResultProvider.notifier)
        .update((state) => {...state, hero.id: result});
  }
}

final tickProvider = StateProvider<int>((ref) => 0);
