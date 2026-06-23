import 'dart:math';

/// The kinds of short-term daily goal a player can be set. Each maps to a
/// monotonic lifetime metric measured against a day-start baseline.
enum DailyObjectiveType { completeQuests, earnGold, findItems, gainLevels }

/// One daily objective: a target on some metric and the gold it pays out.
/// Pure data + math — no Flutter, so it can be unit-tested directly.
class DailyObjective {
  final DailyObjectiveType type;
  final int target;
  final int rewardGold;

  const DailyObjective({
    required this.type,
    required this.target,
    required this.rewardGold,
  });

  String get title {
    switch (type) {
      case DailyObjectiveType.completeQuests:
        return 'Complete $target quests';
      case DailyObjectiveType.earnGold:
        return 'Earn $target gold';
      case DailyObjectiveType.findItems:
        return 'Find $target items';
      case DailyObjectiveType.gainLevels:
        return target == 1 ? 'Gain a level' : 'Gain $target levels';
    }
  }

  /// Progress toward this objective: how far the [current] lifetime metric has
  /// climbed since the day-start [baseline], clamped to [target].
  int progress(int current, int baseline) =>
      (current - baseline).clamp(0, target);

  bool isComplete(int current, int baseline) =>
      progress(current, baseline) >= target;

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'target': target,
        'rewardGold': rewardGold,
      };

  factory DailyObjective.fromJson(Map<String, dynamic> j) => DailyObjective(
        type: DailyObjectiveType.values[j['type'] as int],
        target: j['target'] as int,
        rewardGold: j['rewardGold'] as int,
      );

  /// The three objectives for a given [dateKey]. Generation is seeded from the
  /// date so it's stable across reloads (and the result is also persisted).
  static List<DailyObjective> forDate(String dateKey) {
    final rng = Random(_seedFor(dateKey));
    final types = List<DailyObjectiveType>.from(DailyObjectiveType.values)
      ..shuffle(rng);
    return [for (final t in types.take(3)) _build(t, rng)];
  }

  static DailyObjective _build(DailyObjectiveType type, Random rng) {
    switch (type) {
      case DailyObjectiveType.completeQuests:
        final target = 5 + rng.nextInt(6) * 5; // 5..30 (step 5)
        return DailyObjective(type: type, target: target, rewardGold: target * 20);
      case DailyObjectiveType.earnGold:
        final target = (2 + rng.nextInt(4)) * 250; // 500..1250
        return DailyObjective(
            type: type, target: target, rewardGold: (target * 0.2).round());
      case DailyObjectiveType.findItems:
        final target = 2 + rng.nextInt(4); // 2..5
        return DailyObjective(type: type, target: target, rewardGold: target * 100);
      case DailyObjectiveType.gainLevels:
        final target = 1 + rng.nextInt(3); // 1..3
        return DailyObjective(type: type, target: target, rewardGold: target * 150);
    }
  }

  /// Stable (run-independent) seed from a date key, so the same day always
  /// generates the same objectives even across app restarts.
  static int _seedFor(String dateKey) {
    int h = 0;
    for (final c in dateKey.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }
}
