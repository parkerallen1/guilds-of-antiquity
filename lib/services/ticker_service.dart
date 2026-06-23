import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
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

  /// Anti-repetition tracking (P1.3): the last quest resolved and how many
  /// times in a row it has been run, so back-to-back repeats of the same node
  /// earn tapering rewards. Session-scoped (this service lives for the run).
  String? _lastQuestId;
  int _questStreak = 0;

  /// Loot pity tracking (P1.5): successful quests since the last random drop,
  /// so a long dry streak ramps the drop chance toward a guarantee.
  int _questsSinceDrop = 0;

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

    // 2. Passive healing. Heroes regenerate while idle, while recovering
    //    (downed, ~3x faster), AND now while questing too (P1.1) — so the old
    //    "fight → stop → wait to heal → fight" loop no longer serializes the
    //    game. Re-read the latest heroes so one whose quest just completed
    //    above (now idle) isn't healed off the stale questing snapshot.
    for (final hero in ref.read(heroProvider)) {
      final canRegen =
          hero.status == HeroStatus.idle ||
          hero.status == HeroStatus.recovering ||
          hero.status == HeroStatus.questing;

      if (canRegen && hero.hp < hero.maxHp) {
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
    final bool sameAsLast = _lastQuestId == quest.id;
    final int priorStreak = sameAsLast ? _questStreak : 0;
    final outcome = QuestResolver.resolve(
      hero,
      quest,
      alreadyCompleted: alreadyCompleted,
      activeArtifacts: gameState.activeArtifacts,
      sameQuestStreak: priorStreak,
      questsSinceDrop: _questsSinceDrop,
    );
    // Advance the anti-repetition streak: another run of the same node grows
    // it; switching to a different node resets it (full rewards next time).
    _questStreak = sameAsLast ? _questStreak + 1 : 1;
    _lastQuestId = quest.id;

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

      // Random loot drop. Reset the pity counter on a drop; otherwise count
      // this dry quest (P1.5).
      final Item? loot = outcome.loot;
      _questsSinceDrop = loot != null ? 0 : _questsSinceDrop + 1;
      if (loot != null) {
        logNotifier.addLog(
          "FOUND: ${loot.name} (${loot.rarity.name})!",
          LogType.loot,
        );
        gameNotifier.addItem(loot);
        // Rarity-scaled juice (P1.5): better gear gets a bigger, louder,
        // colour-coded celebration; commons stay quiet so they don't over-juice.
        _playLootFeedback(feedback, audio, loot);
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

  /// Rarity-scaled loot celebration (P1.5): colour, text size, haptics and SFX
  /// all scale with rarity, with a stamp on the rarer drops. Commons stay quiet
  /// so a 10-gold pickup isn't over-juiced.
  void _playLootFeedback(
    FeedbackService feedback,
    AudioService audio,
    Item loot,
  ) {
    final Color color = _rarityColor(loot.rarity);
    switch (loot.rarity) {
      case ItemRarity.legendary:
        audio.playLegendaryDrop();
        feedback.vibrate();
        feedback.triggerShake();
        feedback.showFloatingText(
          '★ LEGENDARY! ${loot.name}',
          FeedbackType.info,
          color: color,
          scale: 1.6,
        );
        break;
      case ItemRarity.epic:
        audio.playGoldSound();
        feedback.heavyImpact();
        feedback.showFloatingText(
          '✦ EPIC! ${loot.name}',
          FeedbackType.info,
          color: color,
          scale: 1.3,
        );
        break;
      case ItemRarity.rare:
        feedback.mediumImpact();
        feedback.showFloatingText(
          'NEW! ${loot.name}',
          FeedbackType.info,
          color: color,
          scale: 1.1,
        );
        break;
      default: // common / quest
        feedback.lightImpact();
        feedback.showFloatingText(
          'Found ${loot.name}',
          FeedbackType.info,
          color: color,
        );
    }
  }

  Color _rarityColor(ItemRarity rarity) {
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
}

final tickProvider = StateProvider<int>((ref) => 0);
