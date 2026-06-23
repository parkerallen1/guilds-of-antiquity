// Unit tests for the pure offline catch-up math. No Flutter binding / Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:guilds_of_antiquity/engine/offline_progress.dart';
import 'package:guilds_of_antiquity/models/hero_model.dart';

HeroModel _hero({required int hp, int maxHp = 100, int speed = 0}) {
  return HeroModel(
    id: 'h',
    name: 'Test',
    classType: 'Mercenary',
    strength: 5,
    speed: speed,
    hp: hp,
    maxHp: maxHp,
    level: 1,
    xp: 0,
    upgradePoints: 0,
    luck: 0,
  );
}

void main() {
  group('OfflineProgress.healedHp', () {
    test('a full hero heals nothing', () {
      expect(OfflineProgress.healedHp(_hero(hp: 100), const Duration(hours: 5)),
          0);
    });

    test('non-positive elapsed heals nothing', () {
      expect(OfflineProgress.healedHp(_hero(hp: 10), Duration.zero), 0);
    });

    test('one hour at base rate (speed 0) heals a full bar', () {
      // 3600s at base => full maxHp; from 0 HP that is the whole bar.
      expect(OfflineProgress.healedHp(_hero(hp: 0), const Duration(hours: 1)),
          100);
    });

    test('healing never overshoots maxHp', () {
      final healed =
          OfflineProgress.healedHp(_hero(hp: 90), const Duration(hours: 10));
      expect(healed, 10);
    });

    test('half an hour at base rate heals roughly half a bar', () {
      final healed =
          OfflineProgress.healedHp(_hero(hp: 0), const Duration(minutes: 30));
      expect(healed, closeTo(50, 1));
    });

    test('higher Speed heals faster for the same elapsed time', () {
      final slow =
          OfflineProgress.healedHp(_hero(hp: 0, speed: 0), const Duration(minutes: 10));
      final fast =
          OfflineProgress.healedHp(_hero(hp: 0, speed: 100), const Duration(minutes: 10));
      expect(fast, greaterThan(slow));
    });
  });
}
