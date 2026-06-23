import 'dart:io';

import '../lib/quest_repo.dart';
import '../lib/simulator.dart';
import '../lib/policies.dart';
import '../lib/metrics.dart';

/// Mass balance simulator.
///
/// Usage:
///   dart run bin/run_sim.dart [--policy NAME|--all] [--runs N]
///                             [--no-tavern] [--csv FILE] [--seed N]
void main(List<String> args) {
  final opts = _parse(args);
  final repo = QuestRepo.load();

  final policies = opts['all'] == true
      ? Policy.all
      : [(opts['policy'] as String?) ?? 'balanced'];
  final runs = int.parse((opts['runs'] as String?) ?? '100');
  final enableTavern = opts['no-tavern'] != true;
  final baseSeed = opts['seed'] != null ? int.parse(opts['seed'] as String) : null;

  stdout.writeln('=' * 78);
  stdout.writeln('GUILDS OF ANTIQUITY — headless balance simulation');
  stdout.writeln('runs/policy: $runs   tavern faucet: '
      '${enableTavern ? "on" : "OFF"}   (questing-only loop; business excluded)');
  stdout.writeln('=' * 78);

  final csvLines = <String>['policy,run,reachedEnd,actions,hours,finalLevel,'
      'successRate,downs,shards,replayAttempts,maxReplaysOneQuest'];

  // Critical-path gate order.
  final gateOrder = [
    'explore_ruins',
    'clear_forest',
    'defend_village',
    'mountain_pass',
    'cursed_temple',
    'dragon_lair',
    'dark_army',
    'siege_capital',
  ];

  for (final pname in policies) {
    final results = <RunResult>[];
    for (int i = 0; i < runs; i++) {
      final sim = Simulator(repo, seed: baseSeed != null ? baseSeed + i : null);
      final r = sim.run(SimConfig(
        policy: Policy.byName(pname),
        enableTavern: enableTavern,
      ));
      results.add(r);
      csvLines.add('$pname,$i,${r.reachedEnd},${r.actions},'
          '${r.totalHours.toStringAsFixed(1)},${r.finalLevel},'
          '${r.successRate.toStringAsFixed(3)},${r.downs},${r.shardsBought},'
          '${r.replayAttempts},${r.maxSingleQuestReplays}');
    }
    _report(pname, results, gateOrder, repo);
  }

  if (opts['csv'] != null) {
    File(opts['csv'] as String).writeAsStringSync(csvLines.join('\n'));
    stdout.writeln('\nPer-run CSV written to ${opts['csv']}');
  }
}

void _report(
  String policy,
  List<RunResult> results,
  List<String> gateOrder,
  QuestRepo repo,
) {
  final n = results.length;
  final reached = results.where((r) => r.reachedEnd).length;

  stdout.writeln('\n${'-' * 78}');
  stdout.writeln('POLICY: $policy   ($n runs)');
  stdout.writeln('-' * 78);
  stdout.writeln('  reached endgame (siege_capital): $reached/$n '
      '(${(100 * reached / n).toStringAsFixed(0)}%)');
  stdout.writeln('  median total play-time : '
      '${median(results.map((r) => r.totalHours).toList()).toStringAsFixed(1)} h'
      '   (questing '
      '${median(results.map((r) => r.questingSeconds / 3600).toList()).toStringAsFixed(1)}h'
      ' + healing '
      '${median(results.map((r) => r.healingSeconds / 3600).toList()).toStringAsFixed(1)}h)');
  stdout.writeln('  median quest attempts  : '
      '${median(results.map((r) => r.actions.toDouble()).toList()).toStringAsFixed(0)}'
      '   (of which replays: '
      '${median(results.map((r) => r.replayAttempts.toDouble()).toList()).toStringAsFixed(0)})');
  stdout.writeln('  median final level     : '
      '${median(results.map((r) => r.finalLevel.toDouble()).toList()).toStringAsFixed(0)}');
  stdout.writeln('  median success rate    : '
      '${(100 * median(results.map((r) => r.successRate).toList())).toStringAsFixed(0)}%');
  stdout.writeln('  median downs (deaths)  : '
      '${median(results.map((r) => r.downs.toDouble()).toList()).toStringAsFixed(0)}');
  stdout.writeln('  median shards bought   : '
      '${median(results.map((r) => r.shardsBought.toDouble()).toList()).toStringAsFixed(0)}'
      '   median most-replayed single quest: '
      '${median(results.map((r) => r.maxSingleQuestReplays.toDouble()).toList()).toStringAsFixed(0)}x');

  // Per-gate grind analysis.
  stdout.writeln('\n  STORY-GATE PROGRESSION (median across runs that reached each gate)');
  stdout.writeln('  ${'gate'.padRight(18)} ${'diff'.padLeft(4)} '
      '${'lvl'.padLeft(4)} ${'cum.attempts'.padLeft(12)} '
      '${'cum.hours'.padLeft(10)} ${'grind→gate(attempts/hrs)'.padLeft(26)}');

  Map<String, List<GateClear>> byGate = {};
  for (final r in results) {
    for (final g in r.gates) {
      byGate.putIfAbsent(g.questId, () => []).add(g);
    }
  }

  double prevAttempts = 0, prevHours = 0;
  for (final gid in gateOrder) {
    final gs = byGate[gid] ?? [];
    final q = repo.byId(gid);
    if (gs.isEmpty) {
      stdout.writeln('  ${gid.padRight(18)} ${(q?.difficulty ?? 0).toString().padLeft(4)} '
          '${'—'.padLeft(4)} ${'(not reached)'.padLeft(12)}');
      continue;
    }
    final medLvl = median(gs.map((g) => g.heroLevel.toDouble()).toList());
    final medAtt = median(gs.map((g) => g.atAction.toDouble()).toList());
    final medHrs = median(gs.map((g) => g.atSeconds / 3600).toList());
    final segAtt = medAtt - prevAttempts;
    final segHrs = medHrs - prevHours;
    stdout.writeln('  ${gid.padRight(18)} ${q!.difficulty.toString().padLeft(4)} '
        '${medLvl.toStringAsFixed(0).padLeft(4)} '
        '${medAtt.toStringAsFixed(0).padLeft(12)} '
        '${medHrs.toStringAsFixed(1).padLeft(10)} '
        '${'${segAtt.toStringAsFixed(0)} / ${segHrs.toStringAsFixed(1)}h'.padLeft(26)}');
    prevAttempts = medAtt;
    prevHours = medHrs;
  }
}

Map<String, dynamic> _parse(List<String> args) {
  final m = <String, dynamic>{};
  for (int i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--all') {
      m['all'] = true;
    } else if (a == '--no-tavern') {
      m['no-tavern'] = true;
    } else if (a.startsWith('--')) {
      final key = a.substring(2);
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        m[key] = args[++i];
      } else {
        m[key] = true;
      }
    }
  }
  return m;
}
