import 'dart:math';

import '../../lib/models/hero_model.dart';
import '../../lib/models/quest_model.dart';
import '../../lib/utils/game_logic.dart';
import '../../lib/utils/quest_logic.dart';
import '../../lib/engine/quest_resolver.dart';

import 'sim_state.dart';
import 'quest_repo.dart';
import 'policies.dart';
import 'metrics.dart';

class SimConfig {
  final Policy policy;
  final bool enableTavern;
  final double maxSeconds; // virtual-time cap (default 60 in-game days)
  final int maxActions; // safety cap on quest attempts
  const SimConfig({
    required this.policy,
    this.enableTavern = true,
    this.maxSeconds = 60 * 24 * 3600,
    this.maxActions = 200000,
  });
}

/// Result of one quest step (shared by bot loop and REPL).
class StepResult {
  final Quest adjusted;
  final QuestOutcome outcome;
  final int durationSeconds;
  final bool alreadyCompleted;
  final bool wasFirstCompletion;
  StepResult(this.adjusted, this.outcome, this.durationSeconds,
      this.alreadyCompleted, this.wasFirstCompletion);
}

class Simulator {
  final QuestRepo repo;
  final Random rng;
  late final Set<String> criticalPath;

  /// Last run's final state, for inspection/debugging.
  SimState? lastState;

  Simulator(this.repo, {int? seed}) : rng = Random(seed) {
    criticalPath = _computeCriticalPath('siege_capital');
  }

  Set<String> _computeCriticalPath(String endId) {
    final path = <String>{};
    String? id = endId;
    while (id != null) {
      final q = repo.byId(id);
      if (q == null) break;
      path.add(q.id);
      id = q.requiredQuestId;
    }
    return path;
  }

  RunResult run(SimConfig cfg) {
    final result = RunResult(cfg.policy.name);
    final state = SimState(
      hero: HeroModel(
        id: 'hero',
        name: 'Sim',
        classType: 'Mercenary',
        strength: 5,
        speed: 5,
        hp: 100,
        maxHp: 100,
        level: 1,
        xp: 0,
        upgradePoints: 0,
        luck: 0,
      ),
    );

    double nextTavernAt = 3600; // first tavern quest ~1h in

    while (true) {
      // Stop conditions.
      if (state.completedQuestIds.contains('siege_capital')) {
        result.reachedEnd = true;
        result.stoppedReason = 'reached siege_capital';
        break;
      }
      if (result.actions >= cfg.maxActions) {
        result.stoppedReason = 'hit maxActions';
        break;
      }
      if (state.totalSeconds >= cfg.maxSeconds) {
        result.stoppedReason = 'hit maxSeconds';
        break;
      }

      // Tavern faucet: surface a new side quest on its slow cadence.
      if (cfg.enableTavern && state.totalSeconds >= nextTavernAt) {
        _tavernDiscover(state);
        nextTavernAt = state.totalSeconds + (10 + rng.nextInt(5)) * 3600.0;
      }

      // Spend any upgrade points.
      _spendPoints(state, cfg.policy);

      // Pick the next quest to run.
      final choice = _chooseQuest(state, cfg.policy);
      if (choice == null) {
        // Nothing attemptable and can't progress — genuinely stuck.
        result.stoppedReason = 'no attemptable quest (stuck)';
        break;
      }
      final quest = choice;
      final step = applyQuestStep(state, quest);

      // Metrics bookkeeping.
      result.actions++;
      if (step.alreadyCompleted) result.replayAttempts++;
      if (step.outcome.success) {
        result.successes++;
        result.totalGoldEarned += step.outcome.goldGained;
        if (step.wasFirstCompletion &&
            quest.isMainQuest &&
            criticalPath.contains(quest.id)) {
          result.gates.add(GateClear(
            quest.id,
            quest.difficulty,
            result.actions,
            state.totalSeconds,
            step.outcome.updatedHero.level,
          ));
        }
      } else {
        result.failures++;
      }
      if (step.outcome.downed) result.downs++;
    }

    result.finalLevel = state.hero.level;
    result.questingSeconds = state.questingSeconds;
    result.healingSeconds = state.healingSeconds;
    result.shardsBought = state.shardsBought;
    result.maxSingleQuestReplays = state.completionCounts.values.isEmpty
        ? 0
        : state.completionCounts.values.reduce(max);
    lastState = state;
    return result;
  }

  /// Run one quest end-to-end against [state]: rest to full, pay the time cost,
  /// resolve with the shared [QuestResolver], and apply rewards/loot/equip/
  /// discovery to [state]. Used by both the bot loop and the interactive REPL.
  StepResult applyQuestStep(SimState state, Quest quest) {
    final alreadyCompleted = state.completedQuestIds.contains(quest.id);
    final adjusted = QuestLogic.getAdjustedQuest(
      quest,
      state.completionCounts[quest.id] ?? 0,
    );

    // Rest to full before fighting (free, but costs virtual time).
    state.restToFull();

    // Time cost of the quest (Speed + artifacts).
    int duration = GameLogic.calculateQuestDuration(state.hero, adjusted);
    for (final a in state.activeArtifacts) {
      duration = a.modifyQuestDuration(duration);
    }
    state.questingSeconds += duration;

    // Resolve with the REAL shared resolver.
    final outcome = QuestResolver.resolve(
      state.hero,
      adjusted,
      alreadyCompleted: alreadyCompleted,
      activeArtifacts: state.activeArtifacts,
    );

    // Apply. Hero (xp/level/hp/status) first, then layer equipment on top.
    state.hero = outcome.updatedHero;
    bool wasFirst = false;
    if (outcome.success) {
      state.addGold(outcome.goldGained);
      wasFirst = !state.completedQuestIds.contains(quest.id);
      state.markCompleted(quest.id);
      if (outcome.loot != null && !state.tryEquip(outcome.loot!)) {
        state.addItemToInventory(outcome.loot!);
      }
      if (outcome.specialInventoryItem != null &&
          !state.tryEquip(outcome.specialInventoryItem!)) {
        state.addItemToInventory(outcome.specialInventoryItem!);
      }
      if (outcome.discoveredQuestId != null) {
        state.discoveredSideQuestIds.add(outcome.discoveredQuestId!);
      }
    }
    return StepResult(adjusted, outcome, duration, alreadyCompleted, wasFirst);
  }

  // --- public accessors for the interactive REPL ---

  List<Quest> attemptableQuests(SimState s) => _attemptable(s);
  Quest? storyTarget(SimState s) => _storyTarget(s);
  void buyShard(SimState s) => _buyShard(s);
  void tavernDiscover(SimState s) => _tavernDiscover(s);

  // --- helpers ---

  void _spendPoints(SimState state, Policy policy) {
    while ((state.hero.upgradePoints ?? 0) > 0) {
      final stat = policy.chooseStat(state.hero);
      var h = state.hero;
      switch (stat) {
        case 'str':
          h = h.copyWith(strength: h.strength + 1);
          break;
        case 'spd':
          h = h.copyWith(speed: h.speed + 1);
          break;
        case 'hp':
          h = h.copyWith(maxHp: h.maxHp + 10);
          break;
        case 'luck':
          h = h.copyWith(luck: (h.luck ?? 0) + 1);
          break;
      }
      state.hero = h.copyWith(upgradePoints: (h.upgradePoints ?? 0) - 1);
    }
  }

  void _tavernDiscover(SimState state) {
    final candidates = repo.sideQuests
        .where((q) =>
            !state.discoveredSideQuestIds.contains(q.id) &&
            repo.prereqSatisfied(q, state.completedQuestIds) &&
            repo.hintsSatisfied(q, state.questHints))
        .toList();
    if (candidates.isEmpty) return;
    state.discoveredSideQuestIds.add(candidates[rng.nextInt(candidates.length)].id);
  }

  /// The first uncompleted critical-path main quest whose prerequisite is done.
  Quest? _storyTarget(SimState state) {
    Quest? best;
    for (final q in repo.mainQuests) {
      if (!criticalPath.contains(q.id)) continue;
      if (state.completedQuestIds.contains(q.id)) continue;
      if (!repo.prereqSatisfied(q, state.completedQuestIds)) continue;
      if (best == null || q.difficulty < best.difficulty) best = q;
    }
    return best;
  }

  /// All quests the player could attempt right now.
  List<Quest> _attemptable(SimState state) {
    final out = <Quest>[];
    for (final q in repo.all) {
      if (!repo.prereqSatisfied(q, state.completedQuestIds)) continue;
      if (!repo.hintsSatisfied(q, state.questHints)) continue;
      if (q.isMainQuest) {
        out.add(q); // main quests are visible once prereq+hints are met
      } else if (state.discoveredSideQuestIds.contains(q.id)) {
        out.add(q);
      }
    }
    return out;
  }

  Quest? _chooseQuest(SimState state, Policy policy) {
    final target = _storyTarget(state);

    // Try to unlock a hint-gated story target by buying shards.
    if (target != null &&
        !repo.hintsSatisfied(target, state.questHints) &&
        policy.buysHints) {
      if (state.gold >= 500) {
        _buyShard(state);
        // Re-evaluate target attemptability after the (random) hint.
      }
    }

    // If the story target is attemptable at acceptable odds, take it.
    if (target != null &&
        repo.hintsSatisfied(target, state.questHints) &&
        repo.prereqSatisfied(target, state.completedQuestIds)) {
      final chance = GameLogic.calculateSuccessChance(state.hero, target);
      if (chance >= policy.mainAttemptThreshold) {
        return target;
      }
    }

    // Otherwise grind the best XP-per-second quest available to level up.
    final options = _attemptable(state);
    if (options.isEmpty) return null;

    Quest? best;
    double bestScore = -1;
    for (final q in options) {
      final completed = state.completedQuestIds.contains(q.id);
      final adjusted =
          QuestLogic.getAdjustedQuest(q, state.completionCounts[q.id] ?? 0);
      int xp = adjusted.xpReward;
      if (completed && adjusted.isReplayable) {
        xp = adjusted.repeatXpReward ?? (adjusted.xpReward ~/ 2);
      } else if (completed && !adjusted.isReplayable) {
        continue; // can't repeat a non-replayable completed quest
      }
      final chance =
          GameLogic.calculateSuccessChance(state.hero, adjusted) / 100.0;
      int dur = GameLogic.calculateQuestDuration(state.hero, adjusted);
      final score = (xp * chance) / dur;
      if (score > bestScore) {
        bestScore = score;
        best = q;
      }
    }
    return best;
  }

  /// Mirrors `GameNotifier.buyShard`: 500 gold, a hint goes to a RANDOM
  /// eligible hidden quest (so it can land on a quest you didn't want).
  void _buyShard(SimState state) {
    final eligible = repo.hintEligible(state.questHints);
    if (eligible.isEmpty) return;
    state.spendGold(500);
    state.shardsBought++;
    final q = eligible[rng.nextInt(eligible.length)];
    state.questHints[q.id] = (state.questHints[q.id] ?? 0) + 1;
  }
}
