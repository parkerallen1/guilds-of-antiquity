// Unit tests for hero-class mechanical identity. No Flutter binding / Hive.

import 'package:flutter_test/flutter_test.dart';
import 'package:guilds_of_antiquity/models/hero_class.dart';

void main() {
  group('HeroClasses.of', () {
    test('each class has its distinct passive lever', () {
      expect(HeroClasses.of('Thief').goldMult, greaterThan(1.0));
      expect(HeroClasses.of('Mage').xpMult, greaterThan(1.0));
      expect(HeroClasses.of('Ranger').dropBonus, greaterThan(0.0));
      expect(HeroClasses.of('Warrior').damageTakenMult, lessThan(1.0));
    });

    test('unknown classes (e.g. the sim hero) are neutral', () {
      final m = HeroClasses.of('Mercenary');
      expect(m.goldMult, 1.0);
      expect(m.xpMult, 1.0);
      expect(m.dropBonus, 0.0);
      expect(m.damageTakenMult, 1.0);
    });

    test('a class boosts exactly one lever, leaving the rest neutral', () {
      final thief = HeroClasses.of('Thief');
      expect(thief.xpMult, 1.0);
      expect(thief.dropBonus, 0.0);
      expect(thief.damageTakenMult, 1.0);
    });
  });
}
