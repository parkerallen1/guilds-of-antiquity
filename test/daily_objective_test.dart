// Unit tests for the pure daily-objective logic. No Flutter binding / Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:guilds_of_antiquity/models/daily_objective.dart';

void main() {
  group('DailyObjective.progress', () {
    const obj = DailyObjective(
      type: DailyObjectiveType.completeQuests,
      target: 5,
      rewardGold: 100,
    );

    test('measures gain since baseline, clamped to target', () {
      expect(obj.progress(10, 8), 2); // 10 - 8
      expect(obj.progress(100, 8), 5); // clamped to target
      expect(obj.progress(8, 8), 0); // no progress yet
    });

    test('never reports negative progress (e.g. after a prestige reset)', () {
      expect(obj.progress(2, 8), 0);
    });

    test('isComplete only once the target is reached', () {
      expect(obj.isComplete(12, 8), isFalse); // 4 < 5
      expect(obj.isComplete(13, 8), isTrue); // 5 >= 5
    });
  });

  group('DailyObjective.forDate', () {
    test('always produces exactly 3 distinct objective types', () {
      final objs = DailyObjective.forDate('2026-06-23');
      expect(objs.length, 3);
      expect(objs.map((o) => o.type).toSet().length, 3);
    });

    test('is deterministic for the same date (stable across reloads)', () {
      final a = DailyObjective.forDate('2026-06-23');
      final b = DailyObjective.forDate('2026-06-23');
      expect(
        a.map((o) => '${o.type}:${o.target}:${o.rewardGold}').toList(),
        b.map((o) => '${o.type}:${o.target}:${o.rewardGold}').toList(),
      );
    });

    test('different dates can produce different objective sets', () {
      final a = DailyObjective.forDate('2026-06-23')
          .map((o) => '${o.type}:${o.target}')
          .toList();
      final b = DailyObjective.forDate('2026-09-01')
          .map((o) => '${o.type}:${o.target}')
          .toList();
      expect(a == b, isFalse);
    });

    test('serializes round-trip', () {
      final obj = DailyObjective.forDate('2026-06-23').first;
      final round = DailyObjective.fromJson(obj.toJson());
      expect(round.type, obj.type);
      expect(round.target, obj.target);
      expect(round.rewardGold, obj.rewardGold);
    });
  });
}
