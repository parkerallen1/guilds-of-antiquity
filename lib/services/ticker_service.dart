import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/hero_provider.dart';
import '../providers/game_provider.dart';
import '../providers/log_provider.dart';
import '../providers/quest_provider.dart';
import '../models/hero_model.dart';

import '../models/log_entry_model.dart';
import '../utils/text_gen.dart';
import 'feedback_service.dart';

import 'audio_service.dart';
import '../utils/quest_logic.dart';
import '../engine/quest_resolver.dart';
import '../models/item_model.dart';

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

    // 2. Passive healing. Idle heroes recover slowly; downed (recovering)
    //    heroes recover ~3x faster, then flip back to idle once fully healed.
    for (final hero in heroes) {
      final isResting =
          hero.status == HeroStatus.idle ||
          hero.status == HeroStatus.recovering;

      if (isResting && hero.hp < hero.maxHp) {
        // Heal to 100% in 1 hour (3600s) base; Speed reduces this time.
        // Use a per-tick probability so fractional heal rates average out.
        double speedFactor = 100.0 / (100.0 + hero.totalSpd);
        double timeToHeal = 3600.0 * speedFactor;
        double healPerSec = hero.maxHp / timeToHeal;
        if (hero.status == HeroStatus.recovering) healPerSec *= 3.0;

        if (_random.nextDouble() < healPerSec) {
          int newHp = min(hero.maxHp, hero.hp + 1);
          heroNotifier.updateHero(hero.copyWith(hp: newHp));
        }
      } else if (hero.status == HeroStatus.recovering &&
          hero.hp >= hero.maxHp) {
        heroNotifier.updateHero(hero.copyWith(status: HeroStatus.idle));
        logNotifier.addLog(
          "${hero.name} has fully recovered and is ready for battle.",
          LogType.info,
        );
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

    final feedback = ref.read(feedbackServiceProvider);
    final audio = ref.read(audioServiceProvider);

    // Resolve the quest using the shared, pure resolver (same code path the
    // headless balance simulator runs). This computes success, rewards, loot,
    // leveling, damage and survival; we apply the side effects below.
    final alreadyCompleted = gameState.completedQuestIds.contains(quest.id);
    final outcome = QuestResolver.resolve(
      hero,
      quest,
      alreadyCompleted: alreadyCompleted,
      activeArtifacts: gameState.activeArtifacts,
    );

    if (outcome.success) {
      gameNotifier.addGold(outcome.goldGained);
      audio.playCombatHit();
      feedback.mediumImpact();

      logNotifier.addLog(
        TextGen.generateQuestSuccess(hero.name, quest.title),
        LogType.info,
      );
      logNotifier.addLog("Gained ${outcome.goldGained} Gold.", LogType.gold);
      logNotifier.addLog("Gained ${outcome.xpGained} XP.", LogType.info);
      feedback.showFloatingText('+${outcome.xpGained} XP', FeedbackType.xp);

      // First-time special reward: museum trophy OR a legendary item.
      if (outcome.specialMuseumItemId != null) {
        gameNotifier.unlockMuseumItem(outcome.specialMuseumItemId!);
        logNotifier.addLog(
          "UNLOCKED MUSEUM ARTIFACT: ${outcome.specialMuseumItemName}!",
          LogType.loot,
        );
        audio.playLegendaryDrop();
      }
      if (outcome.specialInventoryItem != null) {
        gameNotifier.addItem(outcome.specialInventoryItem!);
        logNotifier.addLog(
          "OBTAINED LEGENDARY ITEM: ${outcome.specialInventoryItem!.name}!",
          LogType.loot,
        );
        audio.playLegendaryDrop();
      }

      // Random loot drop.
      final Item? loot = outcome.loot;
      if (loot != null) {
        logNotifier.addLog(
          "FOUND: ${loot.name} (${loot.rarity.name})!",
          LogType.loot,
        );
        gameNotifier.addItem(loot);
        if (loot.rarity == ItemRarity.legendary) {
          audio.playLegendaryDrop();
          feedback.vibrate();
        } else {
          feedback.lightImpact();
        }
        feedback.showFloatingText('Found ${loot.name}!', FeedbackType.info);
      }

      gameNotifier.completeQuest(quest.id);

      if (outcome.discoveredQuestId != null) {
        gameNotifier.discoverSideQuest(outcome.discoveredQuestId!);
        logNotifier.addLog("New Quest Unlocked!", LogType.info);
      }
    } else {
      logNotifier.addLog(
        TextGen.generateQuestFailure(hero.name, quest.title),
        LogType.combat,
      );
      audio.playCombatHit();
      feedback.heavyImpact();
      feedback.triggerShake();
    }

    // Damage (applied on success and failure).
    if (outcome.damage > 0) {
      logNotifier.addLog(
        "${hero.name} lost ${outcome.damage} HP.",
        LogType.combat,
      );
      feedback.showFloatingText('-${outcome.damage} HP', FeedbackType.damage);
    } else {
      logNotifier.addLog("${hero.name} took no damage!", LogType.info);
    }

    // Level-up feedback (one line per level gained).
    for (int lvl = hero.level + 1; lvl <= outcome.updatedHero.level; lvl++) {
      logNotifier.addLog("${hero.name} reached Level $lvl!", LogType.info);
      feedback.showFloatingText("Level Up!", FeedbackType.gold);
      audio.playGoldSound();
    }

    // Survival outcome.
    if (outcome.cheatedDeath && outcome.consumedArtifactId != null) {
      final savior = gameState.activeArtifacts
          .where((a) => a.id == outcome.consumedArtifactId)
          .map((a) => a.name)
          .firstOrNull;
      gameNotifier.removeArtifact(outcome.consumedArtifactId!);
      logNotifier.addLog(
        "The ${savior ?? 'artifact'} shatters — ${hero.name} cheats death!",
        LogType.loot,
      );
      feedback.vibrate();
    } else if (outcome.downed) {
      logNotifier.addLog(
        "${hero.name} has fallen and must recover before questing again.",
        LogType.combat,
      );
      feedback.triggerShake();
    }

    heroNotifier.updateHero(outcome.updatedHero);

    // Save Quest Result for the UI.
    final result = QuestResult(
      success: outcome.success,
      goldGained: outcome.success ? outcome.goldGained : 0,
      xpGained: outcome.xpGained,
      itemsGained: outcome.loot != null ? [outcome.loot!.name] : [],
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
