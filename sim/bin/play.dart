import 'dart:io';
import 'dart:math';

import '../../lib/models/hero_model.dart';
import '../../lib/models/quest_model.dart';
import '../../lib/models/item_model.dart';
import '../../lib/utils/game_logic.dart';
import '../../lib/utils/quest_logic.dart';

import '../lib/quest_repo.dart';
import '../lib/sim_state.dart';
import '../lib/simulator.dart';
import '../lib/policies.dart';

/// Interactive, text-only play harness so a human OR an LLM can play the real
/// game loop turn by turn (pipe commands via stdin, or type them).
///
///   dart run bin/play.dart            # interactive
///   echo "s\ngo training_day\ns" | dart run bin/play.dart   # scripted
void main(List<String> args) {
  final repo = QuestRepo.load();
  final sim = Simulator(repo, seed: args.contains('--seed') ? 42 : null);
  final autoPolicy = Balanced();

  final state = SimState(
    hero: HeroModel(
      id: 'hero',
      name: 'Hero',
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
  double nextTavernAt = 3600;

  void maybeTavern() {
    if (state.totalSeconds >= nextTavernAt) {
      final before = state.discoveredSideQuestIds.length;
      sim.tavernDiscover(state);
      if (state.discoveredSideQuestIds.length > before) {
        stdout.writeln('  * A tavern patron offered a new side quest.');
      }
      nextTavernAt = state.totalSeconds + (10 + Random().nextInt(5)) * 3600.0;
    }
  }

  String fmtTime(double s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  void printStatus() {
    final h = state.hero;
    stdout.writeln('── HERO ${h.name}  Lv${h.level}  (${h.status.name}) ──');
    stdout.writeln('  XP ${h.xp}/${h.level * 100}   HP ${h.hp}/${h.maxHp}'
        '   points:${h.upgradePoints ?? 0}');
    stdout.writeln('  STR ${h.totalStr} (base ${h.strength})'
        '   SPD ${h.totalSpd} (base ${h.speed})'
        '   DEF ${h.totalDef}   LUCK ${h.totalLuck}');
    stdout.writeln('  Gold ${state.gold}    Inv ${state.inventory.length}/${state.inventoryLimit}'
        '    Time played ${fmtTime(state.totalSeconds)}'
        ' (heal ${fmtTime(state.healingSeconds)})');
    final target = sim.storyTarget(state);
    if (target != null) {
      final ch = GameLogic.calculateSuccessChance(state.hero, target);
      final hintOk = repo.hintsSatisfied(target, state.questHints);
      stdout.writeln('  Story target: ${target.title} (diff ${target.difficulty}, '
          '${ch.toStringAsFixed(0)}% win${hintOk ? "" : ", NEEDS HINTS"})');
    } else {
      stdout.writeln('  Story target: (none — endgame reached?)');
    }
  }

  List<Quest> listQuests() {
    final qs = sim.attemptableQuests(state)
      ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    stdout.writeln('── ATTEMPTABLE QUESTS ──');
    for (int i = 0; i < qs.length; i++) {
      final q = qs[i];
      final adj = QuestLogic.getAdjustedQuest(q, state.completionCounts[q.id] ?? 0);
      final ch = GameLogic.calculateSuccessChance(state.hero, adj);
      int dur = GameLogic.calculateQuestDuration(state.hero, adj);
      final done = state.completionCounts[q.id] ?? 0;
      final replay = done > 0 && q.isReplayable;
      final xp = replay ? (adj.repeatXpReward ?? adj.xpReward ~/ 2) : adj.xpReward;
      final gold = replay ? (adj.repeatGoldReward ?? adj.goldReward ~/ 2) : adj.goldReward;
      stdout.writeln('  [$i] ${q.id.padRight(16)} d${q.difficulty.toString().padLeft(2)} '
          '${ch.toStringAsFixed(0).padLeft(3)}%  ${dur}s  '
          '+${xp}xp +${gold}g  '
          '${q.isMainQuest ? "MAIN " : ""}${done > 0 ? "(done ${done}x)" : ""}');
    }
    return qs;
  }

  void doGo(String arg) {
    final qs = sim.attemptableQuests(state);
    Quest? quest;
    final idx = int.tryParse(arg);
    if (idx != null) {
      final sorted = [...qs]..sort((a, b) => a.difficulty.compareTo(b.difficulty));
      if (idx >= 0 && idx < sorted.length) quest = sorted[idx];
    } else {
      quest = qs.where((q) => q.id == arg).cast<Quest?>().firstWhere((q) => true,
          orElse: () => null);
    }
    if (quest == null) {
      stdout.writeln('  ! No attemptable quest "$arg". Type "q" to list.');
      return;
    }
    final hpBefore = state.hero.hp;
    final lvlBefore = state.hero.level;
    final step = sim.applyQuestStep(state, quest);
    final o = step.outcome;
    stdout.writeln('  > ${quest.title} (${step.durationSeconds}s'
        '${state.hero.hp < hpBefore || hpBefore < state.hero.maxHp ? "" : ""})'
        ' → ${o.success ? "SUCCESS" : "FAILED"}');
    if (o.success) {
      stdout.writeln('    +${o.goldGained}g +${o.xpGained}xp'
          '${o.loot != null ? ", loot: ${o.loot!.name} (${o.loot!.rarity.name})" : ""}'
          '${o.specialMuseumItemName != null ? ", museum: ${o.specialMuseumItemName}" : ""}'
          '${o.specialInventoryItem != null ? ", reward: ${o.specialInventoryItem!.name}" : ""}');
    }
    if (o.damage > 0) stdout.writeln('    -${o.damage} HP');
    if (o.levelsGained > 0) {
      stdout.writeln('    *** LEVEL UP to ${state.hero.level} '
          '(+${o.levelsGained} point${o.levelsGained > 1 ? "s" : ""}) ***');
    }
    if (o.downed) stdout.writeln('    !!! ${state.hero.name} was downed — recovered by resting.');
    if (o.discoveredQuestId != null) {
      stdout.writeln('    + New quest unlocked: ${o.discoveredQuestId}');
    }
    maybeTavern();
    if (state.completedQuestIds.contains('siege_capital')) {
      stdout.writeln('  ========================================');
      stdout.writeln('  *** ENDGAME CLEARED in ${fmtTime(state.totalSeconds)}'
          ' / ${lvlBefore} actions. Prestige available. ***');
      stdout.writeln('  ========================================');
    }
  }

  void doUp(String stat) {
    if ((state.hero.upgradePoints ?? 0) <= 0) {
      stdout.writeln('  ! No upgrade points.');
      return;
    }
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
      default:
        stdout.writeln('  ! Unknown stat. Use str|spd|hp|luck.');
        return;
    }
    state.hero = h.copyWith(upgradePoints: (h.upgradePoints ?? 0) - 1);
    stdout.writeln('  +1 $stat  (points left: ${state.hero.upgradePoints})');
  }

  void doAuto(String arg) {
    final n = int.tryParse(arg) ?? 1;
    final goldBefore = state.gold;
    final lvlBefore = state.hero.level;
    final actBefore = _autoActions;
    for (int i = 0; i < n; i++) {
      if (state.completedQuestIds.contains('siege_capital')) break;
      // Spend points via policy.
      while ((state.hero.upgradePoints ?? 0) > 0) {
        doUpSilent(state, autoPolicy.chooseStat(state.hero));
      }
      final target = sim.storyTarget(state);
      if (target != null &&
          !repo.hintsSatisfied(target, state.questHints) &&
          state.gold >= 500) {
        sim.buyShard(state);
      }
      Quest? pick;
      if (target != null &&
          repo.hintsSatisfied(target, state.questHints) &&
          GameLogic.calculateSuccessChance(state.hero, target) >=
              autoPolicy.mainAttemptThreshold) {
        pick = target;
      } else {
        pick = _bestGrind(sim, repo, state);
      }
      if (pick == null) break;
      sim.applyQuestStep(state, pick);
      _autoActions++;
      maybeTavern();
    }
    stdout.writeln('  auto: +${_autoActions - actBefore} quests, '
        '+${state.gold - goldBefore}g, level ${lvlBefore}→${state.hero.level}, '
        'time ${fmtTime(state.totalSeconds)}');
  }

  void printInv() {
    final h = state.hero;
    stdout.writeln('── EQUIPPED ──');
    stdout.writeln('  main : ${_itm(h.mainHand)}');
    stdout.writeln('  off  : ${_itm(h.offHand)}');
    stdout.writeln('  armor: ${_itm(h.armor)}');
    stdout.writeln('  acc  : ${_itm(h.accessory)}');
    stdout.writeln('── INVENTORY (${state.inventory.length}/${state.inventoryLimit}) ──');
    for (final it in state.inventory.take(20)) {
      stdout.writeln('  ${_itm(it)}');
    }
  }

  stdout.writeln('GUILDS OF ANTIQUITY — text play harness. Type "help".');
  printStatus();

  while (true) {
    stdout.write('\n> ');
    final line = stdin.readLineSync();
    if (line == null) break; // EOF
    final parts = line.trim().split(RegExp(r'\s+'));
    final cmd = parts.isEmpty ? '' : parts[0].toLowerCase();
    final arg = parts.length > 1 ? parts[1] : '';
    switch (cmd) {
      case '':
        break;
      case 'help':
      case 'h':
        stdout.writeln('''
  s / status            show hero + story target
  q / quests            list attemptable quests (indexed)
  go <id|index>         run a quest once (rests to full first)
  up <str|spd|hp|luck>  spend one upgrade point
  auto <n>              let the built-in bot play n quests (fast-forward)
  i / inv               show equipment + inventory
  shard                 buy a hint shard (500g)
  exit                  quit''');
        break;
      case 's':
      case 'status':
        printStatus();
        break;
      case 'q':
      case 'quests':
        listQuests();
        break;
      case 'go':
        doGo(arg);
        break;
      case 'up':
        doUp(arg);
        break;
      case 'auto':
        doAuto(arg);
        break;
      case 'i':
      case 'inv':
        printInv();
        break;
      case 'shard':
        if (state.gold >= 500) {
          sim.buyShard(state);
          stdout.writeln('  Bought a shard (a random hidden quest got a hint).');
        } else {
          stdout.writeln('  ! Need 500g.');
        }
        break;
      case 'exit':
      case 'quit':
        return;
      default:
        stdout.writeln('  ? unknown command "$cmd" (try "help")');
    }
  }
}

int _autoActions = 0;

void doUpSilent(SimState state, String stat) {
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

Quest? _bestGrind(Simulator sim, QuestRepo repo, SimState state) {
  Quest? best;
  double bestScore = -1;
  for (final q in sim.attemptableQuests(state)) {
    final completed = state.completedQuestIds.contains(q.id);
    final adj = QuestLogic.getAdjustedQuest(q, state.completionCounts[q.id] ?? 0);
    int xp = adj.xpReward;
    if (completed && adj.isReplayable) {
      xp = adj.repeatXpReward ?? (adj.xpReward ~/ 2);
    } else if (completed && !adj.isReplayable) {
      continue;
    }
    final chance = GameLogic.calculateSuccessChance(state.hero, adj) / 100.0;
    int dur = GameLogic.calculateQuestDuration(state.hero, adj);
    final score = (xp * chance) / dur;
    if (score > bestScore) {
      bestScore = score;
      best = q;
    }
  }
  return best;
}

String _itm(Item? it) {
  if (it == null) return '(empty)';
  final bonuses = <String>[];
  if (it.strengthBonus != 0) bonuses.add('str+${it.strengthBonus}');
  if (it.defenseBonus != 0) bonuses.add('def+${it.defenseBonus}');
  if (it.bonusSpd != 0) bonuses.add('spd+${it.bonusSpd}');
  if (it.bonusLuck != 0) bonuses.add('luck+${it.bonusLuck}');
  return '${it.name} [${it.rarity.name}] ${bonuses.join(" ")}';
}
